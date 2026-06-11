import SwiftUI

// MARK: - Monster abilities

enum MonsterAbility: String, Codable {
    case swarm      // +15% attack per adjacent goblin
    case armor      // flat damage reduction
    case regen      // heals every tick
    case swift      // dodge chance
    case brutal     // chance to strike double
    case web        // chance to root the hero's next move
    case drain      // heals for half the damage dealt
    case taunt      // heroes must strike this monster first
    case phase      // high dodge chance
    case venom      // attacks poison the hero
    case inspire    // adjacent monsters gain +20% attack
    case splash     // hits every hero in the tile

    var displayName: String {
        switch self {
        case .swarm: return "Swarm"
        case .armor: return "Bone Plate"
        case .regen: return "Regenerate"
        case .swift: return "Swift"
        case .brutal: return "Brutal"
        case .web: return "Web"
        case .drain: return "Life Drain"
        case .taunt: return "Taunt"
        case .phase: return "Phase"
        case .venom: return "Venom"
        case .inspire: return "Dark Chant"
        case .splash: return "Flame Gout"
        }
    }
}

// MARK: - Monster definitions

struct MonsterDef {
    let family: MonsterFamily
    let name: String
    let baseHP: Double
    let baseATK: Double
    let baseCost: Int
    let baseUpkeep: Int
    let ability: MonsterAbility
    let abilityText: String
    let lore: String
    let tierNames: [String]     // 3 entries
    let tint: Color
}

enum MonsterCatalog {
    static let tierHP: [Double] = [1.0, 2.0, 3.8]
    static let tierATK: [Double] = [1.0, 2.0, 3.8]
    static let tierCost: [Double] = [1.0, 2.2, 4.5]
    static let tierUpkeep: [Double] = [1.0, 2.0, 3.5]

