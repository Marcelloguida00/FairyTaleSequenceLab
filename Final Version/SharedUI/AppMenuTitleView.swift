import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum AppMenuTitleStyle {
    /// Main menu panel — large two-line hero title.
    case mainMenu
    /// About and other compact panels.
    case compact
}

/// Titolo «Lumi» / «World Of Fables» (menu principale e About).
struct AppMenuTitleView: View {
    let panelWidth: CGFloat
    var style: AppMenuTitleStyle = .compact

    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize // Forces view update on system text size changes
    @AppStorage("reduceContrast") private var reduceContrast = false

    // ==========================================
    // STYLING PROPERTIES (Without Reduce Contrast - Original Outline style)
    // ==========================================
    private var titleStrokeColor: Color {
        GameButtonAppearance.border
    }

    /// Light cream highlight on top; FCDB00 dominates the fill.
    private var titleFillGradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: Color(hex: "#FFFBDC"), location: 0),
                .init(color: Color(hex: "#FCDB00"), location: 0.2),
                .init(color: Color(hex: "#FCDB00"), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var titleStrokeOffsets: [CGSize] {
        let w: CGFloat = style == .mainMenu ? 2.2 : 1.6
        return [
            CGSize(width: -w, height: 0),
            CGSize(width: w, height: 0),
            CGSize(width: 0, height: -w),
            CGSize(width: 0, height: w),
            CGSize(width: -w, height: -w),
            CGSize(width: w, height: -w),
            CGSize(width: -w, height: w),
            CGSize(width: w, height: w)
        ]
    }

    private var lineSpacing: CGFloat {
        switch style {
        case .mainMenu: panelWidth * 0.02
        case .compact: panelWidth * 0.012
        }
    }

    private var titleLines: [String] {
        [
            lm.t("menu.title.line1"),
            lm.t("menu.title.line2")
        ]
    }

    private func titleFontSize(for lineIndex: Int) -> CGFloat {
        switch style {
        case .mainMenu:
            return lineIndex == 0 ? panelWidth * 0.26 : panelWidth * 0.125
        case .compact:
            return lineIndex == 0 ? panelWidth * 0.13 : panelWidth * 0.108
        }
    }

    @ViewBuilder
    private func titleLine(_ text: String, lineIndex: Int) -> some View {
        let fontSize = titleFontSize(for: lineIndex)

        ZStack {
            ForEach(Array(titleStrokeOffsets.enumerated()), id: \.offset) { _, offset in
                Text(text)
                    .font(.app(size: fontSize, weight: .black))
                    .foregroundStyle(titleStrokeColor)
                    .offset(x: offset.width, y: offset.height)
            }

            Text(text)
                .font(.app(size: fontSize, weight: .black))
                .foregroundStyle(titleFillGradient)
        }
        .lineLimit(1)
        .minimumScaleFactor(style == .mainMenu ? 0.5 : 0.55)
    }

    // ==========================================
    // STYLING PROPERTIES (With Reduce Contrast - High Contrast Style)
    // ==========================================
    private var titleFontSizeContrast: CGFloat {
        let baseSize = panelWidth * 0.18
        #if canImport(UIKit)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledValue(for: baseSize)
        #else
        return baseSize
        #endif
    }

    private var subtitleFontSizeContrast: CGFloat {
        let baseSize = panelWidth * 0.075
        #if canImport(UIKit)
        return UIFontMetrics(forTextStyle: .title3).scaledValue(for: baseSize)
        #else
        return baseSize
        #endif
    }

    private var titleGradientContrast: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.55, green: 0.22, blue: 0.05), // Deep copper brown
                Color(red: 0.28, green: 0.08, blue: 0.01)  // Dark chocolate brown
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var subtitleStyleContrast: AnyShapeStyle {
        AnyShapeStyle(Color(red: 0.28, green: 0.08, blue: 0.01)) // High contrast dark chocolate brown
    }

    private var textShadowColorContrast: Color {
        Color.black.opacity(0.22) // Soft shadow for depth
    }

    private var shadowRadiusContrast: CGFloat { 1.5 }
    private var shadowOffsetContrast: CGPoint { CGPoint(x: 1, y: 1) }

    // ==========================================
    // VIEW BODY
    // ==========================================
    var body: some View {
        if reduceContrast {
            VStack(spacing: 6) {
                // "LUMI" - Bold dynamic title scaling with device size and Dynamic Type
                Text(lm.t("menu.title.line1"))
                    .font(.custom(AppTypography.bold, size: titleFontSizeContrast, relativeTo: .largeTitle))
                    .foregroundStyle(titleGradientContrast)
                    .shadow(color: textShadowColorContrast, radius: shadowRadiusContrast, x: shadowOffsetContrast.x, y: shadowOffsetContrast.y)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                // "WORLD OF FABLES" - Elegant dynamic subtitle scaling with device size and Dynamic Type
                Text(lm.t("menu.title.line2"))
                    .font(.custom(AppTypography.medium, size: subtitleFontSizeContrast, relativeTo: .title3))
                    .foregroundStyle(subtitleStyleContrast)
                    .shadow(color: textShadowColorContrast, radius: shadowRadiusContrast, x: shadowOffsetContrast.x, y: shadowOffsetContrast.y)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, panelWidth * 0.04)
            .fixedSize(horizontal: false, vertical: true)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .accessibilityElement(children: .ignore)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("\(lm.t("menu.title.line1")) \(lm.t("menu.title.line2"))")
        } else {
            VStack(spacing: lineSpacing) {
                ForEach(Array(titleLines.enumerated()), id: \.offset) { index, line in
                    titleLine(line, lineIndex: index)
                }
            }
            .padding(.horizontal, panelWidth * 0.04)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel(titleLines.joined(separator: " "))
        }
    }
}
