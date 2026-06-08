import Foundation

let p8 = "She tried to act brave and replied: \"I'm going to Grandmother's house to bring her these cakes. She lives just past the old mill.\" \"How nice,\" the wolf said, thinking of a wicked plan. \"Why don't you pick some more flowers for her? I'm sure she would love them.\" While the girl was distracted, the wolf ran as fast as the wind straight to Grandmother's house. He knocked on the door: tap, tap, tap. When the grandmother saw the scary wolf, she quickly hid inside the wooden closet."
let p9 = "The wolf, feeling very clever, put on her nightgown and cap, then climbed into her bed to wait. A little while later, Little Red Riding Hood finally arrived at the cottage."
let p10 = "She noticed the door was wide open, which felt very strange. \"Grandmother, are you there?\" she called out, stepping inside."
let p11 = "The wolf pulled the blanket up to his chin and replied in a squeaky voice: \"Come closer, my dear.\" Little Red Riding Hood walked to the bed. \"Grandmother, what big ears you have!\" she said, confused. \"The better to hear you with, my dear,\" the wolf lied. \"And Grandmother... what big eyes you have!\" \"The better to see you with, my dear.\" \"But Grandmother... what big teeth you have!\" The wolf threw off the blanket and roared: \"THE BETTER TO EAT YOU WITH!\" A woodcutter passing by heard Little Red Riding Hood's loud screams coming from the cottage."

func printSentences(text: String, page: Int) {
    var sentences: [String] = []
    text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { substring, _, _, _ in
        if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            sentences.append(s)
        }
    }
    for (i, s) in sentences.enumerated() {
        print("Page \(page) - Sent \(i): \(s)")
    }
}

printSentences(text: p8, page: 8)
printSentences(text: p9, page: 9)
printSentences(text: p10, page: 10)
printSentences(text: p11, page: 11)
