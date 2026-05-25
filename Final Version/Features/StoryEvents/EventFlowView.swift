import SwiftUI

struct EventFlowView: View {
    let eventData: EventData
    let onComplete: () -> Void

    private enum Phase { case intro, activity }
    @State private var phase: Phase = .intro

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
                }
            }
        }
    }
}
