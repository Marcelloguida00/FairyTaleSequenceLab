import SwiftUI

struct RewardView: View {
    let event: EventData
    let attemptCount: Int
    var showsBookChapterUnlock: Bool = false
    let onDismiss: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var showBookChapterUnlocked = false

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
            Color.clear.onAppear {
                Task { @MainActor in
                    finishRewardFlow()
                }
            }
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
}
