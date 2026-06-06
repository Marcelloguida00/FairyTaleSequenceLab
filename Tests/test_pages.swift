import Foundation

let text = """
Once upon a time, there was a sweet little girl who lived in a village near the forest. She always wore a beautiful red velvet riding hood that her grandmother had made for her. Everyone in the village simply called her Little Red Riding Hood.
One sunny morning, her mother called her from the kitchen. "Little Red Riding Hood, your grandmother is feeling ill," she said gently. "Please take this basket with some fresh bread, cheese, and a slice of cake. It will make her feel much better."
"Of course, Mother," the little girl replied cheerfully. "But remember," her mother warned, "stay on the path and do not talk to strangers!" "I promise," Little Red Riding Hood said as she kissed her mother goodbye and skipped out the door.
As she entered the woods, the tall trees created cool shadows along the path. The birds were singing, and colorful butterflies danced in the air. The little girl soon forgot her mother's warning and began picking wildflowers.
As the woods grew darker, a large, dark wolf stepped out from behind the trees. Little Red Riding Hood's heart began to race. "Where are you going all alone, little girl?" the wolf asked in a deep voice.
"I'm going to my grandmother's cottage at the end of this path to bring her some cakes," she replied timidly. The clever wolf hatched a quick plan. "Have a safe trip!" he said, and instantly vanished into the bushes.
The wolf ran as fast as he could, thinking only of his next meal. He arrived at the cottage and knocked gently on the door. Knock! Knock!
"Who is it?" asked the grandmother. "It's me, Little Red Riding Hood!" the wolf replied, disguising his voice. "Come in, dear, the door is unlocked," said the old woman.
The wolf burst into the room, but the clever grandmother quickly hid inside the closet to avoid being found.
Finding the room empty, the wolf put on her nightcap, climbed into her bed, and pulled up the covers.
Soon after, Little Red Riding Hood arrived and knocked. "Come in, my sweet child," the wolf whispered, trying to sound sweet.
The girl stepped inside but noticed something was very strange.
"Oh, Grandmother, what a deep voice you have!" "The better to speak to you, my dear." "And what big eyes you have!" "The better to see you, my dear."
"And what big hands you have!" "The better to hug you, my dear." "But Grandmother... what a giant mouth you have!" she gasped. "The better to EAT YOU!" the wolf roared. He jumped out of bed, but Little Red Riding Hood, terrified, started screaming as loud as she could!
A woodcutter passing by heard Little Red Riding Hood's loud screams coming from the cottage. He ran as fast as he could and burst through the door with a large wooden stick.
Seeing the brave woodcutter, the cowardly wolf panicked, jumped out of the window, and ran deep into the forest, never to be seen again.
Hearing that the danger was over, the grandmother finally came out of the closet. Both she and Little Red Riding Hood were completely safe and sound.
"Thank you! You saved us just in time," the grandmother cheered.
At sunset, the mother arrived at the cottage, terrified because her daughter was late. When she saw everyone safe, she wept with joy.
As Little Red Riding Hood and her mother walked back home together under the trees, the little girl held her mother's hand tightly and said: "From now on, we will always stick to the path, without any distractions!"
"""

var sentences: [String] = []
text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}

let layouts = [
    200, // Page 3
    200, // Page 4
    500, // Page 5
    200, // Page 6
    200, // Page 7
    320, // Page 8
    250, // Page 9
    320, // Page 10
    200, // Page 11
    320, // Page 12
    500, // Page 13
    200  // Page 14
]

func testMultiplier(_ mult: Double) {
    var pageIndex = 0
    var currentSentenceIndex = 0

    while currentSentenceIndex < sentences.count {
        var maxChars = layouts[pageIndex % layouts.count]
        var targetChars1 = maxChars
        pageIndex += 1
        
        if pageIndex >= 5 {
            maxChars = Int(Double(maxChars) * mult)
            targetChars1 = Int(Double(targetChars1) * mult)
        }
        
        var chunk1 = ""
        while currentSentenceIndex < sentences.count {
            let sentence = sentences[currentSentenceIndex]
            if chunk1.isEmpty {
                chunk1 = sentence
            } else if chunk1.count + sentence.count + 1 <= targetChars1 {
                chunk1 += " " + sentence
            } else {
                break
            }
            currentSentenceIndex += 1
        }
        print("Page \(pageIndex + 2): \(chunk1.count) chars")
    }
    let totalPages = pageIndex + 2
    let evenPages = totalPages % 2 != 0 ? totalPages + 1 : totalPages
    print("Multiplier \(mult) -> Book pages: \(evenPages)")
}

testMultiplier(1.3)
testMultiplier(1.4)

