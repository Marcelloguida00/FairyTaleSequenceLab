import SwiftUI
import CoreText

enum AppTypography {
    static let regular = "FredokaOne-Regular"
    static let medium = "FredokaOne-Regular"
    static let bold = "FredokaOne-Regular"
    static let extraBold = "FredokaOne-Regular"
    static let black = "FredokaOne-Regular"
    static let dyslexiaRegular = "OpenDyslexic-Regular"
    static let dyslexiaBold = "OpenDyslexic-Bold"
    static let dyslexiaItalic = "OpenDyslexic-Italic"

    static func fontName(for weight: Font.Weight) -> String {
        if UserDefaults.standard.bool(forKey: "dyslexiaFontEnabled") {
            switch weight {
            case .black, .heavy, .bold, .semibold:
                return dyslexiaBold
            default:
                return dyslexiaRegular
            }
        }

        switch weight {
        case .black, .heavy:
            return black
        case .bold:
            return bold
        case .semibold:
            return medium
        case .medium:
            return medium
        default:
            return regular
        }
    }

    static func registerCustomFonts() {
        [
            ("Alegreya", "ttf"),
            ("Alegreya-Italic", "ttf"),
            ("FredokaOne-Regular", "ttf"),
            ("OpenDyslexic-Regular", "otf"),
            ("OpenDyslexic-Bold", "otf"),
            ("OpenDyslexic-Italic", "otf")
        ].forEach { fileName, fileExtension in
            guard let fontURL = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else { return }
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}

extension Font {
    static var appBody: Font { Font.custom(AppTypography.fontName(for: .regular), size: 17, relativeTo: .body) }
    static var appCallout: Font { Font.custom(AppTypography.fontName(for: .medium), size: 16, relativeTo: .callout) }
    static var appCaption: Font { Font.custom(AppTypography.fontName(for: .medium), size: 12, relativeTo: .caption) }
    static var appHeadline: Font { Font.custom(AppTypography.fontName(for: .bold), size: 17, relativeTo: .headline) }
    static var appTitle3: Font { Font.custom(AppTypography.fontName(for: .bold), size: 20, relativeTo: .title3) }
    static var appTitle2: Font { Font.custom(AppTypography.fontName(for: .bold), size: 22, relativeTo: .title2) }
    static var appLargeTitle: Font { Font.custom(AppTypography.fontName(for: .black), size: 34, relativeTo: .largeTitle) }

    static func app(size: CGFloat, weight: Font.Weight = .regular, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        Font.custom(AppTypography.fontName(for: weight), size: size, relativeTo: textStyle)
    }

    static func app(_ textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        let name = AppTypography.fontName(for: weight)

        switch textStyle {
        case .largeTitle:
            return Font.custom(name, size: 34, relativeTo: .largeTitle)
        case .title:
            return Font.custom(name, size: 28, relativeTo: .title)
        case .title2:
            return Font.custom(name, size: 22, relativeTo: .title2)
        case .title3:
            return Font.custom(name, size: 20, relativeTo: .title3)
        case .headline:
            return Font.custom(name, size: 17, relativeTo: .headline)
        case .callout:
            return Font.custom(name, size: 16, relativeTo: .callout)
        case .subheadline:
            return Font.custom(name, size: 15, relativeTo: .subheadline)
        case .footnote:
            return Font.custom(name, size: 13, relativeTo: .footnote)
        case .caption:
            return Font.custom(name, size: 12, relativeTo: .caption)
        case .caption2:
            return Font.custom(name, size: 11, relativeTo: .caption2)
        default:
            return Font.custom(name, size: 17, relativeTo: .body)
        }
    }
}
