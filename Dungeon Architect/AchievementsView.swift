import SwiftUI

/// Achievements ("Feats") plus the lifetime statistics ledger.
struct AchievementsView: View {
    @EnvironmentObject var store: GameStore
    @State private var section = 0

    var body: some View {
        VStack(spacing: 0) {
            DAScreenHeader(title: "Feats", onBack: { store.screen = .menu })

            HStack(spacing: 6) {
                segButton("Achievements", index: 0)
                segButton("Statistics", index: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    if section == 0 {
                        achievementsHeader
                        ForEach(AchievementBook.all) { def in
                            achievementCard(def)
                        }
                    } else {
                        statisticsPanel
                    }
                    Spacer(minLength: 24)
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func segButton(_ title: String, index: Int) -> some View {
        Button(action: {
            SoundBox.shared.play(.uiTap)
            section = index
        }) {
            Text(title)
                .font(DATheme.ui(12, .bold))
                .foregroundColor(section == index ? DATheme.voidShade : DATheme.boneDim)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(section == index ? DATheme.ember : DATheme.plumDeep)
                )
        }
        .buttonStyle(DAPressStyle())
    }

    // MARK: - Achievements

    private var achievementsHeader: some View {
        let earned = store.profile.achievements.count
        let total = AchievementBook.all.count
        return HStack(spacing: 12) {
            TrophyIcon(size: 34)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(earned) of \(total) feats earned")
                    .font(DATheme.head(15))
                    .foregroundColor(DATheme.bone)
                Text(earned == total ? "The mountain bows to its keeper."
                                     : "Cruelty, like all crafts, rewards practice.")
                    .font(DATheme.ui(11, .medium))
                    .foregroundColor(DATheme.boneDim)
            }
            Spacer()
        }
        .padding(13)
        .daPanel(stroke: DATheme.goldCoin.opacity(0.45))
    }

    private func achievementCard(_ def: AchievementDef) -> some View {
        let earned = store.profile.achievements.contains(def.id)
        return HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(DATheme.voidShade)
                    .frame(width: 42, height: 42)
                if earned {
                    TrophyIcon(size: 24)
                } else {
                    LockIcon(size: 20, color: DATheme.boneFaint)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(def.title)
                    .font(DATheme.head(14))
                    .foregroundColor(earned ? DATheme.goldCoin : DATheme.boneDim)
                Text(def.desc)
                    .font(DATheme.ui(11, .medium))
                    .foregroundColor(DATheme.boneDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if earned {
                CheckIcon(size: 16, color: DATheme.sickly)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .daPanel(stroke: earned ? DATheme.goldCoin.opacity(0.4) : DATheme.plumLight)
        .opacity(earned ? 1 : 0.75)
    }

    // MARK: - Statistics

    private var statisticsPanel: some View {
        let st = store.profile.stats
        return VStack(spacing: 10) {
            statGroup("The Ledger of War", [
                ("Raids weathered", "\(st.totalRaids)"),
                ("Raids repelled", "\(st.wins)"),
                ("Raids lost", "\(st.losses)"),
                ("Ticks simulated", "\(st.ticksSimulated)")
            ])
            statGroup("The Butcher's Bill", [
                ("Heroes slain", "\(st.heroesSlain)"),
                ("Heroes escaped", "\(st.heroesEscaped)"),
                ("Legends felled", "\(st.bossesSlain)"),
                ("Monsters lost", "\(st.monstersLost)")
            ])
            statGroup("Machinery & Coin", [
                ("Traps sprung", "\(st.trapsTriggered)"),
                ("Mimic meals", "\(st.mimicKills)"),
                ("Treasuries looted", "\(st.treasuriesLooted)"),
                ("Gold earned", "\(st.goldEarned)"),
                ("Gold spent", "\(st.goldSpent)"),
                ("Heart damage suffered", "\(st.heartDamageTaken)")
            ])
            statGroup("Standing", [
                ("Campaign stars", "\(store.totalStars) / 90"),
                ("Best endless wave", store.profile.endlessBest > 0 ? "\(store.profile.endlessBest)" : "—"),
                ("Pacts sealed", "\(store.profile.unlocked.count) / \(UnlockTree.nodes.count)"),
                ("Monster families fielded", "\(st.familiesPlaced.count) / \(MonsterFamily.allCases.count)"),
                ("Trap types deployed", "\(st.trapTypesPlaced.count) / \(TrapType.allCases.count)")
            ])
        }
    }

    private func statGroup(_ title: String, _ rows: [(String, String)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(DATheme.ui(10, .heavy))
                .foregroundColor(DATheme.boneFaint)
            ForEach(rows, id: \.0) { row in
                HStack {
                    Text(row.0)
                        .font(DATheme.ui(13, .medium))
                        .foregroundColor(DATheme.boneDim)
                    Spacer()
                    Text(row.1)
                        .font(DATheme.mono(13))
                        .foregroundColor(DATheme.bone)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .daPanel()
    }
}
