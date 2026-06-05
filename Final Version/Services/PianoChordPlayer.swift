import AVFoundation
import Foundation

enum PianoChord: String {
    case cMajor = "PianoChord_CMajor"
}

/// Warm felt / upright acoustic piano notes for the fairy-tale card sequencing game.
/// Slot 0 → Do (C4), 1 → Mi (E4), 2 → Sol (G4), 3 → Do high (C5).
/// Pickup drag → Re (D4), same Do-major colour as the placement notes.
enum SequencingPianoNote: String {
    case do4 = "PianoNote_Do"
    case mi4 = "PianoNote_Mi"
    case sol4 = "PianoNote_Sol"
    case do5 = "PianoNote_DoHigh"
    case re4 = "PianoNote_Re"
    case grave = "PianoNote_Grave"
    case victoryJingle = "SequencingVictory_Jingle"

    static func forSlot(_ slot: Int) -> SequencingPianoNote? {
        switch slot {
        case 0: return .do4
        case 1: return .mi4
        case 2: return .sol4
        case 3: return .do5
        default: return nil
        }
    }
}

enum PlacementTone {
    /// Single warm felt-piano note mapped to the slot (Do / Mi / Sol / Do high).
    case correct(slot: Int)
    /// Soft low felt-piano note for a wrong placement.
    case incorrect
    /// Victory jingle: felt-piano arpeggio + held Do major + soft glockenspiel/flute.
    case victoryJingle
}

@MainActor
final class PianoChordPlayer {
    static let shared = PianoChordPlayer()

    private var players: [PianoChord: AVAudioPlayer] = [:]
    private var notePlayers: [String: AVAudioPlayer] = [:]

    private init() {}

    func play(_ chord: PianoChord) {
        playChord(chord, rate: 1.0, volumeScale: 1.0)
    }

    func playPlacementTone(_ tone: PlacementTone) {
        switch tone {
        case .correct(let slot):
            guard let note = SequencingPianoNote.forSlot(slot) else { return }
            playNote(note, volumeScale: 0.94)
        case .incorrect:
            playNote(.grave, volumeScale: 0.58)
        case .victoryJingle:
            playNote(.victoryJingle, volumeScale: 1.0)
        }
    }

    /// Re₄ (D4) — pickup note; harmonizes with Do₄ Mi₄ Sol₄ Do₅ in C major.
    func playCardPickupNote() {
        playNote(.re4, volumeScale: 0.86)
    }

    private func playChord(_ chord: PianoChord, rate: Float, volumeScale: Float) {
        guard AppAudioSettings.isMusicAudible else { return }

        let player = players[chord] ?? preparePlayer(named: chord.rawValue, cache: &players, key: chord)
        guard let player else { return }

        player.enableRate = true
        player.rate = min(max(rate, 0.75), 1.35)
        player.currentTime = 0
        player.volume = min(savedVolume * 1.25 * volumeScale, 1)
        player.play()
    }

    private func playNote(_ note: SequencingPianoNote, volumeScale: Float) {
        guard AppAudioSettings.isSequencingSFXAudible else { return }

        let player = notePlayers[note.rawValue] ?? preparePlayer(named: note.rawValue, cache: &notePlayers, key: note.rawValue)
        guard let player else { return }

        player.enableRate = false
        player.rate = 1.0
        player.currentTime = 0
        player.volume = min(savedVolume * 1.38 * volumeScale, 1)
        player.play()
    }

    private var savedVolume: Float {
        AppAudioSettings.volume
    }

    private func preparePlayer<K>(
        named resource: String,
        cache: inout [K: AVAudioPlayer],
        key: K
    ) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav")
                ?? Bundle.main.url(forResource: resource, withExtension: "wav", subdirectory: "Resources/Audio") else {
            print("Warning: Missing piano audio resource: \(resource).wav")
            return nil
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            cache[key] = player
            return player
        } catch {
            print("Warning: Unable to play piano audio: \(error.localizedDescription)")
            return nil
        }
    }
}
