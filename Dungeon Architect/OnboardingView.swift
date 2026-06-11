import SwiftUI

/// Five-step skippable introduction shown on first launch.
struct OnboardingView: View {
    @EnvironmentObject var store: GameStore
    @State private var step = 0

    private let lastStep = 4

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadialGradient(colors: [DATheme.plumDeep, DATheme.obsidian],
                               center: .top, startRadius: 50, endRadius: geo.size.height)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: {
                            SoundBox.shared.play(.uiTap)
                            store.completeOnboarding()
                        }) {
                            Text("Skip")
                                .font(DATheme.ui(14))
                                .foregroundColor(DATheme.boneDim)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .daPanel(radius: 10)
                        }
                        .buttonStyle(DAPressStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    Spacer()

                    pageContent(step)
                        .padding(.horizontal, 30)
                        .frame(maxWidth: 520)
                        .id(step)
                        .transition(.opacity)

                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(0...lastStep, id: \.self) { i in
                            Capsule()
                                .fill(i == step ? DATheme.ember : DATheme.plumLight.opacity(0.6))
                                .frame(width: i == step ? 22 : 8, height: 8)
                        }
                    }
                    .padding(.bottom, 18)

                    HStack(spacing: 12) {
                        if step > 0 {
                            Button(action: {
                                SoundBox.shared.play(.uiTap)
                                withAnimation(.easeOut(duration: 0.2)) { step -= 1 }
                            }) {
                                Text("Back")
                                    .font(DATheme.head(15))
                                    .foregroundColor(DATheme.boneDim)
                                    .padding(.vertical, 13)
                                    .frame(width: 100)
                                    .daPanel(radius: 12)
                            }
                            .buttonStyle(DAPressStyle())
                        }
                        DAActionButton(title: step == lastStep ? "Take the Throne" : "Next") {
                            if step == lastStep {
                                store.completeOnboarding()
                            } else {
                                withAnimation(.easeOut(duration: 0.2)) { step += 1 }
                            }
                        }
                    }
                    .padding(.horizontal, 26)
                    .frame(maxWidth: 520)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    @ViewBuilder
    private func pageContent(_ s: Int) -> some View {
        switch s {
        case 0:
            page(icon: AnyView(HeartCrystalIcon(size: 84, color: DATheme.blood)),
                 title: "You Are the Dungeon",
                 text: "Forget the sword-swingers. You are the one who digs the halls, stocks the dark, and owns the glowing Heart at the bottom. Heroes raid YOU — and that is their mistake.")
        case 1:
            page(icon: AnyView(PickaxeIcon(size: 80)),
                 title: "Carve and Rig",
                 text: "Dig corridors and chambers on the grid: treasuries to tempt, barracks to bolster, shrines that knit wounds. Lace the floor with ten kinds of traps and garrison twelve monster families. One law is sacred: a path from the entrance to your Heart must always remain open.")
        case 2:
            page(icon: AnyView(SwordIcon(size: 80, color: DATheme.bone)),
                 title: "Know Your Enemy",
                 text: "Raiding parties think for themselves. Rogues disarm your traps, clerics mend the wounded, mages scorch whole rooms, and the greedy detour for every coin. Watch their intent arrows, break their morale, and send the survivors running.")
        case 3:
            page(icon: AnyView(StarIcon(size: 76, filled: true)),
                 title: "Watch It Unfold",
                 text: "When the gates open, the raid plays out tick by tick. Pause to think, or run it at double and quadruple speed. Win to earn gold; defend flawlessly and build lean for up to three stars per raid.")
        case 4:
            page(icon: AnyView(RenownIcon(size: 78)),
                 title: "Grow Infamous",
                 text: "Thirty campaign raids across five regions, five legendary heroes with second winds, and an Endless Siege that never stops knocking. Spend Dark Renown on permanent pacts: new monsters, crueler traps, a tougher Heart. The mountain is yours. Keep it.")
        default:
            EmptyView()
        }
    }

    private func page(icon: AnyView, title: String, text: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(DATheme.voidShade.opacity(0.7))
                    .frame(width: 140, height: 140)
                Circle()
                    .stroke(DATheme.plumLight.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 140, height: 140)
                icon
            }
            Text(title)
                .font(DATheme.display(27))
                .foregroundColor(DATheme.bone)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            Text(text)
                .font(DATheme.ui(14, .medium))
                .foregroundColor(DATheme.boneDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
