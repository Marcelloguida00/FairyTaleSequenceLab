import SwiftUI

enum RedHoodEventFlowPhase: Equatable {
    case intro
    case activity
}

struct RedHoodRewardPhaseView: View {
    let eventData: EventData
    let attemptCount: Int
    let onRewardReached: () -> Void
    let onReplay: () -> Void
    let onChapterUnlock: (String) -> Void
    let onComplete: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var didNotifyRewardReached = false
    @State private var isFirstTimeCompletion = false

    var body: some View {
        ZStack {
            RewardView(
                event: eventData,
                attemptCount: attemptCount,
                showsBookChapterUnlock: isFirstTimeCompletion && (1...8).contains(eventData.id),
                onChapterUnlock: onChapterUnlock,
                onDismiss: onReplay,
                onNext: onComplete
            )
        }
        .ignoresSafeArea()
        .onAppear {
            let completed = UserDefaults.standard.array(forKey: "completedRedHoodLevels") as? [Int] ?? []
            isFirstTimeCompletion = !completed.contains(eventData.id)

            guard !didNotifyRewardReached else { return }
            didNotifyRewardReached = true
            onRewardReached()
        }
    }

}

struct EventFlowView: View {
    let eventData: EventData
    let onPhaseChange: (RedHoodEventFlowPhase) -> Void
    let onCelebrationZoomChange: (Bool) -> Void
    let onSequencingFinished: (Int) -> Void
    let onRewardReached: () -> Void
    let onComplete: () -> Void

    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var lm: LanguageManager
    @AppStorage("hasAskedForReview") private var hasAskedForReview = false
    @State private var showReviewAlert = false

    @State private var phase: RedHoodEventFlowPhase = .intro

    var body: some View {
        ZStack {
            if phase == .intro {
                EventIntroductionView(event: eventData) {
                    phase = .activity
                }
            } else {
                SequencingActivityView(
                    event: eventData,
                    showsReward: false,
                    onSequencingComplete: { attemptCount in
                        onSequencingFinished(attemptCount)
                    },
                    onCelebrationZoomChange: onCelebrationZoomChange,
                    makeReward: { _, _ in
                        EmptyView()
                    }
                )
            }
        }
        .onAppear {
            phase = .intro
            notifyPhaseChange(.intro)

            BackgroundMusicPlayer.shared.fadeOut()
            ForestAmbiencePlayer.shared.fadeIn()

            if eventData.id == 3 && !hasAskedForReview {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    showReviewAlert = true
                }
            }
        }
        .onChange(of: phase) { _, newPhase in
            notifyPhaseChange(newPhase)
        }
        .onDisappear {
            ForestAmbiencePlayer.shared.fadeOutAndStop()
            BackgroundMusicPlayer.shared.fadeIn()
        }
        .alert(lm.t("review.popup.title"), isPresented: $showReviewAlert) {
            Button(lm.t("review.popup.later"), role: .cancel) {
                hasAskedForReview = true
            }
            Button(lm.t("review.popup.rate")) {
                hasAskedForReview = true
                if let url = URL(string: "https://apps.apple.com/app/id6773034104?action=write-review") {
                    openURL(url)
                }
            }
        } message: {
            Text(lm.t("review.popup.message"))
        }
    }

    private func notifyPhaseChange(_ phase: RedHoodEventFlowPhase) {
        DispatchQueue.main.async {
            onPhaseChange(phase)
        }
    }
}

// MARK: - Previews

private struct EventFlowPreview: View {
    let eventId: Int
    var skipIntro = false

    init(eventId: Int, skipIntro: Bool = false) {
        PreviewSetup.registerFontsIfNeeded()
        self.eventId = eventId
        self.skipIntro = skipIntro
    }

    private var event: EventData? {
        EventLoader.event(id: eventId, from: .main)
    }

    var body: some View {
        Group {
            if let event {
                if skipIntro {
                    SequencingActivityView(event: event) { _, _ in
                        RewardView(
                            event: event,
                            attemptCount: 1,
                            onDismiss: {},
                            onNext: {}
                        )
                    }
                } else {
                    EventFlowView(
                        eventData: event,
                        onPhaseChange: { _ in },
                        onCelebrationZoomChange: { _ in },
                        onSequencingFinished: { _ in },
                        onRewardReached: {},
                        onComplete: {}
                    )
                }
            } else {
                ContentUnavailableView("Event not found", systemImage: "book.closed")
            }
        }
        .environmentObject(LanguageManager())
    }
}

#Preview("Chapter 1 – Intro + game", traits: .fixedLayout(width: 1194, height: 834)) {
    EventFlowPreview(eventId: 1)
}

#Preview("Chapter 1 – Sequencing only", traits: .fixedLayout(width: 1194, height: 834)) {
    EventFlowPreview(eventId: 1, skipIntro: true)
}
