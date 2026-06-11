import SwiftUI

// MARK: - Grid primitives

struct GridPoint: Codable, Hashable {
    var x: Int
    var y: Int
}

// MARK: - Tile / room kinds

enum TileKind: String, Codable, CaseIterable {
    case wall
    case corridor
    case treasury
    case barracks
    case trapChamber
    case shrine
    case illusionHall
    case entrance
    case heart

    var isOpen: Bool { self != .wall }

    /// Kinds the player can paint from the editor palette.
    static let buildable: [TileKind] = [.corridor, .treasury, .barracks, .trapChamber, .shrine, .illusionHall]

    var displayName: String {
        switch self {
        case .wall: return "Bedrock"
        case .corridor: return "Corridor"
        case .treasury: return "Treasury"
        case .barracks: return "Barracks"
        case .trapChamber: return "Trap Chamber"
        case .shrine: return "Dark Shrine"
        case .illusionHall: return "Illusion Hall"
        case .entrance: return "Entrance"
        case .heart: return "Dungeon Heart"
        }
    }

    var buildCost: Int {
        switch self {
        case .corridor: return 20
        case .treasury: return 60      // plus bait gold stocked separately
        case .barracks: return 80
        case .trapChamber: return 70
        case .shrine: return 100
        case .illusionHall: return 90
        default: return 0
        }
    }

    /// Short room effect line for palette and codex.
    var effectText: String {
        switch self {
        case .wall: return "Solid rock. Heroes cannot pass."
        case .corridor: return "Plain dug passage. Cheap to carve."
        case .treasury: return "Stocked with 50 gold bait. Greedy heroes detour to loot it."
        case .barracks: return "Monsters garrisoned here gain +25% health."
        case .trapChamber: return "Traps set here strike 30% harder."
        case .shrine: return "Monsters on or beside the shrine regenerate each tick."
        case .illusionHall: return "Heroes entering may lose a step to disorientation."
        case .entrance: return "Where hero parties break in. Cannot be sealed."
        case .heart: return "Your lifeforce. If it shatters, the raid is lost."
        }
    }

    var lore: String {
        switch self {
        case .wall: return "The mountain's old bones. They remember being whole, and they do not forgive the pick."
        case .corridor: return "Every empire starts as a hole in the ground. Yours simply admits it."
        case .treasury: return "Gold sings through stone. Heroes claim they cannot hear it. Heroes lie."
        case .barracks: return "Straw, bones, a communal whetstone. Your garrison calls it home and defends it like one."
        case .trapChamber: return "An armory of unkind ideas. The gears in the walls turn a little faster here, eager to be useful."
        case .shrine: return "Something older than the mountain accepts small offerings here, and pays its debts in knitted flesh."
        case .illusionHall: return "The corridor that is also a lie. Visitors arrive twice and leave once, if at all."
        case .entrance: return "You could seal it, but then who would bring you all this lovely gear?"
        case .heart: return "A heart-crystal grown from centuries of patient malice. It beats once a year. Try not to let anyone interrupt."
        }
    }

    var tint: Color {
        switch self {
        case .wall: return DATheme.voidShade
        case .corridor: return DATheme.plum
        case .treasury: return Color(daHex: 0x4A3A22)
        case .barracks: return Color(daHex: 0x4A2B25)
        case .trapChamber: return Color(daHex: 0x442030)
        case .shrine: return Color(daHex: 0x27402A)
        case .illusionHall: return Color(daHex: 0x223A4A)
        case .entrance: return Color(daHex: 0x4E4636)
        case .heart: return Color(daHex: 0x521F2A)
        }
    }
}

// MARK: - Traps, monsters, heroes (identifiers; stats live in catalogs)

enum TrapType: String, Codable, CaseIterable {
    case spike, fireJet, frostRune, pit, poisonDart, crusher, glue, fearTotem, lightningCoil, mimicChest
}

