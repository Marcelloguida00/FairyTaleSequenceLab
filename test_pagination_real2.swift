import Foundation

let scene1 = "Once upon a time, deep inside a thick forest, there was a small cottage where a lovely little girl lived. Everyone called her Little Red Riding Hood because her mother had made her a beautiful red cloak with a matching hood. One morning, her mother said: \"Grandmother is sick in bed with a bad cold. Take her this basket of fresh cakes, but remember: stay on the main path and do not stop!\" The little girl kissed her mother goodbye and promised: \"Don't worry, Mom! I will walk quickly and go straight to Grandmother's house.\""
let scene2 = "However, as soon as she entered the forest, she forgot her promise. She saw a patch of delicious wild strawberries and delicious flowers, so she put her basket down. \"Grandmother will love these!\" she thought, running around to pick them. Suddenly, she realized how late it was, rushed back to grab her basket, and hurried along the trail."
let scene3 = "As the woods grew darker, a large, dark wolf stepped out from behind the trees. Little Red Riding Hood's heart began to race. \"Where are you going all alone, little girl?\" the wolf asked in a deep voice. \"I'm going to my grandmother's cottage at the end of this path to bring her some cakes,\" she replied timidly. The clever wolf hatched a quick plan. \"Have a safe trip!\" he said, and instantly vanished into the bushes."
let scene4 = "The wolf ran as fast as he could, thinking only of his next meal. He arrived at the cottage and knocked gently on the door. Knock! Knock! \"Who is it?\" asked the grandmother. \"It's me, Little Red Riding Hood!\" the wolf replied, disguising his voice. \"Come in, dear, the door is unlocked,\" said the old woman."
let scene5 = "The wolf burst into the room, but the clever grandmother quickly hid inside the closet to avoid being found. Finding the room empty, the wolf put on her nightcap, climbed into her bed, and pulled up the covers."
let scene6 = "Soon after, Little Red Riding Hood arrived and knocked. \"Come in, my sweet child,\" the wolf whispered, trying to sound sweet. The girl stepped inside but noticed something was very strange."
let scene7 = "\"Oh, Grandmother, what a deep voice you have!\" \"The better to speak to you, my dear.\" \"And what big eyes you have!\" \"The better to see you, my dear.\" \"And what big hands you have!\" \"The better to hug you, my dear.\" \"But Grandmother... what a giant mouth you have!\" she gasped. \"The better to EAT YOU!\" the wolf roared. He jumped out of bed, but Little Red Riding Hood, terrified, started screaming as loud as she could!"
let scene8 = "A woodcutter passing by heard Little Red Riding Hood's loud screams coming from the cottage. He ran as fast as he could and burst through the door with a large wooden stick. Seeing the brave woodcutter, the cowardly wolf panicked, jumped out of the window, and ran deep into the forest, never to be seen again. Hearing that the danger was over, the grandmother finally came out of the closet. Little Red Riding Hood and her grandmother hugged each other tightly, so happy to be completely safe and sound at last. They thanked the brave woodcutter with all their hearts for saving their lives. At sunset, the mother arrived at the cottage, terrified because her daughter was late. When she saw everyone safe, she wept with joy. As Little Red Riding Hood and her mother walked back home together under the trees, the little girl held her mother's hand tightly and said: \"From now on, we will always stick to the path, without any distractions!\""

let fullText = [scene1, scene2, scene3, scene4, scene5, scene6, scene7, scene8].joined(separator: " ")
var sentences: [String] = []
fullText.enumerateSubstrings(in: fullText.startIndex..<fullText.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}

enum PageLayoutType {
    case fullText, poemCenterText, gatheredBottomRight, gatheredTopLeft, textTopImageBottom, imageTopTextBottom, imageLeftTextRight, imageTopRightTextWrap, textLeftImageRight
}

let layouts: [PageLayoutType] = [
    .textTopImageBottom,
    .imageTopTextBottom,
    .fullText,
    .imageTopTextBottom,
    .gatheredBottomRight,
    .textTopImageBottom,
    .poemCenterText,
    .imageTopRightTextWrap,
    .textTopImageBottom,
    .textTopImageBottom,
    .fullText
]

let layoutWeights: [PageLayoutType: Double] = [
    .fullText: 1.0,
    .poemCenterText: 0.5,
    .gatheredBottomRight: 0.5,
    .gatheredTopLeft: 0.5,
    .textTopImageBottom: 0.4,
    .imageTopTextBottom: 0.4,
    .imageLeftTextRight: 0.6,
    .imageTopRightTextWrap: 0.5,
    .textLeftImageRight: 0.6
]

let totalWeight = layouts.reduce(0.0) { $0 + (layoutWeights[$1] ?? 1.0) }
let totalChars = sentences.reduce(0) { $0 + $1.count + 1 }
var remainingTotalChars = totalChars
var remainingWeight = totalWeight
var currentSentenceIndex = 0

for pageIndex in 0..<layouts.count {
    let layout = layouts[pageIndex]
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
    
    if pageIndex == layouts.count - 1 {
        while currentSentenceIndex < sentences.count {
            let sentence = sentences[currentSentenceIndex]
            chunk += " " + sentence
            currentSentenceIndex += 1
        }
    }
    
    print("Page \(pageIndex + 3): \(chunk)")
    
    remainingTotalChars -= chunk.count
    remainingWeight -= currentWeight
}
