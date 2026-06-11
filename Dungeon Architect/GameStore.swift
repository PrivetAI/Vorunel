import SwiftUI
import Combine

// MARK: - Screens (custom router; every screen has an explicit exit)

enum AppScreen: Equatable {
    case menu
    case campaign
    case briefing(Int)
    case editor
    case raid
    case result
    case unlocks
    case endless
    case codex
    case achievements
    case settings
    case onboarding
}

// MARK: - Player profile (everything persisted under dar.profile)

struct PlayerProfile: Codable {
    var gold: Int = 750
    var renown: Int = 0
    var unlocked: Set<String> = []
    var campaignStars: [Int: Int] = [:]
    var bossesSlainNames: Set<String> = []
    var endlessBest: Int = 0
    var endlessWave: Int = 1
    var endlessSeed: UInt64 = 0
    var achievements: Set<String> = []
    var stats = GameStats()
    var settings = AppSettings()
    var onboardingDone: Bool = false
    var dungeon = DungeonState.freshStart()
}

// MARK: - Store

final class GameStore: ObservableObject {
    static let profileKey = "dar.profile"
    static let raidKey = "dar.raid"

    @Published var profile: PlayerProfile
    @Published var screen: AppScreen = .menu
    @Published var activeRaid: RaidState? = nil
    @Published var lastOutcome: RaidOutcome? = nil
    @Published var raidSnapshotExists: Bool = false

