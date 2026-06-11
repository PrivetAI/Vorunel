import SwiftUI

// MARK: - Trap definitions

struct TrapDef {
    let type: TrapType
    let name: String
    let baseCost: Int
    let baseDamage: Double      // level 1 damage (some traps deal 0 and apply effects)
    let cooldown: Int           // ticks between triggers
    let tagline: String
    let effectText: String
    let lore: String
    let tint: Color
}

enum TrapCatalog {
    /// Damage multiplier per level 1...3
    static let levelDamage: [Double] = [1.0, 1.6, 2.4]
    /// Upgrade price share of base cost per step
    static let upgradeShare: Double = 0.6
    /// Rogue base disarm chance vs a level-1 trap.
    static let disarmBase: Double = 0.55

    static let all: [TrapDef] = [
        TrapDef(type: .spike, name: "Spike Row", baseCost: 40, baseDamage: 18, cooldown: 4,
                tagline: "Honest iron through dishonest boots.",
                effectText: "Pierces a hero entering the tile.",
                lore: "The oldest trick in the book, because the book was written on the survivors.",
                tint: DATheme.bone),
        TrapDef(type: .fireJet, name: "Fire Jet", baseCost: 60, baseDamage: 14, cooldown: 5,
                tagline: "A warm welcome, repeated.",
                effectText: "Burns on entry, then sears for 3 more ticks.",
                lore: "Fed by a vein of angry oil. The mountain was going to waste it anyway.",
                tint: DATheme.ember),
        TrapDef(type: .frostRune, name: "Frost Rune", baseCost: 55, baseDamage: 8, cooldown: 5,
                tagline: "Cold feet, by design.",
                effectText: "Chills a hero, slowing their next two moves.",
                lore: "Scratched by a wizard who owed you money. The debt is paid in shivers.",
                tint: DATheme.frost),
        TrapDef(type: .pit, name: "Hidden Pit", baseCost: 50, baseDamage: 16, cooldown: 6,
                tagline: "The floor is a suggestion.",
                effectText: "Drops a hero; they spend 2 ticks climbing out.",
                lore: "Technically just a hole. Marketing calls it an unplanned descent experience.",
                tint: DATheme.shadowMauve),
        TrapDef(type: .poisonDart, name: "Poison Dart", baseCost: 65, baseDamage: 8, cooldown: 4,
                tagline: "A small prick, a long regret.",
                effectText: "Stings on entry, then poisons for 4 ticks.",
                lore: "The serpents donate venom every full moon. They insist it is a gift, not a tax.",
                tint: DATheme.sickly),
        TrapDef(type: .crusher, name: "Ceiling Crusher", baseCost: 110, baseDamage: 45, cooldown: 9,
                tagline: "Gravity, but premium.",
                effectText: "Slams a hero for massive damage. Slow to reset.",
                lore: "Four tons of disappointment on a counterweight. Resets slowly, regrets nothing.",
                tint: DATheme.blood),
        TrapDef(type: .glue, name: "Glue Floor", baseCost: 45, baseDamage: 0, cooldown: 6,
                tagline: "Stay a while. Longer, actually.",
                effectText: "No damage; roots a hero in place for 3 ticks.",
                lore: "Rendered from slime sheddings. The slimes are flattered anyone wants their leftovers.",
                tint: DATheme.sicklyDeep),
        TrapDef(type: .fearTotem, name: "Fear Totem", baseCost: 70, baseDamage: 0, cooldown: 5,
                tagline: "It only whispers the truth.",
                effectText: "Shreds morale; shaken heroes may turn back early.",
                lore: "Carved with every hero's least favorite fact: nobody at home remembers their name.",
                tint: DATheme.plumLight),
        TrapDef(type: .lightningCoil, name: "Lightning Coil", baseCost: 95, baseDamage: 22, cooldown: 7,
                tagline: "Sharing is shocking.",
                effectText: "Arcs to every hero standing in the tile.",
                lore: "Hums a tune in storm season. The imps swear it knows two more songs.",
                tint: Color(daHex: 0xB8A4FF)),
        TrapDef(type: .mimicChest, name: "Mimic Chest", baseCost: 85, baseDamage: 38, cooldown: 99,
                tagline: "Treasure with teeth.",
                effectText: "Reads as loot to greedy heroes, then bites once, hard.",
                lore: "Not a trap, it insists. A self-employed predator with a profit-sharing agreement.",
                tint: DATheme.goldCoin)
    ]

    static func def(_ t: TrapType) -> TrapDef {
        all.first { $0.type == t } ?? all[0]
    }

    static func damage(_ t: TrapType, level: Int, inChamber: Bool) -> Double {
        let lvl = max(1, min(3, level))
        var d = def(t).baseDamage * levelDamage[lvl - 1]
        if inChamber { d *= 1.3 }
        return d
    }

    /// Cost to place at level 1.
    static func placeCost(_ t: TrapType) -> Int { def(t).baseCost }

    /// Cost to upgrade from (toLevel-1) to toLevel.
    static func upgradeCost(_ t: TrapType, toLevel: Int) -> Int {
        Int((Double(def(t).baseCost) * upgradeShare * Double(toLevel - 1)).rounded())
    }

    /// Total invested value at a given level.
    static func value(_ t: TrapType, level: Int) -> Int {
        var v = def(t).baseCost
        if level >= 2 { v += upgradeCost(t, toLevel: 2) }
        if level >= 3 { v += upgradeCost(t, toLevel: 3) }
        return v
    }

    /// Chance a rogue disarms the trap on entry.
    static func disarmChance(_ t: TrapType, level: Int, heroLevel: Int) -> Double {
        var c = disarmBase + 0.04 * Double(heroLevel - 1) - 0.12 * Double(level - 1)
        if t == .mimicChest { c -= 0.15 }   // hard to argue with teeth
        return min(0.9, max(0.15, c))
    }
}
