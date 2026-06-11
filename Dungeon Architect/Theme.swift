import SwiftUI

extension Color {
    init(daHex hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1.0
        )
    }
}

/// Wicked-cozy dungeon keeper palette: deep plum / obsidian, ember orange,
/// sickly green accents and old bone. Forced dark, theme independent.
enum DATheme {
    static let obsidian   = Color(daHex: 0x120D1C)
    static let voidShade  = Color(daHex: 0x0B0713)
    static let plumDeep   = Color(daHex: 0x221636)
    static let plum       = Color(daHex: 0x2D2047)
    static let plumLight  = Color(daHex: 0x3F2D60)
    static let ember      = Color(daHex: 0xFF7B33)
    static let emberDeep  = Color(daHex: 0xC25118)
    static let sickly     = Color(daHex: 0x9ADB4A)
    static let sicklyDeep = Color(daHex: 0x60902B)
    static let bone       = Color(daHex: 0xEDE0C6)
    static let boneDim    = Color(daHex: 0xEDE0C6).opacity(0.55)
    static let boneFaint  = Color(daHex: 0xEDE0C6).opacity(0.28)
    static let blood      = Color(daHex: 0xC8453F)
    static let goldCoin   = Color(daHex: 0xE9B83E)
    static let frost      = Color(daHex: 0x77B7DD)
    static let shadowMauve = Color(daHex: 0x594A78)

    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .serif)
    }
    static func head(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }
    static func ui(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
    static func mono(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

struct DAPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct DAPanelModifier: ViewModifier {
    var fill: Color = DATheme.plumDeep
    var stroke: Color = DATheme.plumLight
    var radius: CGFloat = 14
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(stroke.opacity(0.7), lineWidth: 1)
            )
    }
}

extension View {
    func daPanel(fill: Color = DATheme.plumDeep, stroke: Color = DATheme.plumLight, radius: CGFloat = 14) -> some View {
        modifier(DAPanelModifier(fill: fill, stroke: stroke, radius: radius))
    }
}

/// Primary action button used across the app.
struct DAActionButton: View {
    let title: String
    var tint: Color = DATheme.ember
    var textColor: Color = DATheme.voidShade
    var compact: Bool = false
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: {
            guard enabled else { return }
            SoundBox.shared.play(.uiTap)
            Haptics.tap()
            action()
        }) {
            Text(title)
                .font(DATheme.head(compact ? 14 : 17))
                .foregroundColor(enabled ? textColor : DATheme.boneDim)
                .padding(.vertical, compact ? 8 : 13)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(enabled ? tint : DATheme.plum)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(enabled ? 0.18 : 0.05), lineWidth: 1)
                )
        }
        .buttonStyle(DAPressStyle())
        .disabled(!enabled)
    }
}

/// Small back chevron + label header button.
struct DABackButton: View {
    var label: String = "Back"
    let action: () -> Void
    var body: some View {
        Button(action: {
            SoundBox.shared.play(.uiTap)
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 6) {
                ChevronIcon(size: 14, color: DATheme.bone, direction: .left)
                Text(label)
                    .font(DATheme.ui(15))
                    .foregroundColor(DATheme.bone)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .daPanel(radius: 10)
        }
        .buttonStyle(DAPressStyle())
    }
}

/// Currency pill: coin / renown displays.
struct DACurrencyPill: View {
    enum Kind { case gold, renown }
    let kind: Kind
    let value: Int
    var body: some View {
        HStack(spacing: 5) {
            if kind == .gold {
                CoinIcon(size: 14)
            } else {
                RenownIcon(size: 14)
            }
            Text("\(value)")
                .font(DATheme.mono(13))
                .foregroundColor(DATheme.bone)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .daPanel(fill: DATheme.voidShade.opacity(0.8), radius: 9)
    }
}
