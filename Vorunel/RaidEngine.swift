import Foundation

// MARK: - Deterministic tick engine. All randomness flows through state.rng.

enum RaidEngine {

    static func step(_ s: inout RaidState) {
        guard s.phase == .running else { return }
        s.tick += 1

        cooldownTick(&s)
        heroPhase(&s)
        guard s.phase == .running else { return }
        monsterPhase(&s)
        guard s.phase == .running else { return }
        moralePhase(&s)
        endCheck(&s)
    }

    // MARK: - Hero phase

    private static func heroPhase(_ s: inout RaidState) {
        for i in s.heroes.indices {
            guard s.phase == .running else { return }
            switch s.heroes[i].status {
            case .dead, .escaped:
                continue
            case .waiting:
                s.heroes[i].entryDelay -= 1
                if s.heroes[i].entryDelay <= 0 {
                    s.heroes[i].status = .advancing
                    s.heroes[i].pos = DungeonState.entrancePoint
                    s.addLog("\(s.heroes[i].name) (\(s.heroes[i].cls.displayName)) enters the dungeon.", .bad)
                }
                continue
            case .advancing, .retreating:
                tickStatuses(&s, i)
                guard s.heroes[i].status == .advancing || s.heroes[i].status == .retreating else { continue }
                actHero(&s, i)
            }
        }
    }

    private static func tickStatuses(_ s: inout RaidState, _ i: Int) {
        if s.heroes[i].poisonTicks > 0 {
            s.heroes[i].poisonTicks -= 1
            damageHero(&s, i, s.heroes[i].poisonDmg, source: "poison")
            if s.heroes[i].status == .dead { return }
        }
        if s.heroes[i].burnTicks > 0 {
            s.heroes[i].burnTicks -= 1
            damageHero(&s, i, s.heroes[i].burnDmg, source: "flames")
            if s.heroes[i].status == .dead { return }
        }
        // Paladin stalwart self-mend
        if s.heroes[i].cls == .paladin && s.heroes[i].hp < s.heroes[i].maxHP * 0.5 {
            let heal = 5.0 * HeroCatalog.levelScale(s.heroes[i].level)
            s.heroes[i].hp = min(s.heroes[i].maxHP, s.heroes[i].hp + heal)
        }
    }

    private static func actHero(_ s: inout RaidState, _ i: Int) {
        let pos = s.heroes[i].pos
        let foes = monsterIndices(s, at: pos)

        if !foes.isEmpty {
            s.heroes[i].nextStep = nil
            heroFight(&s, i, foes: foes)
            return
        }

        // Cleric mends the most wounded ally instead of advancing.
        if s.heroes[i].cls == .cleric, let t = woundedAlly(s), let ti = s.heroes.firstIndex(where: { $0.id == t }) {
            var heal = HeroCatalog.healPower(s.heroes[i].level)
            if s.modifiers.contains(.blessed) { heal *= 1.5 }
            s.heroes[ti].hp = min(s.heroes[ti].maxHP, s.heroes[ti].hp + heal)
            s.heroes[i].nextStep = nil
            return
        }

        // Loot a stocked treasury underfoot.
        let tIdx = s.dungeon.index(pos)
        if s.heroes[i].status == .advancing && s.dungeon.tiles[tIdx].loot > 0 {
            let grabbed = s.dungeon.tiles[tIdx].loot
            s.dungeon.tiles[tIdx].loot = 0
            s.heroes[i].carried += grabbed
            s.treasuriesLooted += 1
            s.addLog("\(s.heroes[i].name) loots \(grabbed) gold from your treasury.", .loot)
            s.heroes[i].nextStep = nil
            return
        }

        // Strike the Dungeon Heart.
        if s.heroes[i].status == .advancing && pos == DungeonState.heartPoint {
            let atk = heroAttack(s, i)
            s.heartHP -= atk
            s.heartDamage += atk
            s.heroes[i].nextStep = nil
            if s.tick % 4 == 0 || s.heartHP <= 0 {
                s.addLog("\(s.heroes[i].name) strikes the Dungeon Heart!", .bad)
            }
            if s.heartHP <= 0 {
                s.heartHP = 0
                s.phase = .lost
                s.addLog("The Dungeon Heart shatters. The raid has beaten you.", .bad)
            }
            return
        }

        // Otherwise: move.
        if s.heroes[i].rooted > 0 {
            s.heroes[i].rooted -= 1
            s.heroes[i].nextStep = nil
            return
        }
        if s.heroes[i].moveCD > 0 {
            s.heroes[i].moveCD -= 1
            return
        }
        moveHero(&s, i)
    }

