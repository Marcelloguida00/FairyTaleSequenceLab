import SwiftUI

/// Optional celebrating ship layered on a still onboarding beat.
struct OnboardingShipOverlay {
    let position: CGPoint
    let jumpFrames: [String]
    let jumpLoopCount: Int
    let byeFrames: [String]
    let byeLoopCount: Int

    /// Onboarding 4: jump once, then wave goodbye four times.
    static let outroCelebration = OnboardingShipOverlay(
        position: CGPoint(x: 0.78, y: 0.68),
        jumpFrames: ["ShipJumping1", "ShipJumping2", "ShipJumping3"],
        jumpLoopCount: 3,
        byeFrames: ["ShipBye1", "ShipBye2", "ShipBye3"],
        byeLoopCount: 5
    )
}

/// Placeholder onboarding beat: full-screen background while narration plays.
struct OnboardingStillSceneView: View {
    let backgroundImageName: String
    let narrationResource: String
    let startsUnderCloudCover: Bool
    let shipOverlay: OnboardingShipOverlay?
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var coverCloudEnter: CGFloat = 0
    @State private var curtainCloudExit: CGFloat = 0
    @State private var currentShipImage = "ShipJumping1"

    private static let shipAspectRatio: CGFloat = 768.0 / 1024.0
    private let shipWidthScale: CGFloat = 0.54
    private var timingScale: TimeInterval { OnboardingScripts.shipTimingScale }

    init(
        backgroundImageName: String,
        narrationResource: String,
        startsUnderCloudCover: Bool = false,
        shipOverlay: OnboardingShipOverlay? = nil,
        onComplete: @escaping () -> Void
    ) {
        self.backgroundImageName = backgroundImageName
        self.narrationResource = narrationResource
        self.startsUnderCloudCover = startsUnderCloudCover
        self.shipOverlay = shipOverlay
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

                if let shipOverlay {
                    let shipWidth = min(proxy.size.width, proxy.size.height) * shipWidthScale
                    let shipHeight = shipWidth * Self.shipAspectRatio

                    shipLayer(
                        width: shipWidth,
                        height: shipHeight,
                        position: shipOverlay.position,
                        in: proxy.size
                    )
                }

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

    @ViewBuilder
    private func shipLayer(
        width: CGFloat,
        height: CGFloat,
        position: CGPoint,
        in size: CGSize
    ) -> some View {
        Image(currentShipImage)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)
            .position(
                x: position.x * size.width,
                y: position.y * size.height
            )
            .animation(nil, value: currentShipImage)
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
            if let shipOverlay {
                currentShipImage = shipOverlay.byeFrames.last ?? shipOverlay.jumpFrames.first ?? "ShipBye2"
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
            await OnboardingNarrationPlayer.shared.playAndWait(named: narrationResource)
            onComplete()
            return
        }

        if let shipOverlay {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { @MainActor in
                    await OnboardingNarrationPlayer.shared.playAndWait(named: narrationResource)
                }
                group.addTask { @MainActor in
                    await playShipAnimation(shipOverlay)
                }
            }
        } else {
            await OnboardingNarrationPlayer.shared.playAndWait(named: narrationResource)
        }

        onComplete()
    }

    @MainActor
    private func playShipAnimation(_ overlay: OnboardingShipOverlay) async {
        await playFrameLoop(overlay.jumpFrames, times: overlay.jumpLoopCount, frameDuration: 0.17)
        await playFrameLoop(overlay.byeFrames, times: overlay.byeLoopCount, frameDuration: 0.22)
    }

    @MainActor
    private func playFrameLoop(_ frames: [String], times: Int, frameDuration: TimeInterval) async {
        guard !frames.isEmpty, times > 0 else { return }

        for _ in 0..<times {
            for imageName in frames {
                currentShipImage = imageName
                try? await Task.sleep(nanoseconds: UInt64(scaled(frameDuration) * 1_000_000_000))
            }
        }
    }

    private func scaled(_ duration: TimeInterval) -> TimeInterval {
        duration * timingScale
    }
}

#Preview("Onboarding Still") {
    OnboardingStillSceneView(
        backgroundImageName: "OnboardingSea",
        narrationResource: "onboarding1",
        onComplete: {}
    )
}

#Preview("Onboarding 4 Outro") {
    OnboardingStillSceneView(
        backgroundImageName: "OnboardingSea",
        narrationResource: "onboarding4",
        shipOverlay: .outroCelebration,
        onComplete: {}
    )
}
