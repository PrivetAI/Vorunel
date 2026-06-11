import SwiftUI

// MARK: - Core UI icons (all custom Shapes — no SF Symbols, no emoji)

enum ChevronDirection { case left, right, up, down }

struct ChevronIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var direction: ChevronDirection = .right

    var body: some View {
        ChevronShape(direction: direction)
            .stroke(color, style: StrokeStyle(lineWidth: max(2, size * 0.16), lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

struct ChevronShape: Shape {
    let direction: ChevronDirection
    func path(in r: CGRect) -> Path {
        var p = Path()
        switch direction {
        case .right:
            p.move(to: CGPoint(x: r.minX + r.width * 0.3, y: r.minY + r.height * 0.15))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.72, y: r.midY))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.3, y: r.maxY - r.height * 0.15))
        case .left:
            p.move(to: CGPoint(x: r.maxX - r.width * 0.3, y: r.minY + r.height * 0.15))
            p.addLine(to: CGPoint(x: r.minX + r.width * 0.28, y: r.midY))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.3, y: r.maxY - r.height * 0.15))
        case .up:
            p.move(to: CGPoint(x: r.minX + r.width * 0.15, y: r.maxY - r.height * 0.3))
            p.addLine(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.28))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.15, y: r.maxY - r.height * 0.3))
        case .down:
            p.move(to: CGPoint(x: r.minX + r.width * 0.15, y: r.minY + r.height * 0.3))
            p.addLine(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.28))
            p.addLine(to: CGPoint(x: r.maxX - r.width * 0.15, y: r.minY + r.height * 0.3))
        }
        return p
    }
}

struct CoinIcon: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle().fill(DATheme.goldCoin)
            Circle().stroke(Color(daHex: 0x9A7420), lineWidth: max(1, size * 0.1))
                .padding(size * 0.16)
            Rectangle().fill(Color(daHex: 0x9A7420))
                .frame(width: size * 0.12, height: size * 0.34)
        }
        .frame(width: size, height: size)
    }
}

/// Dark Renown: a horned crown.
struct RenownIcon: View {
    let size: CGFloat
    var color: Color = Color(daHex: 0xB58BE8)
    var body: some View {
        HornedCrownShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

struct HornedCrownShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.minX + w * 0.1, y: r.maxY - h * 0.12))
        p.addLine(to: CGPoint(x: r.minX + w * 0.06, y: r.minY + h * 0.18))
        p.addLine(to: CGPoint(x: r.minX + w * 0.3, y: r.minY + h * 0.52))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY + h * 0.08))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.3, y: r.minY + h * 0.52))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.06, y: r.minY + h * 0.18))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.1, y: r.maxY - h * 0.12))
        p.closeSubpath()
        return p
    }
}

struct StarShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let outer = min(r.width, r.height) / 2
        let inner = outer * 0.42
        for i in 0..<10 {
            let angle = (Double(i) * .pi / 5.0) - .pi / 2.0
            let radius = i % 2 == 0 ? outer : inner
            let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * radius, y: c.y + CGFloat(sin(angle)) * radius)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

struct StarIcon: View {
    let size: CGFloat
    var filled: Bool = true
    var body: some View {
        ZStack {
            if filled {
                StarShape().fill(DATheme.goldCoin)
                StarShape().stroke(Color(daHex: 0x9A7420), lineWidth: 1)
            } else {
                StarShape().stroke(DATheme.boneFaint, lineWidth: max(1, size * 0.07))
            }
        }
        .frame(width: size, height: size)
    }
}

struct LockIcon: View {
    let size: CGFloat
    var color: Color = DATheme.boneDim
    var body: some View {
        VStack(spacing: 0) {
            ArcShape()
                .stroke(color, lineWidth: max(1.5, size * 0.12))
                .frame(width: size * 0.55, height: size * 0.4)
            RoundedRectangle(cornerRadius: size * 0.12)
                .fill(color)
                .frame(width: size * 0.8, height: size * 0.55)
        }
        .frame(width: size, height: size)
    }
}

struct ArcShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.midX, y: r.maxY),
                 radius: min(r.width / 2, r.height) * 0.85,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return p
    }
}

struct CheckIcon: View {
    let size: CGFloat
    var color: Color = DATheme.sickly
    var body: some View {
        CheckShape()
            .stroke(color, style: StrokeStyle(lineWidth: max(2, size * 0.16), lineCap: .round, lineJoin: .round))
            .frame(width: size, height: size)
    }
}

struct CheckShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.16, y: r.midY + r.height * 0.06))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.42, y: r.maxY - r.height * 0.2))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.12, y: r.minY + r.height * 0.2))
        return p
    }
}

struct CrossIcon: View {
    let size: CGFloat
    var color: Color = DATheme.blood
    var body: some View {
        CrossShape()
            .stroke(color, style: StrokeStyle(lineWidth: max(2, size * 0.16), lineCap: .round))
            .frame(width: size, height: size)
    }
}

struct CrossShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let inset = min(r.width, r.height) * 0.2
        p.move(to: CGPoint(x: r.minX + inset, y: r.minY + inset))
        p.addLine(to: CGPoint(x: r.maxX - inset, y: r.maxY - inset))
        p.move(to: CGPoint(x: r.maxX - inset, y: r.minY + inset))
        p.addLine(to: CGPoint(x: r.minX + inset, y: r.maxY - inset))
        return p
    }
}

struct PlayIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        TriangleShape()
            .fill(color)
            .frame(width: size, height: size)
    }
}

struct TriangleShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.22, y: r.minY + r.height * 0.1))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.12, y: r.midY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.22, y: r.maxY - r.height * 0.1))
        p.closeSubpath()
        return p
    }
}

