import Foundation

let p13 = "Sentendo che il pericolo era passato, la nonna uscì finalmente dall'armadio. Cappuccetto Rosso e la sua nonna si abbracciarono forte, così felici di essere finalmente sane e salve. Ringraziarono il coraggioso taglialegna con tutto il cuore per aver salvato loro la vita. Al tramonto, la mamma arrivò alla casetta, terrorizzata perché sua figlia era in ritardo. Quando vide tutti sani e salvi, pianse di gioia. Mentre Cappuccetto Rosso e sua madre tornavano a casa insieme sotto gli alberi, la bambina strinse forte la mano della mamma e disse: \"D'ora in poi, resteremo sempre sul sentiero, senza alcuna distrazione!\""

var sentences: [String] = []
p13.enumerateSubstrings(in: p13.startIndex..<p13.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}
for (i, s) in sentences.enumerated() {
    print("Sent \(i): \(s)")
}
