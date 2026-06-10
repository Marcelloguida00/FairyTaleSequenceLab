import SwiftUI

/// Placeholder onboarding beat: full-screen background while narration plays.
struct OnboardingStillSceneView: View {
    let backgroundImageName: String
    let narrationResource: String
    let startsUnderCloudCover: Bool
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var coverCloudEnter: CGFloat = 0
    @State private var curtainCloudExit: CGFloat = 0

    init(
        backgroundImageName: String,
        narrationResource: String,
        startsUnderCloudCover: Bool = false,
        onComplete: @escaping () -> Void
    ) {
        self.backgroundImageName = backgroundImageName
        self.narrationResource = narrationResource
        self.startsUnderCloudCover = startsUnderCloudCover
        self.onComplete = onComplete
        _coverCloudEnter = State(initialValue: startsUnderCloudCover ? 1 : 0)
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Image(backgroundImageName)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                CloudTransitionOverlay(
                    enterProgress: coverCloudEnter,
                    exitProgress: curtainCloudExit,
                    cloudImageName: OnboardingScripts.cloudImageName
                )
            }
        }
        .ignoresSafeArea()
        .background(Color.black)
        .task {
            await runSequence()
        }
    }

    @MainActor
    private func runSequence() async {
        if startsUnderCloudCover {
            try? await Task.sleep(nanoseconds: UInt64(CloudTransitionAnimator.holdAfterSceneChange * 1_000_000_000))

            let openDuration = reduceMotion ? 0.01 : CloudTransitionAnimator.exitDuration
            withAnimation(.easeInOut(duration: openDuration)) {
                curtainCloudExit = 1
            }
            try? await Task.sleep(nanoseconds: UInt64(openDuration * 1_000_000_000))

            curtainCloudExit = 0
            coverCloudEnter = 0
        }

        if reduceMotion {
            try? await Task.sleep(nanoseconds: 500_000_000)
            onComplete()
            return
        }

        await OnboardingNarrationPlayer.shared.playAndWait(named: narrationResource)
        onComplete()
    }
}

#Preview("Onboarding Still") {
    OnboardingStillSceneView(
        backgroundImageName: "OnboardingSea",
        narrationResource: "onboarding1",
        onComplete: {}
    )
}
