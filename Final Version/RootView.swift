import SwiftUI

struct RootView: View {
    @State private var gameStarted = false
    @State private var cloudEnterProgress: CGFloat = 0
    @State private var cloudExitProgress: CGFloat = 0
    @State private var isTransitioning = false

    private var showsCloudOverlay: Bool {
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
                MainMenuView {
                    Task { await beginGame() }
                }
            }

            if showsCloudOverlay {
                CloudTransitionOverlay(
                    enterProgress: cloudEnterProgress,
                    exitProgress: cloudExitProgress
                )
                .ignoresSafeArea()
                .allowsHitTesting(isTransitioning)
                .zIndex(100)
            }
        }
    }

    @MainActor
    private func beginGame() async {
        guard !isTransitioning else { return }

        await CloudTransitionAnimator.runSceneTransition(
            isActive: $isTransitioning,
            enterProgress: $cloudEnterProgress,
            exitProgress: $cloudExitProgress
        ) {
            gameStarted = true
        }
    }

    @MainActor
    private func returnToMainMenu() async {
        guard !isTransitioning, gameStarted else { return }

        await CloudTransitionAnimator.runSceneTransition(
            isActive: $isTransitioning,
            enterProgress: $cloudEnterProgress,
            exitProgress: $cloudExitProgress
        ) {
            gameStarted = false
        }
    }
}
