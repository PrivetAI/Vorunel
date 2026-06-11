import SwiftUI

// MARK: - Campaign map

struct CampaignMapView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        VStack(spacing: 0) {
            DAScreenHeader(title: "Campaign", onBack: { store.screen = .menu },
                           trailing: AnyView(
                            HStack(spacing: 4) {
                                StarIcon(size: 14)
                                Text("\(store.totalStars)")
                                    .font(DATheme.mono(13))
                                    .foregroundColor(DATheme.bone)
                            }
                            .padding(.horizontal, 10).padding(.vertical, 8)
                            .daPanel(radius: 10)
                           ))

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(CampaignBook.chapters) { chapter in
                        chapterPanel(chapter)
                    }
                    Spacer(minLength: 20)
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func chapterUnlocked(_ chapter: CampaignChapter) -> Bool {
        chapter.id == 1 || store.chapterCleared(chapter.id - 1)
    }

    @ViewBuilder
    private func chapterPanel(_ chapter: CampaignChapter) -> some View {
        let open = chapterUnlocked(chapter)
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                SkullBannerIcon(size: 34, bannerColor: chapter.tint)
                    .opacity(open ? 1 : 0.35)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Chapter \(chapter.id)")
                        .font(DATheme.ui(11, .bold))
                        .foregroundColor(DATheme.boneFaint)
                    Text(chapter.name)
                        .font(DATheme.head(18))
                        .foregroundColor(open ? DATheme.bone : DATheme.boneDim)
                }
                Spacer()
                if !open { LockIcon(size: 20) }
            }

            Text(open ? chapter.blurb : "Repel every raid in the previous chapter to open these gates.")
                .font(DATheme.ui(12, .regular))
                .foregroundColor(DATheme.boneDim)
                .fixedSize(horizontal: false, vertical: true)

            if open {
                HStack(spacing: 8) {
                    ForEach(Array(chapter.scenarioIDs), id: \.self) { id in
                        scenarioNode(id, tint: chapter.tint)
                    }
                }
            }
        }
        .padding(14)
        .daPanel(stroke: open ? chapter.tint.opacity(0.8) : DATheme.plumLight)
    }

    @ViewBuilder
    private func scenarioNode(_ id: Int, tint: Color) -> some View {
        let unlocked = store.isScenarioUnlocked(id)
        let stars = store.stars(for: id)
        let sc = CampaignBook.scenario(id)

        Button(action: {
            guard unlocked else { return }
            SoundBox.shared.play(.uiTap)
            Haptics.tap()
            store.screen = .briefing(id)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(unlocked ? (stars > 0 ? tint.opacity(0.35) : DATheme.plum) : DATheme.voidShade)
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(sc.isBossRaid ? DATheme.goldCoin.opacity(unlocked ? 0.9 : 0.25) : tint.opacity(unlocked ? 0.7 : 0.2),
                                lineWidth: sc.isBossRaid ? 2 : 1)
                    if unlocked {
                        if sc.isBossRaid {
                            SkullIcon(size: 18)
                        } else {
                            Text("\(id)")
                                .font(DATheme.mono(14))
                                .foregroundColor(DATheme.bone)
                        }
                    } else {
                        LockIcon(size: 14)
                    }
                }
                .frame(height: 40)

                HStack(spacing: 1) {
                    ForEach(0..<3, id: \.self) { i in
                        StarIcon(size: 8, filled: i < stars)
                    }
                }
                .opacity(unlocked ? 1 : 0.25)
            }
        }
        .buttonStyle(DAPressStyle())
        .disabled(!unlocked)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pre-raid briefing

struct BriefingView: View {
    @EnvironmentObject var store: GameStore
    let scenarioID: Int

    private var sc: CampaignScenario { CampaignBook.scenario(scenarioID) }
    private var chapter: CampaignChapter { CampaignBook.chapter(sc.chapter) }

