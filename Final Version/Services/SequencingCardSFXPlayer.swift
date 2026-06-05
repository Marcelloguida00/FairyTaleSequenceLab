import AVFoundation
import Foundation

/// WAV files live in `Final Version/Resources/Audio/` — replace in Xcode to change sounds.
enum SequencingCardSFX: String {
    /// First flip action (single card or flip all).
    case flipAll1 = "SequencingFlipAll_1"
    /// Next flip action (alternates with flipAll1).
    case flipAll2 = "SequencingFlipAll_2"
}

@MainActor
final class SequencingCardSFXPlayer {
    static let shared = SequencingCardSFXPlayer()

    private var players: [String: AVAudioPlayer] = [:]

    private init() {}

    func play(_ sfx: SequencingCardSFX) {
        guard !isMuted, AppSettings.enableSounds else { return }

        let name = sfx.rawValue
        let player = players[name] ?? preparePlayer(named: name)
        guard let player else { return }

        players[name] = player
        player.currentTime = 0
        player.volume = min(savedVolume * volumeScale(for: sfx), 1)
        player.play()
    }

    private func volumeScale(for sfx: SequencingCardSFX) -> Float {
        switch sfx {
        case .flipAll1: return 1.05
        case .flipAll2: return 1.05
        }
    }

    private var isMuted: Bool {
        UserDefaults.standard.object(forKey: "musicMuted") as? Bool ?? false
    }

    private var savedVolume: Float {
        let volume = UserDefaults.standard.object(forKey: "musicVolume") as? Float
        return volume ?? 0.32
    }

    private func preparePlayer(named resource: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav")
            ?? Bundle.main.url(forResource: resource, withExtension: "wav", subdirectory: "Resources/Audio") else {
            print("Warning: Missing audio resource: \(resource).wav")
            return nil
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            return player
        } catch {
            print("Warning: Unable to play card SFX \(resource): \(error.localizedDescription)")
            return nil
        }
    }
}
