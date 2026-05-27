import SwiftUI
import CoreText

enum AppTypography {
    static let regular = "AlegreyaRoman-Regular"
    static let medium = "AlegreyaRoman-Medium"
    static let bold = "AlegreyaRoman-Bold"
    static let extraBold = "AlegreyaRoman-ExtraBold"
    static let black = "AlegreyaRoman-Black"

    static func fontName(for weight: Font.Weight) -> String {
        switch weight {
        case .black, .heavy:
            black
        case .bold:
            bold
        case .semibold:
            medium
        case .medium:
            medium
        default:
            regular
        }
    }

    static func registerCustomFonts() {
        ["Alegreya", "Alegreya-Italic"].forEach { fileName in
            guard let fontURL = Bundle.main.url(forResource: fileName, withExtension: "ttf") else { return }
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}

extension Font {
    static let appBody = Font.custom(AppTypography.regular, size: 17, relativeTo: .body)
    static let appCallout = Font.custom(AppTypography.medium, size: 16, relativeTo: .callout)
    static let appCaption = Font.custom(AppTypography.medium, size: 12, relativeTo: .caption)
    static let appHeadline = Font.custom(AppTypography.bold, size: 17, relativeTo: .headline)
    static let appTitle3 = Font.custom(AppTypography.bold, size: 20, relativeTo: .title3)
    static let appTitle2 = Font.custom(AppTypography.bold, size: 22, relativeTo: .title2)
    static let appLargeTitle = Font.custom(AppTypography.extraBold, size: 34, relativeTo: .largeTitle)

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