    var body: some View {
        VStack(spacing: 0) {
            DAScreenHeader(title: "Raid \(scenarioID)", onBack: { store.screen = .campaign })

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(chapter.name.uppercased())
                            .font(DATheme.ui(11, .bold))
                            .foregroundColor(chapter.tint)
                        Text(sc.title)
                            .font(DATheme.display(24))
                            .foregroundColor(DATheme.bone)
                        if sc.isBossRaid {
                            HStack(spacing: 6) {
                                SkullIcon(size: 14)
                                Text("LEGENDARY HERO")
                                    .font(DATheme.ui(11, .heavy))
                                    .foregroundColor(DATheme.goldCoin)
                            }
                        }
                        Text(sc.brief)
                            .font(DATheme.ui(13, .regular))
                            .foregroundColor(DATheme.boneDim)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .daPanel(stroke: chapter.tint.opacity(0.7))

                    // Party intel
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Scouting Report — \(sc.party.count) intruders")
                            .font(DATheme.head(15))
                            .foregroundColor(DATheme.bone)
                        ForEach(Array(sc.party.enumerated()), id: \.offset) { _, slot in
                            partyRow(slot)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .daPanel()

                    // Modifiers
                    if !sc.modifiers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Raid Blessings")
                                .font(DATheme.head(15))
                                .foregroundColor(DATheme.bone)
                            ForEach(sc.modifiers, id: \.self) { mod in
                                HStack(alignment: .top, spacing: 8) {
                                    WaveCrestIcon(size: 14, color: DATheme.frost)
                                        .padding(.top, 2)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(mod.displayName)
                                            .font(DATheme.ui(13, .bold))
                                            .foregroundColor(DATheme.frost)
                                        Text(mod.blurb)
                                            .font(DATheme.ui(12, .regular))
                                            .foregroundColor(DATheme.boneDim)
                                    }
                                }
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .daPanel()
                    }

                    // Rewards & stars
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Spoils & Stars")
                            .font(DATheme.head(15))
                            .foregroundColor(DATheme.bone)
                        HStack(spacing: 10) {
                            DACurrencyPill(kind: .gold, value: sc.goldReward)
                            DACurrencyPill(kind: .renown, value: sc.renownReward)
                            Spacer()
                        }
                        starLine(filled: true, text: "Repel the raid")
                        starLine(filled: store.stars(for: scenarioID) >= 2, text: "Keep the Heart untouched")
                        starLine(filled: store.stars(for: scenarioID) >= 3, text: "Dungeon worth at most \(sc.budgetCap) gold (now \(store.profile.dungeon.buildValue))")
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .daPanel()

                    DAActionButton(title: "Prepare the Dungeon") {
                        store.pendingContext = .campaign(scenarioID)
                        store.screen = .editor
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 24)
                }
                .padding(16)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func starLine(filled: Bool, text: String) -> some View {
        HStack(spacing: 8) {
            StarIcon(size: 13, filled: filled)
            Text(text)
                .font(DATheme.ui(12, .medium))
                .foregroundColor(DATheme.boneDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func partyRow(_ slot: PartySlot) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle().fill(DATheme.voidShade)
                    .frame(width: 36, height: 36)
                Circle().stroke(slot.isBoss ? DATheme.goldCoin : HeroCatalog.def(slot.cls).tint, lineWidth: slot.isBoss ? 2 : 1)
                    .frame(width: 36, height: 36)
                HeroClassIcon(cls: slot.cls, size: 22)
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(slot.name)
                    .font(DATheme.ui(13, .bold))
                    .foregroundColor(slot.isBoss ? DATheme.goldCoin : DATheme.bone)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("\(slot.cls.displayName) • Level \(slot.level) • \(slot.personality.displayName)")
                    .font(DATheme.ui(11, .medium))
                    .foregroundColor(DATheme.boneDim)
            }
            Spacer()
            if slot.isBoss {
                Text("2 PHASES")
                    .font(DATheme.ui(9, .heavy))
                    .foregroundColor(DATheme.voidShade)
                    .padding(.horizontal, 6).padding(.vertical, 3)
                    .background(Capsule().fill(DATheme.goldCoin))
            }
        }
    }
}
