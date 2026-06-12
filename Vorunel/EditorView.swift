import SwiftUI

enum EditorTool: Equatable {
    case room(TileKind)
    case trap(TrapType)
    case monster(MonsterFamily)
    case erase
}

enum EditorTab: Int, CaseIterable {
    case rooms, traps, monsters, tools

    var label: String {
        switch self {
        case .rooms: return "Rooms"
        case .traps: return "Traps"
        case .monsters: return "Garrison"
        case .tools: return "Tools"
        }
    }
}

struct EditorView: View {
    @EnvironmentObject var store: GameStore
    @State private var tab: EditorTab = .rooms
    @State private var tool: EditorTool? = nil
    @State private var selected: GridPoint? = nil
    @State private var message: String? = nil
    @State private var messageIsError = false

    var body: some View {
        GeometryReader { geo in
            let isWide = geo.size.width > geo.size.height
            VStack(spacing: 0) {
                header
                if isWide {
                    HStack(spacing: 0) {
                        boardSection
                            .frame(width: geo.size.width * 0.46)
                        controlSection
                    }
                } else {
                    boardSection
                        .frame(height: geo.size.height * 0.46)
                    controlSection
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            DABackButton(label: "Back") {
                store.screen = backTarget
            }
            Spacer()
            DACurrencyPill(kind: .gold, value: store.profile.gold)
            if case .campaign(let id)? = store.pendingContext {
                budgetPill(cap: CampaignBook.scenario(id).budgetCap)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    private var backTarget: AppScreen {
        switch store.pendingContext {
        case .campaign(let id): return .briefing(id)
        case .endless: return .endless
        case nil: return .menu
        }
    }

    private func budgetPill(cap: Int) -> some View {
        let value = store.profile.dungeon.buildValue
        return HStack(spacing: 5) {
            StarIcon(size: 12, filled: value <= cap)
            Text("\(value)/\(cap)")
                .font(DATheme.mono(12))
                .foregroundColor(value <= cap ? DATheme.sickly : DATheme.blood)
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .daPanel(fill: DATheme.voidShade.opacity(0.8), radius: 9)
    }

    // MARK: - Board

    private var boardSection: some View {
        DungeonBoardView(dungeon: store.profile.dungeon, selected: selected, onTap: tapTile)
            .padding(8)
    }

    // MARK: - Controls

    private var controlSection: some View {
        VStack(spacing: 8) {
            messageLine
            tabBar
            ScrollView(showsIndicators: false) {
                VStack(spacing: 8) {
                    switch tab {
                    case .rooms: roomPalette
                    case .traps: trapPalette
                    case .monsters: monsterPalette
                    case .tools: toolsPanel
                    }
                    if let sel = selected { inspectPanel(sel) }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            footer
        }
        .frame(maxWidth: .infinity)
    }

    private var messageLine: some View {
        Group {
            if let msg = message {
                Text(msg)
                    .font(DATheme.ui(12, .semibold))
                    .foregroundColor(messageIsError ? DATheme.blood : DATheme.sickly)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
            } else {
                Text(toolHint)
                    .font(DATheme.ui(12, .medium))
                    .foregroundColor(DATheme.boneFaint)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 14)
            }
        }
        .frame(height: 30)
    }

    private var toolHint: String {
        switch tool {
        case .room(let k): return "Tap a tile to dig: \(k.displayName) (\(k.buildCost + (k == .treasury ? DungeonState.treasuryBait : 0)) gold)"
        case .trap(let t): return "Tap an open tile to set: \(TrapCatalog.def(t).name). Tap it again to hone."
        case .monster(let f): return "Tap an open tile to garrison: \(MonsterCatalog.def(f).name). Tap again to promote."
        case .erase: return "Tap a tile to demolish it for a full refund."
        case nil: return "Pick a tool below, then tap the grid. Tap any tile to inspect it."
        }
    }

    private func flash(_ text: String, error: Bool) {
        message = text
        messageIsError = error
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) {
            if message == text { message = nil }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(EditorTab.allCases, id: \.rawValue) { t in
                Button(action: {
                    SoundBox.shared.play(.uiTap)
                    tab = t
                    tool = nil
                }) {
                    Text(t.label)
                        .font(DATheme.ui(12, .bold))
                        .foregroundColor(tab == t ? DATheme.voidShade : DATheme.boneDim)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(tab == t ? DATheme.ember : DATheme.plumDeep)
                        )
                }
                .buttonStyle(DAPressStyle())
            }
        }
        .padding(.horizontal, 12)
    }

    // MARK: - Palettes

    private var paletteColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 96), spacing: 8)]
    }

    private var roomPalette: some View {
        LazyVGrid(columns: paletteColumns, spacing: 8) {
            ForEach(TileKind.buildable, id: \.rawValue) { kind in
                let locked = !store.unlockedRooms.contains(kind)
                paletteCell(title: kind.displayName,
                            cost: kind.buildCost + (kind == .treasury ? DungeonState.treasuryBait : 0),
                            locked: locked,
                            active: tool == .room(kind),
                            icon: AnyView(RoundedRectangle(cornerRadius: 5).fill(kind.tint)
                                .frame(width: 22, height: 22)
                                .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.white.opacity(0.25))))) {
                    if locked {
                        flash("Seal a pact in Dark Renown to dig this room.", error: true)
                    } else {
                        tool = .room(kind)
                    }
                }
            }
        }
    }

    private var trapPalette: some View {
        LazyVGrid(columns: paletteColumns, spacing: 8) {
            ForEach(TrapCatalog.all, id: \.type.rawValue) { def in
                let locked = !store.unlockedTraps.contains(def.type)
                paletteCell(title: def.name,
                            cost: def.baseCost,
                            locked: locked,
                            active: tool == .trap(def.type),
                            icon: AnyView(def.type == .spike
                                          ? AnyView(SpikesIcon(size: 22, color: def.tint))
                                          : AnyView(TrapGearIcon(size: 22, color: def.tint)))) {
                    if locked {
                        flash("Seal a pact in Dark Renown to build this trap.", error: true)
                    } else {
                        tool = .trap(def.type)
                    }
                }
            }
        }
    }

    private var monsterPalette: some View {
        LazyVGrid(columns: paletteColumns, spacing: 8) {
            ForEach(MonsterCatalog.all, id: \.family.rawValue) { def in
                let locked = !store.unlockedMonsters.contains(def.family)
                paletteCell(title: def.name,
                            cost: def.baseCost,
                            locked: locked,
                            active: tool == .monster(def.family),
                            icon: AnyView(FangIcon(size: 22, color: def.tint))) {
                    if locked {
                        flash("Seal a pact in Dark Renown to recruit this family.", error: true)
                    } else {
                        tool = .monster(def.family)
                    }
                }
            }
        }
    }

    private var toolsPanel: some View {
        VStack(spacing: 8) {
            paletteCell(title: "Demolish", cost: nil, locked: false, active: tool == .erase,
                        icon: AnyView(CrossIcon(size: 20))) {
                tool = .erase
            }
            // Heart upgrade
            HStack(spacing: 10) {
                HeartCrystalIcon(size: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Dungeon Heart — Level \(store.profile.dungeon.heartLevel)")
                        .font(DATheme.ui(13, .bold))
                        .foregroundColor(DATheme.bone)
                    Text("\(Int(store.heartMaxHP)) health")
                        .font(DATheme.ui(11, .medium))
                        .foregroundColor(DATheme.boneDim)
                }
                Spacer()
                if store.profile.dungeon.heartLevel < 6 {
                    Button(action: {
                        SoundBox.shared.play(.build)
                        Haptics.tap()
                        if let err = store.upgradeHeart() {
                            flash(err, error: true)
                        } else {
                            flash("The Heart swells with patient malice.", error: false)
                        }
                    }) {
                        HStack(spacing: 4) {
                            CoinIcon(size: 12)
                            Text("\(store.heartUpgradeCost)")
                                .font(DATheme.mono(12))
                                .foregroundColor(DATheme.voidShade)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Capsule().fill(DATheme.ember))
                    }
                    .buttonStyle(DAPressStyle())
                } else {
                    Text("MAX")
                        .font(DATheme.ui(11, .heavy))
                        .foregroundColor(DATheme.goldCoin)
                }
            }
            .padding(12)
            .daPanel()

            HStack(spacing: 10) {
                SkullIcon(size: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Garrison upkeep")
                        .font(DATheme.ui(13, .bold))
                        .foregroundColor(DATheme.bone)
                    Text("Paid from your hoard when each raid begins.")
                        .font(DATheme.ui(11, .medium))
                        .foregroundColor(DATheme.boneDim)
                }
                Spacer()
                DACurrencyPill(kind: .gold, value: store.currentUpkeep)
            }
            .padding(12)
            .daPanel()
        }
    }

    private func paletteCell(title: String, cost: Int?, locked: Bool, active: Bool, icon: AnyView, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundBox.shared.play(.uiTap)
            Haptics.tap()
            action()
        }) {
            VStack(spacing: 5) {
                ZStack {
                    icon.opacity(locked ? 0.3 : 1)
                    if locked { LockIcon(size: 14) }
                }
                .frame(height: 24)
                Text(title)
                    .font(DATheme.ui(10, .bold))
                    .foregroundColor(locked ? DATheme.boneFaint : DATheme.bone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
                if let cost = cost {
                    HStack(spacing: 3) {
                        CoinIcon(size: 9)
                        Text("\(cost)")
                            .font(DATheme.mono(10))
                            .foregroundColor(DATheme.goldCoin.opacity(locked ? 0.4 : 1))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(active ? DATheme.plumLight : DATheme.plumDeep)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(active ? DATheme.ember : DATheme.plumLight.opacity(0.5), lineWidth: active ? 2 : 1)
            )
        }
        .buttonStyle(DAPressStyle())
    }

    // MARK: - Inspect panel

    @ViewBuilder
    private func inspectPanel(_ p: GridPoint) -> some View {
        let tile = store.profile.dungeon.tile(at: p)
        VStack(alignment: .leading, spacing: 6) {
            Text(tile.kind.displayName)
                .font(DATheme.head(14))
                .foregroundColor(DATheme.bone)
            Text(tile.kind.effectText)
                .font(DATheme.ui(11, .medium))
                .foregroundColor(DATheme.boneDim)
                .fixedSize(horizontal: false, vertical: true)
            if let trap = tile.trap {
                HStack {
                    Text("\(TrapCatalog.def(trap.type).name) — Level \(trap.level)")
                        .font(DATheme.ui(12, .semibold))
                        .foregroundColor(TrapCatalog.def(trap.type).tint)
                    Spacer()
                    removeButton("Remove") {
                        store.removeTrap(at: p)
                        SoundBox.shared.play(.erase)
                    }
                }
            }
            if let m = tile.monster {
                HStack {
                    Text("\(MonsterCatalog.tierName(m.family, tier: m.tier)) — Tier \(m.tier)")
                        .font(DATheme.ui(12, .semibold))
                        .foregroundColor(MonsterCatalog.def(m.family).tint)
                    Spacer()
                    removeButton("Dismiss") {
                        store.removeMonster(at: p)
                        SoundBox.shared.play(.erase)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .daPanel(stroke: DATheme.ember.opacity(0.5))
    }

    private func removeButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Text(label)
                .font(DATheme.ui(11, .bold))
                .foregroundColor(DATheme.blood)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(Capsule().stroke(DATheme.blood.opacity(0.6)))
        }
        .buttonStyle(DAPressStyle())
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 6) {
            if store.pendingContext != nil {
                DAActionButton(title: beginTitle) {
                    if let err = store.beginRaid() {
                        flash(err, error: true)
                    }
                }
                .padding(.horizontal, 12)
            } else {
                Text("Pick a raid in Campaign or Endless Siege to put this layout to work.")
                    .font(DATheme.ui(11, .medium))
                    .foregroundColor(DATheme.boneFaint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 10)
    }

    private var beginTitle: String {
        switch store.pendingContext {
        case .campaign(let id): return "Begin Raid \(id): \(CampaignBook.scenario(id).title)"
        case .endless(let w): return "Hold the Line — Wave \(w)"
        case nil: return ""
        }
    }

    // MARK: - Tile interaction

    private func tapTile(_ p: GridPoint) {
        selected = p
        let tile = store.profile.dungeon.tile(at: p)
        switch tool {
        case .room(let kind):
            guard store.unlockedRooms.contains(kind) else { return }
            if let err = store.paintRoom(kind, at: p) {
                flash(err, error: true)
                SoundBox.shared.play(.erase)
            } else {
                SoundBox.shared.play(.build)
                Haptics.tap()
            }
        case .trap(let type):
            guard store.unlockedTraps.contains(type) else { return }
            if let existing = tile.trap {
                if existing.type == type {
                    if let err = store.upgradeTrap(at: p) {
                        flash(err, error: true)
                    } else {
                        SoundBox.shared.play(.build)
                        flash("Trap honed to level \(store.profile.dungeon.tile(at: p).trap?.level ?? 2).", error: false)
                    }
                } else {
                    store.removeTrap(at: p)
                    if let err = store.placeTrap(type, at: p) {
                        flash(err, error: true)
                    } else {
                        SoundBox.shared.play(.trapSnap)
                        Haptics.tap()
                    }
                }
            } else {
                if let err = store.placeTrap(type, at: p) {
                    flash(err, error: true)
                } else {
                    SoundBox.shared.play(.trapSnap)
                    Haptics.tap()
                }
            }
        case .monster(let family):
            guard store.unlockedMonsters.contains(family) else { return }
            if let existing = tile.monster {
                if existing.family == family {
                    if let err = store.upgradeMonster(at: p) {
                        flash(err, error: true)
                    } else {
                        SoundBox.shared.play(.build)
                        flash("Promoted to \(MonsterCatalog.tierName(family, tier: store.profile.dungeon.tile(at: p).monster?.tier ?? 2)).", error: false)
                    }
                } else {
                    store.removeMonster(at: p)
                    if let err = store.placeMonster(family, at: p) {
                        flash(err, error: true)
                    } else {
                        SoundBox.shared.play(.build)
                        Haptics.tap()
                    }
                }
            } else {
                if let err = store.placeMonster(family, at: p) {
                    flash(err, error: true)
                } else {
                    SoundBox.shared.play(.build)
                    Haptics.tap()
                }
            }
        case .erase:
            if let err = store.eraseTile(at: p) {
                flash(err, error: true)
            } else {
                SoundBox.shared.play(.erase)
                Haptics.tap()
            }
        case nil:
            break
        }
    }
}
