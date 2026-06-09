import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasSeenTutorial")   private var hasSeenTutorial   = false
    @AppStorage("differentiate") private var differentiate = false
    @Environment(AppFontSettings.self) private var fontSettings

    @State private var gameStarted = false
    @State private var menuCloudEnterProgress: CGFloat = 1
    @State private var menuCloudExitProgress: CGFloat = 0
    @State private var cloudEnterProgress: CGFloat = 0
    @State private var cloudExitProgress: CGFloat = 0
    @State private var isTransitioning = false
    @State private var menuPanelResetID = 0

    private var showsGlobalCloudOverlay: Bool {
        isTransitioning || cloudEnterProgress > 0.01 || cloudExitProgress > 0.01
    }

    private var shouldDeferMainMenuPanelReveal: Bool {
        AppFeatureFlags.showsOnboarding && !hasSeenOnboarding
    }

    var body: some View {
        let usesDyslexiaFont = fontSettings.dyslexiaFontEnabled

        ZStack {
            if gameStarted {
                ContentView(isGlobalTransitioning: isTransitioning)
            }

            if !gameStarted {
                MainMenuSceneView(
                    cloudEnterProgress: $menuCloudEnterProgress,
                    cloudExitProgress: $menuCloudExitProgress
                )
            }

            if showsGlobalCloudOverlay {
                CloudTransitionOverlay(
                    enterProgress: cloudEnterProgress,
                    exitProgress: cloudExitProgress
                )
                .ignoresSafeArea()
                .allowsHitTesting(isTransitioning)
                .zIndex(50)
            }

            if !gameStarted {
                MainMenuPanelLayer(
                    isTransitioning: isTransitioning,
                    resetID: menuPanelResetID,
                    deferPanelReveal: shouldDeferMainMenuPanelReveal,
                    onPlay: {
                        Task { await beginGame() }
                    }
                )
                .zIndex(60)
            }

            // Tutorial: primo accesso al gioco
            if gameStarted && !hasSeenTutorial {
                TutorialOverlayView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        hasSeenTutorial = true
                    }
                }
                .zIndex(70)
                .transition(.opacity)
            }

            // Onboarding: primo avvio assoluto
            if AppFeatureFlags.showsOnboarding && !hasSeenOnboarding {
                Group {
                    if AppFeatureFlags.usesVillainOnboardingCinematic {
                        OnboardingIntroFlowView {
                            Task { await completeVillainOnboarding() }
                        }
                    } else {
                        OnboardingView {
                            Task { await completeOnboarding() }
                        }
                    }
                }
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .differentiate(differentiate)
        .font(Font.custom(
            AppTypography.fontName(for: .regular, dyslexiaEnabled: usesDyslexiaFont),
            size: 17,
            relativeTo: .body
        ))
        .environment(\.dyslexiaFontEnabled, usesDyslexiaFont)
        .onAppear {
            if !AppFeatureFlags.showsOnboarding {
                hasSeenOnboarding = true
            }
            if !(AppFeatureFlags.showsOnboarding && !hasSeenOnboarding) {
                BackgroundMusicPlayer.shared.start()
            }
        }
        .onChange(of: hasSeenOnboarding) { _, seen in
            if seen {
                BackgroundMusicPlayer.shared.start()
            }
        }
    }

    @MainActor
    private func completeOnboarding() async {
        withAnimation(.easeInOut(duration: 0.35)) {
            hasSeenOnboarding = true
        }

        await CloudTransitionAnimator.runCurtainOpen(
            exitProgress: $menuCloudExitProgress,
            duration: CloudTransitionAnimator.playOpenDuration
        ) {}

        menuCloudExitProgress = 0
    }

    @MainActor
    private func completeVillainOnboarding() async {
        withAnimation(.easeInOut(duration: 0.35)) {
            hasSeenOnboarding = true
        }

        menuCloudEnterProgress = 1
        menuCloudExitProgress = 0

        await CloudTransitionAnimator.runCurtainOpen(
            exitProgress: $menuCloudExitProgress,
            duration: CloudTransitionAnimator.playOpenDuration
        ) {}

        menuCloudExitProgress = 0
    }

    /// Play: sipario già presente → si apre (0.8s) → gioco.
    @MainActor
    private func beginGame() async {
        guard !isTransitioning else { return }
        isTransitioning = true
        menuCloudEnterProgress = 1
        menuCloudExitProgress = 0

        await CloudTransitionAnimator.runCurtainOpen(
            exitProgress: $menuCloudExitProgress,
            duration: CloudTransitionAnimator.playOpenDuration
        ) {
            gameStarted = true
        }

        menuCloudExitProgress = 0
        isTransitioning = false
    }
}


