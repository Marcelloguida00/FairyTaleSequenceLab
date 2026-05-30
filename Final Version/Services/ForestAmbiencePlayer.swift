import AVFoundation
import Foundation

@MainActor
final class ForestAmbiencePlayer {
    static let shared = ForestAmbiencePlayer()

    private var player: AVAudioPlayer?
    private var restartTask: Task<Void, Never>?
    private var fadeTask: Task<Void, Never>?
    private let resourceName = "ForestAmbience"
    private let resourceExtension = "mp3"
    private let loopDuration: TimeInterval = 300

    private init() {}

    func start() {
        restartTask?.cancel()
        fadeTask?.cancel()

        guard !isMuted else {
            stop()
            return
        }

        if player == nil {
            preparePlayer()
        }

        guard let player else { return }
        player.currentTime = 0
        player.volume = savedVolume
        player.play()
        scheduleRestart()
    }

    func fadeIn(duration: TimeInterval = 2.2) {
        restartTask?.cancel()
        fadeTask?.cancel()

        guard !isMuted else {
            stop()
            return
        }

        if player == nil {
            preparePlayer()
        }

        guard let player else { return }
        player.currentTime = 0
        player.volume = 0
        player.play()
        scheduleRestart()
        fade(to: savedVolume, duration: duration, stopWhenFinished: false)
    }

    func fadeOutAndStop(duration: TimeInterval = 2.2) {
        fade(to: 0, duration: duration, stopWhenFinished: true)
    }

    func stop() {
        restartTask?.cancel()
        restartTask = nil
        fadeTask?.cancel()
        fadeTask = nil
        player?.stop()
        player?.currentTime = 0
    }

    private var isMuted: Bool {
        UserDefaults.standard.object(forKey: "musicMuted") as? Bool ?? false
    }

    private var savedVolume: Float {
        let volume = UserDefaults.standard.object(forKey: "musicVolume") as? Float
        return volume ?? 0.32
    }

    private func scheduleRestart() {
        restartTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(loopDuration))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let self, let player = self.player else { return }
                    guard !self.isMuted else {
                        self.stop()
                        return
                    }
                    player.currentTime = 0
                    player.volume = self.savedVolume
                    player.play()
                }
            }
        }
    }

    private func preparePlayer() {
        guard let url = Bundle.main.url(forResource: resourceName, withExtension: resourceExtension)
                ?? Bundle.main.url(forResource: resourceName, withExtension: resourceExtension, subdirectory: "Resources/Audio") else {
            assertionFailure("Missing forest ambience resource: \(resourceName).\(resourceExtension)")
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = 0
            newPlayer.volume = savedVolume
            newPlayer.prepareToPlay()
            player = newPlayer
        } catch {
            assertionFailure("Unable to start forest ambience: \(error.localizedDescription)")
        }
    }

    private func fade(to targetVolume: Float, duration: TimeInterval, stopWhenFinished: Bool) {
        fadeTask?.cancel()

        guard !isMuted else {
            stop()
            return
        }

        guard let player else { return }

        let startVolume = player.volume
        let clampedTarget = max(0, min(targetVolume, 1))
        let steps = 36
        let stepDuration = max(duration / Double(steps), 0.01)

        fadeTask = Task { [weak self] in
            for step in 1...steps {
                guard !Task.isCancelled else { return }
                try? await Task.sleep(for: .seconds(stepDuration))
                await MainActor.run {
                    guard let self, let player = self.player else { return }
                    guard !self.isMuted else {
                        self.stop()
                        return
                    }

                    let progress = Float(step) / Float(steps)
                    player.volume = startVolume + (clampedTarget - startVolume) * progress
                }
            }

            await MainActor.run {
                guard let self else { return }
                if stopWhenFinished {
                    self.stop()
                }
            }
        }
    }
}