    /// What the editor is preparing for (set by briefing / endless hub).
    @Published var pendingContext: RaidContext? = nil

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.profileKey),
           let p = try? JSONDecoder().decode(PlayerProfile.self, from: data) {
            profile = p
        } else {
            profile = PlayerProfile()
        }
        raidSnapshotExists = UserDefaults.standard.data(forKey: Self.raidKey) != nil
        SoundBox.shared.enabled = profile.settings.soundOn
        Haptics.enabled = profile.settings.hapticsOn
        if !profile.onboardingDone { screen = .onboarding }
    }

    func save() {
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: Self.profileKey)
        }
    }

    // MARK: - Settings

    func setSound(_ on: Bool) {
        profile.settings.soundOn = on
        SoundBox.shared.enabled = on
        save()
    }
    func setHaptics(_ on: Bool) {
        profile.settings.hapticsOn = on
        Haptics.enabled = on
        save()
    }
    func resetProgress() {
        profile = PlayerProfile()
        profile.onboardingDone = true
        activeRaid = nil
        lastOutcome = nil
        pendingContext = nil
        clearRaidSnapshot()
        save()
    }

    // MARK: - Unlock tree

    var unlockedMonsters: Set<MonsterFamily> {
        var set = UnlockTree.starterMonsters
        for id in profile.unlocked {
            if case .monsters(let fams)? = UnlockTree.node(id)?.effect { set.formUnion(fams) }
        }
        return set
    }
    var unlockedTraps: Set<TrapType> {
        var set = UnlockTree.starterTraps
        for id in profile.unlocked {
            if case .traps(let ts)? = UnlockTree.node(id)?.effect { set.formUnion(ts) }
        }
        return set
    }
    var unlockedRooms: Set<TileKind> {
        var set = UnlockTree.starterRooms
        for id in profile.unlocked {
            if case .rooms(let rs)? = UnlockTree.node(id)?.effect { set.formUnion(rs) }
        }
        return set
    }
    var trapMaxLevel: Int { profile.unlocked.contains("trapmastery") ? 3 : 2 }
    var upkeepFactor: Double { profile.unlocked.contains("bargain") ? 0.75 : 1.0 }
    var rewardFactor: Double { profile.unlocked.contains("warchest") ? 1.2 : 1.0 }

    var heartMaxHP: Double {
        var hp = 400.0 + 120.0 * Double(profile.dungeon.heartLevel - 1)
        for id in profile.unlocked {
            if case .heartHP(let bonus)? = UnlockTree.node(id)?.effect { hp += Double(bonus) }
        }
        return hp
    }

    func nodeState(_ node: UnlockNode) -> (owned: Bool, available: Bool) {
        let owned = profile.unlocked.contains(node.id)
        let reqMet = node.requires.allSatisfy { profile.unlocked.contains($0) }
        return (owned, !owned && reqMet)
    }

    func buyNode(_ node: UnlockNode) -> Bool {
        let st = nodeState(node)
        guard st.available, profile.renown >= node.cost else { return false }
        profile.renown -= node.cost
        profile.unlocked.insert(node.id)
        if profile.unlocked.count == UnlockTree.nodes.count {
            grantAchievement("full_tree")
        }
        save()
        return true
    }

    // MARK: - Campaign progression

    func stars(for scenarioID: Int) -> Int { profile.campaignStars[scenarioID] ?? 0 }

    func isScenarioUnlocked(_ id: Int) -> Bool {
        if id <= 1 { return true }
        return stars(for: id - 1) >= 1
    }

    func chapterCleared(_ chapterID: Int) -> Bool {
        CampaignBook.chapters.first { $0.id == chapterID }
            .map { $0.scenarioIDs.allSatisfy { stars(for: $0) >= 1 } } ?? false
    }

    var totalStars: Int { CampaignBook.scenarios.reduce(0) { $0 + stars(for: $1.id) } }

    // MARK: - Editor economy

    func spendGold(_ amount: Int) -> Bool {
        guard profile.gold >= amount else { return false }
        profile.gold -= amount
        profile.stats.goldSpent += amount
        return true
    }

    func paintRoom(_ kind: TileKind, at p: GridPoint) -> String? {
        var d = profile.dungeon
        guard d.inBounds(p) else { return nil }
        let idx = d.index(p)
        let old = d.tiles[idx]
        guard old.kind != .entrance && old.kind != .heart else { return "The \(old.kind.displayName) cannot be rebuilt." }
        guard old.kind != kind else { return nil }

        var cost = kind.buildCost
        if kind == .treasury { cost += DungeonState.treasuryBait }
        var refund = old.kind.buildCost
        if old.kind == .treasury { refund += old.loot }

        guard profile.gold + refund >= cost else { return "Not enough gold (\(cost - refund) needed)." }
        profile.gold += refund
        guard spendGold(cost) else { return "Not enough gold." }

        d.tiles[idx].kind = kind
        d.tiles[idx].loot = kind == .treasury ? DungeonState.treasuryBait : 0
        profile.dungeon = d
        save()
        return nil
    }

    func eraseTile(at p: GridPoint) -> String? {
        var d = profile.dungeon
        guard d.inBounds(p) else { return nil }
        let idx = d.index(p)
        let old = d.tiles[idx]
        guard old.kind != .entrance && old.kind != .heart else { return "That tile is eternal." }
        guard old.kind != .wall else { return nil }
        guard d.pathExists(treatingAsWall: p) else { return "Sealing this tile would block the road to your Heart. Heroes must always have a way in." }

        var refund = old.kind.buildCost + old.loot
        if let trap = old.trap { refund += TrapCatalog.value(trap.type, level: trap.level) }
        if let m = old.monster { refund += MonsterCatalog.cost(m.family, tier: m.tier) }
        profile.gold += refund
        d.tiles[idx] = TileModel()
        profile.dungeon = d
        save()
        return nil
    }

    func placeTrap(_ type: TrapType, at p: GridPoint) -> String? {
        var d = profile.dungeon
        let idx = d.index(p)
        let tile = d.tiles[idx]
        guard tile.kind.isOpen, tile.kind != .entrance, tile.kind != .heart else { return "Traps need an open floor tile." }
        if tile.trap != nil { return "A trap already waits here. Tap it again to hone it." }
        let cost = TrapCatalog.placeCost(type)
        guard spendGold(cost) else { return "Not enough gold (\(cost) needed)." }
        d.tiles[idx].trap = TrapPlacement(type: type, level: 1)
        profile.dungeon = d
        profile.stats.trapTypesPlaced.insert(type.rawValue)
        checkCollectionAchievements()
        save()
        return nil
    }

    func upgradeTrap(at p: GridPoint) -> String? {
        var d = profile.dungeon
        let idx = d.index(p)
        guard var trap = d.tiles[idx].trap else { return nil }
        guard trap.level < trapMaxLevel else {
            return trapMaxLevel < 3 ? "Unlock Trap Mastery to hone traps further." : "This trap is already perfect."
        }
        let cost = TrapCatalog.upgradeCost(trap.type, toLevel: trap.level + 1)
        guard spendGold(cost) else { return "Not enough gold (\(cost) needed)." }
        trap.level += 1
        d.tiles[idx].trap = trap
        profile.dungeon = d
        save()
        return nil
    }

    func removeTrap(at p: GridPoint) {
        var d = profile.dungeon
        let idx = d.index(p)
        guard let trap = d.tiles[idx].trap else { return }
        profile.gold += TrapCatalog.value(trap.type, level: trap.level)
        d.tiles[idx].trap = nil
        profile.dungeon = d
        save()
    }

    func placeMonster(_ family: MonsterFamily, at p: GridPoint) -> String? {
        var d = profile.dungeon
        let idx = d.index(p)
        let tile = d.tiles[idx]
        guard tile.kind.isOpen, tile.kind != .entrance, tile.kind != .heart else { return "Garrison needs an open floor tile." }
        if tile.monster != nil { return "A monster already holds this post. Tap it again to promote it." }
        let cost = MonsterCatalog.cost(family, tier: 1)
        guard spendGold(cost) else { return "Not enough gold (\(cost) needed)." }
        d.tiles[idx].monster = MonsterPlacement(family: family, tier: 1)
        profile.dungeon = d
        profile.stats.familiesPlaced.insert(family.rawValue)
        checkCollectionAchievements()
        save()
        return nil
    }

    func upgradeMonster(at p: GridPoint) -> String? {
        var d = profile.dungeon
        let idx = d.index(p)
        guard var m = d.tiles[idx].monster else { return nil }
        guard m.tier < 3 else { return "This monster is already at peak menace." }
        let cost = MonsterCatalog.cost(m.family, tier: m.tier + 1) - MonsterCatalog.cost(m.family, tier: m.tier)
        guard spendGold(cost) else { return "Not enough gold (\(cost) needed)." }
        m.tier += 1
        d.tiles[idx].monster = m
        profile.dungeon = d
        save()
        return nil
    }

    func removeMonster(at p: GridPoint) {
        var d = profile.dungeon
        let idx = d.index(p)
        guard let m = d.tiles[idx].monster else { return }
        profile.gold += MonsterCatalog.cost(m.family, tier: m.tier)
        d.tiles[idx].monster = nil
        profile.dungeon = d
        save()
    }

    var heartUpgradeCost: Int { 150 * profile.dungeon.heartLevel }

    func upgradeHeart() -> String? {
        guard profile.dungeon.heartLevel < 6 else { return "The Heart can grow no stronger." }
        let cost = heartUpgradeCost
        guard spendGold(cost) else { return "Not enough gold (\(cost) needed)." }
        profile.dungeon.heartLevel += 1
        save()
        return nil
    }

    var currentUpkeep: Int { profile.dungeon.upkeepTotal(factor: upkeepFactor) }

    // MARK: - Raid lifecycle

    func beginRaid() -> String? {
        guard let context = pendingContext else { return "No raid is pending." }
        guard profile.dungeon.pathExists() else { return "The road from entrance to Heart is sealed. Open a path." }

        let party: [PartySlot]
        let mods: [RaidModifier]
        let goldReward: Int
        let renownReward: Int
        let budgetCap: Int
        let firstClear: Bool

        switch context {
        case .campaign(let id):
            let sc = CampaignBook.scenario(id)
            party = sc.party
            mods = sc.modifiers
            goldReward = sc.goldReward
            renownReward = sc.renownReward
            budgetCap = sc.budgetCap
            firstClear = stars(for: id) == 0
        case .endless(let wave):
            if profile.endlessSeed == 0 {
                profile.endlessSeed = UInt64.random(in: 1...UInt64.max)
            }
            let forged = EndlessForge.party(wave: wave, runSeed: profile.endlessSeed)
            party = forged.0
            mods = forged.1
            goldReward = EndlessForge.goldReward(wave: wave)
            renownReward = EndlessForge.renownReward(wave: wave)
            budgetCap = 0
            firstClear = true
        }

        // Garrison upkeep is paid in blood... well, gold, when the gates open.
        let upkeep = min(profile.gold, currentUpkeep)
        profile.gold -= upkeep

        let state = RaidBuilder.make(context: context,
                                     dungeon: profile.dungeon,
                                     party: party,
                                     modifiers: mods,
                                     heartMaxHP: heartMaxHP,
                                     goldReward: goldReward,
                                     renownReward: renownReward,
                                     budgetCap: budgetCap,
                                     firstClear: firstClear,
                                     seed: UInt64.random(in: 1...UInt64.max))
        activeRaid = state
        save()
        screen = .raid
        return nil
    }

    func saveRaidSnapshot(_ state: RaidState) {
        guard state.phase == .running else { return }
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.raidKey)
            raidSnapshotExists = true
        }
    }

    func loadRaidSnapshot() -> RaidState? {
        guard let data = UserDefaults.standard.data(forKey: Self.raidKey),
              let s = try? JSONDecoder().decode(RaidState.self, from: data) else { return nil }
        return s
    }

    func clearRaidSnapshot() {
        UserDefaults.standard.removeObject(forKey: Self.raidKey)
        raidSnapshotExists = false
    }

    func resumeSavedRaid() {
        guard let s = loadRaidSnapshot() else {
            raidSnapshotExists = false
            return
        }
        activeRaid = s
        pendingContext = s.context
        screen = .raid
    }

    /// Apply the finished raid to the profile and surface the outcome.
    func finishRaid(_ state: RaidState) {
        clearRaidSnapshot()
        let won = state.phase == .won

        var outcome = RaidOutcome(context: state.context,
                                  won: won,
                                  stars: 0,
                                  heartUntouched: state.heartDamage <= 0,
                                  underBudget: state.budgetCap > 0 && state.buildValueAtStart <= state.budgetCap,
                                  goldGained: 0,
                                  renownGained: 0,
                                  heroesSlain: state.heroesSlain,
                                  heroesEscaped: state.heroesEscaped,
                                  bossDefeated: state.bossesSlain.first,
                                  heartHPLeft: max(0, state.heartHP),
                                  heartMaxHP: state.heartMaxHP,
                                  ticks: state.tick)

        var gold = state.goldRecovered
        var renown = 0

        switch state.context {
        case .campaign(let id):
            if won {
                var stars = 1
                if outcome.heartUntouched { stars += 1 }
                if outcome.underBudget { stars += 1 }
                outcome.stars = stars
                let base = Double(state.goldReward) * rewardFactor
                gold += Int(state.firstClear ? base : base * 0.4)
                if state.firstClear { renown += state.renownReward }
                let prev = self.stars(for: id)
                if stars > prev {
                    profile.campaignStars[id] = stars
                    if !state.firstClear && prev < 3 {
                        renown += 1   // a sliver of renown for improving the defense
                    }
                }
            }
        case .endless(let wave):
            outcome.waveNumber = wave
            if won {
                gold += Int(Double(state.goldReward) * rewardFactor)
                renown += state.renownReward
                profile.endlessWave = wave + 1
                if wave > profile.endlessBest {
                    profile.endlessBest = wave
                    outcome.newWaveRecord = true
                }
            } else {
                profile.endlessWave = 1
                profile.endlessSeed = 0
            }
        }

        profile.gold += gold
        profile.renown += renown
        outcome.goldGained = gold
        outcome.renownGained = renown

        for b in state.bossesSlain { profile.bossesSlainNames.insert(b) }

        // Statistics
        profile.stats.totalRaids += 1
        if won { profile.stats.wins += 1 } else { profile.stats.losses += 1 }
        profile.stats.heroesSlain += state.heroesSlain
        profile.stats.heroesEscaped += state.heroesEscaped
        profile.stats.bossesSlain += state.bossesSlain.count
        profile.stats.goldEarned += gold
        profile.stats.trapsTriggered += state.trapsTriggered
        if state.mimicKill { profile.stats.mimicKills += 1 }
        profile.stats.monstersLost += state.monstersLost
        profile.stats.treasuriesLooted += state.treasuriesLooted
        profile.stats.ticksSimulated += state.tick
        profile.stats.heartDamageTaken += Int(state.heartDamage)
        if won && !state.startedWithMonsters { profile.stats.monsterlessWin = true }
        if won && !state.startedWithTraps { profile.stats.traplessWin = true }

        outcome.newAchievements = evaluateAchievements(after: state, outcome: outcome)

        lastOutcome = outcome
        activeRaid = nil
        save()
        screen = .result
    }

    func abandonRaid() {
        guard var state = activeRaid else { return }
        state.phase = .lost
        state.addLog("You collapse the tunnels and concede the raid.", .bad)
        finishRaid(state)
    }

    // MARK: - Achievements

    @discardableResult
    private func grantAchievement(_ id: String) -> Bool {
        guard !profile.achievements.contains(id), AchievementBook.def(id) != nil else { return false }
        profile.achievements.insert(id)
        return true
    }

    private func checkCollectionAchievements() {
        if profile.stats.familiesPlaced.count >= MonsterFamily.allCases.count { grantAchievement("menagerie") }
        if profile.stats.trapTypesPlaced.count >= TrapType.allCases.count { grantAchievement("trapsmith") }
    }

    private func evaluateAchievements(after state: RaidState, outcome: RaidOutcome) -> [String] {
        var fresh: [String] = []
        func tryGrant(_ id: String, _ cond: Bool) {
            if cond && grantAchievement(id) { fresh.append(id) }
        }
        tryGrant("first_blood", outcome.won)
        tryGrant("untouched", outcome.won && outcome.heartUntouched)
        tryGrant("three_star", outcome.stars >= 3)
        tryGrant("ch1", chapterCleared(1))
        tryGrant("ch2", chapterCleared(2))
        tryGrant("ch3", chapterCleared(3))
        tryGrant("ch4", chapterCleared(4))
        tryGrant("ch5", chapterCleared(5))
        tryGrant("boss_slayer", !profile.bossesSlainNames.isEmpty)
        tryGrant("all_bosses", CampaignBook.scenarios.compactMap { $0.bossName }.allSatisfy { profile.bossesSlainNames.contains($0) })
        tryGrant("hundred", profile.stats.heroesSlain >= 100)
        tryGrant("springloaded", profile.stats.trapsTriggered >= 50)
        tryGrant("mimic_meal", profile.stats.mimicKills >= 1)
        tryGrant("monsterless", profile.stats.monsterlessWin)
        tryGrant("trapless", profile.stats.traplessWin)
        tryGrant("wave5", profile.endlessBest >= 5)
        tryGrant("wave10", profile.endlessBest >= 10)
        tryGrant("wave20", profile.endlessBest >= 20)
        tryGrant("hoard", profile.stats.goldEarned >= 10000)
        if profile.stats.familiesPlaced.count >= MonsterFamily.allCases.count && grantAchievement("menagerie") { fresh.append("menagerie") }
        if profile.stats.trapTypesPlaced.count >= TrapType.allCases.count && grantAchievement("trapsmith") { fresh.append("trapsmith") }
        return fresh
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        profile.onboardingDone = true
        save()
        screen = .menu
    }
}
