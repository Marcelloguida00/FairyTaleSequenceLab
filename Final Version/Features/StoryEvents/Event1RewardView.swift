import SwiftUI

struct RewardView: View {
    let event: EventData
    let attemptCount: Int
    var showsBookChapterUnlock: Bool = false
    var onChapterUnlock: ((String) -> Void)? = nil
    let onDismiss: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        rewardContent
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
        if showsBookChapterUnlock, let onChapterUnlock {
            onChapterUnlock(BookChapterTitles.title(for: event.id, lm: lm))
        } else {
            onNext()
        }
    }
}
