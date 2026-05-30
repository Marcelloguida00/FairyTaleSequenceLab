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
