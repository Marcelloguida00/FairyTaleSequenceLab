import AVFoundation
import Foundation

enum PianoChord: String, CaseIterable {
    case cMajor = "PianoChord_CMajor"
    case aMinor = "PianoChord_AMinor"
    case dMinor = "PianoChord_DMinor"
    case gMajor = "PianoChord_GMajor"
}

@MainActor
final class PianoChordPlayer {
    static let shared = PianoChordPlayer()

    private var players: [PianoChord: AVAudioPlayer] = [:]

    private init() {}

    func play(_ chord: PianoChord) {
        guard !isMuted else { return }

        let player = players[chord] ?? preparePlayer(for: chord)
        guard let player else { return }

        player.currentTime = 0
        player.volume = min(savedVolume * 1.25, 1)
        player.play()
    }

    private var isMuted: Bool {
        UserDefaults.standard.object(forKey: "musicMuted") as? Bool ?? false
    }

    private var savedVolume: Float {
        let volume = UserDefaults.standard.object(forKey: "musicVolume") as? Float
        return volume ?? 0.32
    }

    private func preparePlayer(for chord: PianoChord) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: chord.rawValue, withExtension: "wav")
                ?? Bundle.main.url(forResource: chord.rawValue, withExtension: "wav", subdirectory: "Resources/Audio") else {
            assertionFailure("Missing piano chord resource: \(chord.rawValue).wav")
            return nil
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            players[chord] = player
            return player
        } catch {
            assertionFailure("Unable to play piano chord: \(error.localizedDescription)")
            return nil
        }
    }
}
