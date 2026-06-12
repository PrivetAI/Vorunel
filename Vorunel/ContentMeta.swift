import SwiftUI

// MARK: - Permanent unlock tree (Dark Renown)

enum UnlockEffect {
    case monsters([MonsterFamily])
    case traps([TrapType])
    case rooms([TileKind])
    case heartHP(Int)
    case upkeepDiscount(Double)   // multiplier, e.g. 0.75
    case rewardBonus(Double)      // gold reward multiplier bonus, e.g. 0.2
    case trapMastery              // allows trap level 3
}

struct UnlockNode: Identifiable {
    let id: String
    let title: String
    let desc: String
    let cost: Int
    let requires: [String]
    let effect: UnlockEffect
}

enum UnlockTree {
    /// Content available before any nodes are bought.
    static let starterMonsters: Set<MonsterFamily> = [.goblin, .skeleton, .slime, .bat]
    static let starterTraps: Set<TrapType> = [.spike, .fireJet, .pit]
    static let starterRooms: Set<TileKind> = [.corridor, .treasury, .barracks]

    static let nodes: [UnlockNode] = [
        // Monster branch
        UnlockNode(id: "warband", title: "Warband Pact", desc: "Recruit Orcs and Spiders.",
                   cost: 3, requires: [], effect: .monsters([.orc, .spider])),
        UnlockNode(id: "gravecall", title: "Gravecall Rite", desc: "Recruit Wraiths and Imps.",
                   cost: 5, requires: ["warband"], effect: .monsters([.wraith, .imp])),
        UnlockNode(id: "deepforge", title: "Deepforge Oath", desc: "Recruit Golems and Serpents.",
                   cost: 8, requires: ["gravecall"], effect: .monsters([.golem, .serpent])),
        UnlockNode(id: "darkcourt", title: "The Dark Court", desc: "Recruit Cultists and Dragonlings.",
                   cost: 12, requires: ["deepforge"], effect: .monsters([.cultist, .dragonling])),
        // Trap branch
        UnlockNode(id: "chillworks", title: "Chillworks", desc: "Build Frost Runes and Poison Darts.",
                   cost: 3, requires: [], effect: .traps([.frostRune, .poisonDart])),
        UnlockNode(id: "snareworks", title: "Snareworks", desc: "Build Glue Floors and Fear Totems.",
                   cost: 5, requires: ["chillworks"], effect: .traps([.glue, .fearTotem])),
        UnlockNode(id: "doomworks", title: "Doomworks", desc: "Build Ceiling Crushers and Lightning Coils.",
                   cost: 8, requires: ["snareworks"], effect: .traps([.crusher, .lightningCoil])),
        UnlockNode(id: "mimicry", title: "Mimicry Contract", desc: "Hire Mimic Chests. Treasure with teeth.",
                   cost: 10, requires: ["snareworks"], effect: .traps([.mimicChest])),
        UnlockNode(id: "trapmastery", title: "Trap Mastery", desc: "Traps can be honed to level 3.",
                   cost: 9, requires: ["chillworks"], effect: .trapMastery),
        // Room branch
        UnlockNode(id: "blades", title: "Chamber of Blades", desc: "Dig Trap Chambers: traps there strike 30% harder.",
                   cost: 4, requires: [], effect: .rooms([.trapChamber])),
        UnlockNode(id: "shrine", title: "Whispering Shrine", desc: "Dig Dark Shrines: nearby monsters regenerate.",
                   cost: 6, requires: ["blades"], effect: .rooms([.shrine])),
        UnlockNode(id: "lies", title: "Hall of Lies", desc: "Dig Illusion Halls: intruders lose their way.",
                   cost: 8, requires: ["shrine"], effect: .rooms([.illusionHall])),
        // Heart & economy
        UnlockNode(id: "fortress", title: "Heart Fortress", desc: "The Dungeon Heart gains +200 health.",
                   cost: 6, requires: [], effect: .heartHP(200)),
        UnlockNode(id: "bastion", title: "Heart Bastion", desc: "The Dungeon Heart gains a further +300 health.",
                   cost: 12, requires: ["fortress"], effect: .heartHP(300)),
        UnlockNode(id: "bargain", title: "Dark Bargain", desc: "Garrison upkeep reduced by 25%.",
                   cost: 7, requires: [], effect: .upkeepDiscount(0.75)),
        UnlockNode(id: "warchest", title: "War Chest", desc: "Victory gold rewards increased by 20%.",
                   cost: 5, requires: [], effect: .rewardBonus(0.2)),
    ]

    static func node(_ id: String) -> UnlockNode? {
        nodes.first { $0.id == id }
    }
}

// MARK: - Achievements

struct AchievementDef: Identifiable {
    let id: String
    let title: String
    let desc: String
}

enum AchievementBook {
    static let all: [AchievementDef] = [
        AchievementDef(id: "first_blood", title: "First Blood", desc: "Win your first raid defense."),
        AchievementDef(id: "untouched", title: "Not a Scratch", desc: "Win a raid with the Dungeon Heart at full health."),
        AchievementDef(id: "three_star", title: "Triple Crown", desc: "Earn 3 stars on any campaign raid."),
        AchievementDef(id: "ch1", title: "Outpost Overlord", desc: "Clear every raid in Forest Outpost."),
        AchievementDef(id: "ch2", title: "Vault Keeper", desc: "Clear every raid in Mountain Vault."),
        AchievementDef(id: "ch3", title: "Crypt Sovereign", desc: "Clear every raid in Sunken Crypt."),
        AchievementDef(id: "ch4", title: "Keep Breaker", desc: "Clear every raid in Obsidian Keep."),
        AchievementDef(id: "ch5", title: "Spire's Bane", desc: "Clear every raid in The Worldspire."),
        AchievementDef(id: "boss_slayer", title: "Legend Killer", desc: "Defeat a legendary hero."),
        AchievementDef(id: "all_bosses", title: "Five Crowns Fallen", desc: "Defeat all five legendary heroes."),
        AchievementDef(id: "hundred", title: "Hundred Graves", desc: "Defeat 100 heroes in total."),
        AchievementDef(id: "springloaded", title: "Springloaded", desc: "Trigger traps 50 times."),
        AchievementDef(id: "mimic_meal", title: "Chest's Revenge", desc: "A Mimic Chest finishes off a hero."),
        AchievementDef(id: "monsterless", title: "Empty Halls", desc: "Win a raid with no monsters garrisoned."),
        AchievementDef(id: "trapless", title: "Bare Knuckles", desc: "Win a raid with no traps placed."),
        AchievementDef(id: "wave5", title: "Siege Holder", desc: "Survive to wave 5 in Endless Siege."),
        AchievementDef(id: "wave10", title: "Siege Master", desc: "Survive to wave 10 in Endless Siege."),
        AchievementDef(id: "wave20", title: "Eternal Bulwark", desc: "Survive to wave 20 in Endless Siege."),
        AchievementDef(id: "hoard", title: "Dragon's Hoard", desc: "Earn 10,000 gold in total."),
        AchievementDef(id: "full_tree", title: "Architect Ascendant", desc: "Purchase every unlock in the Dark Renown tree."),
        AchievementDef(id: "menagerie", title: "Full Menagerie", desc: "Garrison all 12 monster families at least once."),
        AchievementDef(id: "trapsmith", title: "Master Trapsmith", desc: "Place all 10 trap types at least once."),
    ]

    static func def(_ id: String) -> AchievementDef? {
        all.first { $0.id == id }
    }
}
