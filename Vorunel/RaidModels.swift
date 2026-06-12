import SwiftUI

// MARK: - Raid runtime models (all Codable so a raid can be snapshotted & resumed)

enum HeroStatus: String, Codable {
    case waiting      // not yet entered the dungeon
    case advancing
    case retreating
    case dead
    case escaped
}

struct RaidHero: Codable, Identifiable {
    let id: Int
    let cls: HeroClass
    let level: Int
    let personality: Personality
    let name: String
    let isBoss: Bool

    var hp: Double
    var maxHP: Double
    var pos: GridPoint
    var status: HeroStatus = .waiting
    var entryDelay: Int

    var morale: Double = 100
    var carried: Int = 0
    var moveCD: Int = 0
    var rooted: Int = 0       // glue / web / pit climb
    var slowCharges: Int = 0  // frost: next moves cost extra
    var poisonTicks: Int = 0
    var poisonDmg: Double = 0
    var burnTicks: Int = 0
    var burnDmg: Double = 0
    var phase2: Bool = false
    var nextStep: GridPoint? = nil   // intent arrow target

    var isActive: Bool { status == .advancing || status == .retreating || status == .waiting }
    var onBoard: Bool { status == .advancing || status == .retreating }
}

struct RaidMonster: Codable, Identifiable {
    let id: Int
    let family: MonsterFamily
    let tier: Int
    let pos: GridPoint
    var hp: Double
    var maxHP: Double
}

enum LogTone: String, Codable {
    case info, damage, good, bad, loot, boss

    var color: Color {
        switch self {
        case .info: return DATheme.boneDim
        case .damage: return DATheme.ember
        case .good: return DATheme.sickly
        case .bad: return DATheme.blood
        case .loot: return DATheme.goldCoin
        case .boss: return Color(daHex: 0xB58BE8)
        }
    }
}

struct RaidLogEntry: Codable, Identifiable {
    let id: Int
    let tick: Int
    let text: String
    let tone: LogTone
}

enum RaidPhase: String, Codable {
    case running, won, lost
}

struct RaidState: Codable {
    var context: RaidContext
    var dungeon: DungeonState          // working copy: loot drains during the raid
    var trapCooldowns: [Int: Int] = [:] // tile index -> ticks until rearmed
    var disarmedTraps: Set<Int> = []
    var sprungTraps: Set<Int> = []      // tiles where a trap fired (cautious heroes remember)
    var heroes: [RaidHero]
    var monsters: [RaidMonster]
    var tick: Int = 0
    var heartHP: Double
    var heartMaxHP: Double
    var rng: SeededRNG
    var modifiers: [RaidModifier]
    var log: [RaidLogEntry] = []
    var nextLogID: Int = 0
    var phase: RaidPhase = .running

    // Tallies for results / stats / achievements
    var goldRecovered: Int = 0
    var heroesSlain: Int = 0
    var heroesEscaped: Int = 0
    var trapsTriggered: Int = 0
    var treasuriesLooted: Int = 0
    var monstersLost: Int = 0
    var mimicKill: Bool = false
    var bossesSlain: [String] = []
    var heartDamage: Double = 0

    // Reward context captured at raid start
    var goldReward: Int
    var renownReward: Int
    var budgetCap: Int
    var buildValueAtStart: Int
    var firstClear: Bool
    var startedWithMonsters: Bool
    var startedWithTraps: Bool

    var hasModifier: (RaidModifier) -> Bool { { m in modifiers.contains(m) } }

    mutating func addLog(_ text: String, _ tone: LogTone = .info) {
        log.append(RaidLogEntry(id: nextLogID, tick: tick, text: text, tone: tone))
        nextLogID += 1
        if log.count > 160 { log.removeFirst(log.count - 160) }
    }

    var livingHeroes: [RaidHero] { heroes.filter { $0.status == .advancing || $0.status == .retreating } }
    var anyActiveHero: Bool { heroes.contains { $0.isActive } }
}

// MARK: - Raid outcome (computed when the raid ends)

struct RaidOutcome: Codable {
    var context: RaidContext
    var won: Bool
    var stars: Int                // 0 (loss) ... 3
    var heartUntouched: Bool
    var underBudget: Bool
    var goldGained: Int
    var renownGained: Int
    var heroesSlain: Int
    var heroesEscaped: Int
    var bossDefeated: String?
    var heartHPLeft: Double
    var heartMaxHP: Double
    var ticks: Int
    var newAchievements: [String] = []
    var waveNumber: Int? = nil    // endless
    var newWaveRecord: Bool = false

    var scenarioID: Int? {
        if case .campaign(let id) = context { return id }
        return nil
    }
}

// MARK: - Raid construction

enum RaidBuilder {
    /// Build the initial RaidState from the player's dungeon + a party.
    static func make(context: RaidContext,
                     dungeon: DungeonState,
                     party: [PartySlot],
                     modifiers: [RaidModifier],
                     heartMaxHP: Double,
                     goldReward: Int,
                     renownReward: Int,
                     budgetCap: Int,
                     firstClear: Bool,
                     seed: UInt64) -> RaidState {

        var heroes: [RaidHero] = []
        for (i, slot) in party.enumerated() {
            var hp = HeroCatalog.hp(slot.cls, level: slot.level)
            if slot.isBoss { hp *= 1.9 }
            heroes.append(RaidHero(id: i,
                                   cls: slot.cls,
                                   level: slot.level,
                                   personality: slot.personality,
                                   name: slot.name,
                                   isBoss: slot.isBoss,
                                   hp: hp, maxHP: hp,
                                   pos: DungeonState.entrancePoint,
                                   entryDelay: i * 3))
        }

        var monsters: [RaidMonster] = []
        var mid = 0
        for p in dungeon.allPoints {
            let tile = dungeon.tile(at: p)
            guard let m = tile.monster else { continue }
            var hp = MonsterCatalog.hp(m.family, tier: m.tier)
            if tile.kind == .barracks { hp *= 1.25 }
            monsters.append(RaidMonster(id: mid, family: m.family, tier: m.tier, pos: p, hp: hp, maxHP: hp))
            mid += 1
        }

        var state = RaidState(context: context,
                              dungeon: dungeon,
                              heroes: heroes,
                              monsters: monsters,
                              heartHP: heartMaxHP,
                              heartMaxHP: heartMaxHP,
                              rng: SeededRNG(seed: seed),
                              modifiers: modifiers,
                              goldReward: goldReward,
                              renownReward: renownReward,
                              budgetCap: budgetCap,
                              buildValueAtStart: dungeon.buildValue,
                              firstClear: firstClear,
                              startedWithMonsters: !monsters.isEmpty,
                              startedWithTraps: dungeon.trapCount > 0)

        switch context {
        case .campaign(let id):
            let sc = CampaignBook.scenario(id)
            state.addLog("Raid begins: \(sc.title).", .info)
        case .endless(let wave):
            state.addLog("Siege wave \(wave) crashes against your gates.", .info)
        }
        if !modifiers.isEmpty {
            state.addLog("Party blessing: " + modifiers.map { $0.displayName }.joined(separator: ", ") + ".", .info)
        }
        return state
    }
}