struct PauseIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        HStack(spacing: size * 0.18) {
            RoundedRectangle(cornerRadius: size * 0.08).fill(color)
                .frame(width: size * 0.26, height: size * 0.8)
            RoundedRectangle(cornerRadius: size * 0.08).fill(color)
                .frame(width: size * 0.26, height: size * 0.8)
        }
        .frame(width: size, height: size)
    }
}

/// Toothed gear — the trap glyph and settings glyph.
struct GearShape: Shape {
    var teeth: Int = 8
    func path(in r: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: r.midX, y: r.midY)
        let outer = min(r.width, r.height) / 2
        let inner = outer * 0.72
        let steps = teeth * 4
        for i in 0...steps {
            let a = Double(i) / Double(steps) * 2 * .pi - .pi / 2
            let phase = i % 4
            let radius = (phase == 0 || phase == 3) ? inner : outer
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * radius, y: c.y + CGFloat(sin(a)) * radius)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        let hole = outer * 0.3
        p.addEllipse(in: CGRect(x: c.x - hole, y: c.y - hole, width: hole * 2, height: hole * 2))
        return p
    }
}

struct TrapGearIcon: View {
    let size: CGFloat
    var color: Color = DATheme.ember
    var body: some View {
        GearShape()
            .fill(color, style: FillStyle(eoFill: true))
            .frame(width: size, height: size)
    }
}

/// The Dungeon Heart: a faceted heart-crystal.
struct HeartCrystalShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        p.move(to: CGPoint(x: r.midX, y: r.minY + h * 0.06))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.12, y: r.minY + h * 0.3))
        p.addLine(to: CGPoint(x: r.maxX - w * 0.2, y: r.minY + h * 0.62))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - h * 0.04))
        p.addLine(to: CGPoint(x: r.minX + w * 0.2, y: r.minY + h * 0.62))
        p.addLine(to: CGPoint(x: r.minX + w * 0.12, y: r.minY + h * 0.3))
        p.closeSubpath()
        return p
    }
}

struct HeartCrystalIcon: View {
    let size: CGFloat
    var color: Color = DATheme.blood
    var body: some View {
        ZStack {
            HeartCrystalShape().fill(color)
            HeartCrystalShape().stroke(Color.white.opacity(0.35), lineWidth: max(1, size * 0.05))
            // Facet lines
            FacetShape().stroke(Color.white.opacity(0.25), lineWidth: max(1, size * 0.04))
        }
        .frame(width: size, height: size)
    }
}

struct FacetShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.06))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY - r.height * 0.04))
        p.move(to: CGPoint(x: r.minX + r.width * 0.12, y: r.minY + r.height * 0.3))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY + r.height * 0.45))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.12, y: r.minY + r.height * 0.3))
        return p
    }
}

/// Crossed pickaxe — the editor / dig glyph.
struct PickaxeIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        ZStack {
            // Handle
            RoundedRectangle(cornerRadius: size * 0.05)
                .fill(Color(daHex: 0x8A6F4D))
                .frame(width: size * 0.13, height: size * 0.85)
                .rotationEffect(.degrees(45))
            // Head
            PickHeadShape()
                .fill(color)
                .frame(width: size * 0.9, height: size * 0.5)
                .rotationEffect(.degrees(45))
                .offset(x: size * 0.14, y: -size * 0.14)
        }
        .frame(width: size, height: size)
    }
}

struct PickHeadShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.minY - r.height * 0.6))
        p.addQuadCurve(to: CGPoint(x: r.minX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.minY + r.height * 0.35))
        p.closeSubpath()
        return p
    }
}

/// Skull — monsters / kills glyph.
struct SkullShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        let w = r.width, h = r.height
        // Cranium
        p.addEllipse(in: CGRect(x: r.minX + w * 0.08, y: r.minY, width: w * 0.84, height: h * 0.72))
        // Jaw
        p.addRect(CGRect(x: r.minX + w * 0.26, y: r.minY + h * 0.55, width: w * 0.48, height: h * 0.36))
        return p
    }
}

struct SkullIcon: View {
    let size: CGFloat
    var color: Color = DATheme.bone
    var body: some View {
        ZStack {
            SkullShape().fill(color)
            // Eyes
            HStack(spacing: size * 0.14) {
                Ellipse().fill(DATheme.voidShade).frame(width: size * 0.2, height: size * 0.24)
                Ellipse().fill(DATheme.voidShade).frame(width: size * 0.2, height: size * 0.24)
            }
            .offset(y: -size * 0.08)
            // Teeth gaps
            HStack(spacing: size * 0.07) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle().fill(color == DATheme.voidShade ? DATheme.bone : DATheme.voidShade)
                        .frame(width: size * 0.04, height: size * 0.14)
                }
            }
            .offset(y: size * 0.34)
        }
        .frame(width: size, height: size)
    }
}

/// Skull banner — campaign glyph.
struct SkullBannerIcon: View {
    let size: CGFloat
    var bannerColor: Color = DATheme.emberDeep
    var body: some View {
        ZStack(alignment: .top) {
            BannerShape()
                .fill(bannerColor)
                .frame(width: size * 0.72, height: size * 0.95)
            BannerShape()
                .stroke(Color.white.opacity(0.25), lineWidth: max(1, size * 0.04))
                .frame(width: size * 0.72, height: size * 0.95)
            SkullIcon(size: size * 0.4)
                .offset(y: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

struct BannerShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY - r.height * 0.18))
        p.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - r.height * 0.18))
        p.closeSubpath()
        return p
    }
}
