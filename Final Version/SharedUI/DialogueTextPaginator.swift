import SwiftUI
import UIKit

/// Suddivide il dialogo in segmenti da `maxLines` righe con scorrimento riga per riga.
enum DialogueTextPaginator {
    static func chunks(
        text: String,
        fontSize: CGFloat,
        maxWidth: CGFloat,
        maxLines: Int = 2,
        weight: Font.Weight = .medium
    ) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, maxWidth > 0, maxLines > 0 else { return [trimmed] }

        let font = uiFont(size: fontSize, weight: weight)
        let lines = wrappedLines(text: trimmed, font: font, maxWidth: maxWidth)

        guard lines.count > maxLines else {
            return [lines.joined(separator: "\n")]
        }

        var result: [String] = []
        let lastStart = lines.count - maxLines
        for start in 0...lastStart {
            let window = lines[start..<(start + maxLines)]
            result.append(window.joined(separator: "\n"))
        }
        return result
    }

    /// Word-wrap a fixed width using the same font as dialogue rendering.
    static func wrappedLines(
        text: String,
        fontSize: CGFloat,
        maxWidth: CGFloat,
        weight: Font.Weight = .medium
    ) -> [String] {
        wrappedLines(text: text, font: uiFont(size: fontSize, weight: weight), maxWidth: maxWidth)
    }

    private static func wrappedLines(text: String, font: UIFont, maxWidth: CGFloat) -> [String] {
        guard !text.isEmpty, maxWidth > 0 else { return [text] }

        let words = text.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !words.isEmpty else { return [text] }

        var lines: [String] = []
        var current = ""

        for word in words {
            let candidate = current.isEmpty ? word : "\(current) \(word)"
            if current.isEmpty || singleLineWidth(candidate, font: font) <= maxWidth {
                current = candidate
            } else {
                lines.append(current)
                current = word
            }
        }

        if !current.isEmpty {
            lines.append(current)
        }

        return lines.isEmpty ? [text] : lines
    }

    private static func singleLineWidth(_ text: String, font: UIFont) -> CGFloat {
        let size = (text as NSString).size(withAttributes: [.font: font])
        return ceil(size.width)
    }

    private static func uiFont(size: CGFloat, weight: Font.Weight) -> UIFont {
        let name = AppTypography.fontName(for: weight)
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .medium)
    }
}
