import CoreGraphics

/// Layout constants shared between `SequencingActivityView` and level chrome (`ContentView`).
///
/// **Come provare le modifiche**
/// 1. Salva questo file e premi **⌘R** (non basta il canvas Preview).
/// 2. Entra in un capitolo, finisci il dialogo intro, poi guarda il **gioco sequenza**.
/// 3. Durante il solo dialogo i bottoni in alto sono nascosti: non è il layout sequenza.
///
/// **Orizzontale**
/// - `sequenceSlotsInsetFromStage` → carte sequenza verso centro o bordi.
/// - `chromeButtonInsetFromStage` → solo Indietro / Impostazioni.
///
/// **Verticale**
/// - `storybookSlotsTopPad` / `storybookSlotsBottomPad` → carte sequenza su/giù nello storybook.
/// - `chromeButtonTopInsetFromStage` → Indietro / Impostazioni su/giù (dall’alto dello stage).
/// - `stageStorybookTopPad` / `stageDeckBottomPad` → alza/abbassa storybook e deck nello stage.
enum SequencingLayoutMetrics {
    static let stageAspectRatio: CGFloat = 4.0 / 3.0

    // MARK: - Orizzontale

    /// Margine del pannello storybook rispetto allo stage (non cambia il gap bottoni ↔ carte).
    static let stageHorizontalPad: CGFloat = 28

    /// Bordo sinistro/destro dello **stage** → fila slot sequenza (per lato).
    static let sequenceSlotsInsetFromStage: CGFloat = 106

    /// Bordo sinistro/destro dello **stage** → centro bottoni Indietro / Impostazioni.
    static let chromeButtonInsetFromStage: CGFloat = 60

    // MARK: - Verticale

    /// Spazio tra l’alto dello **stage** e il bordo superiore dello storybook.
    static let stageStorybookTopPad: CGFloat = 18

    /// Spazio tra il bordo inferiore dello **stage** e il deck.
    static let stageDeckBottomPad: CGFloat = 18

    /// Distanza dall’alto dello **stage** al centro dei bottoni chrome (Indietro / Impostazioni).
    static let chromeButtonTopInsetFromStage: CGFloat = 90

    /// Spazio sopra / sotto la fila slot **dentro** lo storybook.
    static let storybookSlotsTopPad: CGFloat = 42
    static let storybookSlotsBottomPad: CGFloat = 34

    // MARK: - Derivati

    static var storybookSlotsHorizontalPad: CGFloat {
        max(0, sequenceSlotsInsetFromStage - stageHorizontalPad)
    }

    static var levelChromeHorizontalInset: CGFloat {
        chromeButtonInsetFromStage
    }

    static func stageSize(in container: CGSize) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }

        let containerAspectRatio = container.width / container.height
        if containerAspectRatio > stageAspectRatio {
            let height = container.height
            return CGSize(width: height * stageAspectRatio, height: height)
        }

        let width = container.width
        return CGSize(width: width, height: width / stageAspectRatio)
    }

    /// Top padding (schermo) per allineare i cerchi chrome a `chromeButtonTopInsetFromStage`.
    static func levelChromeTopPadding(screenSize: CGSize, chromeButtonSize: CGFloat) -> CGFloat {
        let stage = stageSize(in: screenSize)
        let letterboxTop = max((screenSize.height - stage.height) / 2, 0)
        let targetCenterY = letterboxTop + chromeButtonTopInsetFromStage
        return targetCenterY - chromeButtonSize * 0.5
    }
}
