import SwiftUI
import Combine

/// Drives the fixed-step tick loop. Pausing invalidates the timer, freezing
/// every system (movement, cooldowns, statuses live inside RaidEngine.step).
/// Speed only changes the wall-clock interval — never skips logic.
final class RaidRunner: ObservableObject {
    @Published var state: RaidState? = nil
    @Published var paused: Bool = false
    @Published var speed: Int = 1   // 1 / 2 / 4

    private var timer: Timer? = nil
    private var finished = false
    var onFinish: ((RaidState) -> Void)? = nil

    private let baseInterval = 0.55

    var isConfigured: Bool { state != nil }

    func configure(_ s: RaidState) {
        guard state == nil else { return }
        state = s
        finished = s.phase != .running
        paused = false
        restartTimer()
    }

    func setPaused(_ p: Bool) {
        paused = p
        restartTimer()
    }

    func setSpeed(_ s: Int) {
        speed = s
        restartTimer()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func restartTimer() {
        stop()
        guard !paused, !finished, let st = state, st.phase == .running else { return }
        let interval = baseInterval / Double(speed)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    private func tick() {
        guard var s = state, s.phase == .running, !finished else {
            stop()
            return
        }
        RaidEngine.step(&s)
        state = s
        if s.phase != .running {
            finished = true
            stop()
            onFinish?(s)
        }
    }

    deinit { timer?.invalidate() }
}

// MARK: - Raid view

struct RaidView: View {
    @EnvironmentObject var store: GameStore
    @StateObject private var runner = RaidRunner()
    @Environment(\.scenePhase) private var scenePhase
    @State private var showAbandon = false
    @State private var wrappingUp = false

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > geo.size.height
            Group {
                if let state = runner.state {
                    if isWide {
                        HStack(spacing: 0) {
                            DungeonBoardView(dungeon: state.dungeon, raid: state)
                                .padding(6)
                                .frame(width: geo.size.width * 0.5)
                            VStack(spacing: 8) {
                                hud(state)
                                controls
                                logPanel(state)
                            }
                            .padding(.trailing, 10)
                        }
                    } else {
                        VStack(spacing: 6) {
                            hud(state)
                            DungeonBoardView(dungeon: state.dungeon, raid: state)
                                .padding(.horizontal, 6)
                            controls
                            logPanel(state)
                                .frame(height: max(96, geo.size.height * 0.17))
                                .padding(.horizontal, 10)
                                .padding(.bottom, 8)
                        }
                    }
                } else {
                    Color.clear
                }
            }
        }
        .onAppear {
            if let s = store.activeRaid, !runner.isConfigured {
                runner.onFinish = { final in
                    wrappingUp = true
                    if final.phase == .won {
                        SoundBox.shared.play(.win)
                        Haptics.success()
                    } else {
                        SoundBox.shared.play(.lose)
                        Haptics.failure()
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        store.activeRaid = final
                        store.finishRaid(final)
                    }
                }
                runner.configure(s)
                // A snapshot resumed mid-battle comes back frozen so the
                // keeper can reorient before unpausing.
                if s.tick > 0 { runner.setPaused(true) }
            }
        }
        .onChange(of: scenePhase) { phase in
            // Stamp/save ONLY on .background — .inactive fires on the way in AND out.
            if phase == .background, let s = runner.state, s.phase == .running {
                runner.setPaused(true)
                store.saveRaidSnapshot(s)
            }
        }
        .alert(isPresented: $showAbandon) {
            Alert(title: Text("Collapse the tunnels?"),
                  message: Text("Abandoning counts as a defeat. The raiders pick your halls clean."),
                  primaryButton: .destructive(Text("Abandon")) {
                      runner.stop()
                      if let s = runner.state {
                          store.activeRaid = s
                          store.abandonRaid()
                      }
                  },
                  secondaryButton: .cancel(Text("Keep Fighting")) )
        }
    }

    // MARK: - HUD

