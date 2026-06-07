import UIKit

// Legge le preferenze sensoriali salvate con @AppStorage nelle viste.
// Usa `object(forKey:) as? Bool ?? true` così il default è ON anche al primo avvio.
enum AppSettings {
    static var enableHaptics: Bool {
        UserDefaults.standard.object(forKey: "enableHaptics") as? Bool ?? true
    }
    static var reduceAnimations: Bool {
        UserDefaults.standard.object(forKey: "reduceAnimations") as? Bool ?? false
    }
    static var enableSounds: Bool {
        UserDefaults.standard.object(forKey: "enableSounds") as? Bool ?? true
    }
    static var differentiate: Bool {
        UserDefaults.standard.object(forKey: "differentiate") as? Bool ?? false
    }

    static func hapticSuccess() {
        guard enableHaptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
    static func hapticError() {
        guard enableHaptics else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
    static func hapticImpact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard enableHaptics else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
