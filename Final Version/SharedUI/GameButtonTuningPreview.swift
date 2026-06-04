import SwiftUI

// MARK: - Canvas per regolare i bottoni
// Modifica le dimensioni in `GameButtonMetrics.swift`, poi Resume nel canvas.

/// Tutti i bottoni gialli + metriche attuali (legge `GameButtonMetrics` a runtime).
struct GameButtonTuningPreview: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                metricsPanel

                primaryPillSection

                defaultPillSection

                circleChromeSection

                menuStylePillSection
            }
            .padding(24)
        }
        .background(previewBackground)
    }

    private var previewBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.45, green: 0.62, blue: 0.38),
                Color(red: 0.32, green: 0.48, blue: 0.30)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Game buttons")
                .font(.title.bold())
                .foregroundStyle(.white)

            Text("Valori da `GameButtonMetrics.swift` · dispositivo: \(GameButtonMetrics.isPad ? "iPad" : "iPhone")")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
        }
    }

    private var metricsPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            previewSectionTitle("Metriche chrome (back, settings…)")

            metricRow("chromeCircleSize", GameButtonMetrics.chromeCircleSize)

            previewSectionTitle("Metriche primary (Play mappa)")

            metricRow("primaryPillWidth", GameButtonMetrics.primaryPillWidth)
            metricRow("primaryPillHeight", GameButtonMetrics.primaryPillHeight)
            metricRow("primaryPillFontSize", GameButtonMetrics.primaryPillFontSize)
            metricRow("primaryPillHorizontalPadding", GameButtonMetrics.primaryPillHorizontalPadding)
            metricRow("primaryPillVerticalPadding", GameButtonMetrics.primaryPillVerticalPadding)

            previewSectionTitle("Metriche pillola standard")

            metricRow("pillMinHeight", GameButtonMetrics.pillMinHeight)
            metricRow("pillFontSize", GameButtonMetrics.pillFontSize)
            metricRow("pillHorizontalPadding", GameButtonMetrics.pillHorizontalPadding)
            metricRow("pillVerticalPadding", GameButtonMetrics.pillVerticalPadding)
        }
        .padding(16)
        .background(previewCard)
    }

    private var primaryPillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            previewSectionTitle("Primary · Play (mappa)")

            slotOutline(
                width: GameButtonMetrics.primaryPillWidth,
                height: GameButtonMetrics.primaryPillHeight,
                label: "bounds"
            )
            .overlay {
                GamePrimaryPillButton(title: "PLAY", action: {})
            }

            GamePrimaryPillButton(title: "PLAY", action: {})
        }
        .padding(16)
        .background(previewCard)
    }

    private var defaultPillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            previewSectionTitle("Pillola default (Done, tutorial…)")

            GamePillButton(title: "DONE", action: {})

            GamePillButton(
                title: "CONTINUA",
                minWidth: 120,
                minHeight: GameButtonMetrics.pillMinHeight(atLeast: 52),
                trailingIcon: "arrow.right",
                action: {}
            )
        }
        .padding(16)
        .background(previewCard)
    }

    private var circleChromeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            previewSectionTitle("Cerchi chrome (mappa / AR)")

            HStack(spacing: 20) {
                GameCircleBackButton(action: {})
                GameCircleSettingsButton(action: {})
            }
        }
        .padding(16)
        .background(previewCard)
    }

    private var menuStylePillSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            previewSectionTitle("Menu (Play / Settings proporzionali)")

            let sampleWidth: CGFloat = 220

            GamePillButton(
                title: "PLAY",
                fontSize: sampleWidth * 0.14,
                horizontalPadding: sampleWidth * 0.07,
                verticalPadding: sampleWidth * 0.08,
                minWidth: sampleWidth,
                minHeight: GameButtonMetrics.pillMinHeight(atLeast: sampleWidth * 0.38),
                action: {}
            )

            GamePillButton(
                title: "SETTINGS",
                fontSize: sampleWidth * 0.14,
                horizontalPadding: sampleWidth * 0.07,
                verticalPadding: sampleWidth * 0.08,
                minWidth: sampleWidth,
                minHeight: GameButtonMetrics.pillMinHeight(atLeast: sampleWidth * 0.38),
                action: {}
            )
        }
        .padding(16)
        .background(previewCard)
    }

    // MARK: - Helpers

    private var previewCard: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(Color.black.opacity(0.22))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 1)
            )
    }

    private func previewSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundStyle(.white)
    }

    private func metricRow(_ name: String, _ value: CGFloat) -> some View {
        HStack {
            Text(name)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.white.opacity(0.75))
            Spacer()
            Text("\(Int(value)) pt")
                .font(.system(.caption, design: .monospaced).bold())
                .foregroundStyle(.white)
        }
    }

    private func slotOutline(width: CGFloat, height: CGFloat, label: String) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [6, 4]))
                .foregroundStyle(Color.white.opacity(0.45))
                .frame(width: width, height: height)

            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white.opacity(0.55))
        }
    }
}

// MARK: - Previews (apri il canvas su uno di questi)

#Preview("Bottoni · tuning") {
    GameButtonTuningPreview()
}

#Preview("Bottoni · iPad landscape", traits: .landscapeLeft) {
    GameButtonTuningPreview()
}

#Preview("Bottoni · iPhone", traits: .fixedLayout(width: 390, height: 844)) {
    GameButtonTuningPreview()
}

#Preview("Solo Play primary") {
    ZStack {
        Color(red: 0.45, green: 0.62, blue: 0.38)
        GamePrimaryPillButton(title: "PLAY", action: {})
    }
    .frame(width: 400, height: 200)
}