    private static func heroFight(_ s: inout RaidState, _ i: Int, foes: [Int]) {
        let atk = heroAttack(s, i)

        if s.heroes[i].cls == .mage {
            // Area caster: hits every monster in the room.
            for m in foes {
                dealToMonster(&s, m, atk, heroIdx: i)
                guard s.phase == .running else { return }
            }
            return
        }

        // Pick target: taunting golem first, otherwise the weakest.
        var targetIdx = foes[0]
        let taunters = foes.filter { MonsterCatalog.def(s.monsters[$0].family).ability == .taunt }
        if let t = taunters.first {
            targetIdx = t
        } else {
            targetIdx = foes.min(by: { s.monsters[$0].hp < s.monsters[$1].hp }) ?? foes[0]
        }

        var dmg = atk
        if s.heroes[i].cls == .ranger && s.monsters[targetIdx].hp >= s.monsters[targetIdx].maxHP {
            dmg *= 1.25
        }
        dealToMonster(&s, targetIdx, dmg, heroIdx: i)
    }

    private static func heroAttack(_ s: RaidState, _ i: Int) -> Double {
        var atk = HeroCatalog.atk(s.heroes[i].cls, level: s.heroes[i].level)
        if s.heroes[i].isBoss { atk *= 1.4 }
        if s.heroes[i].phase2 { atk *= 1.4 }
        if s.heroes[i].cls == .mage && s.modifiers.contains(.arcane) { atk *= 1.4 }
        return atk
    }

    private static func dealToMonster(_ s: inout RaidState, _ m: Int, _ raw: Double, heroIdx: Int) {
        guard s.monsters[m].hp > 0 else { return }
        let fam = s.monsters[m].family
        if s.rng.chance(MonsterCatalog.dodge(fam)) { return }
        let dmg = max(1, raw - MonsterCatalog.armor(fam, tier: s.monsters[m].tier))
        s.monsters[m].hp -= dmg
        if s.monsters[m].hp <= 0 {
            s.monsters[m].hp = 0
            s.monstersLost += 1
            s.addLog("\(MonsterCatalog.tierName(fam, tier: s.monsters[m].tier)) falls to \(s.heroes[heroIdx].name).", .damage)
        }
    }

    // MARK: - Monster phase

    private static func monsterPhase(_ s: inout RaidState) {
        for m in s.monsters.indices {
            guard s.phase == .running else { return }
            guard s.monsters[m].hp > 0 else { continue }
            let fam = s.monsters[m].family
            let tier = s.monsters[m].tier
            let def = MonsterCatalog.def(fam)

            // Regeneration: slimes always, anyone on/adjacent to a shrine.
            var regen = MonsterCatalog.regenPerTick(fam, tier: tier)
            if nearShrine(s, s.monsters[m].pos) { regen += 2.0 * Double(tier) }
            if regen > 0 {
                s.monsters[m].hp = min(s.monsters[m].maxHP, s.monsters[m].hp + regen)
            }

            let targets = heroIndices(s, at: s.monsters[m].pos)
            guard !targets.isEmpty else { continue }

            var atk = MonsterCatalog.atk(fam, tier: tier)
            if def.ability == .swarm {
                atk *= 1.0 + 0.15 * Double(adjacentLivingGoblins(s, s.monsters[m].pos))
            }
            if adjacentLivingCultist(s, s.monsters[m].pos) { atk *= 1.2 }
            if s.modifiers.contains(.torchlit) { atk *= 0.85 }
            if def.ability == .brutal && s.rng.chance(0.25) { atk *= 2 }

            if def.ability == .splash {
                for h in targets {
                    monsterStrike(&s, m, h, atk)
                    guard s.phase == .running else { return }
                }
            } else {
                let h = pickHeroTarget(s, targets)
                monsterStrike(&s, m, h, atk)
            }
        }
    }

