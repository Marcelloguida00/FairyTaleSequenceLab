import AVFoundation
import Foundation

/// Background ambience used only inside the sequencing game section.
/// Simplified SFX → `ForestAmbience.mp3`; orchestral SFX → `musicaorchestrale.wav`.
@MainActor
final class ForestAmbiencePlayer {
    static let shared = ForestAmbiencePlayer()

    private var player: AVAudioPlayer?
    private var restartTask: Task<Void, Never>?
    private var fadeTask: Task<Void, Never>?
    private(set) var isSequencingSectionActive = false

    private let simplifiedResourceName = "ForestAmbience"
    private let simplifiedResourceExtension = "mp3"
    private let simplifiedLoopDuration: TimeInterval = 300

    private init() {}

    func enterSequencingSection(fadeDuration: TimeInterval = 2.2) {
        isSequencingSectionActive = true
        fadeIn(duration: fadeDuration)
    }

    func leaveSequencingSection(fadeDuration: TimeInterval = 2.2) {
        isSequencingSectionActive = false
        fadeOutAndStop(duration: fadeDuration)
    }

    func applySequencingSFXMode() {
        guard isSequencingSectionActive else { return }

        let wasPlaying = player?.isPlaying == true
        stopPlaybackOnly()
        guard wasPlaying, !isMuted else { return }
        fadeIn()
    }

    func start() {
        restartTask?.cancel()
        fadeTask?.cancel()

        guard !isMuted else {
            stopPlaybackOnly()
            return
        }

        if player == nil {
            preparePlayer()
        }

        guard let player else { return }
        player.currentTime = 0
        player.volume = savedVolume
        player.play()
        scheduleRestartIfNeeded()
    }

    func fadeIn(duration: TimeInterval = 2.2) {
        restartTask?.cancel()
        fadeTask?.cancel()

        guard !isMuted else {
            stopPlaybackOnly()
            return
        }

        stopPlaybackOnly()
        preparePlayer()

        guard let player else { return }
        player.currentTime = 0
        player.volume = 0
        player.play()
        scheduleRestartIfNeeded()
        fade(to: savedVolume, duration: duration, stopWhenFinished: false)
    }

    func fadeOutAndStop(duration: TimeInterval = 2.2) {
        fade(to: 0, duration: duration, stopWhenFinished: true)
    }

    func stop() {
        isSequencingSectionActive = false
        stopPlaybackOnly()
    }

    private var usesOrchestralAmbience: Bool {
        AppFeatureFlags.showsOrchestralSequencingSFX && SequencingSFXMode.current == .orchestral
    }

    private var isMuted: Bool {
        !AppAudioSettings.isMusicAudible
    }

    private var savedVolume: Float {
        AppAudioSettings.volume
    }

    private func stopPlaybackOnly() {
        restartTask?.cancel()
        restartTask = nil
        fadeTask?.cancel()
        fadeTask = nil
        player?.stop()
        player?.currentTime = 0
        player = nil
    }

    private func scheduleRestartIfNeeded() {
        restartTask?.cancel()
        guard !usesOrchestralAmbience else { return }

        restartTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                try? await Task.sleep(for: .seconds(self.simplifiedLoopDuration))
                guard !Task.isCancelled else { return }
                await MainActor.run {
                    guard let player = self.player else { return }
                    guard !self.isMuted else {
                        self.stopPlaybackOnly()
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
        if usesOrchestralAmbience {
            prepareOrchestralPlayer()
        } else {
            prepareSimplifiedPlayer()
        }
    }

    private func prepareSimplifiedPlayer() {
        guard let url = audioURL(resource: simplifiedResourceName, extension: simplifiedResourceExtension) else {
            print("Warning: Missing forest ambience resource: \(simplifiedResourceName).\(simplifiedResourceExtension)")
            return
        }
        installPlayer(from: url, loops: 0)
    }

    private func prepareOrchestralPlayer() {
        let resourceName = OrchestralAudioResources.backgroundMusic
        guard let url = audioURL(resource: resourceName, extension: "wav") else {
            print("Warning: Missing orchestral sequencing ambience: \(resourceName).wav")
            return
        }
        installPlayer(from: url, loops: -1)
    }

    private func audioURL(resource: String, extension ext: String) -> URL? {
        Bundle.main.url(forResource: resource, withExtension: ext)
            ?? Bundle.main.url(forResource: resource, withExtension: ext, subdirectory: "Resources/Audio")
    }

    private func installPlayer(from url: URL, loops: Int) {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = loops
            newPlayer.volume = savedVolume
            newPlayer.prepareToPlay()
            player = newPlayer
        } catch {
            print("Warning: Unable to start sequencing ambience: \(error.localizedDescription)")
        }
    }

    private func fade(to targetVolume: Float, duration: TimeInterval, stopWhenFinished: Bool) {
        fadeTask?.cancel()

        guard !isMuted else {
            stopPlaybackOnly()
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
                        self.stopPlaybackOnly()
                        return
                    }

                    let progress = Float(step) / Float(steps)
                    player.volume = startVolume + (clampedTarget - startVolume) * progress
                }
            }

            await MainActor.run {
                guard let self else { return }
                if stopWhenFinished {
                    self.stopPlaybackOnly()
                }
            }
        }
    }
}
