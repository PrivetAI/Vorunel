import SwiftUI

// MARK: - Party slots & scenarios

struct PartySlot: Codable, Equatable {
    let cls: HeroClass
    let level: Int
    let personality: Personality
    let name: String
    var isBoss: Bool = false
}

struct CampaignChapter: Identifiable {
    let id: Int
    let name: String
    let blurb: String
    let tint: Color
    var scenarioIDs: ClosedRange<Int> { ((id - 1) * 6 + 1)...(id * 6) }
}

struct CampaignScenario: Identifiable {
    let id: Int
    let chapter: Int
    let title: String
    let brief: String
    let party: [PartySlot]
    let modifiers: [RaidModifier]
    let goldReward: Int
    let renownReward: Int
    let budgetCap: Int
    var bossName: String? = nil
    var isBossRaid: Bool { bossName != nil }
}

enum CampaignBook {
    static let chapters: [CampaignChapter] = [
        CampaignChapter(id: 1, name: "Forest Outpost",
                        blurb: "Word of your little hole in the hills has reached the village notice board. Amateurs with hand-me-down swords are coming to make a name.",
                        tint: DATheme.sicklyDeep),
        CampaignChapter(id: 2, name: "Mountain Vault",
                        blurb: "You dug deeper and struck old dwarven coin. Now the guilds send professionals with receipts and torches.",
                        tint: Color(daHex: 0x8A6F4D)),
        CampaignChapter(id: 3, name: "Sunken Crypt",
                        blurb: "The lower halls flooded with black water and worse rumors. Drowned-court treasure draws a saltier breed of hero.",
                        tint: Color(daHex: 0x3E6E7E)),
        CampaignChapter(id: 4, name: "Obsidian Keep",
                        blurb: "Your heart-crystal's glow now leaks from the mountain's cracks. The capital has chartered veteran companies to put it out.",
                        tint: Color(daHex: 0x53356B)),
        CampaignChapter(id: 5, name: "The Worldspire",
                        blurb: "The surface kingdoms call it a crusade. You call it the busiest season yet. The Spire's chosen are coming, blessed and bannered.",
                        tint: DATheme.emberDeep)
    ]

    static func chapter(_ id: Int) -> CampaignChapter {
        chapters.first { $0.id == id } ?? chapters[0]
    }

    static func scenario(_ id: Int) -> CampaignScenario {
        scenarios.first { $0.id == id } ?? scenarios[0]
    }

    private static func slot(_ cls: HeroClass, _ level: Int, _ p: Personality, _ nameIndex: Int) -> PartySlot {
        PartySlot(cls: cls, level: level, personality: p, name: HeroCatalog.name(for: cls, index: nameIndex))
    }