    private static func pickHeroTarget(_ s: RaidState, _ targets: [Int]) -> Int {
        // Warriors tank, then paladins, otherwise the most wounded.
        if let w = targets.first(where: { s.heroes[$0].cls == .warrior }) { return w }
        if let p = targets.first(where: { s.heroes[$0].cls == .paladin }) { return p }
        return targets.min(by: { s.heroes[$0].hp < s.heroes[$1].hp }) ?? targets[0]
    }

    private static func monsterStrike(_ s: inout RaidState, _ m: Int, _ h: Int, _ atk: Double) {
        guard s.heroes[h].status == .advancing || s.heroes[h].status == .retreating else { return }
        if s.rng.chance(HeroCatalog.def(s.heroes[h].cls).dodge) { return }
        let def = MonsterCatalog.def(s.monsters[m].family)
        damageHero(&s, h, atk, source: MonsterCatalog.tierName(s.monsters[m].family, tier: s.monsters[m].tier))
        guard s.heroes[h].status != .dead else { return }
        switch def.ability {
        case .web:
            if s.rng.chance(0.3) { s.heroes[h].rooted = max(s.heroes[h].rooted, 2) }
        case .venom:
            s.heroes[h].poisonTicks = max(s.heroes[h].poisonTicks, 3)
            s.heroes[h].poisonDmg = 2.0 * Double(s.monsters[m].tier)
        case .drain:
            s.monsters[m].hp = min(s.monsters[m].maxHP, s.monsters[m].hp + atk / 2)
        default:
            break
        }
    }

    // MARK: - Shared damage / death

    static func damageHero(_ s: inout RaidState, _ h: Int, _ dmg: Double, source: String) {
        guard s.heroes[h].status == .advancing || s.heroes[h].status == .retreating else { return }
        s.heroes[h].hp -= dmg

        // Legendary two-phase turn.
        if s.heroes[h].isBoss && !s.heroes[h].phase2 && s.heroes[h].hp > 0
            && s.heroes[h].hp <= s.heroes[h].maxHP * 0.5 {
            s.heroes[h].phase2 = true
            s.heroes[h].hp = min(s.heroes[h].maxHP, s.heroes[h].hp + s.heroes[h].maxHP * 0.3)
            s.addLog("\(s.heroes[h].name) unleashes their second wind — stronger and angrier!", .boss)
            return
        }

        if s.heroes[h].hp <= 0 {
            s.heroes[h].hp = 0
            s.heroes[h].status = .dead
            s.heroesSlain += 1
            s.goldRecovered += s.heroes[h].carried
            if s.heroes[h].carried > 0 {
                s.addLog("\(s.heroes[h].name) dies; you reclaim \(s.heroes[h].carried) gold.", .good)
            } else {
                s.addLog("\(s.heroes[h].name) is slain by \(source).", .good)
            }
            s.heroes[h].carried = 0
            if s.heroes[h].isBoss {
                s.bossesSlain.append(s.heroes[h].name)
                s.addLog("The legend \(s.heroes[h].name) is no more.", .boss)
            }
            if source == "the Mimic Chest" { s.mimicKill = true }
            // Grief shakes the survivors.
            var grief = 22.0
            if s.modifiers.contains(.blessed) { grief *= 0.6 }
            for j in s.heroes.indices where s.heroes[j].status == .advancing {
                s.heroes[j].morale = max(0, s.heroes[j].morale - grief)
            }
        }
    }

    // MARK: - Morale

    private static func moralePhase(_ s: inout RaidState) {
        guard !s.modifiers.contains(.ironwill) else { return }
        for i in s.heroes.indices {
            guard s.heroes[i].status == .advancing else { continue }
            guard !s.heroes[i].isBoss else { continue }
            if s.heroes[i].morale < 30 && s.rng.chance(0.25) {
                s.heroes[i].status = .retreating
                s.addLog("\(s.heroes[i].name)'s nerve breaks — they flee for the entrance!", .good)
            }
        }
    }

