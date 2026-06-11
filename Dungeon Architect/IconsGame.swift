import SwiftUI

// MARK: - Game glyphs (heroes, monsters, traps, misc screens)

struct SwordIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        ZStack {
            SwordShape().fill(color)
        }
        .frame(width: size, height: size)
    }
}

struct SwordShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        // Blade
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.midX + w * 0.09, y: r.minY + h * 0.12))
        p.addLine(to: CGPoint(x: r.midX + w * 0.09, y: r.minY + h * 0.62))
        p.addLine(to: CGPoint(x: r.midX - w * 0.09, y: r.minY + h * 0.62))
        p.addLine(to: CGPoint(x: r.midX - w * 0.09, y: r.minY + h * 0.12))
        p.closeSubpath()
        // Guard
        p.addRect(CGRect(x: r.midX - w * 0.26, y: r.minY + h * 0.6, width: w * 0.52, height: h * 0.08))
        // Grip
        p.addRect(CGRect(x: r.midX - w * 0.05, y: r.minY + h * 0.68, width: w * 0.1, height: h * 0.2))
        // Pommel
        p.addEllipse(in: CGRect(x: r.midX - w * 0.08, y: r.minY + h * 0.86, width: w * 0.16, height: h * 0.12))
        return p
    }
}

struct DaggerIcon: View {
    let size: CGFloat
    var color: Color = DATheme.shadowMauve
    var body: some View {
        SwordShape()
            .fill(color)
            .frame(width: size * 0.7, height: size * 0.85)
            .rotationEffect(.degrees(22))
            .frame(width: size, height: size)
    }
}

struct StaffIcon: View {
    let size: CGFloat
    var color: Color = DATheme.frost
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.04)
                .fill(Color(daHex: 0x8A6F4D))
                .frame(width: size * 0.1, height: size * 0.9)
                .rotationEffect(.degrees(12))
            Circle()
                .fill(color)
                .frame(width: size * 0.3, height: size * 0.3)
                .offset(x: size * 0.09, y: -size * 0.34)
            Circle()
                .stroke(color.opacity(0.5), lineWidth: max(1, size * 0.04))
                .frame(width: size * 0.44, height: size * 0.44)
                .offset(x: size * 0.09, y: -size * 0.34)
        }
        .frame(width: size, height: size)
    }
}

struct ChaliceIcon: View {
    let size: CGFloat
    var color: Color = DATheme.goldCoin
    var body: some View {
        VStack(spacing: 0) {
            ChaliceCupShape().fill(color)
                .frame(width: size * 0.7, height: size * 0.45)
            Rectangle().fill(color)
                .frame(width: size * 0.1, height: size * 0.28)
            RoundedRectangle(cornerRadius: size * 0.05).fill(color)
                .frame(width: size * 0.46, height: size * 0.1)
        }
        .frame(width: size, height: size)
    }
}

struct ChaliceCupShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY),
                       control: CGPoint(x: r.maxX - r.width * 0.08, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.minY),
                       control: CGPoint(x: r.minX + r.width * 0.08, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

struct ShieldIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        ZStack {
            ShieldShape().fill(color)
            ShieldShape().stroke(Color.black.opacity(0.25), lineWidth: max(1, size * 0.05))
                .padding(size * 0.14)
        }
        .frame(width: size, height: size)
    }
}

struct ShieldShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.08, y: r.minY + r.height * 0.16))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.14, y: r.minY + r.height * 0.6))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.maxY),
                       control: CGPoint(x: r.maxX - r.width * 0.22, y: r.maxY - r.height * 0.12))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.14, y: r.minY + r.height * 0.6),
                       control: CGPoint(x: r.minX + r.width * 0.22, y: r.maxY - r.height * 0.12))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.08, y: r.minY + r.height * 0.16))
        p.closeSubpath()
        return p
    }
}

