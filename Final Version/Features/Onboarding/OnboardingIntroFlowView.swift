import SwiftUI

/// Four-beat onboarding: intro still → ship → villain → outro still → main menu.
struct OnboardingIntroFlowView: View {
    let onFinish: () -> Void

    private enum Phase: Int {
        case intro1 = 0
        case ship = 1
        case outro4 = 3
    }

    @Environment(LanguageManager.self) private var lm

    @State private var phase: Phase = .intro1
    @State private var showsVillainScene = false
    @State private var hidesShipScene = false
    @State private var narratorScriptIndex = 0
    @State private var showsNarratorBar = true
    @State private var narrationTask: Task<Void, Never>?
    @State private var sceneSessionID = 0

    private enum ActiveScene: Int {
        case harbor = 0
        case ship = 1
        case villain = 2
        case outro = 3
    }

    private var activeScene: ActiveScene {
        switch phase {
        case .intro1:
            return .harbor
        case .ship:
            return showsVillainScene ? .villain : .ship
        case .outro4:
            return .outro
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let narratorWidth = min(proxy.size.width - 32, 920)

            ZStack {
                switch phase {
                case .intro1:
                    Onboarding1HarborSceneView {
                        advance(to: .ship)
                    }
                    .id("onboarding-harbor-\(sceneSessionID)")

                case .ship:
                    if !hidesShipScene {
                        ShipOnboardingSceneView(
                            onComplete: {
                                advanceToVillain()
                            },
                            startsUnderCloudCover: true,
                            onNarrationStart: {
                                playNarration(at: 1)
                            }
                        )
                        .id("onboarding-ship-\(sceneSessionID)")
                        .opacity(showsVillainScene ? 0 : 1)
                        .allowsHitTesting(!showsVillainScene)
                    }

                    if showsVillainScene {
                        VillainOnboardingCinematicView(
                            onFinish: {},
                            startsUnderCloudCover: true,
                            narratorScriptIndex: $narratorScriptIndex,
                            showsNarratorBar: $showsNarratorBar,
                            onHandoffCurtainOpened: {
                                hidesShipScene = true
                            },
                            onNarrationStart: {
                                playNarration(at: 2)
                            },
                            onSceneComplete: {
                                advanceToOutro()
                            }
                        )
                        .id("onboarding-villain-\(sceneSessionID)")
                    }

                case .outro4:
                    OnboardingStillSceneView(
                        backgroundImageName: "OnboardingSea",
                        narrationResource: "onboarding4",
                        startsUnderCloudCover: true,
                        shipOverlay: .outroCelebration
                    ) {
                        finishOnboarding()
                    }
                    .id("onboarding-outro-\(sceneSessionID)")
                }
            }
            .overlay(alignment: .topTrailing) {
                onboardingSkipSceneButton
                    .padding(.top, max(52, proxy.safeAreaInsets.top + 12))
                    .padding(.trailing, max(20, proxy.safeAreaInsets.trailing + 12))
                    .zIndex(120)
            }
            .overlay(alignment: .bottom) {
                if showsNarratorBar {
                    NarratorScriptBar(
                        message: lm.t(OnboardingScripts.bodyKeys[narratorScriptIndex]),
                        maxWidth: narratorWidth,
                        narrationResource: OnboardingScripts.audioResources[narratorScriptIndex],
                        narrationDuration: OnboardingScripts.audioDurations[narratorScriptIndex]
                    )
                    .padding(.horizontal, max(16, proxy.safeAreaInsets.leading + 12))
                    .padding(.bottom, max(20, proxy.safeAreaInsets.bottom + 14))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.35), value: showsNarratorBar)
            .animation(.easeInOut(duration: 0.25), value: narratorScriptIndex)
        }
        .ignoresSafeArea()
        .onAppear {
            BackgroundMusicPlayer.shared.startOnboardingMusic()
            narratorScriptIndex = Phase.intro1.rawValue
        }
        .onDisappear {
            narrationTask?.cancel()
            OnboardingNarrationPlayer.shared.stop()
            BackgroundMusicPlayer.shared.endOnboardingMusic()
        }
    }

    private var onboardingSkipSceneButton: some View {
        GamePillButton(
            title: lm.t("onboarding.skip"),
            fontSize: GameButtonMetrics.pillFontSize,
            horizontalPadding: GameButtonMetrics.pillHorizontalPadding,
            verticalPadding: GameButtonMetrics.pillVerticalPadding,
            minWidth: GameButtonMetrics.isPad ? 148 : 112,
            minHeight: GameButtonMetrics.pillMinHeight(atLeast: GameButtonMetrics.isPad ? 56 : 52),
            trailingIcon: "forward.fill",
            accessibilityHint: lm.t("a11y.onboarding_skip_scene_hint"),
            action: skipToNextScene
        )
        .accessibilityLabel(lm.t("onboarding.skip"))
    }

    private func skipToNextScene() {
        AppSettings.hapticImpact(.light)
        narrationTask?.cancel()
        OnboardingNarrationPlayer.shared.stop()
        sceneSessionID += 1

        switch activeScene {
        case .harbor:
            advance(to: .ship)
        case .ship:
            hidesShipScene = true
            narratorScriptIndex = 2
            showsVillainScene = true
        case .villain:
            showsVillainScene = false
            hidesShipScene = true
            advanceToOutro()
        case .outro:
            finishOnboarding()
        }
    }

    private func advance(to next: Phase) {
        narrationTask?.cancel()
        OnboardingNarrationPlayer.shared.stop()
        narratorScriptIndex = next.rawValue
        phase = next
    }

    private func advanceToVillain() {
        narratorScriptIndex = 2
        showsVillainScene = true
    }

    private func advanceToOutro() {
        narratorScriptIndex = 3
        showsNarratorBar = true
        showsVillainScene = false
        hidesShipScene = true
        phase = .outro4
    }

    private func finishOnboarding() {
        narrationTask?.cancel()
        OnboardingNarrationPlayer.shared.stop()
        showsNarratorBar = false
        onFinish()
    }

    private func playNarration(at index: Int) {
        guard OnboardingScripts.audioResources.indices.contains(index) else { return }
        let resource = OnboardingScripts.audioResources[index]
        narrationTask?.cancel()
        OnboardingNarrationPlayer.shared.play(named: resource)
    }
}

enum OnboardingScripts {
    static let brightCloudImageName = "cloud"
    static let stormCloudImageName = "cloudBlack"
    /// Default storm clouds for onboarding scenes 2→4 and the villain.
    static let cloudImageName = stormCloudImageName

    static let bodyKeys = [
        "onboarding.page1.body",
        "onboarding.page2.body",
        "onboarding.page3.body",
        "onboarding.page4.body"
    ]

    static let audioResources = [
        "onboarding1",
        "onboarding2",
        "onboarding3",
        "onboarding4"
    ]

    /// Measured narration lengths — scenes pace themselves to these targets.
    static let audioDurations: [TimeInterval] = [8.99, 10.14, 15.90, 7.29]

    /// Slows ship beats so the cinematic matches `onboarding2.wav`.
    static let shipTimingScale: TimeInterval = 1.24

    /// Post-curtain villain beat length (seconds) before `villainTimingScale` is applied.
    private static let villainBeatDuration: TimeInterval = 13.26

    /// Slows villain beats so the cinematic matches `onboarding3.wav`.
    static let villainTimingScale: TimeInterval = {
        let target = audioDurations[2]
        return target / villainBeatDuration * 1.25
    }()
}

#Preview("Onboarding Intro Flow") {
    OnboardingIntroFlowView(onFinish: {})
        .environment(LanguageManager())
}