enum MonsterFamily: String, Codable, CaseIterable {
    case goblin, skeleton, slime, bat, orc, spider, wraith, golem, imp, serpent, cultist, dragonling
}

enum HeroClass: String, Codable, CaseIterable {
    case warrior, rogue, mage, cleric, paladin, ranger

    var displayName: String {
        switch self {
        case .warrior: return "Warrior"
        case .rogue: return "Rogue"
        case .mage: return "Mage"
        case .cleric: return "Cleric"
        case .paladin: return "Paladin"
        case .ranger: return "Ranger"
        }
    }
}

enum Personality: String, Codable, CaseIterable {
    case bold, greedy, cautious

    var displayName: String {
        switch self {
        case .bold: return "Bold"
        case .greedy: return "Greedy"
        case .cautious: return "Cautious"
        }
    }
    var blurb: String {
        switch self {
        case .bold: return "Marches straight for the Heart."
        case .greedy: return "Detours to loot every treasury first."
        case .cautious: return "Avoids corridors where traps have sprung."
        }
    }
}

enum RaidModifier: String, Codable, CaseIterable {
    case torchlit, blessed, greedy, hasted, ironwill, arcane

    var displayName: String {
        switch self {
        case .torchlit: return "Torch-lit"
        case .blessed: return "Blessed"
        case .greedy: return "Greedy"
        case .hasted: return "Hasted"
        case .ironwill: return "Iron Will"
        case .arcane: return "Arcane"
        }
    }
    var blurb: String {
        switch self {
        case .torchlit: return "Bright torches: your monsters strike 15% softer."
        case .blessed: return "Warded by priests: heals stronger, grief dulled."
        case .greedy: return "The whole party detours to treasure."
        case .hasted: return "The party moves at double pace."
        case .ironwill: return "Morale never breaks. No hero retreats."
        case .arcane: return "Mages channel 40% more power."
        }
    }
}

// MARK: - Placements stored in the dungeon

struct TrapPlacement: Codable, Equatable {
    var type: TrapType
    var level: Int
}

struct MonsterPlacement: Codable, Equatable {
    var family: MonsterFamily
    var tier: Int
}

struct TileModel: Codable {
    var kind: TileKind = .wall
    var trap: TrapPlacement? = nil
    var monster: MonsterPlacement? = nil
    var loot: Int = 0
}

// MARK: - Dungeon

struct DungeonState: Codable {
    static let cols = 9
    static let rows = 12
    static let entrancePoint = GridPoint(x: 4, y: 0)
    static let heartPoint = GridPoint(x: 4, y: 11)
    static let treasuryBait = 50

    var tiles: [TileModel]
    var heartLevel: Int = 1

    static func freshStart() -> DungeonState {
        var t = Array(repeating: TileModel(), count: cols * rows)
        for y in 0..<rows {
            let idx = y * cols + entrancePoint.x
            if y == entrancePoint.y {
                t[idx].kind = .entrance
            } else if y == heartPoint.y {
                t[idx].kind = .heart
            } else {
                t[idx].kind = .corridor
            }
        }
        return DungeonState(tiles: t, heartLevel: 1)
    }

    func inBounds(_ p: GridPoint) -> Bool {
        p.x >= 0 && p.x < Self.cols && p.y >= 0 && p.y < Self.rows
    }
    func index(_ p: GridPoint) -> Int { p.y * Self.cols + p.x }

    func tile(at p: GridPoint) -> TileModel { tiles[index(p)] }

    mutating func setTile(_ t: TileModel, at p: GridPoint) { tiles[index(p)] = t }

    func isOpen(_ p: GridPoint) -> Bool {
        inBounds(p) && tile(at: p).kind.isOpen
    }

    func neighbors(of p: GridPoint) -> [GridPoint] {
        [GridPoint(x: p.x + 1, y: p.y),
         GridPoint(x: p.x - 1, y: p.y),
         GridPoint(x: p.x, y: p.y + 1),
         GridPoint(x: p.x, y: p.y - 1)].filter { inBounds($0) }
    }