struct BowArrowIcon: View {
    let size: CGFloat
    var color: Color = DATheme.sicklyDeep
    var body: some View {
        ZStack {
            BowShape().stroke(color, style: StrokeStyle(lineWidth: max(1.5, size * 0.08), lineCap: .round))
            ArrowShape().stroke(DATheme.bone, style: StrokeStyle(lineWidth: max(1.5, size * 0.07), lineCap: .round))
        }
        .frame(width: size, height: size)
    }
}

struct BowShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY + r.height * 0.1))
        p.addQuadCurve(to: CGPoint(x: r.minX + r.width * 0.2, y: r.maxY - r.height * 0.1),
                       control: CGPoint(x: r.maxX - r.width * 0.05, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.2, y: r.minY + r.height * 0.1))
        return p
    }
}

struct ArrowShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.05, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.18, y: r.midY))
        p.move(to: CGPoint(x: r.maxX - r.width * 0.32, y: r.midY - r.height * 0.1))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.18, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.32, y: r.midY + r.height * 0.1))
        return p
    }
}

/// Per-class hero glyph.
struct HeroClassIcon: View {
    let cls: HeroClass
    let size: CGFloat
    var body: some View {
        switch cls {
        case .warrior: SwordIcon(size: size, color: DATheme.blood)
        case .rogue: DaggerIcon(size: size)
        case .mage: StaffIcon(size: size)
        case .cleric: ChaliceIcon(size: size)
        case .paladin: ShieldIcon(size: size)
        case .ranger: BowArrowIcon(size: size)
        }
    }
}

/// Monster fang-maw glyph (tinted per family elsewhere).
struct FangIcon: View {
    let size: CGFloat
    var color: Color = DATheme.sickly
    var body: some View {
        FangShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

struct FangShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        // Upper jaw arc with 3 fangs
        p.move(to: CGPoint(x: r.minX, y: r.minY + h * 0.25))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY + h * 0.25),
                       control: CGPoint(x: r.midX, y: r.minY - h * 0.1))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.12, y: r.minY + h * 0.55))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.28, y: r.minY + h * 0.38))
        p.addLine(to: CGPoint(x: r.midX + w * 0.08, y: r.minY + h * 0.72))
        p.addLine(to: CGPoint(x: r.midX - w * 0.08, y: r.minY + h * 0.4))
        p.addLine(to: CGPoint(x: r.minX + w * 0.24, y: r.minY + h * 0.62))
        p.addLine(to: CGPoint(x: r.minX + w * 0.1, y: r.minY + h * 0.42))
        p.closeSubpath()
        // Lower fang
        p.move(to: CGPoint(x: r.midX - w * 0.18, y: r.maxY - h * 0.06))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - h * 0.34))
        p.addLine(to: CGPoint(x: r.midX + w * 0.18, y: r.maxY - h * 0.06))
        p.closeSubpath()
        return p
    }
}

/// Spike strip glyph for traps.
struct SpikesIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        SpikesShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

struct SpikesShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let n = 4
        let w = r.width / CGFloat(n)
        for i in 0..<n {
            let x0 = r.minX + CGFloat(i) * w
            p.move(to: CGPoint(x: x0, y: r.maxY - r.height * 0.12))
            p.addLine(to: CGPoint(x: x0 + w / 2, y: r.minY + r.height * 0.12))
            p.addLine(to: CGPoint(x: x0 + w, y: r.maxY - r.height * 0.12))
            p.closeSubpath()
        }
        return p
    }
}

struct BookIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.08)
                .fill(color)
                .frame(width: size * 0.78, height: size * 0.9)
            Rectangle()
                .fill(DATheme.voidShade.opacity(0.7))
                .frame(width: size * 0.1, height: size * 0.9)
                .offset(x: -size * 0.28)
            VStack(spacing: size * 0.1) {
                Rectangle().fill(DATheme.voidShade.opacity(0.5)).frame(width: size * 0.4, height: size * 0.05)
                Rectangle().fill(DATheme.voidShade.opacity(0.5)).frame(width: size * 0.4, height: size * 0.05)
                Rectangle().fill(DATheme.voidShade.opacity(0.5)).frame(width: size * 0.26, height: size * 0.05)
            }
            .offset(x: size * 0.05)
        }
        .frame(width: size, height: size)
    }
}

