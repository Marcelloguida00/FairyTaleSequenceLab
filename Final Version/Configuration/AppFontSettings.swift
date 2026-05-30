import SwiftUI

@Observable
final class AppFontSettings {
    static let dyslexiaFontKey = "dyslexiaFontEnabled"

    var dyslexiaFontEnabled: Bool {
        didSet {
            UserDefaults.standard.set(dyslexiaFontEnabled, forKey: Self.dyslexiaFontKey)
        }
    }

    init() {
        dyslexiaFontEnabled = UserDefaults.standard.bool(forKey: Self.dyslexiaFontKey)
    }
}
