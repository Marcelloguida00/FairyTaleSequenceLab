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

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.92, blue: 0.35),
                Color(red: 0.98, green: 0.62, blue: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var outlineColor: Color {
        Color(red: 0.35, green: 0.20, blue: 0.06)
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
            return lineIndex == 0 ? panelWidth * 0.26 : panelWidth * 0.155
        case .compact:
            return panelWidth * 0.13
        }
    }

    @ViewBuilder
    private func titleLine(_ text: String, lineIndex: Int) -> some View {
        let fontSize = titleFontSize(for: lineIndex)

        ZStack {
            Text(text)
                .font(.app(size: fontSize, weight: .black))
                .foregroundStyle(outlineColor)
                .offset(x: 1.5, y: 1.5)

            Text(text)
                .font(.app(size: fontSize, weight: .black))
                .foregroundStyle(titleGradient)
        }
        .lineLimit(1)
        .minimumScaleFactor(style == .mainMenu ? 0.5 : 0.55)
    }
}