    /// BFS reachability entrance -> heart over open tiles, optionally treating one tile as sealed.
    func pathExists(treatingAsWall sealed: GridPoint? = nil) -> Bool {
        var visited = Array(repeating: false, count: Self.cols * Self.rows)
        var queue = [Self.entrancePoint]
        visited[index(Self.entrancePoint)] = true
        var head = 0
        while head < queue.count {
            let cur = queue[head]; head += 1
            if cur == Self.heartPoint { return true }
            for n in neighbors(of: cur) {
                let i = index(n)
                if visited[i] { continue }
                if let s = sealed, s == n { continue }
                guard tiles[i].kind.isOpen else { continue }
                visited[i] = true
                queue.append(n)
            }
        }
        return false
    }

    /// Total invested value of rooms + traps + monsters; used for the budget star.
    var buildValue: Int {
        var total = 0
        for t in tiles {
            total += t.kind.buildCost
            if let trap = t.trap { total += TrapCatalog.value(trap.type, level: trap.level) }
            if let m = t.monster { total += MonsterCatalog.cost(m.family, tier: m.tier) }
        }
        return total
    }

    func upkeepTotal(factor: Double) -> Int {
        var total = 0
        for t in tiles {
            if let m = t.monster { total += MonsterCatalog.upkeep(m.family, tier: m.tier) }
        }
        return Int((Double(total) * factor).rounded())
    }

    var monsterCount: Int { tiles.compactMap { $0.monster }.count }
    var trapCount: Int { tiles.compactMap { $0.trap }.count }

    var allPoints: [GridPoint] {
        var pts: [GridPoint] = []
        pts.reserveCapacity(Self.cols * Self.rows)
        for y in 0..<Self.rows {
            for x in 0..<Self.cols { pts.append(GridPoint(x: x, y: y)) }
        }
        return pts
    }
}

// MARK: - Deterministic RNG (Codable so raids resume identically)

struct SeededRNG: Codable {
    var s: UInt64

    init(seed: UInt64) { s = seed == 0 ? 0x9E3779B97F4A7C15 : seed }

    mutating func next() -> UInt64 {
        s &+= 0x9E3779B97F4A7C15
        var z = s
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func double01() -> Double {
        Double(next() >> 11) / Double(1 << 53)
    }
    mutating func chance(_ p: Double) -> Bool { double01() < p }
    mutating func int(_ range: ClosedRange<Int>) -> Int {
        if range.lowerBound == range.upperBound { return range.lowerBound }
        let span = UInt64(range.upperBound - range.lowerBound + 1)
        return range.lowerBound + Int(next() % span)
    }
    mutating func pick<T>(_ array: [T]) -> T {
        array[int(0...(array.count - 1))]
    }
}

// MARK: - Raid context

enum RaidContext: Codable, Equatable {
    case campaign(Int)   // scenario id 1...30
    case endless(Int)    // wave number 1...

    var isEndless: Bool {
        if case .endless = self { return true }
        return false
    }
}

// MARK: - Settings & statistics

struct AppSettings: Codable {
    var soundOn: Bool = true
    var hapticsOn: Bool = true
}

struct GameStats: Codable {
    var totalRaids: Int = 0
    var wins: Int = 0
    var losses: Int = 0
    var heroesSlain: Int = 0
    var heroesEscaped: Int = 0
    var bossesSlain: Int = 0
    var goldEarned: Int = 0
    var goldSpent: Int = 0
    var trapsTriggered: Int = 0
    var mimicKills: Int = 0
    var monstersLost: Int = 0
    var treasuriesLooted: Int = 0
    var ticksSimulated: Int = 0
    var heartDamageTaken: Int = 0
    var monsterlessWin: Bool = false
    var traplessWin: Bool = false
    var familiesPlaced: Set<String> = []
    var trapTypesPlaced: Set<String> = []
}
