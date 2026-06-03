import SwiftUI
import UIKit

/// Suddivide il dialogo in segmenti che stanno in `maxLines` righe alla larghezza data.
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
        var result: [String] = []
        var remaining = trimmed

        while !remaining.isEmpty {
            let (chunk, rest) = nextChunk(
                from: remaining,
                font: font,
                maxWidth: maxWidth,
                maxLines: maxLines
            )
            result.append(chunk)
            remaining = rest
            if chunk.isEmpty { break }
        }

        return result.isEmpty ? [trimmed] : result
    }

    private static func nextChunk(
        from text: String,
        font: UIFont,
        maxWidth: CGFloat,
        maxLines: Int
    ) -> (String, String) {
        guard !text.isEmpty else { return ("", "") }

        var low = 1
        var high = text.count
        var best = 0

        while low <= high {
            let mid = (low + high) / 2
            let candidate = String(text.prefix(mid))
            if lineCount(for: candidate, font: font, maxWidth: maxWidth) <= maxLines {
                best = mid
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        if best == 0 {
            return (String(text.prefix(1)), String(text.dropFirst(1)).trimmingCharacters(in: .whitespaces))
        }

        var splitIndex = best
        if splitIndex < text.count {
            let prefix = text.prefix(splitIndex)
            if let lastSpace = prefix.lastIndex(where: { $0.isWhitespace }) {
                let spaceOffset = text.distance(from: text.startIndex, to: lastSpace)
                if spaceOffset > 0 {
                    splitIndex = spaceOffset
                }
            }
        }

        let chunk = String(text.prefix(splitIndex)).trimmingCharacters(in: .whitespaces)
        let restStart = text.index(text.startIndex, offsetBy: min(splitIndex, text.count))
        let rest = String(text[restStart...]).trimmingCharacters(in: .whitespaces)
        return (chunk, rest)
    }

    private static func lineCount(for text: String, font: UIFont, maxWidth: CGFloat) -> Int {
        guard !text.isEmpty else { return 0 }

        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byWordWrapping

        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraph
        ]

        let rect = (text as NSString).boundingRect(
            with: CGSize(width: maxWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )

        let lineHeight = font.lineHeight
        guard lineHeight > 0 else { return 1 }
        return max(1, Int(ceil(rect.height / lineHeight)))
    }

    private static func uiFont(size: CGFloat, weight: Font.Weight) -> UIFont {
        let name = AppTypography.fontName(for: weight)
        return UIFont(name: name, size: size) ?? .systemFont(ofSize: size, weight: .medium)
    }
}
