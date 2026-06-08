import Foundation

// Copying the EXACT generateEditorialPages from BookView.swift
struct PageContent {
    let layout: Int
    var textChunk1: String
    var textChunk2: String?
    var imageName: String?
}

func generateEditorialPages(text: String, isDyslexiaEnabled: Bool, isCompact: Bool) -> [PageContent] {
    var sentences: [String] = []
    text.enumerateSubstrings(in: text.startIndex..<text.endIndex, options: .bySentences) { substring, _, _, _ in
        if let s = substring?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty {
            sentences.append(s)
        }
    }
    
    let layouts: [Int] = [
        0, // textTopImageBottom
        1, // imageTopTextBottom
        2, // fullText
        1, // imageTopTextBottom
        3, // gatheredBottomRight
        0, // textTopImageBottom
        4, // poemCenterText
        5, // imageTopRightTextWrap
        0, // textTopImageBottom
        0, // textTopImageBottom
        2  // fullText
    ]
    
    let layoutWeights: [Int: Double] = [
        2: 1.0,   // fullText
        4: 0.5,   // poemCenterText
        3: 0.5,   // gatheredBottomRight
        6: 0.5,   // gatheredTopLeft
        0: 0.4,   // textTopImageBottom
        1: 0.4,   // imageTopTextBottom
        7: 0.6,   // imageLeftTextRight
        5: 0.5,   // imageTopRightTextWrap
        8: 0.6    // textLeftImageRight
    ]
    
    let totalWeight = layouts.reduce(0.0) { $0 + (layoutWeights[$1] ?? 1.0) }
    let totalChars = sentences.reduce(0) { $0 + $1.count + 1 }
    var remainingTotalChars = totalChars
    var remainingWeight = totalWeight
    
    var pages: [PageContent] = []
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
        
        let minCharsPerBlock = isDyslexiaEnabled ? (isCompact ? 50 : 80) : (isCompact ? 80 : 120)
        if maxChars < minCharsPerBlock { maxChars = minCharsPerBlock }
        
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
        
        let page = PageContent(layout: layout, textChunk1: chunk)
        pages.append(page)
        
        remainingTotalChars -= chunk.count
        remainingWeight -= currentWeight
    }
    
    return pages
}

let scene1 = "C'era una volta, nel fitto di una grande foresta, una piccola casetta dove viveva una graziosa bambina. Tutti la chiamavano Cappuccetto Rosso perché la sua mamma le aveva cucito un bellissimo mantello rosso con un cappuccio abbinato."
let scene2 = "Una mattina, la mamma le disse: \"La nonna è a letto con un brutto raffreddore. Portale questo cestino di dolci freschi, ma ricorda: resta sul sentiero principale e non fermarti per nessun motivo!\"\n\nLa bambina salutò la mamma con un bacio e promise: \"Non preoccuparti, mamma! Camminerò veloce e andrò dritta a casa della nonna.\""
let scene3 = "Tuttavia, non appena entrò nel bosco, dimenticò la sua promessa. Vide una macchia di deliziose fragoline di bosco e dei fiori meravigliosi, così posò il cestino a terra."
let scene4 = "\"Alla nonna piaceranno tantissimo!\" pensò, correndo qua e là per raccoglierli.\n\nImprovvisamente, si rese conto di quanto fosse tardi, tornò in fretta a prendere il cestino e riprese a camminare velocemente lungo il sentiero."
let scene5 = "Mentre il bosco diventava più scuro, un grosso lupo nero sbucò da dietro gli alberi. Il cuore di Cappuccetto Rosso iniziò a battere forte.\n\n\"Dove stai andando tutta sola, bambina?\" le chiese il lupo con voce profonda."
let scene6 = "\"Sto andando alla casetta di mia nonna, alla fine di questo sentiero, per portarle dei dolci,\" rispose lei timidamente.\n\nL'astuto lupo escogitò subito un piano. \"Buon viaggio!\" disse, e scomparve all'istante tra i cespugli."
let scene7 = "Il lupo corse più veloce che poté, pensando solo al suo prossimo pasto. Arrivò alla casetta e bussò dolcemente alla porta. Toc! Toc!"
let scene8 = "\"Chi è?\" chiese la nonna.\n\n\"Sono io, Cappuccetto Rosso!\" rispose il lupo, camuffando la voce.\n\n\"Entra, cara, la porta è aperta,\" disse l'anziana signora."
let scene9 = "Il lupo irruppe nella stanza, ma l'astuta nonna si nascose rapidamente dentro l'armadio per non farsi trovare."
let scene10 = "Trovando la stanza vuota, il lupo indossò la sua cuffia da notte, si infilò nel letto e tirò su le coperte."
let scene11 = "Poco dopo, Cappuccetto Rosso arrivò e bussò.\n\n\"Entra, mia dolce bambina,\" sussurrò il lupo, cercando di sembrare affettuoso."
let scene12 = "La bambina entrò, ma notò che c'era qualcosa di molto strano."
let scene13 = "\"Oh, nonna, che voce profonda che hai!\"\n\n\"Per parlarti meglio, bambina mia.\"\n\n\"E che occhi grandi che hai!\"\n\n\"Per guardarti meglio, bambina mia.\""
let scene14 = "\"E che mani grandi che hai!\"\n\n\"Per abbracciarti meglio, bambina mia.\"\n\n\"Ma nonna... che bocca gigante che hai!\" sussultò lei.\n\n\"Per MANGIARTI meglio!\" ruggì il lupo.\n\nSaltò giù dal letto, ma Cappuccetto Rosso, terrorizzata, iniziò a urlare con tutto il fiato che aveva in gola!"
let scene15 = "Un taglialegna che passava di lì sentì le forti urla di Cappuccetto Rosso provenire dalla casetta. Corse più veloce che poté e sfondò la porta con un grosso bastone di legno.\n\nVedendo il coraggioso taglialegna, il lupo codardo andò nel panico, saltò fuori dalla finestra e fuggì nel fitto del bosco, per non farsi mai più vedere."
let scene16 = "Sentendo che il pericolo era passato, la nonna finalmente uscì dall'armadio.\n\nCappuccetto Rosso e la sua nonna si abbracciarono forte, così felici di essere finalmente sane e salve. Ringraziarono il coraggioso taglialegna con tutto il cuore per aver salvato loro la vita.\n\nAl tramonto, la mamma arrivò alla casetta, terrorizzata perché sua figlia era in ritardo. Quando vide tutti sani e salvi, pianse di gioia.\n\nMentre Cappuccetto Rosso e la sua mamma tornavano a casa insieme sotto gli alberi, la bambina tenne forte la mano della mamma e disse: \"D'ora in poi, resteremo sempre sul sentiero, senza mai distrarci!\""

let fullTextIt = [scene1, scene2, scene3, scene4, scene5, scene6, scene7, scene8, scene9, scene10, scene11, scene12, scene13, scene14, scene15, scene16].joined(separator: " ")

let pages = generateEditorialPages(text: fullTextIt, isDyslexiaEnabled: false, isCompact: false)

for (i, p) in pages.enumerated() {
    print("Page \(i + 3): \(p.textChunk1)")
}
