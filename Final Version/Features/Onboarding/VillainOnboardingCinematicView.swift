import SwiftUI

/// Cinematic first-launch intro: villain crosses the world map, casts a spell, clouds darken and cover the screen, then reveal the main menu.
struct VillainOnboardingCinematicView: View {
    let onFinish: () -> Void

    private static let cloudSkyColor = Color(red: 0.55, green: 0.78, blue: 0.95)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rightCloudEnter: CGFloat = 0
    @State private var rightCloudTrailEnter: CGFloat = 0
    @State private var leftCloudEnter: CGFloat = 0
    @State private var leftCloudTrailEnter: CGFloat = 0
    @State private var coverCloudEnter: CGFloat = 0
    @State private var villainCloudExit: CGFloat = 0
    @State private var showsOnboardingMap = true

    @State private var cloudTint: Color = .white
    @State private var cloudBrightness: CGFloat = 0
    @State private var cloudSaturation: CGFloat = 1
    @State private var skyDimming: CGFloat = 0

    @State private var villainX: CGFloat = 1.18
    @State private var villainY: CGFloat = 0.44
    @State private var villainPose: VillainPose = .flyIn
    @State private var spriteFrame = 0
    @State private var villainOpacity: CGFloat = 1

    private enum VillainPose {
        case flyIn
        case look
        case magicCast
        case laugh
        case magicDecast
        case flyOut
    }

    private let castingFrameNames = (0...11).map { "VillainDecasting\($0)" }
    private let laughFrameNames = (1...5).map { "VillainRisata\($0)" }
    private let magicFrameDuration: TimeInterval = 0.09
    private let laughFrameDuration: TimeInterval = 0.22

    private let sideTrailOpacityScale: CGFloat = 1.14
    private let sideTrailCloudSizeScale: CGFloat = 1.08
    private let sideTrailEntrySpreadScale: CGFloat = 0.86
    private let sideMainOpacityScale: CGFloat = 1.04
    private let sideMainCloudSizeScale: CGFloat = 1.02

    var body: some View {
        GeometryReader { proxy in
            let villainWidth = min(proxy.size.width, proxy.size.height) * 0.46

            ZStack {
                Group {
                    Image("OnboardingWorldMap")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipped()

                    Color.black.opacity(skyDimming * 0.42)
                        .ignoresSafeArea()
                }
                .opacity(showsOnboardingMap ? 1 : 0)

                if !showsOnboardingMap, villainCloudExit < 0.01 {
                    Self.cloudSkyColor
                        .ignoresSafeArea()
                }

                Group {
                    CloudTransitionOverlay(
                        enterProgress: rightCloudTrailEnter,
                        exitProgress: villainCloudExit,
                        cloudTint: cloudTint,
                        cloudBrightness: cloudBrightness,
                        cloudSaturation: cloudSaturation,
                        entrySideFilter: .fromRightTrailing,
                        opacityScale: sideTrailOpacityScale,
                        cloudSizeScale: sideTrailCloudSizeScale,
                        entrySpreadScale: sideTrailEntrySpreadScale
                    )

                    CloudTransitionOverlay(
                        enterProgress: rightCloudEnter,
                        exitProgress: villainCloudExit,
                        cloudTint: cloudTint,
                        cloudBrightness: cloudBrightness,
                        cloudSaturation: cloudSaturation,
                        entrySideFilter: .fromRight,
                        opacityScale: sideMainOpacityScale,
                        cloudSizeScale: sideMainCloudSizeScale
                    )

                    CloudTransitionOverlay(
                        enterProgress: leftCloudTrailEnter,
                        exitProgress: villainCloudExit,
                        cloudTint: cloudTint,
                        cloudBrightness: cloudBrightness,
                        cloudSaturation: cloudSaturation,
                        entrySideFilter: .fromLeftTrailing,
                        opacityScale: sideTrailOpacityScale,
                        cloudSizeScale: sideTrailCloudSizeScale,
                        entrySpreadScale: sideTrailEntrySpreadScale
                    )

                    CloudTransitionOverlay(
                        enterProgress: leftCloudEnter,
                        exitProgress: villainCloudExit,
                        cloudTint: cloudTint,
                        cloudBrightness: cloudBrightness,
                        cloudSaturation: cloudSaturation,
                        entrySideFilter: .fromLeft,
                        opacityScale: sideMainOpacityScale,
                        cloudSizeScale: sideMainCloudSizeScale
                    )

                    CloudTransitionOverlay(
                        enterProgress: coverCloudEnter,
                        exitProgress: villainCloudExit,
                        cloudTint: cloudTint,
                        cloudBrightness: cloudBrightness,
                        cloudSaturation: cloudSaturation,
                        opacityScale: 1.08
                    )
                }
                .allowsHitTesting(false)
            }
            .overlay {
                villainLayer(size: villainWidth)
                    .position(
                        x: villainX * proxy.size.width,
                        y: villainY * proxy.size.height
                    )
                    .opacity(villainOpacity)
            }
        }
        .ignoresSafeArea()
        .background(cinematicBackdropColor)
        .accessibilityHidden(true)
        .task {
            await runSequence()
        }
    }

