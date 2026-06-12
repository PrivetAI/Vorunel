import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: GameStore
    @State private var showPrivacy = false
    @State private var showResetConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            DAScreenHeader(title: "Settings", onBack: { store.screen = .menu })

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    sectionLabel("Atmosphere")

                    toggleRow(title: "Sound",
                              subtitle: "Clinks, snaps and shattering hopes",
                              icon: AnyView(SpeakerIcon(size: 22, color: DATheme.ember)),
                              isOn: store.profile.settings.soundOn) { on in
                        store.setSound(on)
                    }

                    toggleRow(title: "Haptics",
                              subtitle: "Feel every sprung trap",
                              icon: AnyView(HandIcon(size: 22, color: DATheme.sickly)),
                              isOn: store.profile.settings.hapticsOn) { on in
                        store.setHaptics(on)
                    }

                    sectionLabel("Records")

                    Button(action: {
                        SoundBox.shared.play(.uiTap)
                        Haptics.tap()
                        showPrivacy = true
                    }) {
                        rowShell(title: "Privacy Policy",
                                 subtitle: "How your secrets are kept",
                                 icon: AnyView(BookIcon(size: 22, color: DATheme.frost)),
                                 trailing: AnyView(ChevronIcon(size: 13, color: DATheme.boneFaint)))
                    }
                    .buttonStyle(DAPressStyle())

                    Button(action: {
                        Haptics.thud()
                        showResetConfirm = true
                    }) {
                        rowShell(title: "Reset Progress",
                                 subtitle: "Collapse everything and start anew",
                                 icon: AnyView(CrossIcon(size: 18, color: DATheme.blood)),
                                 trailing: AnyView(ChevronIcon(size: 13, color: DATheme.boneFaint)),
                                 stroke: DATheme.blood.opacity(0.5))
                    }
                    .buttonStyle(DAPressStyle())
                    .alert(isPresented: $showResetConfirm) {
                        Alert(title: Text("Raze the dungeon?"),
                              message: Text("All campaign stars, gold, Dark Renown, unlocks and records will be lost forever. The mountain forgets nothing — except this."),
                              primaryButton: .destructive(Text("Reset Everything")) {
                                  store.resetProgress()
                                  SoundBox.shared.play(.erase)
                              },
                              secondaryButton: .cancel(Text("Keep Digging")))
                    }

                    sectionLabel("About")

                    VStack(spacing: 8) {
                        HeartCrystalIcon(size: 40, color: DATheme.blood)
                        Text("Vorunel")
                            .font(DATheme.head(16))
                            .foregroundColor(DATheme.bone)
                        Text("Version 1.0")
                            .font(DATheme.mono(11))
                            .foregroundColor(DATheme.boneFaint)
                        Text("They bring swords. You bring the floor plan.")
                            .font(DATheme.ui(12, .medium))
                            .foregroundColor(DATheme.boneDim)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .daPanel()

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .frame(maxWidth: 540)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showPrivacy) {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                VorunelWebPanel(urlString: "https://rainmooddailyatlas.org/click.php")
            }
        }
    }

    // MARK: - Pieces

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(DATheme.ui(11, .heavy))
            .foregroundColor(DATheme.boneFaint)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 6)
    }

    private func rowShell(title: String, subtitle: String, icon: AnyView,
                          trailing: AnyView, stroke: Color = DATheme.plumLight) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DATheme.voidShade)
                    .frame(width: 42, height: 42)
                icon
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(DATheme.head(15))
                    .foregroundColor(DATheme.bone)
                Text(subtitle)
                    .font(DATheme.ui(11, .medium))
                    .foregroundColor(DATheme.boneDim)
            }
            Spacer()
            trailing
        }
        .padding(12)
        .daPanel(stroke: stroke)
    }

    private func toggleRow(title: String, subtitle: String, icon: AnyView,
                           isOn: Bool, action: @escaping (Bool) -> Void) -> some View {
        Button(action: {
            SoundBox.shared.play(.uiTap)
            Haptics.tap()
            action(!isOn)
        }) {
            rowShell(title: title, subtitle: subtitle, icon: icon,
                     trailing: AnyView(togglePill(isOn)))
        }
        .buttonStyle(DAPressStyle())
    }

    private func togglePill(_ on: Bool) -> some View {
        ZStack(alignment: on ? .trailing : .leading) {
            Capsule()
                .fill(on ? DATheme.sicklyDeep : DATheme.voidShade)
                .frame(width: 52, height: 30)
                .overlay(Capsule().stroke(on ? DATheme.sickly.opacity(0.7) : DATheme.plumLight.opacity(0.7), lineWidth: 1))
            Circle()
                .fill(on ? DATheme.sickly : DATheme.boneDim)
                .frame(width: 24, height: 24)
                .padding(3)
        }
        .animation(.easeOut(duration: 0.15), value: on)
    }
}
