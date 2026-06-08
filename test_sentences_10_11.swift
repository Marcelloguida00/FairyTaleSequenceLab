import Foundation

let p10 = "Little Red Riding Hood walked to the bed. \"Grandmother, what big ears you have!\" she said, confused. \"The better to hear you with, my dear,\" the wolf lied. \"And Grandmother... what big eyes you have!\""
let p11 = "\"The better to see you with, my dear.\" \"But Grandmother... what big teeth you have!\" The wolf threw off the blanket and roared: \"THE BETTER TO EAT YOU WITH!\""

var p10Sentences: [String] = []
p10.enumerateSubstrings(in: p10.startIndex..<p10.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        p10Sentences.append(s)
    }
}

let numSentencesToMoveToP11 = 1
let movedToP11 = p10Sentences.suffix(numSentencesToMoveToP11).joined(separator: " ")
let newP11Text = movedToP11 + " " + p11
let newP10Text = p10Sentences.dropLast(numSentencesToMoveToP11).joined(separator: " ")

print("P10: \(newP10Text)")
print("P11: \(newP11Text)")