    // MARK: - End conditions

    private static func endCheck(_ s: inout RaidState) {
        if !s.anyActiveHero {
            s.phase = .won
            s.addLog("The raid is broken. Your dungeon stands.", .good)
        }
        if s.tick > 2400 {
            // Failsafe: should be unreachable, but never let a raid run forever.
            s.phase = .won
            s.addLog("The invaders give up their long siege.", .good)
        }
    }

    // MARK: - Movement & traps

    private static func moveHero(_ s: inout RaidState, _ i: Int) {
        let hero = s.heroes[i]
        let goal: GridPoint
        if hero.status == .retreating {
            goal = DungeonState.entrancePoint
        } else {
            goal = advanceGoal(s, i)
        }

        guard let step = nextStepToward(s, from: hero.pos, to: goal,
                                        cautious: hero.personality == .cautious) else {
            s.heroes[i].nextStep = nil
            return
        }
        s.heroes[i].nextStep = step
        s.heroes[i].pos = step

        // Escape through the entrance.
        if hero.status == .retreating && step == DungeonState.entrancePoint {
            s.heroes[i].status = .escaped
            s.heroesEscaped += 1
            if s.heroes[i].carried > 0 {
                s.addLog("\(hero.name) escapes with \(s.heroes[i].carried) of your gold!", .bad)
            } else {
                s.addLog("\(hero.name) flees the dungeon.", .info)
            }
            return
        }

        // Movement cost.
        var cd = s.modifiers.contains(.hasted) ? 1 : HeroCatalog.def(hero.cls).moveInterval
        if s.heroes[i].slowCharges > 0 {
            s.heroes[i].slowCharges -= 1
            cd += 2
        }
        s.heroes[i].moveCD = cd

        onEnterTile(&s, i)
    }

    /// Where an advancing hero wants to go: treasure for the greedy, the Heart otherwise.
    private static func advanceGoal(_ s: RaidState, _ i: Int) -> GridPoint {
        let greedy = s.heroes[i].personality == .greedy || s.modifiers.contains(.greedy)
        if greedy {
            var best: GridPoint? = nil
            var bestDist = Int.max
            for p in s.dungeon.allPoints {
                let idx = s.dungeon.index(p)
                let tile = s.dungeon.tiles[idx]
                guard tile.kind.isOpen else { continue }
                let isBait = tile.loot > 0
                let isMimicLure = tile.trap?.type == .mimicChest && !s.disarmedTraps.contains(idx)
                guard isBait || isMimicLure else { continue }
                if let d = pathDistance(s, from: s.heroes[i].pos, to: p), d < bestDist {
                    bestDist = d
                    best = p
                }
            }
            if let b = best { return b }
        }
        return DungeonState.heartPoint
    }

