enum CloudTransitionAnimator {
    /// Apertura sipario dal Main Menu (solo uscita nuvole).
    static let playOpenDuration: TimeInterval = 0.8

    // Timeline (totale ~2.55s):
    // 0.0s        → overlay attivo
    // 0.0–1.05s   → nuvole entrano e coprono (più lento)
    // 1.05s       → cambio scena (schermo coperto)
    // 1.05–1.40s  → pausa
    // 1.40–2.55s  → nuvole escono (sx/dx) + fade-out
    // 2.55s       → overlay rimosso

    static let enterDuration: TimeInterval = 1.05
    static let holdAfterSceneChange: TimeInterval = 0.35
    static let exitDuration: TimeInterval = 1.15
    static let totalDuration: TimeInterval = enterDuration + holdAfterSceneChange + exitDuration

    /// Main Menu → gioco: nuvole già visibili, solo apertura + fade.
    @MainActor
    static func runCurtainOpen(
        exitProgress: Binding<CGFloat>,
        duration: TimeInterval? = nil,
        whenOpen: () async -> Void
    ) async {
        let actualDuration = duration ?? playOpenDuration
        exitProgress.wrappedValue = 0

        withAnimation(.easeInOut(duration: actualDuration)) {
            exitProgress.wrappedValue = 1
        }
