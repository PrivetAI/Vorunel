import SwiftUI

struct CodexView: View {
    @EnvironmentObject var store: GameStore
    @State private var section = 0

    private let sections = ["Heroes", "Monsters", "Traps", "Rooms"]

    var body: some View {
        VStack(spacing: 0) {
            DAScreenHeader(title: "Codex", onBack: { store.screen = .menu })

            HStack(spacing: 6) {
                ForEach(0..<4, id: \.self) { i in
                    Button(action: {
                        SoundBox.shared.play(.uiTap)
                        section = i
                    }) {
                        Text(sections[i])
                            .font(DATheme.ui(12, .bold))
                            .foregroundColor(section == i ? DATheme.voidShade : DATheme.boneDim)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(section == i ? DATheme.ember : DATheme.plumDeep)
                            )
                    }
                    .buttonStyle(DAPressStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    switch section {
                    case 0: heroEntries
                    case 1: monsterEntries
                    case 2: trapEntries
                    default: roomEntries
                    }
                    Spacer(minLength: 24)
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Sections

    private var heroEntries: some View {
        ForEach(HeroCatalog.all, id: \.cls.rawValue) { def in
            entry(icon: AnyView(HeroClassIcon(cls: def.cls, size: 26)),
                  title: def.cls.displayName,
                  subtitle: def.tagline,
                  lines: [
                    ("Tactics", def.aiText),
                    ("Vitality", "\(Int(def.baseHP)) health, \(Int(def.baseATK)) attack at level 1" + (def.dodge > 0 ? ", \(Int(def.dodge * 100))% dodge" : "")),
                    ("Lore", def.lore)
                  ],
                  tint: def.tint)
        }
    }

    private var monsterEntries: some View {
        ForEach(MonsterCatalog.all, id: \.family.rawValue) { def in
            let known = store.unlockedMonsters.contains(def.family)
            entry(icon: AnyView(FangIcon(size: 26, color: def.tint)),
                  title: known ? def.name : "Unknown Creature",
                  subtitle: known ? "\(def.tierNames[0]) • \(def.tierNames[1]) • \(def.tierNames[2])" : "Seal the right pact to study this beast.",
                  lines: known ? [
                    (MonsterCatalog.def(def.family).ability.displayName, def.abilityText),
                    ("Vitality", "\(Int(def.baseHP)) health, \(Int(def.baseATK)) attack, \(def.baseUpkeep) upkeep at tier 1"),
                    ("Lore", def.lore)
                  ] : [],
                  tint: known ? def.tint : DATheme.boneFaint)
        }
    }

    private var trapEntries: some View {
        ForEach(TrapCatalog.all, id: \.type.rawValue) { def in
            let known = store.unlockedTraps.contains(def.type)
            entry(icon: AnyView(def.type == .spike
                                ? AnyView(SpikesIcon(size: 24, color: def.tint))
                                : AnyView(TrapGearIcon(size: 24, color: def.tint))),
                  title: known ? def.name : "Unknown Mechanism",
                  subtitle: known ? def.tagline : "Seal the right pact to read these schematics.",
                  lines: known ? [
                    ("Effect", def.effectText),
                    ("Works", "\(def.baseCost) gold" + (def.baseDamage > 0 ? ", \(Int(def.baseDamage)) base damage" : "") + (def.cooldown < 90 ? ", rearms in \(def.cooldown) ticks" : ", strikes once")),
                    ("Lore", def.lore)
                  ] : [],
                  tint: known ? def.tint : DATheme.boneFaint)
        }
    }

    private var roomEntries: some View {
        ForEach([TileKind.corridor, .treasury, .barracks, .trapChamber, .shrine, .illusionHall, .entrance, .heart], id: \.rawValue) { kind in
            let known = kind == .entrance || kind == .heart || store.unlockedRooms.contains(kind)
            entry(icon: AnyView(RoundedRectangle(cornerRadius: 5).fill(kind.tint)
                    .frame(width: 22, height: 22)
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.3)))),
                  title: known ? kind.displayName : "Sealed Blueprint",
                  subtitle: known ? kind.effectText : "Seal the right pact to dig this chamber.",
                  lines: known ? [("Lore", kind.lore)] : [],
                  tint: known ? DATheme.bone : DATheme.boneFaint)
        }
    }

    // MARK: - Entry card

    private func entry(icon: AnyView, title: String, subtitle: String, lines: [(String, String)], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(DATheme.voidShade)
                        .frame(width: 42, height: 42)
                    icon
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(DATheme.head(15))
                        .foregroundColor(tint)
                    Text(subtitle)
                        .font(DATheme.ui(11, .medium))
                        .foregroundColor(DATheme.boneDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
            }
            ForEach(lines, id: \.0) { line in
                VStack(alignment: .leading, spacing: 1) {
                    Text(line.0.uppercased())
                        .font(DATheme.ui(9, .heavy))
                        .foregroundColor(DATheme.boneFaint)
                    Text(line.1)
                        .font(DATheme.ui(12, .regular))
                        .foregroundColor(DATheme.boneDim)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .daPanel()
    }
}
