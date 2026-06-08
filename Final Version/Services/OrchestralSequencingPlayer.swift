import AVFoundation
import Foundation

/// Orchestral sequencing SFX: looping pick per step, one-shot correct/wrong, victory jingle.
@MainActor
final class OrchestralSequencingPlayer {
    static let shared = OrchestralSequencingPlayer()

    private var pickPlayer: AVAudioPlayer?
    private var oneShotPlayer: AVAudioPlayer?
    private var wrongCycleIndex = 0

    private init() {}

    func resetSession() {
        stopPickLoop()
        wrongCycleIndex = 0
    }

    func startPickLoop(step: Int) {
        guard AppAudioSettings.isSequencingSFXAudible, (1...4).contains(step) else { return }
        stopPickLoop()

        guard let player = preparePlayer(named: OrchestralAudioResources.pickNote(step: step), loops: -1) else { return }
        player.volume = pickVolume
        player.play()
        pickPlayer = player
    }

    func stopPickLoop() {
        pickPlayer?.stop()
        pickPlayer = nil
    }

    func playCorrect(step: Int) {
        guard (1...4).contains(step) else { return }
        stopPickLoop()
        playOneShot(named: OrchestralAudioResources.correctResponse(step: step), volumeScale: 1.0)
    }

    func playWrong() {
        wrongCycleIndex = (wrongCycleIndex % 4) + 1
        playOneShot(named: OrchestralAudioResources.wrongResponse(cycle: wrongCycleIndex), volumeScale: 0.92)
    }

    func playVictoryJingle() {
        stopPickLoop()
        playOneShot(named: OrchestralAudioResources.victoryJingle, volumeScale: 1.0)
    }

    func playFlip(alternate: Bool) {
        let orchestralName = OrchestralAudioResources.flipCard(alternate: alternate)
        if playOneShotIfAvailable(named: orchestralName, volumeScale: 1.05) {
            return
        }
        let fallback = alternate ? "SequencingFlipAll_2" : "SequencingFlipAll_1"
        playOneShot(named: fallback, volumeScale: 1.05)
    }

    private var savedVolume: Float {
        AppAudioSettings.volume
    }

    private var pickVolume: Float {
        min(savedVolume * 1.15, 1)
    }

    private func playOneShot(named resource: String, volumeScale: Float) {
        guard AppAudioSettings.isSequencingSFXAudible else { return }
        guard let player = preparePlayer(named: resource, loops: 0) else { return }
        player.volume = min(savedVolume * 1.35 * volumeScale, 1)
        player.play()
        oneShotPlayer = player
    }

    @discardableResult
    private func playOneShotIfAvailable(named resource: String, volumeScale: Float) -> Bool {
        guard AppAudioSettings.isSequencingSFXAudible else { return false }
        guard let player = preparePlayer(named: resource, loops: 0, logMissing: false) else { return false }
        player.volume = min(savedVolume * 1.35 * volumeScale, 1)
        player.play()
        oneShotPlayer = player
        return true
    }

    private func preparePlayer(named resource: String, loops: Int, logMissing: Bool = true) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "wav")
            ?? Bundle.main.url(forResource: resource, withExtension: "wav", subdirectory: "Resources/Audio") else {
            if logMissing {
                assertionFailure("Missing orchestral audio resource: \(resource).wav")
            }
            return nil
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)

            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loops
            player.prepareToPlay()
            return player
        } catch {
            assertionFailure("Unable to play orchestral audio \(resource): \(error.localizedDescription)")
            return nil
        }
    }
}
