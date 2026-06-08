import Foundation

let scene1_1 = "Once upon a time, deep inside a thick forest, there was a small cottage where a lovely little girl lived.\n\nEveryone called her Little Red Riding Hood because her mother had made her a beautiful red cloak with a matching hood."
let scene1_2 = "One morning, her mother said: \"Grandmother is sick in bed with a bad cold.\n\nTake her this basket of fresh cakes, but remember: stay on the main path and do not stop!\""
let scene2_1 = "The little girl kissed her mother goodbye and promised: \"Don't worry, Mom! I will walk quickly and go straight to Grandmother's house.\"\n\nHowever, as soon as she entered the forest, she forgot her promise."
let scene2_2 = "She saw a patch of delicious wild strawberries and beautiful flowers, so she put her basket down.\n\n\"Grandmother will love these!\" she thought, running around to pick them."
let scene3_1 = "Suddenly, she realized how late it was, rushed back to grab her basket, and hurried along the trail.\n\n\"What a beautiful day!\" she said out loud."
let scene3_2 = "From behind a large oak tree, a dark shadow watched her closely.\n\nIt was the Big Bad Wolf! He licked his lips, imagining a tasty snack."
let scene4_1 = "The wolf stepped out onto the path, blocking her way. He smiled a fake, toothy smile and said:\n\n\"Hello, little girl. What are you doing in the forest all alone?\""
let scene4_2 = "Little Red Riding Hood's heart began to race.\n\n\"Where are you going all alone, little girl?\" the wolf asked with a deep voice."
let scene5_1 = "She tried to act brave and replied: \"I'm going to Grandmother's house to bring her these cakes. She lives just past the old mill.\""
let scene5_2 = "\"How nice,\" the wolf said, thinking of a wicked plan.\n\n\"Why don't you pick some more flowers for her? I'm sure she would love them.\""
let scene6_1 = "While the girl was distracted, the wolf ran as fast as the wind straight to Grandmother's house.\n\nHe knocked on the door: tap, tap, tap."
let scene6_2 = "When the grandmother saw the scary wolf, she quickly hid inside the wooden closet.\n\nThe wolf, feeling very clever, put on her nightgown and cap, then climbed into her bed to wait."
let scene7_title = "Little Red Riding Hood"
let scene7_1 = "\"Come in, my sweet child,\" the wolf whispered, trying to sound sweet.\n\nThe girl stepped inside but noticed something was very strange.\n\n\"Oh, Grandmother, what a deep voice you have!\"\n\n\"The better to speak to you, my dear.\"\n\n\"And what big eyes you have!\"\n\n\"The better to see you, my dear.\""
let scene7_2 = "\"And what big hands you have!\"\n\n\"The better to hug you, my dear.\"\n\n\"But Grandmother... what a giant mouth you have!\" she gasped.\n\n\"The better to EAT YOU!\" the wolf roared.\n\nHe jumped out of bed, but Little Red Riding Hood, terrified, started screaming as loud as she could!"
let scene8_1 = "A woodcutter passing by heard Little Red Riding Hood's loud screams coming from the cottage. He ran as fast as he could and burst through the door with a large wooden stick.\n\nSeeing the brave woodcutter, the cowardly wolf panicked, jumped out of the window, and ran deep into the forest, never to be seen again."
let scene8_2 = "Hearing that the danger was over, the grandmother finally came out of the closet.\n\nLittle Red Riding Hood and her grandmother hugged each other tightly, so happy to be completely safe and sound at last. They thanked the brave woodcutter with all their hearts for saving their lives.\n\nAt sunset, the mother arrived at the cottage, terrified because her daughter was late. When she saw everyone safe, she wept with joy.\n\nAs Little Red Riding Hood and her mother walked back home together under the trees, the little girl held her mother's hand tightly and said: \"From now on, we will always stick to the path, without any distractions!\""

let fullText = [scene7_title, scene1_1, scene1_2, scene2_1, scene2_2, scene3_1, scene3_2, scene4_1, scene4_2, scene5_1, scene5_2, scene6_1, scene6_2, scene7_1, scene7_2, scene8_1, scene8_2].compactMap { $0 }.joined(separator: " ")

var sentences: [String] = []
fullText.enumerateSubstrings(in: fullText.startIndex..<fullText.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}
let layoutWeights = [0.4, 0.4, 1.0, 0.4, 0.5, 0.4, 0.5, 0.6, 0.4, 0.4, 1.0]

let totalWeight = layoutWeights.reduce(0.0, +)
let totalChars = sentences.reduce(0) { $0 + $1.count + 1 }
var remainingTotalChars = totalChars
var remainingWeight = totalWeight

var pageIndex = 0
var currentSentenceIndex = 0

while currentSentenceIndex < sentences.count {
    let currentWeight = layoutWeights[pageIndex]
    
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
    
    if pageIndex == layoutWeights.count - 1 {
        while currentSentenceIndex < sentences.count {
            let sentence = sentences[currentSentenceIndex]
            chunk += " " + sentence
            currentSentenceIndex += 1
        }
        print("Page \(pageIndex + 3) (FINAL): \(chunk)")
        break
    } else {
        remainingTotalChars -= chunk.count
        remainingWeight -= currentWeight
    }
    pageIndex += 1
}