    private static func onEnterTile(_ s: inout RaidState, _ i: Int) {
        let pos = s.heroes[i].pos
        let idx = s.dungeon.index(pos)
        let tile = s.dungeon.tiles[idx]

        // Illusion hall: lose a step to disorientation.
        if tile.kind == .illusionHall && s.rng.chance(0.3) {
            s.heroes[i].moveCD += 2
            if s.tick % 3 == 0 { s.addLog("\(s.heroes[i].name) wanders in circles in the Hall of Lies.", .info) }
        }

        guard let trap = tile.trap,
              !s.disarmedTraps.contains(idx),
              (s.trapCooldowns[idx] ?? 0) <= 0 else { return }

        let def = TrapCatalog.def(trap.type)

        // Rogues read traps like an open book.
        if s.heroes[i].cls == .rogue {
            let chance = TrapCatalog.disarmChance(trap.type, level: trap.level, heroLevel: s.heroes[i].level)
            if s.rng.chance(chance) {
                s.disarmedTraps.insert(idx)
                s.addLog("\(s.heroes[i].name) disarms your \(def.name)!", .bad)
                return
            }
        }

        // Trigger.
        s.trapCooldowns[idx] = def.cooldown
        s.sprungTraps.insert(idx)
        s.trapsTriggered += 1
        let dmg = TrapCatalog.damage(trap.type, level: trap.level, inChamber: tile.kind == .trapChamber)

        var moraleHit = 8.0
        if s.modifiers.contains(.blessed) { moraleHit *= 0.6 }

        switch trap.type {
        case .spike, .crusher:
            s.addLog("\(def.name) catches \(s.heroes[i].name) for \(Int(dmg)) damage.", .damage)
            hitByTrap(&s, i, dmg, def.name, moraleHit)
        case .fireJet:
            s.heroes[i].burnTicks = 3
            s.heroes[i].burnDmg = dmg * 0.25
            s.addLog("\(def.name) scorches \(s.heroes[i].name).", .damage)
            hitByTrap(&s, i, dmg, def.name, moraleHit)
        case .frostRune:
            s.heroes[i].slowCharges = max(s.heroes[i].slowCharges, 2)
            s.addLog("\(def.name) freezes \(s.heroes[i].name)'s boots to the floor.", .damage)
            hitByTrap(&s, i, dmg, def.name, moraleHit)
        case .pit:
            s.heroes[i].rooted = max(s.heroes[i].rooted, 2)
            s.addLog("\(s.heroes[i].name) tumbles into a hidden pit.", .damage)
            hitByTrap(&s, i, dmg, def.name, moraleHit)
        case .poisonDart:
            s.heroes[i].poisonTicks = max(s.heroes[i].poisonTicks, 4)
            s.heroes[i].poisonDmg = dmg * 0.3
            s.addLog("\(def.name) stings \(s.heroes[i].name); venom spreads.", .damage)
            hitByTrap(&s, i, dmg, def.name, moraleHit)
        case .glue:
            s.heroes[i].rooted = max(s.heroes[i].rooted, 3)
            s.addLog("\(s.heroes[i].name) is stuck fast in the glue floor.", .damage)
            heroMorale(&s, i, moraleHit)
        case .fearTotem:
            var hit = 35.0
            if s.heroes.contains(where: { $0.cls == .paladin && ($0.status == .advancing || $0.status == .retreating) }) { hit *= 0.5 }
            if s.modifiers.contains(.blessed) { hit *= 0.6 }
            heroMorale(&s, i, hit)
            s.addLog("The Fear Totem whispers to \(s.heroes[i].name). They do not like what they hear.", .damage)
        case .lightningCoil:
            s.addLog("\(def.name) arcs through everyone in the corridor!", .damage)
            let everyone = heroIndices(s, at: pos)
            for h in everyone {
                hitByTrap(&s, h, dmg, def.name, moraleHit)
                guard s.phase == .running else { return }
            }
        case .mimicChest:
            s.disarmedTraps.insert(idx)   // one bite, then the ruse is done
            s.addLog("The treasure chest sprouts teeth — it bites \(s.heroes[i].name)!", .damage)
            hitByTrapNamed(&s, i, dmg, "the Mimic Chest", moraleHit + 10)
        }
    }

    private static func hitByTrap(_ s: inout RaidState, _ i: Int, _ dmg: Double, _ name: String, _ moraleHit: Double) {
        hitByTrapNamed(&s, i, dmg, "your " + name, moraleHit)
    }

    private static func hitByTrapNamed(_ s: inout RaidState, _ i: Int, _ dmg: Double, _ name: String, _ moraleHit: Double) {
        heroMorale(&s, i, moraleHit)
        damageHero(&s, i, dmg, source: name)
    }

    private static func heroMorale(_ s: inout RaidState, _ i: Int, _ loss: Double) {
        s.heroes[i].morale = max(0, s.heroes[i].morale - loss)
    }

    // MARK: - Queries

    static func monsterIndices(_ s: RaidState, at p: GridPoint) -> [Int] {
        s.monsters.indices.filter { s.monsters[$0].hp > 0 && s.monsters[$0].pos == p }
    }

    static func heroIndices(_ s: RaidState, at p: GridPoint) -> [Int] {
        s.heroes.indices.filter { ($0 < s.heroes.count) && s.heroes[$0].onBoard && s.heroes[$0].pos == p }
    }

