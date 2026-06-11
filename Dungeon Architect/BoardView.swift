import SwiftUI

/// Shared 9x12 dungeon grid renderer for the editor and the live raid.
/// All sizing flows from the parent GeometryReader (never Canvas-internal
/// sizes), is clamped against UIScreen, inscribed with min(), and clipped.
struct DungeonBoardView: View {
    let dungeon: DungeonState
    var raid: RaidState? = nil
    var selected: GridPoint? = nil
    var onTap: ((GridPoint) -> Void)? = nil

    var body: some View {
        GeometryReader { geo in
            let availW = min(geo.size.width, UIScreen.main.bounds.width)
            let availH = min(geo.size.height, UIScreen.main.bounds.height)
            let tile = max(10, min(availW / CGFloat(DungeonState.cols),
                                   availH / CGFloat(DungeonState.rows)))
            let boardW = tile * CGFloat(DungeonState.cols)
            let boardH = tile * CGFloat(DungeonState.rows)

            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(DATheme.voidShade)
                    .frame(width: boardW + 8, height: boardH + 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DATheme.plumLight.opacity(0.6), lineWidth: 1.5)
                    )

                boardContent(tile: tile, boardW: boardW, boardH: boardH)
                    .frame(width: boardW, height: boardH)
                    .clipped()
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
    }

