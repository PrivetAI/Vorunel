import SwiftUI

struct EndlessHubView: View {
    @EnvironmentObject var store: GameStore

    private var wave: Int { store.profile.endlessWave }

    var body: some View {
        VStack(spacing: 0) {
            DAScreenHeader(title: "Endless Siege", onBack: { store.screen = .menu })

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    VStack(spacing: 10) {
                        WaveCrestIcon(size: 56, color: DATheme.blood)
                        Text(wave > 1 ? "The siege rages on" : "A new siege gathers")
                            .font(DATheme.display(24))
                            .foregroundColor(DATheme.bone)
                            .multilineTextAlignment(.center)
                        Text("Wave after wave, the parties grow larger, bolder, and better paid. Hold the Heart as long as the stone allows. One defeat ends the run.")
                            .font(DATheme.ui(13, .medium))
                            .foregroundColor(DATheme.boneDim)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 18)

                    HStack(spacing: 12) {
                        statCard(title: "Next Wave", value: "\(wave)", tint: DATheme.ember)
                        statCard(title: "Best Stand", value: store.profile.endlessBest > 0 ? "\(store.profile.endlessBest)" : "—", tint: DATheme.goldCoin)
                    }

                    // Preview of the coming wave
                    if store.profile.endlessSeed != 0 || wave == 1 {
                        wavePreview
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Siege Rules")
                            .font(DATheme.head(14))
                            .foregroundColor(DATheme.bone)
                        ruleLine("Parties scale with every wave; champions lead every tenth.")
                        ruleLine("Blessings appear from wave 5 and stack from wave 12.")
                        ruleLine("Gold and Dark Renown flow between waves — rebuild freely.")
                        ruleLine("Lose once and the run resets to wave 1.")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .daPanel()

                    DAActionButton(title: wave > 1 ? "Defend — Wave \(wave)" : "Begin the Siege") {
                        store.pendingContext = .endless(wave)
                        store.screen = .editor
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var wavePreview: some View {
        let size = min(5, 2 + wave / 4)
        let level = max(1, 1 + wave / 2)
        return VStack(alignment: .leading, spacing: 6) {
            Text("Scouts Report")
                .font(DATheme.head(14))
                .foregroundColor(DATheme.bone)
            Text("Roughly \(size)\(wave / 4 + 2 < 5 && wave >= 3 ? " or more" : "") raiders, around level \(level).\(wave % 10 == 0 ? " A champion carries their banner." : "")")
                .font(DATheme.ui(12, .medium))
                .foregroundColor(DATheme.boneDim)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .daPanel(stroke: DATheme.blood.opacity(0.5))
    }

    private func statCard(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(DATheme.ui(10, .heavy))
                .foregroundColor(DATheme.boneFaint)
            Text(value)
                .font(DATheme.display(26))
                .foregroundColor(tint)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .daPanel()
    }

    private func ruleLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 7) {
            Circle().fill(DATheme.ember).frame(width: 5, height: 5)
                .padding(.top, 5)
            Text(text)
                .font(DATheme.ui(12, .medium))
                .foregroundColor(DATheme.boneDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
