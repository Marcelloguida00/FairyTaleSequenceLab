import SwiftUI

struct EventFlowView: View {
    let eventData: EventData
    let onRewardReached: () -> Void
    let onComplete: () -> Void

    private enum Phase { case intro, activity }
    @State private var phase: Phase = .intro
    @State private var didNotifyRewardReached = false
    @State private var isFirstTimeCompletion = false
    @State private var showEnvelopeOpening = false

    var body: some View {
        Group {
            switch phase {
            case .intro:
                EventIntroductionView(event: eventData) {
                    phase = .activity
                }
            case .activity:
                SequencingActivityView(event: eventData) { attemptCount, onDismiss in
                    ZStack {
                        if isFirstTimeCompletion && showEnvelopeOpening {
                            EnvelopeOpeningView(event: eventData) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showEnvelopeOpening = false
                                }
                            }
                        } else {
                            RewardView(
                                event: eventData,
                                attemptCount: attemptCount,
                                onDismiss: onDismiss,
                                onNext: onComplete
                            )
                        }
                    }
                    .onAppear {
                        if isFirstTimeCompletion {
                            showEnvelopeOpening = true
                        }
                        
                        guard !didNotifyRewardReached else { return }
                        didNotifyRewardReached = true
                        onRewardReached()
                    }
                }
            }
        }
        .onAppear {
            let completed = UserDefaults.standard.array(forKey: "completedRedHoodLevels") as? [Int] ?? []
            isFirstTimeCompletion = !completed.contains(eventData.id)
            
            BackgroundMusicPlayer.shared.fadeOut()
            ForestAmbiencePlayer.shared.fadeIn()
        }
        .onDisappear {
            ForestAmbiencePlayer.shared.fadeOutAndStop()
            BackgroundMusicPlayer.shared.fadeIn()
        }
    }
}
