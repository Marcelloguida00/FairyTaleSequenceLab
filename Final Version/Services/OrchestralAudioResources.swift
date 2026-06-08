import Foundation

/// Bundled orchestral assets in `Resources/Audio/`.
/// Replace the WAV files in Xcode to update sounds without code changes.
enum OrchestralAudioResources {
    static let backgroundMusic = "musicaorchestrale"
    static let victoryJingle = "JINGLE orchestrale FINALE"

    static func flipCard(alternate: Bool) -> String {
        alternate ? "FLIP CARTA 2" : "FLIP CARTA 1"
    }

    static func pickNote(step: Int) -> String {
        "PICK NOTA \(step)"
    }

    static func correctResponse(step: Int) -> String {
        "RISP GIUSTA \(step)"
    }

    static func wrongResponse(cycle: Int) -> String {
        "RISP ERRATA \(cycle)"
    }
}
