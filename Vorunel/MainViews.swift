import SwiftUI

// MARK: - Root router

struct RootView: View {
    @StateObject private var store = GameStore()

    var body: some View {
        ZStack {
            DATheme.obsidian.edgesIgnoringSafeArea(.all)

            switch store.screen {
            case .menu: MainMenuView()
            case .campaign: CampaignMapView()
            case .briefing(let id): BriefingView(scenarioID: id)
            case .editor: EditorView()
            case .raid: RaidView()
            case .result: RaidResultView()
            case .unlocks: UnlocksView()
            case .endless: EndlessHubView()
            case .codex: CodexView()
            case .achievements: AchievementsView()
            case .settings: SettingsView()
            case .onboarding: OnboardingView()
            }
        }
        .environmentObject(store)
    }
}

// MARK: - Main menu

struct MainMenuView: View {
    @EnvironmentObject var store: GameStore
    @State private var glow = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RadialGradient(colors: [DATheme.plumDeep, DATheme.obsidian],
                               center: .top, startRadius: 60, endRadius: geo.size.height)
                    .edgesIgnoringSafeArea(.all)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        HStack {
                            DACurrencyPill(kind: .gold, value: store.profile.gold)
                            DACurrencyPill(kind: .renown, value: store.profile.renown)
                            Spacer()
                        }
                        .padding(.top, 8)

                        VStack(spacing: 10) {
                            HeartCrystalIcon(size: 76, color: DATheme.blood)
                                .shadow(color: DATheme.blood.opacity(glow ? 0.7 : 0.25), radius: glow ? 24 : 8)
                                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glow)
                                .onAppear { glow = true }
                            Text("Vorunel")
                                .font(DATheme.display(min(34, geo.size.width * 0.085)))
                                .foregroundColor(DATheme.bone)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                            Text("They bring swords. You bring the floor plan.")
                                .font(DATheme.ui(13, .medium))
                                .foregroundColor(DATheme.boneDim)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 6)

                        if store.raidSnapshotExists {
                            menuRow(title: "Resume Raid", subtitle: "A battle waits, frozen mid-tick",
                                    tint: DATheme.ember, badge: AnyView(PlayIcon(size: 22, color: DATheme.ember))) {
                                store.resumeSavedRaid()
                            }
                        }

                        menuRow(title: "Campaign", subtitle: campaignSubtitle,
                                tint: DATheme.emberDeep, badge: AnyView(SkullBannerIcon(size: 30))) {
                            store.screen = .campaign
                        }
                        menuRow(title: "Endless Siege", subtitle: endlessSubtitle,
                                tint: DATheme.blood, badge: AnyView(WaveCrestIcon(size: 26))) {
                            store.screen = .endless
                        }
                        menuRow(title: "My Dungeon", subtitle: "Dig, garrison, and rig the halls",
                                tint: DATheme.plumLight, badge: AnyView(PickaxeIcon(size: 28))) {
                            store.pendingContext = nil
                            store.screen = .editor
                        }
                        menuRow(title: "Dark Renown", subtitle: "\(store.profile.unlocked.count)/\(UnlockTree.nodes.count) pacts sealed",
                                tint: Color(daHex: 0x7E5CA8), badge: AnyView(RenownIcon(size: 26))) {
                            store.screen = .unlocks
                        }

                        HStack(spacing: 12) {
                            smallRow(title: "Codex", badge: AnyView(BookIcon(size: 24))) {
                                store.screen = .codex
                            }
                            smallRow(title: "Feats", badge: AnyView(TrophyIcon(size: 24))) {
                                store.screen = .achievements
                            }
                            smallRow(title: "Settings", badge: AnyView(TrapGearIcon(size: 24, color: DATheme.boneDim))) {
                                store.screen = .settings
                            }
                        }

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal, 20)
                    .frame(maxWidth: 560)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private var campaignSubtitle: String {
        let cleared = CampaignBook.scenarios.filter { store.stars(for: $0.id) >= 1 }.count
        return "\(cleared)/30 raids repelled • \(store.totalStars) stars"
    }

    private var endlessSubtitle: String {
        store.profile.endlessBest > 0
            ? "Best stand: wave \(store.profile.endlessBest)"
            : "How long can the Heart beat?"
    }

    private func menuRow(title: String, subtitle: String, tint: Color, badge: AnyView, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundBox.shared.play(.uiTap)
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(tint.opacity(0.18))
                        .frame(width: 52, height: 52)
                    badge
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(DATheme.head(18))
                        .foregroundColor(DATheme.bone)
                    Text(subtitle)
                        .font(DATheme.ui(12, .medium))
                        .foregroundColor(DATheme.boneDim)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                ChevronIcon(size: 14, color: DATheme.boneFaint)
            }
            .padding(14)
            .daPanel()
        }
        .buttonStyle(DAPressStyle())
    }

    private func smallRow(title: String, badge: AnyView, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundBox.shared.play(.uiTap)
            Haptics.tap()
            action()
        }) {
            VStack(spacing: 8) {
                badge
                Text(title)
                    .font(DATheme.ui(12))
                    .foregroundColor(DATheme.boneDim)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .daPanel()
        }
        .buttonStyle(DAPressStyle())
    }
}

// MARK: - Shared header used by sub-screens

struct DAScreenHeader: View {
    let title: String
    var backLabel: String = "Back"
    let onBack: () -> Void
    var trailing: AnyView? = nil

    var body: some View {
        HStack {
            DABackButton(label: backLabel, action: onBack)
            Spacer()
            Text(title)
                .font(DATheme.head(19))
                .foregroundColor(DATheme.bone)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer()
            if let t = trailing {
                t
            } else {
                // Balance the back button width
                DABackButton(label: backLabel, action: {}).opacity(0).disabled(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