    private static func woundedAlly(_ s: RaidState) -> Int? {
        var bestID: Int? = nil
        var bestRatio = 0.75
        for h in s.heroes where h.onBoard {
            let ratio = h.hp / h.maxHP
            if ratio < bestRatio {
                bestRatio = ratio
                bestID = h.id
            }
        }
        return bestID
    }

    private static func nearShrine(_ s: RaidState, _ p: GridPoint) -> Bool {
        if s.dungeon.tile(at: p).kind == .shrine { return true }
        return s.dungeon.neighbors(of: p).contains { s.dungeon.tile(at: $0).kind == .shrine }
    }

    private static func adjacentLivingGoblins(_ s: RaidState, _ p: GridPoint) -> Int {
        let near = s.dungeon.neighbors(of: p)
        return s.monsters.filter { $0.hp > 0 && $0.family == .goblin && near.contains($0.pos) }.count
    }

    private static func adjacentLivingCultist(_ s: RaidState, _ p: GridPoint) -> Bool {
        let near = s.dungeon.neighbors(of: p)
        return s.monsters.contains { $0.hp > 0 && $0.family == .cultist && near.contains($0.pos) }
    }

    // MARK: - Pathfinding (Dijkstra over the 9x12 grid; tiny, so simple arrays suffice)

    static func nextStepToward(_ s: RaidState, from: GridPoint, to: GridPoint, cautious: Bool) -> GridPoint? {
        if from == to { return nil }
        let total = DungeonState.cols * DungeonState.rows
        var dist = Array(repeating: Int.max, count: total)
        var prev = Array(repeating: -1, count: total)
        var done = Array(repeating: false, count: total)
        let startIdx = s.dungeon.index(from)
        dist[startIdx] = 0

        for _ in 0..<total {
            var u = -1
            var best = Int.max
            for v in 0..<total where !done[v] && dist[v] < best {
                best = dist[v]; u = v
            }
            if u == -1 { break }
            done[u] = true
            if u == s.dungeon.index(to) { break }
            let up = GridPoint(x: u % DungeonState.cols, y: u / DungeonState.cols)
            for n in s.dungeon.neighbors(of: up) {
                let ni = s.dungeon.index(n)
                guard s.dungeon.tiles[ni].kind.isOpen else { continue }
                var cost = 1
                if cautious,
                   s.dungeon.tiles[ni].trap != nil,
                   !s.disarmedTraps.contains(ni),
                   s.sprungTraps.contains(ni) {
                    cost += 6
                }
                if dist[u] != Int.max && dist[u] + cost < dist[ni] {
                    dist[ni] = dist[u] + cost
                    prev[ni] = u
                }
            }
        }

        var cur = s.dungeon.index(to)
        guard dist[cur] != Int.max else { return nil }
        while prev[cur] != startIdx && prev[cur] != -1 {
            cur = prev[cur]
        }
        guard prev[cur] == startIdx else { return nil }
        return GridPoint(x: cur % DungeonState.cols, y: cur / DungeonState.cols)
    }

    static func pathDistance(_ s: RaidState, from: GridPoint, to: GridPoint) -> Int? {
        if from == to { return 0 }
        let total = DungeonState.cols * DungeonState.rows
        var dist = Array(repeating: -1, count: total)
        var queue = [from]
        dist[s.dungeon.index(from)] = 0
        var head = 0
        while head < queue.count {
            let cur = queue[head]; head += 1
            if cur == to { return dist[s.dungeon.index(cur)] }
            for n in s.dungeon.neighbors(of: cur) {
                let ni = s.dungeon.index(n)
                guard dist[ni] == -1, s.dungeon.tiles[ni].kind.isOpen else { continue }
                dist[ni] = dist[s.dungeon.index(cur)] + 1
                queue.append(n)
            }
        }
        return nil
    }

    /// Tick down trap cooldowns once per engine step (called from step's hero phase wrapper).
    static func cooldownTick(_ s: inout RaidState) {
        for (k, v) in s.trapCooldowns where v > 0 {
            s.trapCooldowns[k] = v - 1
        }
    }
}
