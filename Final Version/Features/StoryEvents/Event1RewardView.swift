import SwiftUI

struct RewardView: View {
    let event: EventData
    let attemptCount: Int
    var showsBookChapterUnlock: Bool = false
    let onDismiss: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var showBookChapterUnlocked = false

    private var stars: String {
        switch attemptCount {
        case 0: return "⭐⭐⭐"
        case 1, 2: return "⭐⭐"
        default: return "⭐"
        }
    }

    private var performanceNote: String {
        switch attemptCount {
        case 0: return lm.t("reward.perfect")
        case 1: return lm.t("reward.well_done")
        default: return lm.t("reward.did_it")
        }
    }

    var body: some View {
        ZStack {
            rewardContent
                .allowsHitTesting(!showBookChapterUnlocked)

            if showBookChapterUnlocked {
                BookChapterUnlockedBanner(
                    chapterTitle: BookChapterTitles.title(for: event.id, lm: lm)
                ) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showBookChapterUnlocked = false
                    }
                    onNext()
                }
                .environmentObject(lm)
                .transition(.opacity)
                .zIndex(10)
            }
        }
    }

    @ViewBuilder
    private var rewardContent: some View {
        if let lines = RedHoodDialogueLoader.rewardLines(
            eventId: event.id,
            attemptCount: attemptCount,
            from: lm.bundle
        ), !lines.isEmpty {
            FairyTaleDialogueView(
                lines: lines,
                onComplete: finishRewardFlow
            )
        } else {
            legacyReward
        }
    }

    private func finishRewardFlow() {
        if showsBookChapterUnlock {
            withAnimation(.easeInOut(duration: 0.25)) {
                showBookChapterUnlocked = true
            }
        } else {
            onNext()
        }
    }

    private var legacyReward: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let panelRatio = isLandscape ? 0.46 : 0.40
            let panelHeight = geometry.size.height * panelRatio
            let imageHeight = geometry.size.height - panelHeight
            let compactText = geometry.size.height < 900

            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if UIImage(named: event.rewardImageName) != nil {
                        Image(event.rewardImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: imageHeight)
                            .clipped()
                            .accessibilityHidden(true)
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [Color(red: 0.1, green: 0.2, blue: 0.15), Color(red: 0.15, green: 0.3, blue: 0.22)],
                                startPoint: .top, endPoint: .bottom
                            )

                            VStack(spacing: 12) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.5))

                                Text(stars)
                                    .font(.app(.title))

                                Text("Reward: 16:9 Image Placeholder")
                                    .font(.app(.body))
                                    .foregroundColor(Color(red: 0.8, green: 0.9, blue: 0.85))
                            }
                        }
                        .frame(width: geometry.size.width, height: imageHeight)
                    }

                    ParchmentView {
                        HStack(alignment: .center, spacing: compactText ? 16 : 24) {
                            VStack(alignment: .leading, spacing: compactText ? 4 : 6) {
                                Text(stars)
                                    .font(.app(.title3))

                                Text(performanceNote)
                                    .font(.app(compactText ? .callout : .body))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.appSecondaryText)

                                Text(event.rewardText)
                                    .font(.app(compactText ? .body : .title2))
                                    .fontWeight(.regular)
                                    .foregroundColor(Color.appPrimaryText)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(compactText ? 0 : 2)

                                Text(event.learningOutcome)
                                    .font(.app(compactText ? .callout : .body))
                                    .italic()
                                    .foregroundColor(Color.appSecondaryText)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .padding(.top, compactText ? 2 : 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: 10) {
                                GamePillButton(
                                    title: event.isLastEvent ? lm.t("button.back_to_map") : lm.t("button.next_event"),
                                    minWidth: GameButtonMetrics.isPad ? 200 : 160,
                                    minHeight: GameButtonMetrics.pillMinHeight(atLeast: 52),
                                    trailingIcon: event.isLastEvent ? "map" : "arrow.right",
                                    action: finishRewardFlow
                                )

                                GameCapsuleButton(
                                    title: lm.t("button.play_again"),
                                    systemImage: "arrow.clockwise",
                                    fontSize: GameButtonMetrics.pillFontSize - 2,
                                    foregroundColor: Color.appSecondaryText,
                                    fillColor: Color.appPanelBackground,
                                    action: onDismiss
                                )
                            }
                        }
                        .padding(.horizontal, compactText ? 28 : 32)
                        .padding(.vertical, compactText ? 14 : 20)
                    }
                    .frame(height: panelHeight)
                }
            }
        }
        .ignoresSafeArea()
    }
}