struct TrophyIcon: View {
    let size: CGFloat
    var color: Color = DATheme.goldCoin
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                ChaliceCupShape().fill(color)
                    .frame(width: size * 0.6, height: size * 0.46)
                HStack {
                    ArcShape().stroke(color, lineWidth: max(1.5, size * 0.07))
                        .frame(width: size * 0.2, height: size * 0.26)
                        .rotationEffect(.degrees(-90))
                        .offset(x: -size * 0.36)
                    ArcShape().stroke(color, lineWidth: max(1.5, size * 0.07))
                        .frame(width: size * 0.2, height: size * 0.26)
                        .rotationEffect(.degrees(90))
                        .offset(x: size * 0.36)
                }
            }
            Rectangle().fill(color).frame(width: size * 0.1, height: size * 0.2)
            RoundedRectangle(cornerRadius: size * 0.04).fill(color)
                .frame(width: size * 0.42, height: size * 0.1)
        }
        .frame(width: size, height: size)
    }
}

struct WaveCrestIcon: View {
    let size: CGFloat
    var color: Color = DATheme.ember
    var body: some View {
        WaveCrestShape()
            .stroke(color, style: StrokeStyle(lineWidth: max(2, size * 0.1), lineCap: .round))
            .frame(width: size, height: size)
    }
}

struct WaveCrestShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let h3 = r.height / 3.4
        for row in 0..<3 {
            let y = r.minY + CGFloat(row) * h3 + r.height * 0.16
            p.move(to: CGPoint(x: r.minX + r.width * 0.06, y: y))
            p.addQuadCurve(to: CGPoint(x: r.midX, y: y),
                           control: CGPoint(x: r.minX + r.width * 0.28, y: y - r.height * 0.16))
            p.addQuadCurve(to: CGPoint(x: r.maxX - r.width * 0.06, y: y),
                           control: CGPoint(x: r.midX + r.width * 0.22, y: y - r.height * 0.16))
        }
        return p
    }
}

/// Direction arrow used for hero intent on the raid board.
struct IntentArrowShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.15, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.25, y: r.midY))
        p.move(to: CGPoint(x: r.maxX - r.width * 0.45, y: r.minY + r.height * 0.28))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.22, y: r.midY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.45, y: r.maxY - r.height * 0.28))
        return p
    }
}

struct SpeakerIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var on: Bool = true
    var body: some View {
        ZStack {
            SpeakerBodyShape().fill(color)
            if on {
                ArcShape().stroke(color, lineWidth: max(1.5, size * 0.08))
                    .frame(width: size * 0.22, height: size * 0.3)
                    .rotationEffect(.degrees(90))
                    .offset(x: size * 0.3)
            } else {
                CrossShape().stroke(DATheme.blood, style: StrokeStyle(lineWidth: max(1.5, size * 0.1), lineCap: .round))
                    .frame(width: size * 0.3, height: size * 0.3)
                    .offset(x: size * 0.28)
            }
        }
        .frame(width: size, height: size)
    }
}

struct SpeakerBodyShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.08, y: r.midY - h * 0.16))
        p.addLine(to: CGPoint(x: r.minX + w * 0.3, y: r.midY - h * 0.16))
        p.addLine(to: CGPoint(x: r.minX + w * 0.55, y: r.midY - h * 0.4))
        p.addLine(to: CGPoint(x: r.minX + w * 0.55, y: r.midY + h * 0.4))
        p.addLine(to: CGPoint(x: r.minX + w * 0.3, y: r.midY + h * 0.16))
        p.addLine(to: CGPoint(x: r.minX + w * 0.08, y: r.midY + h * 0.16))
        p.closeSubpath()
        return p
    }
}

struct HandIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.1)
                .fill(color)
                .frame(width: size * 0.34, height: size * 0.6)
                .offset(y: size * 0.14)
            Capsule().fill(color)
                .frame(width: size * 0.14, height: size * 0.5)
                .offset(x: 0, y: -size * 0.18)
        }
        .frame(width: size, height: size)
    }
}
