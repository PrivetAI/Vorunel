import SwiftUI

struct UnlocksView: View {
    @EnvironmentObject var store: GameStore
    @State private var message: String? = nil

    private var branches: [(String, [UnlockNode])] {
        [
            ("Monstrous Pacts", UnlockTree.nodes.filter { if case .monsters = $0.effect { return true }; return false }),
            ("Trapworks", UnlockTree.nodes.filter {
                switch $0.effect {
                case .traps, .trapMastery: return true
                default: return false
                }
            }),
            ("Architecture", UnlockTree.nodes.filter { if case .rooms = $0.effect { return true }; return false }),
            ("Heart & Hoard", UnlockTree.nodes.filter {
                switch $0.effect {
                case .heartHP, .upkeepDiscount, .rewardBonus: return true
                default: return false
                }
            })
        ]
    }

    var body: some View {
        VStack(spacing: 0) {
            DAScreenHeader(title: "Dark Renown", onBack: { store.screen = .menu },
                           trailing: AnyView(DACurrencyPill(kind: .renown, value: store.profile.renown)))

            if let msg = message {
                Text(msg)
                    .font(DATheme.ui(12, .semibold))
                    .foregroundColor(DATheme.goldCoin)
                    .padding(.top, 6)
            } else {
                Text("Renown is earned by repelling raids. Spend it on permanent power.")
                    .font(DATheme.ui(12, .medium))
                    .foregroundColor(DATheme.boneFaint)
                    .padding(.top, 6)
                    .padding(.horizontal, 18)
                    .multilineTextAlignment(.center)
            }

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    ForEach(branches, id: \.0) { branch in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(branch.0.uppercased())
                                .font(DATheme.ui(11, .heavy))
                                .foregroundColor(DATheme.boneFaint)
                            ForEach(branch.1) { node in
                                nodeRow(node)
                            }
                        }
                    }
                    Spacer(minLength: 24)
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }

    @ViewBuilder
    private func nodeRow(_ node: UnlockNode) -> some View {
        let st = store.nodeState(node)
        let affordable = store.profile.renown >= node.cost

        Button(action: {
            guard !st.owned else { return }
            guard st.available else {
                flash("First seal: \(node.requires.compactMap { UnlockTree.node($0)?.title }.joined(separator: ", ")).")
                return
            }
            if store.buyNode(node) {
                SoundBox.shared.play(.unlock)
                Haptics.success()
                flash("Pact sealed: \(node.title).")
            } else {
                SoundBox.shared.play(.erase)
                flash("Not enough Dark Renown (\(node.cost) needed).")
            }
        }) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(st.owned ? Color(daHex: 0x4A2F6B) : DATheme.voidShade)
                        .frame(width: 42, height: 42)
                    Circle()
                        .stroke(st.owned ? Color(daHex: 0xB58BE8) : (st.available ? DATheme.plumLight : DATheme.plumDeep), lineWidth: 1.5)
                        .frame(width: 42, height: 42)
                    if st.owned {
                        CheckIcon(size: 18, color: Color(daHex: 0xB58BE8))
                    } else if st.available {
                        RenownIcon(size: 20)
                    } else {
                        LockIcon(size: 16)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(node.title)
                        .font(DATheme.ui(14, .bold))
                        .foregroundColor(st.owned ? Color(daHex: 0xB58BE8) : (st.available ? DATheme.bone : DATheme.boneDim))
                    Text(node.desc)
                        .font(DATheme.ui(11, .medium))
                        .foregroundColor(DATheme.boneDim)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                if !st.owned {
                    HStack(spacing: 4) {
                        RenownIcon(size: 13)
                        Text("\(node.cost)")
                            .font(DATheme.mono(13))
                            .foregroundColor(st.available && affordable ? DATheme.bone : DATheme.boneFaint)
                    }
                    .padding(.horizontal, 9).padding(.vertical, 6)
                    .background(Capsule().fill(DATheme.voidShade.opacity(0.8)))
                }
            }
            .padding(12)
            .daPanel(stroke: st.owned ? Color(daHex: 0xB58BE8).opacity(0.5) : DATheme.plumLight)
        }
        .buttonStyle(DAPressStyle())
    }

    private func flash(_ text: String) {
        message = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            if message == text { message = nil }
        }
    }
}
