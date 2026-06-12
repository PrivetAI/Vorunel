import SwiftUI

// MARK: - Hero class definitions

struct HeroDef {
    let cls: HeroClass
    let baseHP: Double
    let baseATK: Double
    let moveInterval: Int     // ticks per step
    let dodge: Double
    let tagline: String
    let aiText: String
    let lore: String
    let tint: Color
}

enum HeroCatalog {
    /// Stat multiplier per hero level.
    static func levelScale(_ level: Int) -> Double {
        1.0 + 0.35 * Double(max(1, level) - 1)
    }

    static let all: [HeroDef] = [
        HeroDef(cls: .warrior, baseHP: 90, baseATK: 9, moveInterval: 2, dodge: 0,
                tagline: "A wall with opinions.",
                aiText: "Tanks: monsters concentrate their blows on warriors first.",
                lore: "Sells the same story in every tavern: one more dungeon and then the farm. There is never a farm.",
                tint: DATheme.blood),
        HeroDef(cls: .rogue, baseHP: 60, baseATK: 11, moveInterval: 2, dodge: 0.20,
                tagline: "Considers your traps a code review.",
                aiText: "Disarms: may permanently disable a trap when stepping on it.",
                lore: "Keeps a souvenir gear from every trap survived. The necklace is getting heavy.",
                tint: DATheme.shadowMauve),
        HeroDef(cls: .mage, baseHP: 50, baseATK: 8, moveInterval: 2, dodge: 0,
                tagline: "Fragile. Loud about it.",
                aiText: "Area caster: damages every monster in the room at once.",
                lore: "Three towers expelled them for excessive fireball indoors. Your corridors qualify as indoors.",
                tint: DATheme.frost),
        HeroDef(cls: .cleric, baseHP: 55, baseATK: 6, moveInterval: 2, dodge: 0,
                tagline: "The reason your math stops working.",
                aiText: "Healer: mends the most wounded ally instead of attacking.",
                lore: "Prays loudly, heals quietly, and bills the party guild rates either way.",
                tint: DATheme.goldCoin),
        HeroDef(cls: .paladin, baseHP: 85, baseATK: 8, moveInterval: 2, dodge: 0,
                tagline: "Insists the dungeon can be redeemed.",
                aiText: "Stalwart: self-mends when wounded; the party shrugs off fear.",
                lore: "Polishes the armor every night. The armor has started polishing back.",
                tint: DATheme.bone),
        HeroDef(cls: .ranger, baseHP: 65, baseATK: 10, moveInterval: 2, dodge: 0.10,
                tagline: "Shot first. Will explain never.",
                aiText: "Ambusher: strikes fresh monsters 25% harder, hard to pin down.",
                lore: "Claims to hate dungeons and cities both. Keeps visiting dungeons.",
                tint: DATheme.sicklyDeep)
    ]

    static func def(_ c: HeroClass) -> HeroDef {
        all.first { $0.cls == c } ?? all[0]
    }
    static func hp(_ c: HeroClass, level: Int) -> Double {
        def(c).baseHP * levelScale(level)
    }
    static func atk(_ c: HeroClass, level: Int) -> Double {
        def(c).baseATK * levelScale(level)
    }
    static func healPower(_ level: Int) -> Double {
        12.0 * levelScale(level)
    }

    // MARK: - Names

    static let namePool: [HeroClass: [String]] = [
        .warrior: ["Bram Ironside", "Hale Oxbrand", "Greta Shieldmaiden", "Tobin Vance", "Korra Flintheart", "Dunstan Pike", "Maeve Stoneoath", "Roderic Hewn"],
        .rogue: ["Wren Quickfingers", "Silas Vex", "Nim Halloway", "Petra Lockbane", "Fenwick Sly", "Isolde Thorn", "Jasper Creed", "Lyra Nightstep"],
        .mage: ["Aldous Greyspark", "Mirella Voss", "Caspian Embertide", "Ophira Lune", "Bertrand Hex", "Sable Wyrmword", "Edwina Stormquill", "Loras Vane"],
        .cleric: ["Sister Maribel", "Father Odo", "Beata Lightmourn", "Prior Anselm", "Cantor Ivy", "Deacon Hartwell", "Abbess Rowena", "Frater Lucan"],
        .paladin: ["Ser Edmund Vale", "Dame Sorcha Bright", "Ser Galwin Trueforge", "Dame Annora Crest", "Ser Percival Dawn", "Dame Hestia Ward", "Ser Lambert Gold", "Dame Verity Shawe"],
        .ranger: ["Tamsin Farshot", "Corvus Reed", "Briar Whitlock", "Eamon Swiftbough", "Senna Larkwood", "Garrick Pinehollow", "Vesper Cole", "Rhoswen Dart"]
    ]

    /// Deterministic name for campaign slots.
    static func name(for cls: HeroClass, index: Int) -> String {
        let pool = namePool[cls] ?? ["Nameless One"]
        return pool[index % pool.count]
    }

    static func randomName(for cls: HeroClass, rng: inout SeededRNG) -> String {
        let pool = namePool[cls] ?? ["Nameless One"]
        return pool[rng.int(0...(pool.count - 1))]
    }
}
