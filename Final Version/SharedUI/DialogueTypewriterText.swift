import SwiftUI

/// Testo dialogo con effetto digitato; `isFullyShown` diventa true a fine animazione o se saltata dal parent.
struct DialogueTypewriterText: View {
    let fullText: String
    let font: Font
    let color: Color
    let lineLimit: Int
    @Binding var isFullyShown: Bool

    @State private var visibleCount = 0

    private static let characterDelayNs: UInt64 = 60_000_000

    private var visibleText: String {
        if isFullyShown {
            return fullText
        }
        return String(fullText.prefix(visibleCount))
    }

    var body: some View {
        Text(visibleText)
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .animation(nil, value: visibleCount)
            .task(id: fullText) {
                await runTypewriter()
            }
            .onChange(of: isFullyShown) { _, revealed in
                if revealed {
                    visibleCount = fullText.count
                }
            }
    }

    @MainActor
    private func runTypewriter() async {
        isFullyShown = false
        visibleCount = 0

        guard !fullText.isEmpty else {
            isFullyShown = true
            return
        }

        for index in 1...fullText.count {
            if Task.isCancelled { return }
            if isFullyShown {
                visibleCount = fullText.count
                return
            }

            visibleCount = index
            try? await Task.sleep(nanoseconds: Self.characterDelayNs)
        }

        isFullyShown = true
    }
}
