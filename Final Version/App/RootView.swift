import SwiftUI

struct RootView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasSeenTutorial")   private var hasSeenTutorial   = false

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

    var body: some View {
        ZStack {
            if gameStarted {
                ContentView(
                    isGlobalTransitioning: isTransitioning,
                    onReturnToMainMenu: {
                        Task { await returnToMainMenu() }
                    }
                )
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
            if !hasSeenOnboarding {
                OnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        hasSeenOnboarding = true
                    }
                }
                .zIndex(100)
                .transition(.opacity)
            }
        }
        .onAppear {
            BackgroundMusicPlayer.shared.start()
        }
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

    /// Menu: nuvole coprono il gioco → passaggio al menu (senza seconda ondata di uscita).
    @MainActor
    private func returnToMainMenu() async {
        guard !isTransitioning, gameStarted else { return }

        isTransitioning = true
        menuCloudExitProgress = 0

        await CloudTransitionAnimator.runCoverTransition(
            isActive: $isTransitioning,
            enterProgress: $cloudEnterProgress,
            whenCovered: {
                menuCloudEnterProgress = 1
                menuPanelResetID += 1
                gameStarted = false
            }
        )
    }
}
