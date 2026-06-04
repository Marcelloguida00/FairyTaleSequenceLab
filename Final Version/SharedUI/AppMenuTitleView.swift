import SwiftUI

/// Titolo «Lumi: A journey through fables» (stesso stile del menu principale).
struct AppMenuTitleView: View {
    let panelWidth: CGFloat

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

    private var titleFontSize: CGFloat {
        panelWidth * 0.13
    }

    private var titleLines: [String] {
        [
            lm.t("menu.title.line1"),
            lm.t("menu.title.line2"),
            lm.t("menu.title.line3")
        ]
    }

    var body: some View {
        VStack(spacing: panelWidth * 0.012) {
            ForEach(titleLines, id: \.self) { line in
                titleLine(line)
            }
        }
        .padding(.horizontal, panelWidth * 0.04)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(titleLines.joined(separator: " "))
    }

    @ViewBuilder
    private func titleLine(_ text: String) -> some View {
        ZStack {
            Text(text)
                .font(.app(size: titleFontSize, weight: .black))
                .foregroundStyle(outlineColor)
                .offset(x: 1.5, y: 1.5)

            Text(text)
                .font(.app(size: titleFontSize, weight: .black))
                .foregroundStyle(titleGradient)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.55)
    }
}