    @ViewBuilder
    private func villainLayer(size: CGFloat) -> some View {
        switch villainPose {
        case .flyIn:
            villainSprite(name: "VillainVolaInScena", size: size)
        case .look:
            villainSprite(name: "VillainGuardaSpettatore", size: size)
        case .magicCast, .magicDecast:
            villainSprite(name: castingFrameNames[spriteFrame], size: size)
        case .laugh:
            villainSprite(name: laughFrameNames[spriteFrame], size: size)
        case .flyOut:
            villainSprite(name: "VillainVolaInScena", size: size)
        }
    }

    private var cinematicBackdropColor: Color {
        if showsOnboardingMap {
            return .black
        }
        return villainCloudExit > 0.01 ? .clear : Self.cloudSkyColor
    }

    private func villainSprite(name: String, size: CGFloat) -> some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
    }

    @MainActor
    private func runSequence() async {
        if reduceMotion {
            await runReducedMotionSequence()
            return
        }

        // 1. Villain flies in from the right with a dense cloud trail.
        villainPose = .flyIn
        villainX = 1.18
        rightCloudTrailEnter = 0.12
        animate(duration: 2.1) {
            villainX = 0.52
            rightCloudTrailEnter = 0.78
            rightCloudEnter = 0.66
        }
        try? await Task.sleep(nanoseconds: 2_100_000_000)

        // 2. Faces the viewer at the map center.
        villainPose = .look
        animate(duration: 0.45) {
            villainX = 0.50
        }
        try? await Task.sleep(nanoseconds: 700_000_000)

        // 3. Casts the spell: frames 0 → 11.
        villainPose = .magicCast
        await playCastingFrames(forward: true)

        // 4. Laughs at the viewer: frames 1 → 5.
        villainPose = .laugh
        spriteFrame = 0
        await playLaughFrames()

        // 5. Clouds darken; left clouds join with the same density as the right.
        leftCloudTrailEnter = 0.12
        animate(duration: 1.1) {
            cloudTint = Color(white: 0.52)
            cloudBrightness = -0.38
            cloudSaturation = 0.22
            skyDimming = 0.55
            rightCloudTrailEnter = 0.84
            rightCloudEnter = 0.78
            leftCloudTrailEnter = 0.84
            leftCloudEnter = 0.78
        }
        try? await Task.sleep(nanoseconds: 1_100_000_000)

        // 6. Spell dissipates: frames 11 → 0.
        villainPose = .magicDecast
        await playCastingFrames(forward: false)

        // 7. Villain flies away while the screen fills with clouds.
        villainPose = .flyOut
        animate(duration: 1.35) {
            villainX = -0.28
            villainY = 0.36
            coverCloudEnter = 0.92
            leftCloudTrailEnter = 0.90
            leftCloudEnter = 0.86
            rightCloudTrailEnter = 0.90
            rightCloudEnter = 0.86
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        animate(duration: 0.35) {
            villainOpacity = 0
        }
        try? await Task.sleep(nanoseconds: 450_000_000)

        animate(duration: 0.55) {
            coverCloudEnter = 1
        }
        try? await Task.sleep(nanoseconds: 550_000_000)

        // 8. Villain clouds turn white again and hold.
        animate(duration: 0.75) {
            cloudTint = .white
            cloudBrightness = 0
            cloudSaturation = 1
            skyDimming = 0
        }
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        // 9. Main menu sits behind the menu clouds; hide only the onboarding map.
        showsOnboardingMap = false
        try? await Task.sleep(nanoseconds: 700_000_000)

        // 10. Open the villain curtain; main-menu background clouds stay fixed underneath.
        let curtainDuration = CloudTransitionAnimator.exitDuration
        animate(duration: curtainDuration) {
            villainCloudExit = 1
        }
        try? await Task.sleep(nanoseconds: UInt64(curtainDuration * 1_000_000_000))

        onFinish()
    }

    @MainActor
    private func runReducedMotionSequence() async {
        animate(duration: 0.2) {
            coverCloudEnter = 1
            cloudTint = .white
        }
        try? await Task.sleep(nanoseconds: 300_000_000)
        showsOnboardingMap = false
        villainCloudExit = 1
        onFinish()
    }

    @MainActor
    private func playCastingFrames(forward: Bool) async {
        let indices = forward ? Array(0...11) : Array((0...11).reversed())
        for index in indices {
            spriteFrame = index
            try? await Task.sleep(nanoseconds: UInt64(magicFrameDuration * 1_000_000_000))
        }
    }

    @MainActor
    private func playLaughFrames() async {
        for index in laughFrameNames.indices {
            spriteFrame = index
            try? await Task.sleep(nanoseconds: UInt64(laughFrameDuration * 1_000_000_000))
        }
    }

    @MainActor
    private func animate(duration: TimeInterval, _ updates: () -> Void) {
        withAnimation(.easeInOut(duration: duration), updates)
    }
}

#Preview("Villain Onboarding") {
    VillainOnboardingCinematicView(onFinish: {})
}
