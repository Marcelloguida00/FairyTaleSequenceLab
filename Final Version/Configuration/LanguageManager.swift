import Foundation
import Combine

final class LanguageManager: ObservableObject {

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
        Language(code: "fa", nativeName: "فارسی",     flag: "🇮🇷"),
    ]

    @Published var currentLanguage: String {
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
        let saved  = UserDefaults.standard.string(forKey: "appLanguage") ?? device
        let codes  = Self.supported.map(\.code)
        currentLanguage = codes.contains(saved) ? saved : "en"
    }
}
