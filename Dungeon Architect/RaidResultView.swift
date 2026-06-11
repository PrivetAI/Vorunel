import SwiftUI

struct RaidResultView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadialGradient(colors: [outcomeTint.opacity(0.22), DATheme.obsidian],
                               center: .top, startRadius: 30, endRadius: geo.size.height * 0.8)
                    .edgesIgnoringSafeArea(.all)

                if let outcome = store.lastOutcome {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            VStack(spacing: 10) {
                                if outcome.won {
                                    HeartCrystalIcon(size: 64)
                                        .shadow(color: DATheme.blood.opacity(0.6), radius: 18)
                                } else {
                                    ZStack {
                                        HeartCrystalIcon(size: 64, color: DATheme.shadowMauve.opacity(0.5))
                                        CrossIcon(size: 36)
                                    }
                                }
                                Text(outcome.won ? "The Dungeon Stands" : "The Heart Is Shattered")
                                    .font(DATheme.display(26))
                                    .foregroundColor(outcome.won ? DATheme.bone : DATheme.blood)
                                    .multilineTextAlignment(.center)
                                Text(flavor(outcome))
                                    .font(DATheme.ui(13, .medium))
                                    .foregroundColor(DATheme.boneDim)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 24)

                            if outcome.won, outcome.scenarioID != nil {
                                HStack(spacing: 10) {
                                    ForEach(0..<3, id: \.self) { i in
                                        StarIcon(size: 34, filled: i < outcome.stars)
                                    }
                                }
                                starBreakdown(outcome)
                            }

                            if let wave = outcome.waveNumber {
                                VStack(spacing: 4) {
                                    Text(outcome.won ? "Wave \(wave) repelled" : "Fell on wave \(wave)")
                                        .font(DATheme.head(16))
                                        .foregroundColor(DATheme.bone)
                                    if outcome.newWaveRecord {
                                        Text("NEW RECORD")
                                            .font(DATheme.ui(11, .heavy))
                                            .foregroundColor(DATheme.goldCoin)
                                    }
                                    if !outcome.won {
                                        Text("The siege run is over. The next stand begins at wave 1.")
                                            .font(DATheme.ui(12, .medium))
                                            .foregroundColor(DATheme.boneDim)
                                    }
                                }
                            }

                            // Tally
                            VStack(spacing: 8) {
                                tallyRow(label: "Gold claimed", value: "+\(outcome.goldGained)", tint: DATheme.goldCoin)
                                if outcome.renownGained > 0 {
                                    tallyRow(label: "Dark Renown", value: "+\(outcome.renownGained)", tint: Color(daHex: 0xB58BE8))
                                }
                                tallyRow(label: "Heroes slain", value: "\(outcome.heroesSlain)", tint: DATheme.sickly)
                                if outcome.heroesEscaped > 0 {
                                    tallyRow(label: "Heroes escaped", value: "\(outcome.heroesEscaped)", tint: DATheme.blood)
                                }
                                tallyRow(label: "Heart", value: "\(Int(outcome.heartHPLeft))/\(Int(outcome.heartMaxHP))", tint: DATheme.blood)
                                tallyRow(label: "Ticks fought", value: "\(outcome.ticks)", tint: DATheme.boneDim)
                                if let boss = outcome.bossDefeated {
                                    tallyRow(label: "Legend felled", value: boss, tint: DATheme.goldCoin)
                                }
                            }
                            .padding(14)
                            .daPanel()

                            if !outcome.newAchievements.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Feats Earned")
                                        .font(DATheme.head(14))
                                        .foregroundColor(DATheme.goldCoin)
                                    ForEach(outcome.newAchievements, id: \.self) { id in
                                        if let def = AchievementBook.def(id) {
                                            HStack(spacing: 8) {
                                                TrophyIcon(size: 18)
                                                VStack(alignment: .leading, spacing: 1) {
                                                    Text(def.title)
                                                        .font(DATheme.ui(13, .bold))
                                                        .foregroundColor(DATheme.bone)
                                                    Text(def.desc)
                                                        .font(DATheme.ui(11, .medium))
                                                        .foregroundColor(DATheme.boneDim)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .daPanel(stroke: DATheme.goldCoin.opacity(0.6))
                            }

                            VStack(spacing: 10) {
                                DAActionButton(title: primaryLabel(outcome)) {
                                    primaryAction(outcome)
                                }
                                DAActionButton(title: "Rework the Dungeon", tint: DATheme.plumLight, textColor: DATheme.bone) {
                                    store.screen = .editor
                                }
                                DAActionButton(title: "Main Menu", tint: DATheme.plumDeep, textColor: DATheme.boneDim) {
                                    store.pendingContext = nil
                                    store.screen = .menu
                                }
                            }
                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, 20)
                        .frame(maxWidth: 540)
                        .frame(maxWidth: .infinity)
                    }
                } else {
                    VStack(spacing: 14) {
                        Text("No raid to report.")
                            .font(DATheme.head(16))
                            .foregroundColor(DATheme.boneDim)
                        DAActionButton(title: "Main Menu") { store.screen = .menu }
                            .frame(maxWidth: 280)
                    }
                }
            }
        }
    }

    private var outcomeTint: Color {
        (store.lastOutcome?.won ?? false) ? DATheme.sicklyDeep : DATheme.blood
    }

    private func flavor(_ o: RaidOutcome) -> String {
        if o.won {
            if o.heroesEscaped > 0 {
                return "Survivors limp home with stories. Stories are free advertising."
            }
            return "No survivors. The mountain keeps its secrets, and their gear."
        }
        return "Rebuild. Re-rig. The next party will not be so lucky."
    }

    private func starBreakdown(_ o: RaidOutcome) -> some View {
        VStack(spacing: 4) {
            starHint(got: true, text: "Raid repelled")
            starHint(got: o.heartUntouched, text: "Heart untouched")
            starHint(got: o.underBudget, text: "Under the gold budget")
        }
    }

    private func starHint(got: Bool, text: String) -> some View {
        HStack(spacing: 6) {
            if got {
                CheckIcon(size: 12)
            } else {
                CrossIcon(size: 12, color: DATheme.boneFaint)
            }
            Text(text)
                .font(DATheme.ui(12, .medium))
                .foregroundColor(got ? DATheme.bone : DATheme.boneFaint)
        }
    }

    private func tallyRow(label: String, value: String, tint: Color) -> some View {
        HStack {
            Text(label)
                .font(DATheme.ui(13, .medium))
                .foregroundColor(DATheme.boneDim)
            Spacer()
            Text(value)
                .font(DATheme.mono(13))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private func primaryLabel(_ o: RaidOutcome) -> String {
        switch o.context {
        case .campaign: return o.won ? "Back to the Campaign" : "Try Again"
        case .endless: return o.won ? "Prepare the Next Wave" : "Back to the Siege Hub"
        }
    }

    private func primaryAction(_ o: RaidOutcome) {
        switch o.context {
        case .campaign(let id):
            if o.won {
                store.pendingContext = nil
                store.screen = .campaign
            } else {
                store.pendingContext = .campaign(id)
                store.screen = .editor
            }
        case .endless:
            if o.won {
                store.pendingContext = .endless(store.profile.endlessWave)
                store.screen = .editor
            } else {
                store.pendingContext = nil
                store.screen = .endless
            }
        }
    }
}
