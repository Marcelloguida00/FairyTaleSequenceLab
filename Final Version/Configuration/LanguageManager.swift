import Foundation
import Observation

@Observable
final class LanguageManager {

    struct Language {
        let code: String
        let nativeName: String
        let flag: String
    }

    static let supported: [Language] = [
        Language(code: "en", nativeName: "English",  flag: "🇬🇧"),
        Language(code: "it", nativeName: "Italiano",  flag: "🇮🇹"),
        Language(code: "sq", nativeName: "Shqip",     flag: "🇦🇱"),
        Language(code: "ru", nativeName: "Русский",   flag: "🇷🇺"),
        Language(code: "es", nativeName: "Español",   flag: "🇪🇸"),
        Language(code: "pt", nativeName: "Português", flag: "🇵🇹"),
        Language(code: "fa", nativeName: "فارسی",      flag: "🇮🇷"),
        Language(code: "zh-Hans", nativeName: "简体中文", flag: "🇨🇳"),
    ]

    var currentLanguage: String {
        didSet { UserDefaults.standard.set(currentLanguage, forKey: "appLanguage") }
    }

    func t(_ key: String) -> String {
        let value = bundle.localizedString(forKey: key, value: nil, table: nil)
        // Fallback to English when key is missing in current language
        if value == key, currentLanguage != "en" {
            if let path = Bundle.main.path(forResource: "en", ofType: "lproj"),
               let en = Bundle(path: path) {
                return en.localizedString(forKey: key, value: key, table: nil)
            }
        }
        return value
    }

    var bundle: Bundle {
        guard let path = Bundle.main.path(forResource: currentLanguage, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return Bundle.main }
        return bundle
    }

    init() {
        let device = Locale.current.language.languageCode?.identifier ?? "en"
        let codes  = Self.supported.map(\.code)
        if let saved = UserDefaults.standard.string(forKey: "appLanguage"), codes.contains(saved) {
            currentLanguage = saved
        } else if codes.contains(device) {
            currentLanguage = device
        } else if device == "zh" {
            // Chinese is shipped as the "zh-Hans" locale folder, so the bare
            // device language code never matches the supported list directly.
            currentLanguage = "zh-Hans"
        } else {
            currentLanguage = "en"
        }
    }
}
