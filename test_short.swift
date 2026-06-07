import Foundation

let text = """
Once upon a time, deep inside a thick forest, there was a small cottage where a lovely little girl lived. Everyone called her Little Red Riding Hood because her mother had made her a beautiful red cloak with a matching hood. One morning, her mother said: "Grandmother is sick in bed with a bad cold. Take her this basket of fresh cakes, but remember: stay on the main path and do not stop!"

The little girl kissed her mother goodbye and promised: "Don't worry, Mom! I will walk quickly and go straight to Grandmother's house." However, as soon as she entered the forest, she forgot her promise. She saw a patch of delicious wild strawberries and delicious flowers, so she put her basket down. "Grandmother will love these!" she thought, running around to pick them.

Suddenly, she realized how late it was, rushed back to grab her basket, and hurried along the trail.
"""

var sentences: [String] = []
text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}
var pageIndex = 0
var currentSentenceIndex = 0
let layouts = [0, 1, 2, 1, 3, 0, 4, 5, 0, 0, 2]
let layoutWeights = [0: 0.6, 1: 0.4, 2: 2.0, 3: 0.5, 4: 0.5, 5: 0.6]

let totalWeight = layouts.reduce(0.0) { $0 + (layoutWeights[$1] ?? 1.0) }
let totalChars = sentences.reduce(0) { $0 + $1.count + 1 }
var remainingTotalChars = totalChars
var remainingWeight = totalWeight

while currentSentenceIndex < sentences.count {
    let layout = layouts[pageIndex % layouts.count]
    let currentWeight = layoutWeights[layout] ?? 1.0
    
    var maxChars = 0
    if remainingWeight > 0 {
        maxChars = Int((currentWeight / remainingWeight) * Double(remainingTotalChars))
    } else {
        maxChars = remainingTotalChars
    }
    if maxChars < 50 { maxChars = 50 }
    
    var chunk = ""
    while currentSentenceIndex < sentences.count {
        let sentence = sentences[currentSentenceIndex]
        if chunk.isEmpty {
            chunk = sentence
        } else if chunk.count + sentence.count + 1 <= maxChars {
            chunk += " " + sentence
        } else {
            break
        }
        currentSentenceIndex += 1
    }
    print("Page \(pageIndex + 3): \(chunk)")
    
    if pageIndex == layouts.count {
        while currentSentenceIndex < sentences.count {
            let sentence = sentences[currentSentenceIndex]
            chunk += " " + sentence
            currentSentenceIndex += 1
        }
    } else {
        remainingTotalChars -= chunk.count
        remainingWeight -= currentWeight
    }
    pageIndex += 1
}

