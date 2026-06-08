import Foundation

let p12 = "He ran as fast as he could and burst through the door with a large wooden stick. Seeing the brave woodcutter, the cowardly wolf panicked, jumped out of the window, and ran deep into the forest, never to be seen again."
let p13 = "Hearing that the danger was over, the grandmother finally came out of the closet. Little Red Riding Hood and her grandmother hugged each other tightly, so happy to be completely safe and sound at last. They thanked the brave woodcutter with all their hearts for saving their lives. At sunset, the mother arrived at the cottage, terrified because her daughter was late. When she saw everyone safe, she wept with joy. As Little Red Riding Hood and her mother walked back home together under the trees, the little girl held her mother's hand tightly and said: \"From now on, we will always stick to the path, without any distractions!\""

var p13Sentences: [String] = []
p13.enumerateSubstrings(in: p13.startIndex..<p13.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        p13Sentences.append(s)
    }
}
for (i, s) in p13Sentences.enumerated() {
    print("Sentence \(i): \(s)")
}

let movedToP12 = p13Sentences.prefix(2).joined(separator: " ")
let keepOnP13 = p13Sentences.dropFirst(2).prefix(3).joined(separator: " ")

print("---")
print("movedToP12: \(movedToP12)")
print("keepOnP13: \(keepOnP13)")