    private func hud(_ state: RaidState) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text(raidTitle(state))
                    .font(DATheme.head(15))
                    .foregroundColor(DATheme.bone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                Text("Tick \(state.tick)")
                    .font(DATheme.mono(11))
                    .foregroundColor(DATheme.boneFaint)
            }
            HStack(spacing: 10) {
                // Heart bar
                HStack(spacing: 6) {
                    HeartCrystalIcon(size: 18)
                    GeometryReader { g in
                        ZStack(alignment: .leading) {
                            Capsule().fill(DATheme.voidShade)
                            Capsule().fill(DATheme.blood)
                                .frame(width: g.size.width * CGFloat(max(0, state.heartHP / max(1, state.heartMaxHP))))
                        }
                    }
                    .frame(height: 10)
                    Text("\(Int(max(0, state.heartHP)))")
                        .font(DATheme.mono(11))
                        .foregroundColor(DATheme.bone)
                }
                .frame(maxWidth: .infinity)

                HStack(spacing: 4) {
                    HeroClassIcon(cls: .warrior, size: 13)
                    Text("\(state.heroes.filter { $0.isActive }.count)")
                        .font(DATheme.mono(11)).foregroundColor(DATheme.bone)
                }
                HStack(spacing: 4) {
                    FangIcon(size: 13)
                    Text("\(state.monsters.filter { $0.hp > 0 }.count)")
                        .font(DATheme.mono(11)).foregroundColor(DATheme.bone)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
    }

    private func raidTitle(_ state: RaidState) -> String {
        switch state.context {
        case .campaign(let id): return "Raid \(id): \(CampaignBook.scenario(id).title)"
        case .endless(let w): return "Endless Siege — Wave \(w)"
        }
    }

    // MARK: - Controls

    private var controls: some View {
        HStack(spacing: 8) {
            Button(action: {
                SoundBox.shared.play(.uiTap)
                Haptics.tap()
                runner.setPaused(!runner.paused)
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(runner.paused ? DATheme.ember : DATheme.plumDeep)
                        .frame(width: 46, height: 38)
                    if runner.paused {
                        PlayIcon(size: 18, color: DATheme.voidShade)
                    } else {
                        PauseIcon(size: 18)
                    }
                }
            }
            .buttonStyle(DAPressStyle())

            ForEach([1, 2, 4], id: \.self) { s in
                Button(action: {
                    SoundBox.shared.play(.uiTap)
                    runner.setSpeed(s)
                }) {
                    Text("\(s)x")
                        .font(DATheme.mono(13))
                        .foregroundColor(runner.speed == s ? DATheme.voidShade : DATheme.boneDim)
                        .frame(width: 42, height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(runner.speed == s ? DATheme.sickly : DATheme.plumDeep)
                        )
                }
                .buttonStyle(DAPressStyle())
            }

            Spacer()

            if wrappingUp {
                Text("Raid over...")
                    .font(DATheme.ui(12, .bold))
                    .foregroundColor(DATheme.goldCoin)
            } else {
                Button(action: {
                    Haptics.tap()
                    runner.setPaused(true)
                    showAbandon = true
                }) {
                    Text("Abandon")
                        .font(DATheme.ui(12, .bold))
                        .foregroundColor(DATheme.blood)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(DATheme.blood.opacity(0.6), lineWidth: 1)
                        )
                }
                .buttonStyle(DAPressStyle())
            }
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Combat log

    private func logPanel(_ state: RaidState) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 3) {
                ForEach(state.log.suffix(40).reversed()) { entry in
                    HStack(alignment: .top, spacing: 6) {
                        Text("\(entry.tick)")
                            .font(DATheme.mono(9))
                            .foregroundColor(DATheme.boneFaint)
                            .frame(width: 30, alignment: .trailing)
                        Text(entry.text)
                            .font(DATheme.ui(11, .medium))
                            .foregroundColor(entry.tone.color)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(DATheme.voidShade.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(DATheme.plumLight.opacity(0.5), lineWidth: 1)
        )
    }
}
