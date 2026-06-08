import Foundation

let scene1 = "Once upon a time, deep inside a thick forest, there was a small cottage where a lovely little girl lived. Everyone called her Little Red Riding Hood because her mother had made her a beautiful red cloak with a matching hood. One morning, her mother said: \"Grandmother is sick in bed with a bad cold. Take her this basket of fresh cakes, but remember: stay on the main path and do not stop!\""
let scene2 = "The little girl kissed her mother goodbye and promised: \"Don't worry, Mom! I will walk quickly and go straight to Grandmother's house.\" However, as soon as she entered the forest, she forgot her promise. She saw a patch of delicious wild strawberries and delicious flowers, so she put her basket down. \"Grandmother will love these!\" she thought, running around to pick them."
let scene3 = "Suddenly, she realized how late it was, rushed back to grab her basket, and hurried along the trail. \"What a beautiful day!\" she said out loud. From behind a large oak tree, a dark shadow watched her closely. It was the Big Bad Wolf! He licked his lips, imagining a tasty snack."
let scene4 = "The wolf stepped out onto the path, blocking her way. He smiled a fake, toothy smile and said: \"Hello, little girl. What are you doing in the forest all alone?\" Little Red Riding Hood's heart began to race. \"Where are you going all alone, little girl?\" the wolf asked with a deep voice."
let scene5 = "She tried to act brave and replied: \"I'm going to Grandmother's house to bring her these cakes. She lives just past the old mill.\" \"How nice,\" the wolf said, thinking of a wicked plan. \"Why don't you pick some more flowers for her? I'm sure she would love them.\""
let scene6 = "While the girl was distracted, the wolf ran as fast as the wind straight to Grandmother's house. He knocked on the door: tap, tap, tap. When the grandmother saw the scary wolf, she quickly hid inside the wooden closet. The wolf, feeling very clever, put on her nightgown and cap, then climbed into her bed to wait."
let scene7 = "A little while later, Little Red Riding Hood finally arrived at the cottage. She noticed the door was wide open, which felt very strange. \"Grandmother, are you there?\" she called out, stepping inside. The wolf pulled the blanket up to his chin and replied in a squeaky voice: \"Come closer, my dear.\""
let scene8 = "Little Red Riding Hood walked to the bed. \"Grandmother, what big ears you have!\" she said, confused. \"The better to hear you with, my dear,\" the wolf lied. \"And Grandmother... what big eyes you have!\" \"The better to see you with, my dear.\" \"But Grandmother... what big teeth you have!\" The wolf threw off the blanket and roared: \"THE BETTER TO EAT YOU WITH!\""
let scene9 = "A woodcutter passing by heard Little Red Riding Hood's loud screams coming from the cottage. He ran as fast as he could and burst through the door with a large wooden stick. Seeing the brave woodcutter, the cowardly wolf panicked, jumped out of the window, and ran deep into the forest, never to be seen again. Hearing that the danger was over, the grandmother finally came out of the closet. Little Red Riding Hood and her grandmother hugged each other tightly, so happy to be completely safe and sound at last. They thanked the brave woodcutter with all their hearts for saving their lives. At sunset, the mother arrived at the cottage, terrified because her daughter was late. When she saw everyone safe, she wept with joy. As Little Red Riding Hood and her mother walked back home together under the trees, the little girl held her mother's hand tightly and said: \"From now on, we will always stick to the path, without any distractions!\""

let fullText = [scene1, scene2, scene3, scene4, scene5, scene6, scene7, scene8, scene9].joined(separator: " ")
var sentences: [String] = []
fullText.enumerateSubstrings(in: fullText.startIndex..<fullText.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}
var pageIndex = 0
var currentSentenceIndex = 0
let layouts = [0, 1, 2, 1, 3, 0, 4, 5, 0, 0, 2]
let layoutWeights = [0: 1.0, 1: 0.5, 2: 0.5, 3: 0.5, 4: 0.4, 5: 0.4, 6: 0.4, 7: 0.4, 8: 0.6, 9: 0.5, 10: 0.6, 11: 0.4, 12: 0.5]

let totalWeight = layouts.reduce(0.0) { $0 + (layoutWeights[$1] ?? 1.0) }
let totalChars = sentences.reduce(0) { $0 + $1.count + 1 }
var remainingTotalChars = totalChars
var remainingWeight = totalWeight

var pagesText: [String] = []

while currentSentenceIndex < sentences.count {
    let layout = layouts[pageIndex % layouts.count]
    let currentWeight = layoutWeights[layout] ?? 1.0
    var maxChars = remainingWeight > 0 ? Int((currentWeight / remainingWeight) * Double(remainingTotalChars)) : remainingTotalChars
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
    pagesText.append(chunk)
    
    if pageIndex == layouts.count - 1 {
        while currentSentenceIndex < sentences.count {
            pagesText[pageIndex] += " " + sentences[currentSentenceIndex]
            currentSentenceIndex += 1
        }
        break
    } else {
        remainingTotalChars -= chunk.count
        remainingWeight -= currentWeight
    }
    pageIndex += 1
}

// Shifts
var p9Sentences: [String] = []
pagesText[6].enumerateSubstrings(in: pagesText[6].startIndex..<pagesText[6].endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { p9Sentences.append(s) }
}
let movedToP8 = p9Sentences.prefix(1).joined(separator: " ")
pagesText[5] = pagesText[5] + " " + movedToP8
pagesText[6] = p9Sentences.dropFirst(1).joined(separator: " ")

var p10Sentences: [String] = []
pagesText[7].enumerateSubstrings(in: pagesText[7].startIndex..<pagesText[7].endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { p10Sentences.append(s) }
}

print("=== PAGE 10 ===")
for (i, s) in p10Sentences.enumerated() {
    print("Sent \(i): \(s)")
}

var p11Sentences: [String] = []
pagesText[8].enumerateSubstrings(in: pagesText[8].startIndex..<pagesText[8].endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty { p11Sentences.append(s) }
}
print("=== PAGE 11 ===")
for (i, s) in p11Sentences.enumerated() {
    print("Sent \(i): \(s)")
}