    private func center(_ p: GridPoint, _ tile: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(p.x) + 0.5) * tile, y: (CGFloat(p.y) + 0.5) * tile)
    }

    @ViewBuilder
    private func boardContent(tile: CGFloat, boardW: CGFloat, boardH: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            // Tiles
            ForEach(dungeon.allPoints, id: \.self) { p in
                tileCell(p, tile: tile)
                    .frame(width: tile, height: tile)
                    .position(center(p, tile))
                    .onTapGesture { onTap?(p) }
            }

            // Raid layer
            if let raid = raid {
                // Intent arrows
                ForEach(raid.heroes.filter { $0.onBoard }) { hero in
                    if let next = hero.nextStep, hero.status != .dead {
                        intentArrow(from: hero.pos, toward: next, tile: tile)
                    }
                }
                // Heroes
                let onBoard = raid.heroes.filter { $0.onBoard }
                ForEach(onBoard) { hero in
                    let stack = onBoard.filter { $0.pos == hero.pos }
                    let slot = stack.firstIndex(where: { $0.id == hero.id }) ?? 0
                    heroSprite(hero, tile: tile)
                        .position(heroPoint(hero.pos, slot: slot, of: stack.count, tile: tile))
                }
            }
        }
    }

    private func heroPoint(_ p: GridPoint, slot: Int, of count: Int, tile: CGFloat) -> CGPoint {
        var c = center(p, tile)
        if count > 1 {
            let spread = tile * 0.22
            let angle = Double(slot) / Double(count) * 2 * .pi
            c.x += CGFloat(cos(angle)) * spread
            c.y += CGFloat(sin(angle)) * spread
        }
        return c
    }

    // MARK: - Tile

    @ViewBuilder
    private func tileCell(_ p: GridPoint, tile: CGFloat) -> some View {
        let model = dungeon.tile(at: p)
        let idx = dungeon.index(p)
        let isSelected = selected == p

        ZStack {
            RoundedRectangle(cornerRadius: tile * 0.14, style: .continuous)
                .fill(model.kind.tint)
                .padding(1)
            RoundedRectangle(cornerRadius: tile * 0.14, style: .continuous)
                .stroke(isSelected ? DATheme.ember : Color.white.opacity(model.kind == .wall ? 0.04 : 0.1),
                        lineWidth: isSelected ? 2 : 1)
                .padding(1)

            if model.kind == .entrance {
                ChevronIcon(size: tile * 0.46, color: DATheme.bone, direction: .down)
            }
            if model.kind == .heart {
                HeartCrystalIcon(size: tile * 0.66, color: heartColor)
            }
            if model.kind == .shrine {
                Circle()
                    .stroke(DATheme.sickly.opacity(0.45), lineWidth: max(1, tile * 0.05))
                    .frame(width: tile * 0.5, height: tile * 0.5)
            }
            if model.kind == .illusionHall {
                WaveCrestIcon(size: tile * 0.45, color: DATheme.frost.opacity(0.5))
            }
            if model.kind == .barracks {
                RoundedRectangle(cornerRadius: 1.5)
                    .stroke(DATheme.blood.opacity(0.5), lineWidth: max(1, tile * 0.05))
                    .frame(width: tile * 0.4, height: tile * 0.3)
            }

            if model.loot > 0 || (raid != nil && model.kind == .treasury) {
                CoinIcon(size: tile * 0.34)
                    .opacity(model.loot > 0 ? 1 : 0.22)
                    .offset(x: -tile * 0.24, y: -tile * 0.24)
            }

            if let trap = model.trap {
                trapGlyph(trap, idx: idx, tile: tile)
                    .offset(x: tile * 0.24, y: tile * 0.24)
            }

            if let m = model.monster {
                monsterGlyph(m, at: p, tile: tile)
            }
        }
    }

    private var heartColor: Color {
        guard let raid = raid else { return DATheme.blood }
        let ratio = raid.heartHP / max(1, raid.heartMaxHP)
        if ratio > 0.6 { return DATheme.blood }
        if ratio > 0.25 { return DATheme.ember }
        return DATheme.goldCoin
    }

    @ViewBuilder
    private func trapGlyph(_ trap: TrapPlacement, idx: Int, tile: CGFloat) -> some View {
        let disarmed = raid?.disarmedTraps.contains(idx) ?? false
        let cooling = (raid?.trapCooldowns[idx] ?? 0) > 0
        ZStack {
            if trap.type == .mimicChest {
                RoundedRectangle(cornerRadius: 2)
                    .fill(DATheme.goldCoin)
                    .frame(width: tile * 0.34, height: tile * 0.26)
            } else if trap.type == .spike {
                SpikesIcon(size: tile * 0.34, color: TrapCatalog.def(trap.type).tint)
            } else {
                TrapGearIcon(size: tile * 0.34, color: TrapCatalog.def(trap.type).tint)
            }
            if trap.level > 1 && raid == nil {
                Text("\(trap.level)")
                    .font(DATheme.mono(max(7, tile * 0.18)))
                    .foregroundColor(DATheme.bone)
                    .offset(x: tile * 0.2, y: -tile * 0.16)
            }
        }
        .opacity(disarmed ? 0.18 : (cooling ? 0.45 : 1))
    }

    @ViewBuilder
    private func monsterGlyph(_ m: MonsterPlacement, at p: GridPoint, tile: CGFloat) -> some View {
        let live = raidMonster(at: p)
        let dead = raid != nil && (live == nil || (live?.hp ?? 0) <= 0)
        ZStack {
            Circle()
                .fill(DATheme.voidShade.opacity(0.65))
                .frame(width: tile * 0.62, height: tile * 0.62)
            FangIcon(size: tile * 0.4, color: MonsterCatalog.def(m.family).tint)
            // Tier pips
            HStack(spacing: tile * 0.04) {
                ForEach(0..<m.tier, id: \.self) { _ in
                    Circle().fill(DATheme.bone).frame(width: tile * 0.07, height: tile * 0.07)
                }
            }
            .offset(y: tile * 0.36)
            // Raid HP bar
            if let live = live, live.hp > 0, live.hp < live.maxHP {
                hpBar(ratio: live.hp / live.maxHP, width: tile * 0.6, color: DATheme.sickly)
                    .offset(y: -tile * 0.38)
            }
        }
        .opacity(dead ? 0.15 : 1)
    }

    private func raidMonster(at p: GridPoint) -> RaidMonster? {
        raid?.monsters.first { $0.pos == p }
    }

    // MARK: - Raid sprites

    @ViewBuilder
    private func heroSprite(_ hero: RaidHero, tile: CGFloat) -> some View {
        VStack(spacing: tile * 0.05) {
            ZStack {
                Circle()
                    .fill(DATheme.obsidian)
                    .frame(width: tile * 0.56, height: tile * 0.56)
                Circle()
                    .stroke(hero.isBoss ? DATheme.goldCoin : HeroCatalog.def(hero.cls).tint,
                            lineWidth: hero.isBoss ? 2.5 : 1.5)
                    .frame(width: tile * 0.56, height: tile * 0.56)
                HeroClassIcon(cls: hero.cls, size: tile * 0.36)
            }
            hpBar(ratio: hero.hp / max(1, hero.maxHP), width: tile * 0.58,
                  color: hero.status == .retreating ? DATheme.goldCoin : DATheme.blood)
        }
        .opacity(hero.status == .retreating ? 0.8 : 1)
    }

    private func hpBar(ratio: Double, width: CGFloat, color: Color) -> some View {
        ZStack(alignment: .leading) {
            Capsule().fill(Color.black.opacity(0.7))
                .frame(width: width, height: 3.5)
            Capsule().fill(color)
                .frame(width: width * CGFloat(max(0, min(1, ratio))), height: 3.5)
        }
    }

    @ViewBuilder
    private func intentArrow(from: GridPoint, toward: GridPoint, tile: CGFloat) -> some View {
        let angle: Double = {
            if toward.x > from.x { return 0 }
            if toward.x < from.x { return 180 }
            if toward.y > from.y { return 90 }
            return -90
        }()
        IntentArrowShape()
            .stroke(DATheme.ember.opacity(0.75),
                    style: StrokeStyle(lineWidth: max(1.5, tile * 0.06), lineCap: .round, lineJoin: .round))
            .frame(width: tile * 0.7, height: tile * 0.5)
            .rotationEffect(.degrees(angle))
            .position(arrowPoint(from: from, toward: toward, tile: tile))
    }

    private func arrowPoint(from: GridPoint, toward: GridPoint, tile: CGFloat) -> CGPoint {
        let a = center(from, tile)
        let b = center(toward, tile)
        return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }
}
