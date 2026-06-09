import SwiftUI

/// Sea voyage intro: ship sails to the pier, celebrates, clouds gather, then hands off to the villain cinematic.
struct ShipOnboardingSceneView: View {
    let onComplete: () -> Void

    private static let cloudSkyColor = Color(red: 0.55, green: 0.78, blue: 0.95)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var sailProgress: CGFloat = 0
    @State private var shipBob: CGFloat = 0
    @State private var currentShipImage = "ShipSailing"

    @State private var leftCornerCloudEnter: CGFloat = 0
    @State private var rightCornerCloudEnter: CGFloat = 0
    @State private var coverCloudEnter: CGFloat = 0
    @State private var curtainCloudExit: CGFloat = 0

    /// Top-left open sea → knee across the water → pier (bottom-right).
    private static let sailStart = CGPoint(x: 0.04, y: 0.14)
    private static let sailKnee = CGPoint(x: 0.66, y: 0.30)
    private static let sailEnd = CGPoint(x: 0.78, y: 0.68)
    private static let sailKneeProgress: CGFloat = 0.50

    private let happyJumpCycle = ["ShipHappy", "ShipJump1", "ShipJump2", "ShipJump3"]
    private let sadFrames = ["ShipSad1", "ShipSad2", "ShipSad3", "ShipSad4"]

    private let cornerCloudOpacityScale: CGFloat = 0.70
    private let cornerCloudSizeScale: CGFloat = 0.66
    private let cornerCloudSpreadScale: CGFloat = 0.58

    /// Shared canvas aspect for every ship frame (1448×1086 px assets).
    private static let shipAspectRatio: CGFloat = 1086.0 / 1448.0
    private let shipWidthScale: CGFloat = 0.54
    private var timingScale: TimeInterval { OnboardingScripts.shipTimingScale }

    var body: some View {
        GeometryReader { proxy in
            let shipWidth = min(proxy.size.width, proxy.size.height) * shipWidthScale
            let shipHeight = shipWidth * Self.shipAspectRatio

            ZStack {
                Image("OnboardingSea")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()

                shipLayer(width: shipWidth, height: shipHeight, in: proxy.size)

                CloudTransitionOverlay(
                    enterProgress: leftCornerCloudEnter,
                    exitProgress: curtainCloudExit,
                    entrySideFilter: .fromLeft,
                    anchorYMax: 0.36,
                    opacityScale: cornerCloudOpacityScale,
                    cloudSizeScale: cornerCloudSizeScale,
                    entrySpreadScale: cornerCloudSpreadScale
                )

                CloudTransitionOverlay(
                    enterProgress: rightCornerCloudEnter,
                    exitProgress: curtainCloudExit,
                    entrySideFilter: .fromRight,
                    anchorYMax: 0.36,
                    opacityScale: cornerCloudOpacityScale,
                    cloudSizeScale: cornerCloudSizeScale,
                    entrySpreadScale: cornerCloudSpreadScale
                )

                CloudTransitionOverlay(
                    enterProgress: coverCloudEnter,
                    exitProgress: curtainCloudExit
                )
            }
        }
        .ignoresSafeArea()
        .background(Self.cloudSkyColor)
        .task {
            await runSequence()
        }
    }

    @ViewBuilder
    private func shipLayer(width: CGFloat, height: CGFloat, in size: CGSize) -> some View {
        let position = Self.positionAlongCurvedLPath(progress: sailProgress)

        Image(currentShipImage)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: width, height: height)
            .position(
                x: position.x * size.width,
                y: (position.y + shipBob) * size.height
            )
            .animation(nil, value: currentShipImage)
    }

    /// L-shaped route with a soft bend: sail right across the sea, then down toward the pier.
    private static func positionAlongCurvedLPath(progress: CGFloat) -> CGPoint {
        let t = min(max(progress, 0), 1)

        if t <= sailKneeProgress {
            let u = t / sailKneeProgress
            let x = sailStart.x + (sailKnee.x - sailStart.x) * u
            let y = sailStart.y + (sailKnee.y - sailStart.y) * u
            let arc = sin(u * .pi) * 0.018
            return CGPoint(x: x, y: y - arc)
        }

        let u = (t - sailKneeProgress) / (1 - sailKneeProgress)
        let x = sailKnee.x + (sailEnd.x - sailKnee.x) * u
        let y = sailKnee.y + (sailEnd.y - sailKnee.y) * u
        let arc = sin(u * .pi) * 0.014
        return CGPoint(x: x + arc, y: y)
    }

    @MainActor
    private func runSequence() async {
        if reduceMotion {
            await runReducedMotionSequence()
            return
        }

        currentShipImage = "ShipSailing"
        sailProgress = 0

        // 1. Sail from the top-left along a curved L path toward the pier.
        let sailDuration = scaled(4.4)
        animate(duration: sailDuration) {
            sailProgress = 1
        }
        await runBobbing(duration: sailDuration, amplitude: 0.012)
        try? await Task.sleep(nanoseconds: UInt64(scaled(0.20) * 1_000_000_000))

        // 2. Happy + jump loop twice.
        await playHappyJumpLoop(times: 2)

        // 3. A few clouds peek in from the top corners.
        let cornerCloudDuration = scaled(1.1)
        animate(duration: cornerCloudDuration) {
            leftCornerCloudEnter = 0.50
            rightCornerCloudEnter = 0.50
        }
        try? await Task.sleep(nanoseconds: UInt64(cornerCloudDuration * 1_000_000_000))

        // 4. Sad loop twice.
        await playSadLoop(times: 2)

        // 5. Full cloud curtain closes the screen.
        animate(duration: CloudTransitionAnimator.enterDuration) {
            coverCloudEnter = 1
            leftCornerCloudEnter = 0.72
            rightCornerCloudEnter = 0.72
        }
        try? await Task.sleep(nanoseconds: UInt64(CloudTransitionAnimator.enterDuration * 1_000_000_000))

        try? await Task.sleep(nanoseconds: UInt64(CloudTransitionAnimator.holdAfterSceneChange * 1_000_000_000))

        await OnboardingNarrationPlayer.shared.waitUntilFinished()

        // Hand off to the villain scene while the screen stays fully covered.
        onComplete()
    }

    @MainActor
    private func runReducedMotionSequence() async {
        animate(duration: 0.2) {
            sailProgress = 1
            coverCloudEnter = 1
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        onComplete()
    }

    @MainActor
    private func playHappyJumpLoop(times: Int) async {
        for _ in 0..<times {
            for (index, imageName) in happyJumpCycle.enumerated() {
                currentShipImage = imageName
                let frameDuration: TimeInterval = scaled(index == 0 ? 0.38 : 0.17)
                try? await Task.sleep(nanoseconds: UInt64(frameDuration * 1_000_000_000))
            }
        }
    }

    @MainActor
    private func playSadLoop(times: Int) async {
        for _ in 0..<times {
            for imageName in sadFrames {
                currentShipImage = imageName
                try? await Task.sleep(nanoseconds: UInt64(scaled(0.22) * 1_000_000_000))
            }
        }
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

    @MainActor
    private func animate(duration: TimeInterval, _ updates: () -> Void) {
        withAnimation(.easeInOut(duration: duration), updates)
    }

    private func scaled(_ duration: TimeInterval) -> TimeInterval {
        duration * timingScale
    }
}

#Preview("Ship Onboarding") {
    ShipOnboardingSceneView(onComplete: {})
}
