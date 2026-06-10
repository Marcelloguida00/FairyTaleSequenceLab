import AVFoundation

// MARK: - Notification name

/// Posted when the user toggles the custom Voice Over setting,
/// so any open view can react immediately without polling UserDefaults.
extension Notification.Name {
    static let appVoiceOverSettingChanged = Notification.Name("appVoiceOverSettingChanged")
}

// MARK: - AppSpeechSynthesizer

@MainActor
final class AppSpeechSynthesizer: NSObject, AVSpeechSynthesizerDelegate {
    static let shared = AppSpeechSynthesizer()

    private let synthesizer = AVSpeechSynthesizer()

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Public API

    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "voiceOverEnabled")
    }

    /// Toggle the setting and broadcast a notification so live views respond immediately.
    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "voiceOverEnabled")
        if !enabled { stop() }
        NotificationCenter.default.post(name: .appVoiceOverSettingChanged, object: nil)
    }

    /// Speak `text` using the voice matching `languageCode` (e.g. "it", "en", "sq", "ru").
    func speak(_ text: String, languageCode: String) {
        guard isEnabled, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        stop()
        activateAudioSession()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: bcp47LanguageCode(from: languageCode))
        // Slightly slower and warmer pitch — more child-friendly
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0

        synthesizer.speak(utterance)
    }

    func stop() {
        guard synthesizer.isSpeaking else { return }
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - AVSpeechSynthesizerDelegate

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        restoreAudioSession()
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        restoreAudioSession()
    }

    // MARK: - Audio session management

    /// Switches the shared session to .playback + .duckOthers so background music is
    /// automatically lowered while the synthesizer speaks.
    private func activateAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("[AppSpeechSynthesizer] Audio session activation error: \(error)")
        }
    }

    /// Restores the .ambient category used by BackgroundMusicPlayer and deactivates the
    /// session with .notifyOthersOnDeactivation so music resumes at full volume automatically.
    private func restoreAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("[AppSpeechSynthesizer] Audio session restore error: \(error)")
        }
    }

    // MARK: - Helpers

    private func bcp47LanguageCode(from code: String) -> String {
        switch code.lowercased() {
        case "it":      return "it-IT"
        case "sq":      return "sq-AL"
        case "ru":      return "ru-RU"
        case "es":      return "es-ES"
        case "pt":      return "pt-PT"
        case "fa":      return "fa-IR"
        case "zh-hans": return "zh-CN"
        default:        return "en-GB"
        }
    }
}
