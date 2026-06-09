import SwiftUI

/// Narrator caption bar: horizontal frame + typewriter text with tap-to-reveal chunks.
struct NarratorScriptBar: View {
    let message: String
    let maxWidth: CGFloat

    @State private var chunkIndex = 0
    @State private var isTextFullyShown = false

    var body: some View {
        let chunks = narratorChunks
        let displayText = narratorDisplayText(chunks: chunks)

        NarratorFramePanel(
            text: displayText,
            isTextFullyShown: $isTextFullyShown
        )
        .frame(maxWidth: maxWidth)
        .contentShape(Rectangle())
        .onTapGesture { handleTap(chunks: chunks) }
        .onChange(of: message) { _, _ in
            chunkIndex = 0
            isTextFullyShown = false
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
    }

    private var narratorChunks: [String] {
        let fontSize = NarratorFrameMetrics.scaledFontSize(
            NarratorFrameMetrics.dialogueFontSize,
            frameWidth: maxWidth
        )
        let textWidth = max(
            1,
            maxWidth * NarratorFrameMetrics.dialogueTextBoxWidthRatio
                - (NarratorFrameMetrics.scaled(NarratorFrameMetrics.bodyPaddingHorizontal, frameWidth: maxWidth) * 2)
        )
        return DialogueTextPaginator.chunks(
            text: message,
            fontSize: fontSize,
            maxWidth: textWidth,
            maxLines: NarratorFrameMetrics.dialogueLineLimit
        )
    }

    private func narratorDisplayText(chunks: [String]) -> String {
        guard !chunks.isEmpty else { return message }
        let index = min(chunkIndex, chunks.count - 1)
        return chunks[index]
    }

    private func handleTap(chunks: [String]) {
        AppSettings.hapticImpact(.light)

        if !isTextFullyShown {
            isTextFullyShown = true
            return
        }

        guard chunkIndex < chunks.count - 1 else { return }

        withAnimation(.easeInOut(duration: 0.15)) {
            chunkIndex += 1
        }
        isTextFullyShown = false
    }
}