    static let scenarios: [CampaignScenario] = [
        // ---- Chapter 1: Forest Outpost (1-6)
        CampaignScenario(id: 1, chapter: 1, title: "First Knock",
            brief: "Two hopefuls from the village militia, sharing one map and one plan: walk in, smash the glowing thing. Greet them with iron and teeth.",
            party: [slot(.warrior, 1, .bold, 0), slot(.rogue, 1, .greedy, 0)],
            modifiers: [], goldReward: 140, renownReward: 2, budgetCap: 520),
        CampaignScenario(id: 2, chapter: 1, title: "The Apprentice",
            brief: "A hedge-mage tags along this time, hurling sparks at anything that moves. Spread your garrison so one fireball cannot catch them all.",
            party: [slot(.warrior, 1, .bold, 1), slot(.mage, 1, .cautious, 0)],
            modifiers: [], goldReward: 160, renownReward: 2, budgetCap: 700),
        CampaignScenario(id: 3, chapter: 1, title: "Torchbearers",
            brief: "They bring lanterns and bravado. Bright light dulls your monsters' ambush edge, so let traps do the early talking.",
            party: [slot(.warrior, 2, .bold, 2), slot(.rogue, 1, .greedy, 1), slot(.cleric, 1, .cautious, 0)],
            modifiers: [.torchlit], goldReward: 180, renownReward: 3, budgetCap: 900),
        CampaignScenario(id: 4, chapter: 1, title: "Gold Fever",
            brief: "Prospectors heard about your treasury. Every one of them will detour for coin. Bait a side passage and make greed expensive.",
            party: [slot(.rogue, 2, .greedy, 2), slot(.ranger, 1, .greedy, 0), slot(.warrior, 1, .bold, 3)],
            modifiers: [.greedy], goldReward: 200, renownReward: 3, budgetCap: 1100),
        CampaignScenario(id: 5, chapter: 1, title: "The Long March",
            brief: "A seasoned trio with a priest in tow. The cleric will undo your damage unless you focus it down or break their nerve first.",
            party: [slot(.warrior, 2, .bold, 4), slot(.cleric, 2, .cautious, 1), slot(.ranger, 2, .bold, 1)],
            modifiers: [.blessed], goldReward: 220, renownReward: 3, budgetCap: 1300),
        CampaignScenario(id: 6, chapter: 1, title: "The Lantern Knight",
            brief: "Ser Bramwell the Lantern, hero of two wars, has taken personal offense at your existence. When wounded he lights his greatlamp and fights twice as hard.",
            party: [PartySlot(cls: .warrior, level: 4, personality: .bold, name: "Ser Bramwell the Lantern", isBoss: true),
                    slot(.cleric, 2, .cautious, 2), slot(.rogue, 2, .greedy, 3)],
            modifiers: [.torchlit], goldReward: 320, renownReward: 5, budgetCap: 1600,
            bossName: "Ser Bramwell the Lantern"),

        // ---- Chapter 2: Mountain Vault (7-12)
        CampaignScenario(id: 7, chapter: 2, title: "Guild Charter",
            brief: "The Prospectors' Guild filed paperwork to raid you. Their squads are balanced and businesslike. Kill-boxes beat bureaucracy.",
            party: [slot(.warrior, 3, .bold, 5), slot(.mage, 2, .cautious, 1), slot(.cleric, 2, .cautious, 3)],
            modifiers: [], goldReward: 240, renownReward: 3, budgetCap: 1850),
        CampaignScenario(id: 8, chapter: 2, title: "Smoke and Steel",
            brief: "Sappers with fast boots. They will sprint your corridors before traps reset. Layer cooldowns or widen the gauntlet.",
            party: [slot(.rogue, 3, .bold, 4), slot(.ranger, 3, .bold, 2), slot(.warrior, 2, .bold, 6)],
            modifiers: [.hasted], goldReward: 270, renownReward: 4, budgetCap: 2100),
        CampaignScenario(id: 9, chapter: 2, title: "The Counting House",
            brief: "An accountant-knight leads a coin-mad crew. They will weigh every treasury before touching your Heart. Make the ledgers bleed.",
            party: [slot(.paladin, 3, .greedy, 0), slot(.rogue, 3, .greedy, 5), slot(.mage, 3, .greedy, 2)],
            modifiers: [.greedy], goldReward: 300, renownReward: 4, budgetCap: 2350),
        CampaignScenario(id: 10, chapter: 2, title: "Deep Survey",
            brief: "Cartographers under armed escort, careful and slow. Cautious heroes route around sprung traps, so keep a few surprises unsprung.",
            party: [slot(.warrior, 3, .cautious, 7), slot(.ranger, 3, .cautious, 3), slot(.cleric, 3, .cautious, 4)],
            modifiers: [], goldReward: 330, renownReward: 4, budgetCap: 2600),
        CampaignScenario(id: 11, chapter: 2, title: "Iron Resolve",
            brief: "Veterans who have sworn off retreat. They will not break, so they must be broken. Bring overwhelming arithmetic.",
            party: [slot(.warrior, 4, .bold, 0), slot(.paladin, 3, .bold, 1), slot(.mage, 3, .cautious, 3)],
            modifiers: [.ironwill], goldReward: 360, renownReward: 4, budgetCap: 2850),
        CampaignScenario(id: 12, chapter: 2, title: "The Stone Hymn",
            brief: "Dame Eira Stonesong carries a relic hammer and a grudge older than your mountain. At half strength she sings the Stone Hymn and mends her wounds.",
            party: [PartySlot(cls: .paladin, level: 6, personality: .bold, name: "Dame Eira Stonesong", isBoss: true),
                    slot(.cleric, 4, .cautious, 5), slot(.warrior, 4, .bold, 1), slot(.rogue, 4, .greedy, 6)],
            modifiers: [.blessed], goldReward: 480, renownReward: 6, budgetCap: 3200,
            bossName: "Dame Eira Stonesong"),

        // ---- Chapter 3: Sunken Crypt (13-18)
        CampaignScenario(id: 13, chapter: 3, title: "Black Water",
            brief: "Salvage divers with crowbars and no scruples. The flooded halls slow no one who grew up wrecking ships.",
            party: [slot(.rogue, 5, .greedy, 7), slot(.warrior, 4, .bold, 2), slot(.ranger, 4, .greedy, 4)],
            modifiers: [.greedy], goldReward: 380, renownReward: 4, budgetCap: 3500),
        CampaignScenario(id: 14, chapter: 3, title: "The Drowned Choir",
            brief: "Pilgrims seeking their sunken saints, warded head to toe. Their blessings blunt grief and sharpen healing. Silence the choir early.",
            party: [slot(.cleric, 5, .cautious, 6), slot(.paladin, 4, .bold, 2), slot(.warrior, 4, .cautious, 3), slot(.mage, 4, .cautious, 4)],
            modifiers: [.blessed], goldReward: 420, renownReward: 5, budgetCap: 3800),
        CampaignScenario(id: 15, chapter: 3, title: "Spellwake",
            brief: "A college of battle-mages on a field exam. Their fire answers to ambition. Keep your garrison out of shared rooms or lose it in volleys.",
            party: [slot(.mage, 5, .bold, 5), slot(.mage, 4, .cautious, 6), slot(.warrior, 5, .bold, 4)],
            modifiers: [.arcane], goldReward: 460, renownReward: 5, budgetCap: 4100),
        CampaignScenario(id: 16, chapter: 3, title: "Tideborn Runners",
            brief: "Smugglers turned heroes, twice as fast and half as honest. They will sprint, loot, and leave unless the floor itself objects.",
            party: [slot(.rogue, 5, .greedy, 0), slot(.ranger, 5, .greedy, 5), slot(.rogue, 4, .bold, 1), slot(.cleric, 4, .cautious, 7)],
            modifiers: [.hasted, .greedy], goldReward: 500, renownReward: 5, budgetCap: 4400),
        CampaignScenario(id: 17, chapter: 3, title: "No Quarter",
            brief: "Mercenaries paid in advance, contractually forbidden to flee. An expensive clause. Make their employer regret it.",
            party: [slot(.warrior, 5, .bold, 5), slot(.warrior, 5, .bold, 6), slot(.cleric, 5, .cautious, 0), slot(.mage, 5, .bold, 7)],
            modifiers: [.ironwill], goldReward: 540, renownReward: 5, budgetCap: 4700),
        CampaignScenario(id: 18, chapter: 3, title: "The Drowned Blade",
            brief: "Maris Veil drowned twenty years ago and never let it slow her down. She walks through traps like rumor through a tavern. Wounded, she becomes mist and malice.",
            party: [PartySlot(cls: .rogue, level: 8, personality: .cautious, name: "Maris Veil, the Drowned Blade", isBoss: true),
                    slot(.cleric, 5, .cautious, 1), slot(.warrior, 5, .bold, 7), slot(.ranger, 5, .cautious, 6)],
            modifiers: [.hasted], goldReward: 650, renownReward: 7, budgetCap: 5100,
            bossName: "Maris Veil, the Drowned Blade"),

        // ---- Chapter 4: Obsidian Keep (19-24)
        CampaignScenario(id: 19, chapter: 4, title: "The Chartered Companies",
            brief: "Five banners, one invoice. The capital's veteran companies arrive in proper marching order. Proper marching order has never met your basement.",
            party: [slot(.warrior, 6, .bold, 0), slot(.paladin, 6, .bold, 3), slot(.mage, 6, .cautious, 0), slot(.cleric, 6, .cautious, 2)],
            modifiers: [], goldReward: 560, renownReward: 5, budgetCap: 5400),
        CampaignScenario(id: 20, chapter: 4, title: "Sanctified Ground",
            brief: "They consecrate every corridor as they advance. Blessed, brave and insufferable. Faith is harder to spring than a pit, but it shares a weakness: pressure.",
            party: [slot(.paladin, 7, .bold, 4), slot(.cleric, 6, .cautious, 3), slot(.warrior, 6, .bold, 1), slot(.ranger, 6, .bold, 7)],
            modifiers: [.blessed, .ironwill], goldReward: 600, renownReward: 5, budgetCap: 5700),
        CampaignScenario(id: 21, chapter: 4, title: "The Gilded Wager",
            brief: "Nobles on a bet: who can carry the most of your gold out alive. All of them are greedy. None of them are patient. Both facts are exploitable.",
            party: [slot(.rogue, 7, .greedy, 2), slot(.ranger, 6, .greedy, 0), slot(.paladin, 6, .greedy, 5), slot(.mage, 6, .greedy, 1)],
            modifiers: [.greedy, .hasted], goldReward: 660, renownReward: 6, budgetCap: 6000),
        CampaignScenario(id: 22, chapter: 4, title: "Stormcallers",
            brief: "Weather-witches who brought the storm indoors. Their amplified barrages will gut clustered garrisons. Spread wide, strike from doorways.",
            party: [slot(.mage, 7, .bold, 2), slot(.mage, 7, .cautious, 3), slot(.warrior, 7, .bold, 2), slot(.cleric, 6, .cautious, 4)],
            modifiers: [.arcane], goldReward: 700, renownReward: 6, budgetCap: 6300),
        CampaignScenario(id: 23, chapter: 4, title: "The Iron Procession",
            brief: "A full warband under oath: no retreat, no mercy, no detours. They come straight for the Heart. Every tile of their road should cost them.",
            party: [slot(.warrior, 8, .bold, 3), slot(.paladin, 7, .bold, 6), slot(.warrior, 7, .bold, 4), slot(.cleric, 7, .cautious, 5), slot(.mage, 6, .bold, 4)],
            modifiers: [.ironwill], goldReward: 760, renownReward: 6, budgetCap: 6600),
        CampaignScenario(id: 24, chapter: 4, title: "The Last Lecture",
            brief: "Archmagus Corvin Hale wrote the textbook on dungeon demolition. He is here to deliver the final chapter in person. Past half strength he stops holding back the good spells.",
            party: [PartySlot(cls: .mage, level: 10, personality: .bold, name: "Archmagus Corvin Hale", isBoss: true),
                    slot(.warrior, 7, .bold, 5), slot(.paladin, 7, .bold, 7), slot(.cleric, 7, .cautious, 6)],
            modifiers: [.arcane], goldReward: 900, renownReward: 8, budgetCap: 7000,
            bossName: "Archmagus Corvin Hale"),

        // ---- Chapter 5: The Worldspire (25-30)
        CampaignScenario(id: 25, chapter: 5, title: "The Crusade Banners",
            brief: "The first banner of the crusade: picked veterans, blessed steel, sponsored boots. The age of amateurs is over. Good. They were getting cheap to kill.",
            party: [slot(.warrior, 8, .bold, 6), slot(.paladin, 8, .bold, 0), slot(.mage, 8, .cautious, 5), slot(.cleric, 8, .cautious, 7), slot(.ranger, 8, .bold, 1)],
            modifiers: [.blessed], goldReward: 800, renownReward: 6, budgetCap: 7400),
        CampaignScenario(id: 26, chapter: 5, title: "Dawn Sprint",
            brief: "Spire outriders, hasted by relic and rite. They intend to reach the Heart before their torches burn down. Time is their weapon. Make it yours.",
            party: [slot(.ranger, 9, .bold, 2), slot(.rogue, 9, .bold, 3), slot(.warrior, 8, .bold, 7), slot(.cleric, 8, .cautious, 0), slot(.mage, 8, .bold, 6)],
            modifiers: [.hasted, .torchlit], goldReward: 860, renownReward: 7, budgetCap: 7800),
        CampaignScenario(id: 27, chapter: 5, title: "The Reliquary Heist",
            brief: "They say your treasuries hold relics from the old kingdom. The Spire wants them back, and its agents will empty every vault to be sure.",
            party: [slot(.rogue, 9, .greedy, 4), slot(.rogue, 9, .greedy, 5), slot(.paladin, 9, .greedy, 1), slot(.cleric, 8, .cautious, 1), slot(.ranger, 9, .greedy, 3)],
            modifiers: [.greedy], goldReward: 920, renownReward: 7, budgetCap: 8200),
        CampaignScenario(id: 28, chapter: 5, title: "Choir of Annihilation",
            brief: "Three archmages walking abreast, chanting in harmony. Everything they see in a room, they erase. Doorway duels and deep reserves win this.",
            party: [slot(.mage, 10, .bold, 7), slot(.mage, 9, .cautious, 0), slot(.mage, 9, .cautious, 1), slot(.warrior, 9, .bold, 0), slot(.cleric, 9, .cautious, 2)],
            modifiers: [.arcane, .blessed], goldReward: 980, renownReward: 7, budgetCap: 8600),
        CampaignScenario(id: 29, chapter: 5, title: "The Unbroken Line",
            brief: "The crusade's finest shield-wall, sworn before the Spire itself: they advance or they die. Grant them the second option, repeatedly.",
            party: [slot(.warrior, 10, .bold, 1), slot(.warrior, 10, .bold, 2), slot(.paladin, 10, .bold, 2), slot(.cleric, 9, .cautious, 3), slot(.mage, 9, .bold, 2)],
            modifiers: [.ironwill, .blessed], goldReward: 1050, renownReward: 8, budgetCap: 9000),
        CampaignScenario(id: 30, chapter: 5, title: "The Saint Descends",
            brief: "Saint Aurelia of the Spire, the crusade's living miracle, has come to end you herself. When her light gutters at half strength, it flares instead: the Saint's Second Dawn. Survive the dawn. Snuff the light. Keep your Heart.",
            party: [PartySlot(cls: .paladin, level: 12, personality: .bold, name: "Saint Aurelia of the Spire", isBoss: true),
                    slot(.cleric, 10, .cautious, 4), slot(.warrior, 10, .bold, 3), slot(.mage, 10, .cautious, 3), slot(.ranger, 10, .bold, 4)],
            modifiers: [.blessed, .ironwill], goldReward: 1400, renownReward: 10, budgetCap: 9999,
            bossName: "Saint Aurelia of the Spire"),
    ]
}

