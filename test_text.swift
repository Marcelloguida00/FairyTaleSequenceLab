import Foundation

var p4Text = "One morning, her mother said: \"Grandmother is sick in bed with a bad cold."
var p5Text = "Take her this basket of fresh cakes, but remember: stay on the main path and do not stop!\" The little girl kissed her mother goodbye and promised: \"Don't worry, Mom! I will walk quickly and go straight to Grandmother's house.\" However, as soon as she entered the forest, she forgot her promise. She saw a patch of delicious wild strawberries and delicious flowers, so she put her basket down. \"Grandmother will love these!\" she thought, running around to pick them. Suddenly, she realized how late it was, rushed back to grab her basket, and hurried along the trail. As the woods grew darker, a large, dark wolf stepped out from behind the trees. Little Red Riding Hood's heart began to race. \"Where are you going all alone, little girl?\" the wolf asked in a deep voice."

var p5Sentences: [String] = []
p5Text.enumerateSubstrings(in: p5Text.startIndex..<p5Text.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        p5Sentences.append(s)
    }
}

let numSentencesToMove = 3
if p5Sentences.count > numSentencesToMove {
    let movedSentences = p5Sentences.prefix(numSentencesToMove).joined(separator: " ")
    p4Text = p4Text + " " + movedSentences
    p5Text = p5Sentences.dropFirst(numSentencesToMove).joined(separator: " ")
}

print("New P4: \(p4Text)")
print("New P5: \(p5Text)")