    static let all: [MonsterDef] = [
        MonsterDef(family: .goblin, name: "Goblin", baseHP: 35, baseATK: 7, baseCost: 50, baseUpkeep: 4,
                   ability: .swarm, abilityText: "+15% attack per adjacent goblin tile.",
                   lore: "Cheap, loud, and convinced every plan is a good plan if you shout it.",
                   tierNames: ["Goblin Cutpurse", "Goblin Bruiser", "Goblin Warboss"],
                   tint: DATheme.sickly),
        MonsterDef(family: .skeleton, name: "Skeleton", baseHP: 50, baseATK: 8, baseCost: 70, baseUpkeep: 5,
                   ability: .armor, abilityText: "Ignores 2 damage from every hit (more per tier).",
                   lore: "Retired heroes, rehired. Their pension plan is your dungeon.",
                   tierNames: ["Rattle Guard", "Grave Sergeant", "Marrow Knight"],
                   tint: DATheme.bone),
        MonsterDef(family: .slime, name: "Slime", baseHP: 70, baseATK: 6, baseCost: 80, baseUpkeep: 6,
                   ability: .regen, abilityText: "Recovers health every tick while alive.",
                   lore: "It absorbed a philosophy student once. Now it dissolves things thoughtfully.",
                   tierNames: ["Dripling", "Mire Pudding", "Vault Devourer"],
                   tint: DATheme.sicklyDeep),
        MonsterDef(family: .bat, name: "Bat", baseHP: 30, baseATK: 9, baseCost: 60, baseUpkeep: 4,
                   ability: .swift, abilityText: "20% chance to dodge any blow.",
                   lore: "Sleeps nineteen hours a day and still outworks the goblins.",
                   tierNames: ["Cave Bat", "Dusk Screecher", "Night Tyrant"],
                   tint: DATheme.shadowMauve),
        MonsterDef(family: .orc, name: "Orc", baseHP: 80, baseATK: 13, baseCost: 120, baseUpkeep: 9,
                   ability: .brutal, abilityText: "25% chance to strike for double damage.",
                   lore: "Asked for a bigger axe. Was given a bigger axe. Asked for a bigger axe.",
                   tierNames: ["Orc Mauler", "Orc Skullsplitter", "Orc Doomchief"],
                   tint: Color(daHex: 0x8FAE4A)),
        MonsterDef(family: .spider, name: "Spider", baseHP: 55, baseATK: 9, baseCost: 110, baseUpkeep: 8,
                   ability: .web, abilityText: "30% chance its bite roots the hero in place.",
                   lore: "Decorates compulsively. The webs are functional, but mostly they are decor.",
                   tierNames: ["Crypt Weaver", "Silk Stalker", "Brood Empress"],
                   tint: Color(daHex: 0xA88BC9)),
        MonsterDef(family: .wraith, name: "Wraith", baseHP: 60, baseATK: 11, baseCost: 140, baseUpkeep: 10,
                   ability: .drain, abilityText: "Heals for half the damage it deals.",
                   lore: "Owes its existence to unfinished business. Has since invented more business.",
                   tierNames: ["Pale Mourner", "Gloom Shade", "Hollow King"],
                   tint: DATheme.frost),
        MonsterDef(family: .golem, name: "Golem", baseHP: 160, baseATK: 10, baseCost: 180, baseUpkeep: 12,
                   ability: .taunt, abilityText: "Heroes in its tile must strike it first. Heavy armor.",
                   lore: "Built to hold a door. Holds the door. There has never been a better door-holder.",
                   tierNames: ["Clay Sentinel", "Basalt Warden", "Obsidian Colossus"],
                   tint: Color(daHex: 0x9C8F7E)),
        MonsterDef(family: .imp, name: "Imp", baseHP: 45, baseATK: 12, baseCost: 100, baseUpkeep: 7,
                   ability: .phase, abilityText: "30% chance to blink away from any blow.",
                   lore: "Half here, half elsewhere, entirely insufferable about it.",
                   tierNames: ["Spark Imp", "Cinder Fiend", "Pandemonium Prince"],
                   tint: DATheme.ember),
        MonsterDef(family: .serpent, name: "Serpent", baseHP: 65, baseATK: 10, baseCost: 130, baseUpkeep: 9,
                   ability: .venom, abilityText: "Bites leave poison burning for 3 ticks.",
                   lore: "Speaks in a lisp and resents every joke about it. Bites resentfully.",
                   tierNames: ["Tunnel Adder", "Venom Coil", "World Asp"],
                   tint: DATheme.sickly),
        MonsterDef(family: .cultist, name: "Cultist", baseHP: 50, baseATK: 7, baseCost: 150, baseUpkeep: 10,
                   ability: .inspire, abilityText: "Adjacent monsters gain +20% attack.",
                   lore: "Joined for the robes, stayed for the dental plan. Chants with genuine feeling.",
                   tierNames: ["Initiate", "Voice of the Deep", "High Hierophant"],
                   tint: Color(daHex: 0xC98BB7)),
        MonsterDef(family: .dragonling, name: "Dragonling", baseHP: 110, baseATK: 15, baseCost: 220, baseUpkeep: 14,
                   ability: .splash, abilityText: "Its flame strikes every hero in the tile.",
                   lore: "A real dragon, technically. Do not bring up its size. It keeps a list.",
                   tierNames: ["Ember Whelp", "Ashwing", "Pyre Sovereign"],
                   tint: DATheme.emberDeep)
    ]

    static func def(_ f: MonsterFamily) -> MonsterDef {
        all.first { $0.family == f } ?? all[0]
    }

    static func hp(_ f: MonsterFamily, tier: Int) -> Double {
        def(f).baseHP * tierHP[max(1, min(3, tier)) - 1]
    }
    static func atk(_ f: MonsterFamily, tier: Int) -> Double {
        def(f).baseATK * tierATK[max(1, min(3, tier)) - 1]
    }
    static func cost(_ f: MonsterFamily, tier: Int) -> Int {
        Int((Double(def(f).baseCost) * tierCost[max(1, min(3, tier)) - 1]).rounded())
    }
    static func upkeep(_ f: MonsterFamily, tier: Int) -> Int {
        Int((Double(def(f).baseUpkeep) * tierUpkeep[max(1, min(3, tier)) - 1]).rounded())
    }
    static func tierName(_ f: MonsterFamily, tier: Int) -> String {
        def(f).tierNames[max(1, min(3, tier)) - 1]
    }
    /// Flat armor per family/tier (skeleton & golem).
    static func armor(_ f: MonsterFamily, tier: Int) -> Double {
        switch f {
        case .skeleton: return Double(1 + tier)        // 2/3/4
        case .golem: return Double(2 + tier)           // 3/4/5
        default: return 0
        }
    }
    static func dodge(_ f: MonsterFamily) -> Double {
        switch f {
        case .bat: return 0.20
        case .imp: return 0.30
        default: return 0
        }
    }
    static func regenPerTick(_ f: MonsterFamily, tier: Int) -> Double {
        f == .slime ? 3.0 * tierHP[max(1, min(3, tier)) - 1] : 0
    }
}
