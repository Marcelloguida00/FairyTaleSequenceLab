import AVFoundation

final class AppSpeechSynthesizer {
    static let shared = AppSpeechSynthesizer()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    private init() {}
    
    var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: "voiceOverEnabled")
    }
    
    func speak(_ text: String, languageCode: String) {
        guard isEnabled, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        stop()
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: bcp47LanguageCode(from: languageCode))
        // Child-friendly rate and pitch
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.85
        utterance.pitchMultiplier = 1.05
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    
    private func bcp47LanguageCode(from code: String) -> String {
        switch code.lowercased() {
        case "it": return "it-IT"
        case "sq": return "sq-AL"
        case "ru": return "ru-RU"
        default: return "en-GB"
        }
    }
}
