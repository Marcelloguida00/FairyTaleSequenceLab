import Foundation

/// Central audio preferences:
/// - Master: all app audio
/// - Music: background themes + forest ambience (+ musical stingers outside sequencing)
/// - SFX: card sequencing game only (notes, flips, victory jingle)
enum AppAudioSettings {
    static let masterKey = "audioMasterEnabled"
    static let musicMutedKey = "musicMuted"
    static let sfxEnabledKey = "enableSounds"
    static let volumeKey = "musicVolume"

    static var isMasterEnabled: Bool {
        UserDefaults.standard.object(forKey: masterKey) as? Bool ?? true
    }

    static var isMusicEnabled: Bool {
        !(UserDefaults.standard.object(forKey: musicMutedKey) as? Bool ?? false)
    }

    static var isSFXEnabled: Bool {
        UserDefaults.standard.object(forKey: sfxEnabledKey) as? Bool ?? true
    }

    /// Background music and ambience across the whole game.
    static var isMusicAudible: Bool {
        isMasterEnabled && isMusicEnabled
    }

    /// Sequencing card-game sounds only.
    static var isSequencingSFXAudible: Bool {
        isMasterEnabled && isSFXEnabled
    }

    static var volume: Float {
        let stored = UserDefaults.standard.object(forKey: volumeKey) as? Float
        return stored ?? 0.32
    }

    static func setMasterEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: masterKey)
    }

    static func setMusicEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(!enabled, forKey: musicMutedKey)
    }

    static func setSFXEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: sfxEnabledKey)
    }

    static func setVolume(_ volume: Float) {
        UserDefaults.standard.set(volume, forKey: volumeKey)
    }

    @MainActor
    static func applyPlaybackState() {
        if isMusicAudible {
            BackgroundMusicPlayer.shared.resumeIfNeeded()
        } else {
            BackgroundMusicPlayer.shared.applyAudibleState()
            ForestAmbiencePlayer.shared.stop()
        }

        if !isSequencingSFXAudible {
            SequencingSoundCoordinator.resetSession()
        }
    }
}