// MARK: - Endless Siege party generation

enum EndlessForge {
    /// Deterministic party for a wave given the run seed.
    static func party(wave: Int, runSeed: UInt64) -> ([PartySlot], [RaidModifier]) {
        var rng = SeededRNG(seed: runSeed &+ UInt64(wave) &* 0x5851F42D4C957F2D)
        let size = min(5, 2 + wave / 4 + (rng.chance(0.3) ? 1 : 0))
        let level = max(1, 1 + wave / 2)
        var slots: [PartySlot] = []
        var classes: [HeroClass] = []
        // Guarantee a frontliner from wave 3 on.
        if wave >= 3 { classes.append(rng.chance(0.5) ? .warrior : .paladin) }
        while classes.count < size {
            classes.append(rng.pick(HeroClass.allCases))
        }
        for (i, cls) in classes.enumerated() {
            let lvl = max(1, level + rng.int(-1...1))
            let pers = rng.pick(Personality.allCases)
            var s = PartySlot(cls: cls, level: lvl, personality: pers,
                              name: HeroCatalog.name(for: cls, index: rng.int(0...7)))
            // Every 10th wave: a champion leads.
            if wave % 10 == 0 && i == 0 {
                s = PartySlot(cls: cls, level: lvl + 2, personality: .bold,
                              name: "Champion " + HeroCatalog.name(for: cls, index: rng.int(0...7)),
                              isBoss: true)
            }
            slots.append(s)
        }
        var mods: [RaidModifier] = []
        if wave >= 5 && rng.chance(0.45) { mods.append(rng.pick(RaidModifier.allCases)) }
        if wave >= 12 && rng.chance(0.35) {
            let second = rng.pick(RaidModifier.allCases)
            if !mods.contains(second) { mods.append(second) }
        }
        return (slots, mods)
    }

    static func goldReward(wave: Int) -> Int { 100 + 45 * wave }
    static func renownReward(wave: Int) -> Int { wave % 5 == 0 ? 4 : 1 }
}
