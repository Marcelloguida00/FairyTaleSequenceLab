import Foundation

let scene1 = "C'era una volta, nel fitto di una grande foresta, una piccola casetta dove viveva una graziosa bambina. Tutti la chiamavano Cappuccetto Rosso perché la sua mamma le aveva cucito un bellissimo mantello rosso con un cappuccio abbinato. Una mattina, la mamma le disse: \"La nonna è a letto con un brutto raffreddore. Portale questo cestino di dolci freschi, ma ricorda: resta sul sentiero principale e non fermarti per nessun motivo!\" La bambina salutò la mamma con un bacio e promise: \"Non preoccuparti, mamma! Camminerò veloce e andrò dritta a casa della nonna.\""
let scene2 = "Tuttavia, non appena entrò nel bosco, dimenticò la sua promessa. Vide una macchia di deliziose fragoline di bosco e dei fiori meravigliosi, così posò il cestino a terra. \"Alla nonna piaceranno tantissimo!\" pensò, correndo qua e là per raccoglierli. Improvvisamente, si rese conto di quanto fosse tardi, tornò in fretta a prendere il cestino e riprese a camminare velocemente lungo il sentiero."
let scene3 = "Mentre il bosco diventava più scuro, un grosso lupo nero sbucò da dietro gli alberi. Il cuore di Cappuccetto Rosso iniziò a battere forte. \"Dove stai andando tutta sola, bambina?\" le chiese il lupo con voce profonda. \"Sto andando alla casetta di mia nonna, alla fine di questo sentiero, per portarle dei dolci,\" rispose lei timidamente. L'astuto lupo escogitò subito un piano. \"Buon viaggio!\" disse, e scomparve all'istante tra i cespugli."
let scene4 = "Il lupo corse più veloce che poté, pensando solo al suo prossimo pasto. Arrivò alla casetta e bussò dolcemente alla porta. Toc! Toc! \"Chi è?\" chiese la nonna. \"Sono io, Cappuccetto Rosso!\" rispose il lupo, camuffando la voce. \"Entra, cara, la porta è aperta,\" disse l'anziana signora."
let scene5 = "Il lupo irruppe nella stanza, ma l'astuta nonna si nascose rapidamente dentro l'armadio per non farsi trovare. Trovando la stanza vuota, il lupo indossò la sua cuffia da notte, si infilò nel letto e tirò su le coperte."
let scene6 = "Poco dopo, Cappuccetto Rosso arrivò e bussò. \"Entra, mia dolce bambina,\" sussurrò il lupo, cercando di sembrare affettuoso. La bambina entrò, ma notò che c'era qualcosa di molto strano."
let scene7 = "\"Oh, nonna, che voce profonda che hai!\" \"Per parlarti meglio, bambina mia.\" \"E che occhi grandi che hai!\" \"Per guardarti meglio, bambina mia.\" \"E che mani grandi che hai!\" \"Per abbracciarti meglio, bambina mia.\" \"Ma nonna... che bocca gigante che hai!\" sussultò lei. \"Per MANGIARTI meglio!\" ruggì il lupo. Saltò giù dal letto, ma Cappuccetto Rosso, terrorizzata, iniziò a urlare con tutto il fiato che aveva in gola!"
let scene8 = "Un taglialegna che passava di lì sentì le forti urla di Cappuccetto Rosso provenire dalla casetta. Corse più veloce che poté e sfondò la porta con un grosso bastone di legno. Vedendo il coraggioso taglialegna, il lupo codardo andò nel panico, saltò fuori dalla finestra e fuggì nel fitto del bosco, per non farsi mai più vedere. Sentendo che il pericolo era passato, la nonna finalmente uscì dall'armadio. Cappuccetto Rosso e la sua nonna si abbracciarono forte, così felici di essere finalmente sane e salve. Ringraziarono il coraggioso taglialegna con tutto il cuore per aver salvato loro la vita. Al tramonto, la mamma arrivò alla casetta, terrorizzata perché sua figlia era in ritardo. Quando vide tutti sani e salvi, pianse di gioia. Mentre Cappuccetto Rosso e la sua mamma tornavano a casa insieme sotto gli alberi, la bambina tenne forte la mano della mamma e disse: \"D'ora in poi, resteremo sempre sul sentiero, senza mai distrarci!\""

let fullText = [scene1, scene2, scene3, scene4, scene5, scene6, scene7, scene8].joined(separator: " ")
var sentences: [String] = []
fullText.enumerateSubstrings(in: fullText.startIndex..<fullText.endIndex, options: .bySentences) { substring, _, _, _ in
    if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
        sentences.append(s)
    }
}

let layouts: [Int] = [0, 1, 2, 1, 3, 0, 4, 5, 0, 0, 2]
let layoutWeights = [0: 1.0, 1: 0.4, 2: 1.0, 3: 0.4, 4: 0.5, 5: 0.4, 6: 0.5, 7: 0.5, 8: 0.6] // using integer keys

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
