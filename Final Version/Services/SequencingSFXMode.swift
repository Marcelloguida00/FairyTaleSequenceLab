import Foundation

/// Sound style for the card sequencing mini-game.
enum SequencingSFXMode: String, CaseIterable, Identifiable {
    case simplified
    case orchestral

    static let storageKey = "sequencingSFXMode"

    var id: String { rawValue }

    var localizedNameKey: String {
        switch self {
        case .simplified: return "settings.sequencing_sfx.simplified"
        case .orchestral: return "settings.sequencing_sfx.orchestral"
        }
    }

    static var settingsVisibleCases: [SequencingSFXMode] {
        AppFeatureFlags.showsOrchestralSequencingSFX ? allCases : [.simplified]
    }

    static var current: SequencingSFXMode {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? SequencingSFXMode.simplified.rawValue
        let stored = SequencingSFXMode(rawValue: raw) ?? .simplified
        if stored == .orchestral, !AppFeatureFlags.showsOrchestralSequencingSFX {
            return .simplified
        }
        return stored
    }
}
