import Foundation
let text = "\"Oh, Grandmother, what a deep voice you have!\" \"The better to speak to you, my dear.\""
var elements: [String] = []
text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        elements.append(s)
    }
}
print(elements)
