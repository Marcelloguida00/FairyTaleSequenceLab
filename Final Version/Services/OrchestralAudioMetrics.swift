import AVFoundation
import Foundation

/// Reads bundled orchestral WAV durations so animations stay in sync with replaced assets.
enum OrchestralAudioMetrics {
    private static var cache: [String: TimeInterval] = [:]

    static var correctClipDuration: TimeInterval {
        duration(named: "OrchestralCorrect_1", fallback: 2.0)
    }

    static var wrongClipDuration: TimeInterval {
        duration(named: "OrchestralWrong_1", fallback: 2.0)
    }

    static var pickLoopDuration: TimeInterval {
        duration(named: "OrchestralPick_1", fallback: 2.0)
    }

    static var victoryJingleDuration: TimeInterval {
        duration(named: "OrchestralVictory_Jingle", fallback: 5.0)
    }

    static var simplifiedVictoryJingleDuration: TimeInterval {
        duration(named: "SequencingVictory_Jingle", fallback: 2.8)
    }

    static var simplifiedCorrectNoteDuration: TimeInterval {
        duration(named: "PianoNote_DoHigh", fallback: 0.82)
    }

    static func duration(named resource: String, fallback: TimeInterval) -> TimeInterval {
        if let cached = cache[resource] {
            return cached
        }

        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav")
            ?? Bundle.main.url(forResource: resource, withExtension: "wav", subdirectory: "Resources/Audio"),
              let player = try? AVAudioPlayer(contentsOf: url),
              player.duration > 0 else {
            return fallback
        }

        cache[resource] = player.duration
        return player.duration
    }
}
