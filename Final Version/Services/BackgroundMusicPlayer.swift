import AVFoundation
import Foundation

enum BackgroundMusicTheme: String, CaseIterable, Identifiable {
    case gardenGate = "Beyond_the_Garden_Gate"
    case redRidingHood1 = "RedRidingHoodTheme1"
    case redRidingHood2 = "RedRidingHoodTheme2"
    case redRidingHood3 = "RedRidingHoodTheme3"

    var id: String { rawValue }

    var resourceName: String { rawValue }

    var localizedNameKey: String {
        switch self {
        case .gardenGate: return "settings.music.theme.garden_gate"
        case .redRidingHood1: return "settings.music.theme.red_hood_1"
        case .redRidingHood2: return "settings.music.theme.red_hood_2"
        case .redRidingHood3: return "settings.music.theme.red_hood_3"
        }
    }
}

@MainActor
final class BackgroundMusicPlayer {
    static let shared = BackgroundMusicPlayer()

    private var player: AVAudioPlayer?
    private let resourceExtension = "mp3"

    private init() {}

    func start() {
        if player?.isPlaying == true { return }

        if player == nil {
            preparePlayer()
        }

        player?.play()
    }

    func pause() {
        player?.pause()
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

    var selectedTheme: BackgroundMusicTheme {
        let saved = UserDefaults.standard.string(forKey: "musicTheme")
        return saved.flatMap(BackgroundMusicTheme.init(rawValue:)) ?? .gardenGate
    }

    func setTheme(_ theme: BackgroundMusicTheme) {
        guard theme != selectedTheme else { return }

        let wasPlaying = player?.isPlaying == true
        UserDefaults.standard.set(theme.rawValue, forKey: "musicTheme")
        player?.stop()
        player = nil
        preparePlayer()

        if wasPlaying {
            player?.play()
        }
    }

    // MARK: - Private

    private func preparePlayer() {
        let resourceName = selectedTheme.resourceName
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
