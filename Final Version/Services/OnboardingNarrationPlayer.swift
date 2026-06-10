import AVFoundation
import Foundation

/// Stato osservabile della narrazione, usato per sincronizzare i sottotitoli con l'audio.
enum NarrationPlaybackState: Equatable {
    case idle
    case playing(resource: String, progress: Double)
    case finished(resource: String)
}

@MainActor
final class OnboardingNarrationPlayer {
    static let shared = OnboardingNarrationPlayer()

    private var player: AVAudioPlayer?
    private(set) var currentResource: String?

    private init() {}

    var playbackState: NarrationPlaybackState {
        guard let player, let currentResource else { return .idle }
        if player.isPlaying {
            let duration = max(player.duration, 0.1)
            let progress = min(max(player.currentTime / duration, 0), 1)
            return .playing(resource: currentResource, progress: progress)
        }
        return .finished(resource: currentResource)
    }

    func stop() {
        player?.stop()
        player = nil
        currentResource = nil
    }

    func duration(named resource: String) -> TimeInterval {
        guard let url = audioURL(resource: resource),
              let probe = try? AVAudioPlayer(contentsOf: url) else {
            return 0
        }
        return max(probe.duration, 0.1)
    }

    func play(named resource: String) {
        stop()

        guard let url = audioURL(resource: resource) else {
            print("Warning: Missing onboarding narration: \(resource).wav")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.prepareToPlay()
            player = newPlayer
            currentResource = resource
            newPlayer.play()
        } catch {
            print("Warning: Unable to play onboarding narration \(resource): \(error.localizedDescription)")
        }
    }

    func playAndWait(named resource: String) async {
        play(named: resource)
        await waitUntilFinished()
    }

    func waitUntilFinished() async {
        guard let player else { return }

        while player.isPlaying {
            if Task.isCancelled { return }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }

        try? await Task.sleep(nanoseconds: 120_000_000)
    }

    private func audioURL(resource: String) -> URL? {
        Bundle.main.url(forResource: resource, withExtension: "wav")
            ?? Bundle.main.url(forResource: resource, withExtension: "wav", subdirectory: "Resources/Audio")
    }
}
