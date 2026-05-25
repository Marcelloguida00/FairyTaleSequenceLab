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

    private func preparePlayer() {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension) else {
            assertionFailure("Missing background music resource: \(resourceName).\(resourceExtension)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 0.32
            newPlayer.prepareToPlay()
            player = newPlayer
        } catch {
            assertionFailure("Unable to start background music: \(error.localizedDescription)")
        }
    }
}
