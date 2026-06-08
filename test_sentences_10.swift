import Foundation

let p10 = "She noticed the door was wide open, which felt very strange. \"Grandmother, are you there?\" she called out, stepping inside."

var sentences: [String] = []
p10.enumerateSubstrings(in: p10.startIndex..<p10.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}
for (i, s) in sentences.enumerated() {
    print("Page 10 - Sent \(i): \(s)")
}
