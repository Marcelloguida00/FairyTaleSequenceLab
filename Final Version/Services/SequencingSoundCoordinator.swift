import Foundation

/// Routes sequencing gameplay sounds to simplified piano notes or orchestral mode.
@MainActor
enum SequencingSoundCoordinator {
    static func resetSession() {
        OrchestralSequencingPlayer.shared.resetSession()
    }

    static func cardPickupStarted(correctPlacements: Int) {
        switch SequencingSFXMode.current {
        case .simplified:
            PianoChordPlayer.shared.playCardPickupNote()
        case .orchestral:
            let step = min(correctPlacements + 1, 4)
            OrchestralSequencingPlayer.shared.startPickLoop(step: step)
        }
    }

    static func cardPickupEnded() {
        guard SequencingSFXMode.current == .orchestral else { return }
        OrchestralSequencingPlayer.shared.stopPickLoop()
    }

    static func correctPlacement(slot: Int, correctPlacementsAfter: Int) {
        switch SequencingSFXMode.current {
        case .simplified:
            PianoChordPlayer.shared.playPlacementTone(.correct(slot: slot))
        case .orchestral:
            OrchestralSequencingPlayer.shared.playCorrect(step: min(correctPlacementsAfter, 4))
        }
    }

    static func incorrectPlacement() {
        switch SequencingSFXMode.current {
        case .simplified:
            PianoChordPlayer.shared.playPlacementTone(.incorrect)
        case .orchestral:
            OrchestralSequencingPlayer.shared.stopPickLoop()
            OrchestralSequencingPlayer.shared.playWrong()
        }
    }

    static func victoryJingle() {
        switch SequencingSFXMode.current {
        case .simplified:
            PianoChordPlayer.shared.playPlacementTone(.victoryJingle)
        case .orchestral:
            OrchestralSequencingPlayer.shared.playVictoryJingle()
        }
    }
}
