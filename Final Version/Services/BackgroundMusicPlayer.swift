import AVFoundation
import Foundation

@MainActor
final class BackgroundMusicPlayer {
    static let shared = BackgroundMusicPlayer()

    private var player: AVAudioPlayer?
    private let resourceName = "Beyond_the_Garden_Gate"
    private let resourceExtension = "mp3"

    private init() {}

    func start() {
        if player?.isPlaying == true { return }

        if player == nil {
            preparePlayer()
        }

        player?.play()
    }

    // MARK: - Volume & Mute

    var isMuted: Bool {
        UserDefaults.standard.object(forKey: "musicMuted") as? Bool ?? false
    }

    var savedVolume: Float {
        let v = UserDefaults.standard.object(forKey: "musicVolume") as? Float
        return v ?? 0.32
    }

    func setVolume(_ volume: Float) {
        UserDefaults.standard.set(volume, forKey: "musicVolume")
        if !isMuted {
            player?.volume = volume
        }
    }

    func setMuted(_ muted: Bool) {
        UserDefaults.standard.set(muted, forKey: "musicMuted")
        player?.volume = muted ? 0 : savedVolume
    }

    // MARK: - Private

    private func preparePlayer() {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension)
                ?? Bundle.main.url(forResource: resourceName, withExtension: resourceExtension, subdirectory: "Resources/Audio") else {
            assertionFailure("Missing background music resource: \(resourceName).\(resourceExtension)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = isMuted ? 0 : savedVolume
            newPlayer.prepareToPlay()
            player = newPlayer
        } catch {
            assertionFailure("Unable to start background music: \(error.localizedDescription)")
        }
    }
}
