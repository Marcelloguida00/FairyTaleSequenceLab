import SwiftUI

/// Titolo «Lumi : World Of Fables» (menu principale e About).
struct AppMenuTitleView: View {
    let panelWidth: CGFloat

    @EnvironmentObject private var lm: LanguageManager

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.63, green: 0.25, blue: 0.03),
                Color(red: 0.35, green: 0.10, blue: 0.01)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var outlineColor: Color {
        Color(red: 1.0, green: 0.86, blue: 0.34)
    }

    private var titleFontSize: CGFloat {
        panelWidth * 0.13
    }

    private var titleLines: [String] {
        [
            lm.t("menu.title.line1"),
            lm.t("menu.title.line2")
        ]
    }

    var body: some View {
        VStack(spacing: panelWidth * 0.012) {
            ForEach(titleLines, id: \.self) { line in
                titleLine(line)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, panelWidth * 0.04)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(titleLines.joined(separator: " "))
    }

    @ViewBuilder
    private func titleLine(_ text: String) -> some View {
        ZStack {
            // Outline decorativo — nascosto dall'accessibilità per evitare
            // warning di contrasto (giallo-su-giallo: ratio 1.29 < 3.0)
            Text(text)
                .font(.app(size: titleFontSize, weight: .black, relativeTo: .largeTitle))
                .foregroundStyle(outlineColor)
                .offset(x: 1.5, y: 1.5)
                .accessibilityHidden(true)

            // Testo principale con gradiente — nascosto dall'accessibilità
            // perché il VStack padre fornisce l'accessibilityLabel combinato
            Text(text)
                .font(.app(size: titleFontSize, weight: .black, relativeTo: .largeTitle))
                .foregroundStyle(titleGradient)
                .accessibilityHidden(true)
        }
        .lineLimit(2)
        .minimumScaleFactor(0.5)
        .allowsTightening(true)
        .accessibilityHidden(true)
    }
}

