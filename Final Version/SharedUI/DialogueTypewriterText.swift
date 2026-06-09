import SwiftUI

/// Testo dialogo rivelato parola per parola; `isFullyShown` diventa true a fine animazione o se saltata dal parent.
struct DialogueTypewriterText: View {
    let fullText: String
    let font: Font
    let color: Color
    let lineLimit: Int
    @Binding var isFullyShown: Bool

    @State private var visibleWordCount = 0

    @Environment(\.accessibilityReduceMotion) private var sysReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations = false
    private var reduceMotion: Bool { sysReduceMotion || reduceAnimations }

    private static let wordDelayNs: UInt64 = 165_000_000

    private var wordCount: Int {
        fullText.split(whereSeparator: \.isWhitespace).count
    }

    private var visibleText: String {
        if isFullyShown {
            return fullText
        }
        guard visibleWordCount > 0 else { return "" }
        return partialText(wordCount: visibleWordCount)
    }

    private func partialText(wordCount: Int) -> String {
        var revealed = 0
        var result = ""

        var index = fullText.startIndex
        while index < fullText.endIndex {
            if fullText[index].isWhitespace {
                if fullText[index] == "\n" {
                    result.append("\n")
                } else if !result.isEmpty, !result.hasSuffix("\n"), !result.hasSuffix(" ") {
                    result.append(" ")
                }
                index = fullText.index(after: index)
                continue
            }

            let wordStart = index
            while index < fullText.endIndex, !fullText[index].isWhitespace {
                index = fullText.index(after: index)
            }

            revealed += 1
            if revealed > wordCount { break }

            if !result.isEmpty, !result.hasSuffix("\n"), !result.hasSuffix(" ") {
                result.append(" ")
            }
            result.append(String(fullText[wordStart..<index]))
        }

        return result
    }

    var body: some View {
        Text(visibleText)
            .font(font)
            .foregroundColor(color)
            .multilineTextAlignment(.center)
            .lineLimit(lineLimit)
            .animation(nil, value: visibleWordCount)
            .task(id: fullText) {
                await runWordReveal()
            }
            .onChange(of: isFullyShown) { _, revealed in
                if revealed {
                    visibleWordCount = wordCount
                }
            }
    }

    @MainActor
    private func runWordReveal() async {
        isFullyShown = false
        visibleWordCount = 0

        guard !fullText.isEmpty else {
            isFullyShown = true
            return
        }

        let totalWords = wordCount
        if reduceMotion {
            visibleWordCount = totalWords
            isFullyShown = true
            return
        }

        for index in 1...totalWords {
            if Task.isCancelled { return }
            if isFullyShown {
                visibleWordCount = totalWords
                return
            }

            visibleWordCount = index
            try? await Task.sleep(nanoseconds: Self.wordDelayNs)
        }

        isFullyShown = true
    }
}
