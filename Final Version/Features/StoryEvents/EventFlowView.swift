import SwiftUI

struct EventFlowView: View {
    let eventData: EventData
    let onRewardReached: () -> Void
    let onComplete: () -> Void

    private enum Phase { case intro, activity }
    @State private var phase: Phase = .intro
    @State private var didNotifyRewardReached = false

    var body: some View {
        Group {
            switch phase {
            case .intro:
                EventIntroductionView(event: eventData) {
                    phase = .activity
                }
            case .activity:
                SequencingActivityView(event: eventData) { attemptCount, onDismiss in
                    RewardView(
                        event: eventData,
                        attemptCount: attemptCount,
                        onDismiss: onDismiss,
                        onNext: onComplete
                    )
                    .onAppear {
                        guard !didNotifyRewardReached else { return }
                        didNotifyRewardReached = true
                        onRewardReached()
                    }
                }
            }
        }
        .onAppear {
            BackgroundMusicPlayer.shared.fadeOut()
            ForestAmbiencePlayer.shared.fadeIn()
        }
        .onDisappear {
            ForestAmbiencePlayer.shared.fadeOutAndStop()
            BackgroundMusicPlayer.shared.fadeIn()
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
