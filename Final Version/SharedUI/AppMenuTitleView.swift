import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Titolo «Lumi : World Of Fables» (menu principale e About).
struct AppMenuTitleView: View {
    let panelWidth: CGFloat

    @EnvironmentObject private var lm: LanguageManager
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize // Forces view update on system text size changes
    @AppStorage("reduceContrast") private var reduceContrast = false

    // Calculate dynamic base sizes that adjust to panel width and system Dynamic Type preferences
    private var titleFontSize: CGFloat {
        let baseSize = panelWidth * 0.18
        #if canImport(UIKit)
        return UIFontMetrics(forTextStyle: .largeTitle).scaledValue(for: baseSize)
        #else
        return baseSize
        #endif
    }

    private var subtitleFontSize: CGFloat {
        let baseSize = panelWidth * 0.075
        #if canImport(UIKit)
        return UIFontMetrics(forTextStyle: .title3).scaledValue(for: baseSize)
        #else
        return baseSize
        #endif
    }

    // Rich dark bronze gradient when reduceContrast is enabled; bright yellow-orange otherwise
    private var titleGradient: LinearGradient {
        if reduceContrast {
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.22, blue: 0.05), // Deep copper brown
                    Color(red: 0.28, green: 0.08, blue: 0.01)  // Dark chocolate brown
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 1.0, green: 0.92, blue: 0.35),
                    Color(red: 0.98, green: 0.62, blue: 0.12)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    private var subtitleStyle: AnyShapeStyle {
        if reduceContrast {
            return AnyShapeStyle(Color(red: 0.28, green: 0.08, blue: 0.01)) // High contrast dark chocolate brown
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.92, blue: 0.35),
                        Color(red: 0.98, green: 0.62, blue: 0.12)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    private var textShadowColor: Color {
        if reduceContrast {
            return Color.black.opacity(0.22) // Soft shadow for depth
        } else {
            return Color(red: 0.35, green: 0.20, blue: 0.06) // Dark brown outline shadow
        }
    }

    private var shadowRadius: CGFloat {
        reduceContrast ? 1.5 : 0.5
    }

    private var shadowOffset: CGPoint {
        reduceContrast ? CGPoint(x: 1, y: 1) : CGPoint(x: 1.5, y: 1.5)
    }

    var body: some View {
        VStack(spacing: 6) {
            // "LUMI" - Bold dynamic title scaling with device size and Dynamic Type
            if reduceContrast {
                Text(lm.t("menu.title.line1"))
                    .font(.custom(AppTypography.bold, size: titleFontSize, relativeTo: .largeTitle))
                    .foregroundStyle(titleGradient)
                    .shadow(color: textShadowColor, radius: shadowRadius, x: shadowOffset.x, y: shadowOffset.y)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            } else {
                ZStack {
                    Text(lm.t("menu.title.line1"))
                        .font(.custom(AppTypography.bold, size: titleFontSize, relativeTo: .largeTitle))
                        .foregroundStyle(Color(red: 0.35, green: 0.20, blue: 0.06))
                        .offset(x: 1.5, y: 1.5)
                        .accessibilityHidden(true)

                    Text(lm.t("menu.title.line1"))
                        .font(.custom(AppTypography.bold, size: titleFontSize, relativeTo: .largeTitle))
                        .foregroundStyle(titleGradient)
                }
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            }

            // "WORLD OF FABLES" - Elegant dynamic subtitle scaling with device size and Dynamic Type
            if reduceContrast {
                Text(lm.t("menu.title.line2"))
                    .font(.custom(AppTypography.medium, size: subtitleFontSize, relativeTo: .title3))
                    .foregroundStyle(subtitleStyle)
                    .shadow(color: textShadowColor, radius: shadowRadius, x: shadowOffset.x, y: shadowOffset.y)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
            } else {
                ZStack {
                    Text(lm.t("menu.title.line2"))
                        .font(.custom(AppTypography.medium, size: subtitleFontSize, relativeTo: .title3))
                        .foregroundStyle(Color(red: 0.35, green: 0.20, blue: 0.06))
                        .offset(x: 1.5, y: 1.5)
                        .accessibilityHidden(true)

                    Text(lm.t("menu.title.line2"))
                        .font(.custom(AppTypography.medium, size: subtitleFontSize, relativeTo: .title3))
                        .foregroundStyle(subtitleStyle)
                }
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, panelWidth * 0.04)
        .fixedSize(horizontal: false, vertical: true)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("\(lm.t("menu.title.line1")) \(lm.t("menu.title.line2"))")
    }
}
