import Foundation

var p10Text = "\"Come in, my sweet child,\" the wolf whispered, trying to sound sweet. The girl stepped inside but noticed something was very strange. \"Oh, Grandmother, what a deep voice you have!\" \"The better to speak to you, my dear.\" \"And what big eyes you have!\" \"The better to see you, my dear.\" \"And what big hands you have!\" \"The better to hug you, my dear.\""

var p10Sentences: [String] = []
p10Text.enumerateSubstrings(in: p10Text.startIndex..<p10Text.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        p10Sentences.append(s)
    }
}

if let idx = p10Sentences.firstIndex(where: { $0.lowercased().contains("see you") || $0.lowercased().contains("vederti") }) {
    let sentencesToMove = p10Sentences.suffix(from: idx)
    let movedToP11 = sentencesToMove.joined(separator: " ")
    let newP10Text = p10Sentences.prefix(upTo: idx).joined(separator: " ")
    print("NEW P10: \(newP10Text)")
    print("MOVED: \(movedToP11)")
} else {
    print("NOT FOUND")
}
