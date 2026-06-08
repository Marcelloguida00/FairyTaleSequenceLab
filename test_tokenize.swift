import Foundation

let p10Text = "\"Come in, my sweet child,\" the wolf whispered, trying to sound sweet. The girl stepped inside but noticed something was very strange. \"Oh, Grandmother, what a deep voice you have!\" \"The better to speak to you, my dear.\" \"And what big eyes you have!\" \"The better to see you, my dear.\""

var p10Sentences: [String] = []
p10Text.enumerateSubstrings(in: p10Text.startIndex..<p10Text.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        p10Sentences.append(s)
    }
}
print("Count: \(p10Sentences.count)")
for (i, s) in p10Sentences.enumerated() {
    print("Sent \(i): \(s)")
}
