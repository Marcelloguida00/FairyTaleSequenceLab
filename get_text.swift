import Foundation

// Assuming these are the texts from the localizable strings:
let scene1 = "Once upon a time, deep inside a thick forest, there was a small cottage where a lovely little girl lived. Everyone called her Little Red Riding Hood because her mother had made her a beautiful red cloak with a matching hood." + " " + "One morning, her mother said: \"Grandmother is sick in bed with a bad cold. Take her this basket of fresh cakes, but remember: stay on the main path and do not stop!\""
let scene2 = "The little girl kissed her mother goodbye and promised: \"Don't worry, Mom! I will walk quickly and go straight to Grandmother's house.\" However, as soon as she entered the forest, she forgot her promise." + " " + "She saw a patch of delicious wild strawberries and delicious flowers, so she put her basket down. \"Grandmother will love these!\" she thought, running around to pick them."
let scene3 = "Suddenly, she realized how late it was, rushed back to grab her basket, and hurried along the trail. \"What a beautiful day!\" she said out loud." + " " + "From behind a large oak tree, a dark shadow watched her closely. It was the Big Bad Wolf! He licked his lips, imagining a tasty snack."
let scene4 = "The wolf stepped out onto the path, blocking her way. He smiled a fake, toothy smile and said: \"Hello, little girl. What are you doing in the forest all alone?\"" + " " + "Little Red Riding Hood's heart began to race. \"Where are you going all alone, little girl?\" the wolf asked with a deep voice."
let scene5 = "She tried to act brave and replied: \"I'm going to Grandmother's house to bring her these cakes. She lives just past the old mill.\"" + " " + "\"How nice,\" the wolf said, thinking of a wicked plan. \"Why don't you pick some more flowers for her? I'm sure she would love them.\""
let scene6 = "While the girl was distracted, the wolf ran as fast as the wind straight to Grandmother's house. He knocked on the door: tap, tap, tap." + " " + "When the grandmother saw the scary wolf, she quickly hid inside the wooden closet. The wolf, feeling very clever, put on her nightgown and cap, then climbed into her bed to wait."
let scene7 = "A little while later, Little Red Riding Hood finally arrived at the cottage. She noticed the door was wide open, which felt very strange. \"Grandmother, are you there?\" she called out, stepping inside." + " " + "The wolf pulled the blanket up to his chin and replied in a squeaky voice: \"Come closer, my dear.\""
let scene8 = "Little Red Riding Hood walked to the bed. \"Grandmother, what big ears you have!\" she said, confused. \"The better to hear you with, my dear,\" the wolf lied. \"And Grandmother... what big eyes you have!\" \"The better to see you with, my dear.\"" + " " + "\"But Grandmother... what big teeth you have!\" The wolf threw off the blanket and roared: \"THE BETTER TO EAT YOU WITH!\""
let scene9 = "Hearing that the danger was over, the grandmother finally came out of the closet. Little Red Riding Hood and her grandmother hugged each other tightly, so happy to be completely safe and sound at last. They thanked the brave woodcutter with all their hearts for saving their lives." + " " + "At sunset, the mother arrived at the cottage, terrified because her daughter was late. When she saw everyone safe, she wept with joy. As Little Red Riding Hood and her mother walked back home together under the trees, the little girl held her mother's hand tightly and said: \"From now on, we will always stick to the path, without any distractions!\""

let fullText = [scene1, scene2, scene3, scene4, scene5, scene6, scene7, scene8, scene9].joined(separator: " ")
var sentences: [String] = []
fullText.enumerateSubstrings(in: fullText.startIndex..<fullText.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}
for (i, s) in sentences.enumerated() {
    print("\(i): \(s)")
}
