import SwiftUI

/// Onboarding 1: ship sails to center, happy beats, exit right, then full cloud handoff to onboarding 2.
struct Onboarding1HarborSceneView: View {
    let onComplete: () -> Void

    private static let cloudSkyColor = Color(red: 0.55, green: 0.78, blue: 0.95)
    private static let shipAspectRatio: CGFloat = 1086.0 / 1448.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var shipX: CGFloat = -0.10
    @State private var shipY: CGFloat = 0.50
    @State private var shipBob: CGFloat = 0
    @State private var currentShipImage = "ShipSailing"

    @State private var coverCloudEnter: CGFloat = 0

    private let dockCenterX: CGFloat = 0.50
    private let dockCenterY: CGFloat = 0.50
    private let shipWidthScale: CGFloat = 0.54

    private let happyJumpCycle = ["ShipHappy", "ShipJump1", "ShipJump2", "ShipJump3"]

    private var timingScale: TimeInterval { OnboardingScripts.shipTimingScale }

    var body: some View {
        GeometryReader { proxy in
            let shipWidth = min(proxy.size.width, proxy.size.height) * shipWidthScale
            let shipHeight = shipWidth * Self.shipAspectRatio

            ZStack {
                Image("OnboardingHarbor")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                shipLayer(width: shipWidth, height: shipHeight, in: proxy.size)

                CloudTransitionOverlay(
                    enterProgress: coverCloudEnter,
                    exitProgress: 0,
                    cloudImageName: OnboardingScripts.brightCloudImageName
                )
            }
        }
        .ignoresSafeArea()
        .background(Self.cloudSkyColor)
        .task {
            OnboardingNarrationPlayer.shared.play(named: OnboardingScripts.audioResources[0])
            await runSequence()
        }
    }

    @ViewBuilder
    private func shipLayer(width: CGFloat, height: CGFloat, in size: CGSize) -> some View {
        Image(currentShipImage)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)
            .position(
                x: shipX * size.width,
                y: (shipY + shipBob) * size.height
            )
            .animation(nil, value: currentShipImage)
    }

    @MainActor
    private func runSequence() async {
        if reduceMotion {
            shipX = dockCenterX
            shipY = dockCenterY
            coverCloudEnter = 1
            try? await Task.sleep(nanoseconds: 400_000_000)
            await OnboardingNarrationPlayer.shared.waitUntilFinished()
            if !Task.isCancelled { onComplete() }
            return
        }

        currentShipImage = "ShipSailing"
        shipX = -0.10
        shipY = dockCenterY
        // 1. Sail in from the left and settle at center (slower bob, gentle settle).
        let approachDuration = scaled(3.8)
        withAnimation(.easeOut(duration: approachDuration)) {
            shipX = dockCenterX
            shipY = dockCenterY + 0.012
        }
        await runLandingBobbing(duration: approachDuration)
        withAnimation(.easeInOut(duration: scaled(0.35))) {
            shipY = dockCenterY
        }
        try? await Task.sleep(nanoseconds: UInt64(scaled(0.35) * 1_000_000_000))

        // 2. Happy + jump loop twice (same beats as onboarding 2, without sad).
        await playHappyJumpLoop(times: 2)

        // 3. Ship sails away to the right.
        currentShipImage = "ShipSailing"
        let exitDuration = scaled(2.4)
        withAnimation(.easeIn(duration: exitDuration)) {
            shipX = 1.14
            shipY = dockCenterY - 0.01
        }
        await runBobbing(duration: exitDuration, amplitude: 0.008)
        try? await Task.sleep(nanoseconds: UInt64(scaled(0.15) * 1_000_000_000))

        // 4. Full cloud curtain closes before onboarding 2.
        withAnimation(.easeInOut(duration: CloudTransitionAnimator.enterDuration)) {
            coverCloudEnter = 1
        }
        try? await Task.sleep(nanoseconds: UInt64(CloudTransitionAnimator.enterDuration * 1_000_000_000))
        try? await Task.sleep(nanoseconds: UInt64(CloudTransitionAnimator.holdAfterSceneChange * 1_000_000_000))

        await OnboardingNarrationPlayer.shared.waitUntilFinished()
        if !Task.isCancelled { onComplete() }
    }

    @MainActor
    private func playHappyJumpLoop(times: Int) async {
        for _ in 0..<times {
            for (index, imageName) in happyJumpCycle.enumerated() {
                currentShipImage = imageName
                let frameDuration = scaled(index == 0 ? 0.38 : 0.17)
                try? await Task.sleep(nanoseconds: UInt64(frameDuration * 1_000_000_000))
            }
        }
    }

    @MainActor
    private func runLandingBobbing(duration: TimeInterval) async {
        let steps = max(1, Int(duration / 0.08))
        let stepNanos = UInt64((duration / Double(steps)) * 1_000_000_000)

        for step in 0..<steps {
            let progress = CGFloat(step) / CGFloat(max(steps - 1, 1))
            let amplitude = 0.016 * (1 - progress)
            let phase = CGFloat(step) / CGFloat(steps) * .pi * 5
            shipBob = sin(phase) * amplitude
            try? await Task.sleep(nanoseconds: stepNanos)
        }
        shipBob = 0
    }

    @MainActor
    private func runBobbing(duration: TimeInterval, amplitude: CGFloat) async {
        let steps = max(1, Int(duration / 0.08))
        let stepNanos = UInt64((duration / Double(steps)) * 1_000_000_000)

        for step in 0..<steps {
            let phase = CGFloat(step) / CGFloat(steps) * .pi * 4
            shipBob = sin(phase) * amplitude
            try? await Task.sleep(nanoseconds: stepNanos)
        }
        shipBob = 0
    }

    private func scaled(_ duration: TimeInterval) -> TimeInterval {
        duration * timingScale
    }
}

#Preview("Onboarding 1 Harbor") {
    Onboarding1HarborSceneView(onComplete: {})
}
