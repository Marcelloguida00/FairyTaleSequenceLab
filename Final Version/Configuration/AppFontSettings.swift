import SwiftUI

private struct DyslexiaFontEnabledKey: EnvironmentKey {
    static let defaultValue = UserDefaults.standard.bool(forKey: AppFontSettings.dyslexiaFontKey)
}

extension EnvironmentValues {
    var dyslexiaFontEnabled: Bool {
        get { self[DyslexiaFontEnabledKey.self] }
        set { self[DyslexiaFontEnabledKey.self] = newValue }
    }
}

@Observable
final class AppFontSettings {
    static let dyslexiaFontKey = "dyslexiaFontEnabled"

    private(set) var fontRevision = 0

    var dyslexiaFontEnabled: Bool {
        didSet {
            guard dyslexiaFontEnabled != oldValue else { return }
            UserDefaults.standard.set(dyslexiaFontEnabled, forKey: Self.dyslexiaFontKey)
            fontRevision &+= 1
        }
    }

    init() {
        dyslexiaFontEnabled = UserDefaults.standard.bool(forKey: Self.dyslexiaFontKey)
    }
}
