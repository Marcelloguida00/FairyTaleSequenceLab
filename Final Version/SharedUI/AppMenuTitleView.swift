import SwiftUI

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

    var body: some View {
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
}
