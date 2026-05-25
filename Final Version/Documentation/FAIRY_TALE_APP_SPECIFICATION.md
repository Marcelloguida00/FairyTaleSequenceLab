# Interactive Fairy Tale Sequencing Lab - Specifica Tecnica Completa

## 🎯 Panoramica Progetto

Un'app educativa per iPad (SwiftUI) che insegna ai bambini la sequenza logica, la causa e l'effetto, e la progressione narrativa attraverso le fiabe classiche.

**Elemento principale di questa versione:** Mappa interattiva con personaggio che si muove tramite TAP, transizioni con nuvole, e progressione visiva sulla sotto-mappa per ogni fiaba.

---

## 📋 ARCHITETTURA GENERALE

### Flusso Principale dell'App

```
HOME SCREEN
    ↓
MAPPA PRINCIPALE (con personaggio)
    ↓ [Tap su una fiaba]
TRANSIZIONE NUVOLE (schermata di caricamento)
    ↓
SOTTO-MAPPA DELLA FIABA (personaggio cammina e sblocca eventi)
    ↓ [Per ogni evento]
EVENT INTRODUCTION → SEQUENCING ACTIVITY → REWARD → PROGRESSO MAPPA
    ↓ [Dopo 8 eventi completati]
FINAL STORYBOOK
    ↓ [Button "Torna alla Mappa"]
MAPPA PRINCIPALE
```

---

## 🗺️ SCHERMO 1: HOME SCREEN

**Contenuto:**
- Titolo: "Interactive Fairy Tale Sequencing Lab"
- Grande bottone: "Start" (o "Inizia")
- Sfondo colorato e storybook-like

**Azione:**
- Tap su "Start" → naviga a MAPPA PRINCIPALE

---

## 🗺️ SCHERMO 2: MAPPA PRINCIPALE

### Visualizzazione
- **Immagine di sfondo:** mappa.png (quella fornita)
- **Personaggio:** Inizia in una posizione iniziale sulla mappa (es. in basso a sinistra)
- **Fiabe posizionate:** 6 location diverse sulla mappa (castelli, case, monti, spiaggia, ecc.)

### Fiabe Disponibili (da definire sulla mappa)
Per questa versione **implementare completamente:**
- ✅ Little Red Riding Hood (8 eventi)

**Altre fiabe (struttura preparata ma bloccate):**
- 🔒 The Three Little Pigs
- 🔒 Cinderella
- 🔒 Hansel and Gretel
- 🔒 The Ugly Duckling
- 🔒 Goldilocks and the Three Bears

### Meccanica di Movimento del Personaggio

**Input:** Tap sulla mappa

**Comportamento:**
1. Il bambino tappa su una locazione della mappa
2. Il personaggio determina la direzione verso quel punto
3. Carica il frame di animazione corrispondere (fronte/dietro/sinistra/destra)
4. Anima il movimento con i 4 frame di camminata della direzione
5. Quando raggiunge la destinazione:
   - Se è una fiaba già iniziata → entra nella SOTTO-MAPPA di quella fiaba
   - Se è una fiaba nuova → TRANSIZIONE NUVOLE + SOTTO-MAPPA

**Velocità movimento:** Circa 1-2 secondi per raggiungere la destinazione (regolabile)

**Animazione Sprite:**
- Cicla tra i 4 frame della direzione attuale
- Frame rate: ~100ms per frame (regolabile)
- Il personaggio si orienta verso la destinazione (cambia direzione se necessario)
- Quando raggiunge la destinazione, torna al frame "fermo" della direzione finale

**Vincoli:**
- Non puoi tappare mentre il personaggio si sta muovendo (disabilita tap durante movimento)
- Il personaggio non può camminare su aree non-path (deve seguire i sentieri della mappa)

**Calcolo Direzione:**
- Se destinazione è più a destra → DESTRA
- Se destinazione è più a sinistra → SINISTRA
- Se destinazione è più in alto → DIETRO
- Se destinazione è più in basso → FRONTE
- (Oppure calcolo diagonale se necessario)

### Visuals per Fiaba sulla Mappa

Ogni fiaba mostra:
- **Icona/Illustrazione della locazione**
- **Stato di completamento:**
  - 🔒 Bloccata (grigia, non tappabile)
  - 🔓 Sbloccata (colorata, tappabile)
  - ✅ Completata (con badge stella o segno di completamento)
- **Progresso visivo:** (es. numeri 0/8, 3/8, 8/8 eventi completati)

### Persistenza

- **Salva:** Ultima posizione del personaggio sulla mappa principale
- **Salva:** Per ogni fiaba: quanti eventi sono stati completati
- **Salva:** Quali fiabe sono state completate interamente

---

## 🗺️ SCHERMO 3: TRANSIZIONE NUVOLE

**Trigger:** Quando il personaggio raggiunge una nuova fiaba non ancora visita

**Animazione:**
1. Schermo si scurisce leggermente
2. Nuvole animate entrano da sopra, coprendo gradualmente lo schermo
3. Effetto dissolvenza / fade
4. Dura circa 1-2 secondi
5. Dopo la transizione, la nuvola si dissipa e appare la SOTTO-MAPPA

**UX:** Deve essere piacevole e non fastidiosa, adatta ai bambini

---

## 🗺️ SCHERMO 4: SOTTO-MAPPA (Mappa della Fiaba)

**Contenuto:**
- Illustrazione della sotto-mappa specifica della fiaba (per Little Red Riding Hood: casa → foresta → casa nonna)
- **Personaggio:** Posizionato all'inizio del percorso
- **8 Nodi/Tappe:** Una per ogni evento
  - Bloccati = Grigio/Opaco, non tappabili
  - Sbloccati = Colorati, tappabili
  - Completati = Verde brillante con checkmark/stella, mostra illustrazione evento

### Meccanica sulla Sotto-Mappa

**Stato iniziale:**
- Solo il primo nodo (evento 1) è sbloccato
- Gli altri 7 sono bloccati

**Flow per ogni evento:**
1. Bambino tappa sul nodo sbloccato
2. Personaggio cammina verso quel nodo
3. Quando arriva → **EVENT INTRODUCTION SCREEN** si apre
4. Dopo introduzione → **SEQUENCING ACTIVITY SCREEN**
5. Bambino completa il sequencing
6. Se corretto → **REWARD ANIMATION**
7. Evento completato: il nodo diventa verde con check
8. Il nodo successivo si sblocca (se esiste)
9. Personaggio può toccare il prossimo nodo e ripete il flow

**Dopo evento 8 (ultimo):**
- Tutta la sotto-mappa si illumina
- Transizione → **FINAL STORYBOOK SCREEN**
- Bottone "Torna alla Mappa Principale" per tornare alla mappa main

### Persistenza

- **Salva:** Posizione personaggio sulla sotto-mappa
- **Salva:** Quanti eventi sono stati completati (0-8)
- **Salva:** Quali eventi sono sbloccati

---

## 🗺️ SCHERMI 5-8: EVENT FLOW

### Schermo 5: Event Introduction

**Contenuto:**
- Immagine di introduzione dell'evento
- Testo di narrazione breve (2-3 righe)
- Animazione semplice: fade in, scale, o scena che si anima

**Azione:**
- Dopo 2-3 secondi OU tap su "Continua" → **SEQUENCING ACTIVITY SCREEN**

### Schermo 6: Sequencing Activity

**Contenuto:**
- Immagine di sfondo colorato (tema evento)
- 4 schede d'azione mescolate in disordine
- Ogni scheda ha:
  - Immagine (9:16 portrait)
  - Numero di sequenza (1, 2, 3, 4)
  - Testo opzionale (label breve, sotto l'immagine)

**Layout:**
- **Griglia:** 2 colonne × 2 righe (per 4 schede)
- **Card Size:** Adattato a 9:16 aspect ratio (es. 150×267pt su iPad)
- **Spacing:** 16pt tra le schede
- **Drop Zone:** Area sotto le schede per il riordino (sequenza corretta)

**Meccanica:**
- **Drag & Drop:** Trascina le schede dall'area iniziale alla drop zone nell'ordine corretto (ideale su iPad)
- **Fallback (Tap & Place):** Se drag&drop instabile: tap per selezionare, tap nella posizione target della sequenza
- Mostra sequenza corretta come numeri 1, 2, 3, 4 o slots numerati vuoti
- Animazione smooth quando sposti una scheda

**Feedback:**
- **Corretto:** Celebrazione, animazione confetti, continue to reward screen
- **Sbagliato:** Messaggio dolce "Quasi! Riprova." → consente di reorder le schede
- Nessuna penalità, solo incoraggiamento

**Bottone "Check":** Controlla se la sequenza è corretta
- Posizionato in basso, grande, colorato, tappabile dai bambini

### Schermo 7: Reward Animation

**Contenuto:**
- Animazione/immagine celebration
- Effetto celebration (confetti leggero, stelle, ecc.)
- Testo positivo

**Durata:** 2-3 secondi, poi automaticamente:
1. Segna evento come completato
2. Sblocca prossimo evento (se esiste)
3. Torna a SOTTO-MAPPA
4. Personaggio può tap sul prossimo nodo

---

## 🗺️ SCHERMO 9: FINAL STORYBOOK

**Trigger:** Quando tutti gli 8 eventi sono completati

**Contenuto:**
- Titolo: "My Completed Storybook"
- Pagine numerate (1-8), mostra un'illustrazione per pagina
- Navigazione: Frecce Avanti/Indietro tra pagine
- Badge finale di completamento

**Interazioni:**
- Sfoglia le pagine
- Tap su ogni pagina per leggere il testo dell'evento
- Bottone "Replay Story" → ritorna al primo evento, resetta visivamente (ma mantiene salvo il progresso)
- Bottone "Torna alla Mappa Principale" → torna a MAPPA PRINCIPALE

---

## 📊 DATA MODELS

### 1. FairyTale

```swift
struct FairyTale: Identifiable, Codable {
    let id: String
    let title: String
    let coverImageName: String
    let mapImageName: String          // Immagine della sotto-mappa
    let subMapImageName: String       // Immagine della sotto-mappa specifica
    let events: [StoryEvent]
    var isUnlocked: Bool              // Se la fiaba è sbloccata
    var isCompleted: Bool             // Se la fiaba è completamente finita
    var completedEventCount: Int      // Quanti eventi sono completati
    var characterPositionOnSubMap: CGPoint  // Posizione personaggio sulla sotto-mappa
}
```

### 2. StoryEvent

```swift
struct StoryEvent: Identifiable, Codable {
    let id: String
    let title: String
    let introductionText: String
    let introductionImageName: String
    let sequenceCards: [SequenceCard]
    let correctOrder: [String]        // IDs delle schede in ordine corretto
    let rewardImageName: String
    let mapIllustrationName: String
    var isUnlocked: Bool
    var isCompleted: Bool
    var mapPosition: CGPoint           // Posizione del nodo sulla sotto-mappa
}
```

### 3. SequenceCard

```swift
struct SequenceCard: Identifiable, Codable {
    let id: String
    let imageName: String
    let label: String                 // Testo opzionale
    var currentPosition: Int?         // Posizione attuale (per drag&drop)
    var correctPosition: Int          // Posizione corretta (1-4)
}
```

### 4. AppProgress

```swift
struct AppProgress: Codable {
    var fairyTales: [String: FairyTaleProgress]  // id → progress
    var lastViewedFairyTaleId: String?
    var characterPositionOnMainMap: CGPoint
}

struct FairyTaleProgress: Codable {
    var completedEventIds: [String]
    var unlockedEventIds: [String]
    var characterPositionOnSubMap: CGPoint
    var isCompleted: Bool
}
```

---

## 🎨 ASSET REQUIRED

**Mappa Principale:**
- ✅ mappa.png (già fornita)

**Status Immagini di Little Red Riding Hood:**
- ⏳ IN PREPARAZIONE - Saranno aggiunte dopo lo sviluppo iniziale

**Implementazione con Placeholder:**

Durante lo sviluppo, l'app utilizzerà **placeholder automatici** per le immagini non ancora pronte:
- Se un'immagine non è trovata → mostra un rettangolo colorato con testo placeholder
- Formato: "Image: event1_intro.png" (nome file atteso)
- Colore placeholder: Azzurro tenue per facile identificazione
- **L'app rimane completamente funzionale** anche senza le immagini finali
- **Transizione automatica:** Quando le immagini sono pronte, basta copiarle nella cartella Assets e verranno caricate automaticamente senza modifiche al codice

**Per Little Red Riding Hood (8 eventi):**

**Immagini di Introduzione (16:9 - Orizzontali):**
- 8 immagini (una per evento)
- Formato: 16:9 landscape
- Uso: EVENT INTRODUCTION SCREEN
- Nomina: `event1_intro.png`, `event2_intro.png`, ... `event8_intro.png`

**Schede Sequenza (9:16 - Verticali):**
- 32 immagini (4 per evento × 8)
- Formato: 9:16 portrait
- Uso: SEQUENCING ACTIVITY SCREEN (drag & drop cards)
- Nota: Mostrate verticalmente in colonna, per essere tappate e trascinate dai bambini
- Nomina: `event1_card1.png`, `event1_card2.png`, `event1_card3.png`, `event1_card4.png`, ... `event8_card4.png`

**Immagini di Reward (16:9 - Orizzontali):**
- 8 immagini (una per evento)
- Formato: 16:9 landscape
- Uso: REWARD AND TRANSITION SCREEN
- Nomina: `event1_reward.png`, `event2_reward.png`, ... `event8_reward.png`

**Illustrazioni Mappa Evento (Quadrato):**
- 8 immagini (una per evento)
- Formato: Quadrato (200×200 o 256×256)
- Uso: Mostra sulla sotto-mappa quando evento è completato
- Nomina: `event1_map_node.png`, `event2_map_node.png`, ... `event8_map_node.png`

**Illustrazione Sotto-mappa Generale:**
- 1 immagine per Little Red Riding Hood
- Formato: 16:9 landscape
- Uso: SUBMAP SCREEN - Background con i nodi degli 8 eventi posizionati
- ⏳ NON ANCORA PRONTA - Verrà implementata quando disponibile
- Nomina: `littleRedRiddingHood_submap.png`

---

## 📁 STRUTTURA CARTELLE PRONTA PER LE IMMAGINI

Quando sei pronto ad aggiungere le immagini, copia i file nella seguente struttura dentro il progetto Xcode:

```
FairyTaleApp/
└── Assets.xcassets/
    ├── MainMap/
    │   ├── mappa.imageset/
    │   │   ├── mappa.png
    │   │   ├── Contents.json
    │   └── ...
    │
    ├── Character/
    │   ├── character_front_frame1.imageset/
    │   ├── character_front_frame2.imageset/
    │   ├── character_front_frame3.imageset/
    │   ├── character_front_frame4.imageset/
    │   ├── character_back_frame1.imageset/
    │   ├── character_back_frame2.imageset/
    │   ├── character_back_frame3.imageset/
    │   ├── character_back_frame4.imageset/
    │   ├── character_left_frame1.imageset/
    │   ├── character_left_frame2.imageset/
    │   ├── character_left_frame3.imageset/
    │   ├── character_left_frame4.imageset/
    │   ├── character_right_frame1.imageset/
    │   ├── character_right_frame2.imageset/
    │   ├── character_right_frame3.imageset/
    │   └── character_right_frame4.imageset/
    │
    ├── LittleRedRiddingHood/
    │   ├── Submap/
    │   │   └── littleRedRiddingHood_submap.imageset/
    │   │       ├── littleRedRiddingHood_submap.png (⏳ Da aggiungere)
    │   │       └── Contents.json
    │   │
    │   ├── Event1/
    │   │   ├── event1_intro.imageset/
    │   │   │   ├── event1_intro.png (⏳ Da aggiungere)
    │   │   │   └── Contents.json
    │   │   ├── event1_card1.imageset/
    │   │   │   ├── event1_card1.png (⏳ Da aggiungere)
    │   │   │   └── Contents.json
    │   │   ├── event1_card2.imageset/
    │   │   │   ├── event1_card2.png (⏳ Da aggiungere)
    │   │   │   └── Contents.json
    │   │   ├── event1_card3.imageset/
    │   │   │   ├── event1_card3.png (⏳ Da aggiungere)
    │   │   │   └── Contents.json
    │   │   ├── event1_card4.imageset/
    │   │   │   ├── event1_card4.png (⏳ Da aggiungere)
    │   │   │   └── Contents.json
    │   │   ├── event1_reward.imageset/
    │   │   │   ├── event1_reward.png (⏳ Da aggiungere)
    │   │   │   └── Contents.json
    │   │   └── event1_map_node.imageset/
    │   │       ├── event1_map_node.png (⏳ Da aggiungere)
    │   │       └── Contents.json
    │   │
    │   ├── Event2/
    │   │   ├── event2_intro.imageset/
    │   │   ├── event2_card1.imageset/
    │   │   ├── event2_card2.imageset/
    │   │   ├── event2_card3.imageset/
    │   │   ├── event2_card4.imageset/
    │   │   ├── event2_reward.imageset/
    │   │   └── event2_map_node.imageset/
    │   │
    │   ├── Event3/
    │   ├── Event4/
    │   ├── Event5/
    │   ├── Event6/
    │   ├── Event7/
    │   └── Event8/
    │       └── (stesso pattern di Event1)
    │
    └── UI/
        ├── cloud_transition_1.imageset/ (opzionale)
        ├── cloud_transition_2.imageset/ (opzionale)
        └── cloud_transition_3.imageset/ (opzionale)
```

**Nota:** Xcode crea automaticamente le cartelle `.imageset` con `Contents.json`. Basta trascinare i file PNG in Xcode e tutto è configurato.

**Checklist per aggiungere le immagini:**
- [ ] 8 × `event#_intro.png` (16:9)
- [ ] 32 × `event#_card#.png` (9:16) - 4 per evento
- [ ] 8 × `event#_reward.png` (16:9)
- [ ] 8 × `event#_map_node.png` (quadrato)
- [ ] 1 × `littleRedRiddingHood_submap.png` (16:9) - Quando pronta
- [ ] 16 × `character_*_frame#.png` (sprite animation)
- [ ] 1 × `mappa.png` (16:9) - Già disponibile

---
- ✅ 4 direzioni di movimento (fronte, dietro, sinistra, destra)
- ✅ 4 frame di animazione per ogni direzione
- ✅ Totale: 16 frame animati
- Formato: Pixel art style, carino e adatto ai bambini
- Animazione fluida per il movimento sulle mappe

**Dettaglio Sprite Sheet:**
- **Direzione Fronte:** 4 frame (fermo → camminata → fermo)
- **Direzione Dietro:** 4 frame (fermo → camminata → fermo)
- **Direzione Sinistra:** 4 frame (fermo → camminata → fermo)
- **Direzione Destra:** 4 frame (fermo → camminata → fermo)

**Naming Convention per Sprite (da separare in singoli file PNG):**
```
Assets/Character/
├── character_front_frame1.png
├── character_front_frame2.png
├── character_front_frame3.png
├── character_front_frame4.png
├── character_back_frame1.png
├── character_back_frame2.png
├── character_back_frame3.png
├── character_back_frame4.png
├── character_left_frame1.png
├── character_left_frame2.png
├── character_left_frame3.png
├── character_left_frame4.png
├── character_right_frame1.png
├── character_right_frame2.png
├── character_right_frame3.png
└── character_right_frame4.png
```

**Alternativa:** Se le immagini sono in formato sprite sheet unico, usare CropImage per estrarre i singoli frame

**Transizioni:**
- Nuvole (PNG semi-trasparente o animazione)

**Generale:**
- Background home screen
- Background per altri schermi

---

## 🎨 IMPLEMENTAZIONE PLACEHOLDER IMAGES

Per supportare immagini mancanti, implementare un componente `PlaceholderImageView`:

```swift
// PlaceholderImageView.swift
import SwiftUI

struct PlaceholderImageView: View {
    let imageName: String
    let aspectRatio: CGFloat?  // Es. 16/9 o 9/16
    
    var body: some View {
        ZStack {
            // Background azzurro tenue
            Color(red: 0.7, green: 0.85, blue: 1.0)
            
            VStack(spacing: 12) {
                Image(systemName: "photo")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                
                Text("Placeholder")
                    .font(.headline)
                
                Text(imageName)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
    }
}

// Helper Extension
struct SafeImageView: View {
    let imageName: String
    let aspectRatio: CGFloat?
    
    var body: some View {
        if UIImage(named: imageName) != nil {
            Image(imageName)
                .resizable()
                .aspectRatio(aspectRatio, contentMode: .fit)
        } else {
            PlaceholderImageView(imageName: imageName, aspectRatio: aspectRatio)
        }
    }
}

// Utilizzo:
// SafeImageView(imageName: "event1_intro", aspectRatio: 16/9)
// SafeImageView(imageName: "event1_card1", aspectRatio: 9/16)
```

Questo permette all'app di:
- ✅ Funzionare completamente senza le immagini
- ✅ Mostrare placeholder chiari
- ✅ Caricare automaticamente le immagini vere quando aggiunte

---

---

## 🍎 APPLE HUMAN INTERFACE GUIDELINES (HIG) COMPLIANCE

**Questa sezione è OBBLIGATORIA e deve essere rispettata a pennello in tutti gli aspetti dell'app.**

Fonte: https://developer.apple.com/design/human-interface-guidelines

### 1. ACCESSIBILITÀ (OBBLIGATORIO)

#### VoiceOver Support (Screen Reader)
Provide alternative text labels for all important interface elements. Alternative text labels aren't visible onscreen, but they let VoiceOver audibly describe onscreen elements, making navigation easier for people with visual disabilities.

**Implementazione richiesta:**
- ✅ **Ogni bottone, card, immagine, nodo sulla mappa DEVE avere un'etichetta VoiceOver descrittiva**
- ✅ Etichette in italiano, chiare e concise
- ✅ Esempio:
  ```swift
  Button("Continua") {
      // action
  }
  .accessibilityLabel("Continua verso il prossimo evento")
  .accessibilityHint("Doppio tocco per continuare")
  ```

#### Touch Targets (Hit Area)
Touch targets require minimum dimensions of 44×44 points as research demonstrates that smaller interactive elements result in 25% or higher tap error rates, particularly affecting users with motor impairments.

**Implementazione richiesta:**
- ✅ **TUTTI i bottoni, nodi mappa, schede sequenza: MINIMO 44×44 pt**
- ✅ Per i bambini (target secondario), considerare 48×48 pt o più
- ✅ Spacing tra elementi interattivi: MINIMO 8 pt (per evitare tap accidentali)
- ✅ Verificare su Accessibility Inspector in Xcode prima di push

**Esempi di sizing app:**
```swift
// Bottone "Start" (Home Screen)
.frame(minWidth: 60, minHeight: 60)

// Nodi mappa sotto-mappa
.frame(width: 60, height: 60)  // Min 44, consigliato 60+

// Schede sequenza (sequencing activity)
// 9:16 portrait, minimo altezza = 150 pt per fare tappare facilmente
.frame(height: 180)  // Assicura facilità di tap

// Bottone "Check"
.frame(minWidth: 120, minHeight: 60)
```

#### Dynamic Type Support
In iOS, iPadOS, tvOS, and watchOS, use Dynamic Type and test that your app's layout adapts to all font sizes.

**Implementazione richiesta:**
- ✅ **TUTTI i testi DEVONO usare Dynamic Type (font .body, .headline, .caption, ecc.)**
- ✅ NO font size hardcoded (es. `.font(.system(size: 16))` ❌)
- ✅ SÌ preferibilmente `.font(.body)` ✅ o `.font(.system(.title1))`
- ✅ Testare su tutte le accessibility text sizes:
  - Small
  - Default
  - Large (Extra Large Accessibility Text Sizes in Settings)
- ✅ Verificare che layout non si rompa alle dimensioni più grandi

**Esempio corretto:**
```swift
Text("Little Red Riding Hood")
    .font(.headline)  // Dynamic Type

Text("Capitolo 1: Il Cesto per la Nonna")
    .font(.body)      // Dynamic Type

Button("Continua") {
    // action
}
.font(.body)
```

#### Color Contrast Ratio
Color contrast ratios: Body text needs a minimum 4.5:1 contrast ratio against its background. Large text drops to 3:1.

**Implementazione richiesta:**
- ✅ **Testo su sfondo: MINIMO 4.5:1 (per testo piccolo) o 3:1 (per testo grande)**
- ✅ Bottoni e elementi interattivi: MINIMO 3:1
- ✅ Testare in LIGHT MODE e DARK MODE
- ✅ Usare Accessibility Inspector in Xcode per verificare
- ✅ Evitare colori accostati che brillano male (es. rosso su rosa)

**Colori consigliati (app adatta ai bambini):**
- Sfondo: Bianco o azzurro chiaro (#F0F8FF)
- Testo primario: Blu scuro (#003366) o nero (#000000)
- Bottoni: Colori vivaci ma contrastati bene (es. verde brillante su bianco)
- Testo su sfondo colorato: Sempre verificare contrasto

#### Keyboard Navigation
Ideally, people can turn on Full Keyboard Access and perform every task in your experience using only the keyboard.

**Implementazione richiesta:**
- ✅ **L'app DEVE essere navigabile totalmente con tastiera esterna (se disponibile su iPad)**
- ✅ Implementare ordine di focus (tabIndex) logico
- ✅ Non sovrascrivere gesture di sistema (es. swipe-down per notification center)

### 2. TYPOGRAPHY (OBBLIGATORIO)

San Francisco, introduced in 2014, represents Apple's first custom typeface in nearly twenty years. The font was designed from the ground up for optimal legibility on digital screens, incorporating optical sizing that automatically adjusts letterform details based on display size.

**Implementazione richiesta:**
- ✅ **Font OBBLIGATORIO: San Francisco (SF Pro)**
- ✅ SwiftUI usa SF Pro di default, non cambiare
- ✅ NO custom font (a meno che non sia approvato per app bambini)
- ✅ Sizing:
  - Titoli: `.title1`, `.title2` (24pt+)
  - Corpo: `.body` (17pt) o `.callout` (16pt)
  - Etichette: `.caption`, `.caption2` (12pt+)
  - MINIMO 11pt per readability (HIG requirement)

**Esempio:**
```swift
VStack {
    Text("Interactive Fairy Tale Sequencing Lab")
        .font(.title1)
        .bold()
    
    Text("Scegli una fiaba")
        .font(.body)
    
    Text("Capitolo 1")
        .font(.caption)
}
```

### 3. NAVIGATION (OBBLIGATORIO)

The fastest way to create friction is by inventing your own navigation rules. Stick to what iOS users already understand: the Tab Bar for primary sections, the Navigation Bar for hierarchy, and native sheets or modals for focused tasks.

**Implementazione richiesta per questa app:**
- ✅ **NavigationStack per navigazione gerarchica (Home → Mappa → Sotto-mappa → Evento)**
- ✅ NO custom navigation gesture (la back button di iOS va bene)
- ✅ Titoli chiari in Navigation Bar
- ✅ Modal per transizioni importanti (es. REWARD screen)

**Struttura Navigation OK:**
```
Home (NavigationStack)
  ├── Fairy Tale Selection
  │   ├── Main Map
  │   └── Sub-Map
  │       ├── Event Introduction (Modal)
  │       ├── Sequencing Activity (Modal)
  │       └── Reward (Modal)
  └── Final Storybook (Modal)
```

### 4. CUSTOM CONTROLS E GESTURE (ATTENZIONE)

It's tempting to invent slick, unique gesture interactions, but if users can't easily find or understand them, they won't use them.

**Implementazione richiesta:**
- ✅ **Drag & Drop per sequencing: OK, è intuitivo e documentato**
- ✅ **Tap per movimento personaggio: OK, è intuitivo**
- ✅ NO custom gesture come:
  - ❌ Long press per azioni nascoste
  - ❌ Three-finger tap per menu segreto
  - ❌ Swipe di direzione personalizzate
- ✅ **Fornire sempre alternative:**
  - Drag & Drop → Fallback Tap & Place
  - Gesture-based action → Button alternative

### 5. DESIGN PATTERN PER APP BAMBINI (SPECIALE)

Anche se le HIG non sono specifiche per bambini, applicare:
- ✅ **GRANDI touch target (48×48 pt MINIMO, meglio 60×60 pt)**
- ✅ **Testo grande e chiarissimo (18pt+ body text)**
- ✅ **Colori vivaci, ben contrastati**
- ✅ **Feedback visivo e sonoro (celebrazioni, animazioni)**
- ✅ **NO testi complicati**
- ✅ **Feedback positivo sempre (niente "Sbagliato!", piuttosto "Quasi! Riprova")**
- ✅ **Niente penalità per errori**

### 6. DARK MODE SUPPORT

Color does more than just look pretty; it communicates! Apple emphasizes using color purposefully and consistently to indicate interactivity, status, and hierarchy. This guides designers to make sure their color schemes work well in both Light and Dark Mode and have enough contrast for maximum accessibility.

**Implementazione richiesta:**
- ✅ **L'app DEVE funzionare in Light Mode E Dark Mode**
- ✅ Testare che i colori siano leggibili in entrambi
- ✅ Usare `@Environment(\.colorScheme)` se necessario per adattare colori
- ✅ SwiftUI adatta molti colori automaticamente, ma verifica

### 7. TESTING ACCESSIBILITY (OBBLIGATORIO PRIMA DI RELEASE)

**Checklist di Testing:**

**Prima di ogni push:**
- [ ] Accessibility Inspector: 0 errori
- [ ] VoiceOver: navigare l'intera app con solo VoiceOver acceso
- [ ] Dynamic Type: testare a Large Accessibility Text Sizes
- [ ] Color Contrast: verificare con contrast checker
- [ ] Keyboard: navigare solo con tastiera esterna (se disponibile)
- [ ] Touch Target: misurare con Xcode, minimo 44×44 pt

**Script di test VoiceOver:**
1. Attiva VoiceOver in Settings > Accessibility > VoiceOver
2. Naviga intera app con gesti VoiceOver:
   - Z-shape per next element
   - Z-shape reverse per previous element
   - Doppio-tap per attivare
3. Verifica ogni elemento abbia label descrittivo

**Come verificare con Accessibility Inspector:**
1. Xcode > Xcode > Open Developer Tools > Accessibility Inspector
2. Avvia app nel simulator
3. Accessibility Inspector scannerizza l'intera app
4. Correggi tutti gli errori/warning segnalati

### 8. IMPLEMENTATION CHECKLIST HIG COMPLIANCE

**Design Phase:**
- [ ] Figma: Tutti i bottoni ≥44×44 pt
- [ ] Figma: Verificare contrasto colori (usare Figma Accessibility plugin)
- [ ] Figma: Font San Francisco, NO custom
- [ ] Design: Testare con layout su iPad (landscape primary)

**Development Phase:**
- [ ] SwiftUI: Tutti i testi usano Dynamic Type
- [ ] SwiftUI: `.accessibilityLabel()` su OGNI elemento interattivo
- [ ] SwiftUI: NO hardcoded font sizes
- [ ] SwiftUI: NavigationStack implementato correttamente
- [ ] SwiftUI: Modal per transizioni importanti

**Testing Phase:**
- [ ] Accessibility Inspector: 0 errori
- [ ] VoiceOver: test completo dell'app
- [ ] Dynamic Type: test a tutte le font sizes
- [ ] Dark Mode: test in entrambi i modi
- [ ] Contrast: 4.5:1 per tutti i testi
- [ ] Keyboard: navigazione completa (se tastiera disponibile)

**App Store Submission:**
- [ ] Compilare "Accessibility" nel form di submission
- [ ] Indicare tutte le feature accessibili supportate
- [ ] NO false dichiarazioni

---

### UserDefaults Storage

- Salva struttura `AppProgress` in JSON ogni volta che cambia
- Carica al launch dell'app
- Key: "fairyTaleAppProgress"

### Cosa Salvare

1. **Posizione personaggio** sulla mappa principale (CGPoint)
2. **Per ogni fiaba:**
   - Eventi completati (array di ID)
   - Eventi sbloccati (array di ID)
   - Posizione personaggio sulla sotto-mappa
3. **Ultima fiaba visitata** (per riprendere da dove si era rimasti)

### Reset (per testing)

- Bottone "Reset All Progress" nel settings (nascosto o in debug)

---

## 🎬 ANIMAZIONI RICHIESTE

### 1. Sprite Animation del Personaggio (CharacterAnimationManager)

**Type:** Sprite sheet cycling per 4 direzioni
**Direzioni:** Fronte, Dietro, Sinistra, Destra
**Frame per direzione:** 4 frame (fermo → passo1 → passo2 → passo3)
**Frame rate:** ~100ms per frame (circa 10 frame al secondo per fluidità)
**Implementazione:**
- Crea enum per le direzioni
- Determina direzione in base a tap location vs posizione attuale
- Cicla tra i 4 frame della direzione calcolata
- Quando movimento finito, mostra ultimo frame della direzione (posizione finale)

**Pseudo-code:**
```swift
enum CharacterDirection {
    case front, back, left, right
}

func determineDirection(from: CGPoint, to: CGPoint) -> CharacterDirection {
    let dx = to.x - from.x
    let dy = to.y - from.y
    
    if abs(dx) > abs(dy) {
        return dx > 0 ? .right : .left
    } else {
        return dy > 0 ? .front : .back
    }
}

func animateMovement(to: CGPoint, duration: TimeInterval) {
    let direction = determineDirection(from: characterPosition, to: to)
    
    // Cicla sprite animation
    Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
        currentFrame = (currentFrame + 1) % 4
        // Update sprite con frame corrispondente a direction
        
        if characterPosition == to {
            timer.invalidate()
        }
    }
    
    // Anima movimento smoothly
    withAnimation(.easeInOut(duration: duration)) {
        characterPosition = to
    }
}
```

### 2. Movimento Personaggio sulla Mappa

**Type:** Smooth path animation
**Duration:** 1-2 secondi (dipende da distanza)
**Easing:** ease-in-out (naturale)
**Include:** Sprite animation + spostamento posizione

### 3. Transizione Nuvole

**Type:** Cloud fade + blur
**Duration:** 1.5 secondi
**Stages:**
- Nuvole entrano
- Schermo diventa bianco/opaco
- Nuvole si dissipano
- Nuova mappa appare con fade in

### 4. Event Introduction

**Type:** Fade in + scale dell'immagine
**Duration:** 1 secondo
**Easing:** ease-out

### 5. Sequencing Activity - Feedback

**Correct:** Celebration animation (confetti leggero, stella che esplode)
**Incorrect:** Shake animation leggero, testo dolce

### 6. Reward Screen

**Type:** Bounce + celebration effect
**Duration:** 2 secondi
**Include:** Stella/badge che appare con bounce

### 7. Final Storybook

**Type:** Page flip animation (opzionale, o semplice fade)
**Duration:** 0.5 secondi

---

## ♿ ACCESSIBILITY (secondo Apple HIG)

**IMPORTANTE: Questa sezione è OBBLIGATORIA e deve rispettare rigorosamente Apple Human Interface Guidelines.**

Vedi sezione "🍎 APPLE HUMAN INTERFACE GUIDELINES (HIG) COMPLIANCE" per i dettagli completi.

**Requisiti Minimi Accessibilità:**

**Touch Targets:**
- ✅ TUTTI i bottoni, nodi, card: MINIMO 44×44 pt (per app bambini: 48-60 pt consigliato)
- ✅ Spacing tra elementi: MINIMO 8 pt

**VoiceOver:**
- ✅ OGNI elemento interattivo ha `.accessibilityLabel()` descriptivo
- ✅ Descrizioni in italiano, chiare e concise

**Dynamic Type:**
- ✅ TUTTI i testi usano Dynamic Type (`.font(.body)`, `.font(.headline)`, ecc.)
- ✅ Testato a Large Accessibility Text Sizes
- ✅ NO hardcoded font sizes

**Color Contrast:**
- ✅ Text: 4.5:1 minimo su sfondo
- ✅ UI Elements: 3:1 minimo
- ✅ Testato in Light Mode e Dark Mode

**Typography:**
- ✅ Font: San Francisco (SF Pro) - default di SwiftUI
- ✅ Testo minimo: 11pt (HIG requirement)
- ✅ Body text: 17pt o `.body` Dynamic Type

**Keyboard Navigation:**
- ✅ App navigabile completamente con tastiera esterna (iPad)
- ✅ Ordine focus logico

**VoiceOver Labels:**
- Button("Start") → `.accessibilityLabel("Avvia il gioco")`
- Image("character") → `.accessibilityLabel("Il personaggio della storia")`
- Node su mappa → `.accessibilityLabel("Evento 1: Il Cesto. Bloccato.")`

**Dark Mode:**
- ✅ L'app funziona in Light Mode e Dark Mode
- ✅ Colori leggibili in entrambi

---

## 🛠️ STRUTTURA DEI FILE SWIFT

```
FairyTaleApp/
├── FairyTaleApp.swift              // Entry point
├── Models/
│   ├── FairyTale.swift
│   ├── StoryEvent.swift
│   ├── SequenceCard.swift
│   └── AppProgress.swift
├── Views/
│   ├── HomeView.swift
│   ├── MainMapView.swift            // Mappa principale con personaggio
│   ├── SubMapView.swift             // Sotto-mappa fiaba
│   ├── CloudTransitionView.swift    // Transizione nuvole
│   ├── EventIntroductionView.swift
│   ├── SequencingActivityView.swift
│   ├── RewardView.swift
│   └── FinalStorybookView.swift
├── Components/
│   ├── CharacterView.swift          // Personaggio animato
│   ├── MapNodeView.swift            // Nodo sulla mappa
│   ├── SequenceCardView.swift
│   ├── ReusableButtons.swift
│   └── ProgressIndicator.swift
├── ViewModels/
│   ├── AppViewModel.swift           // State management globale
│   ├── MapViewModel.swift           // Logica mappa principale
│   └── StoryViewModel.swift         // Logica fiaba/eventi
├── Services/
│   ├── ProgressManager.swift        // Salva/carica UserDefaults
│   ├── AssetManager.swift           // Gestione nomi immagini
│   ├── AnimationManager.swift       // Utility animazioni
│   └── CharacterAnimationManager.swift  // Gestione sprite animation personaggio
├── Assets/
│   ├── Colors.xcassets
│   ├── Images/
│   │   ├── mappa.png
│   │   ├── littleRedRiddingHood/
│   │   │   ├── event1_intro.png
│   │   │   ├── event1_card1.png
│   │   │   ├── ... etc
│   │   └── ...
│   └── ...
├── SampleData/
│   └── SampleFairyTales.swift       // Dati di test per Little Red Riding Hood
└── Extensions/
    └── View+Extensions.swift
```

---

## 📝 IMPLEMENTAZIONE LITTLE RED RIDING HOOD (8 EVENTI)

### Event 1: The Basket for Grandma

**Intro Image:** event1_intro.png
**Intro Text:** "Little Red Riding Hood è a casa con sua madre. La nonna è malata, quindi la madre prepara un cesto con cibo e chiede a Little Red Riding Hood di portarlo alla casa della nonna."

**Sequence Cards (in ordine corretto):**
1. event1_card1.png - "Madre mette il cibo nel cesto"
2. event1_card2.png - "Madre dà il cesto a Little Red Riding Hood"
3. event1_card3.png - "Little Red Riding Hood mette il suo mantello rosso"
4. event1_card4.png - "Little Red Riding Hood esce da casa"

**Reward Image:** event1_reward.png
**Map Illustration:** event1_map.png

---

### Event 2: Walking Through the Forest

**Intro Image:** event2_intro.png
**Intro Text:** "Little Red Riding Hood cammina lungo il sentiero della foresta. Guarda intorno e vede alberi, fiori, uccelli e farfalle."

**Sequence Cards:**
1. event2_card1.png - "Little Red Riding Hood entra nella foresta"
2. event2_card2.png - "Segue il sentiero"
3. event2_card3.png - "Si ferma a guardare i fiori"
4. event2_card4.png - "Continua a camminare verso la casa della nonna"

**Reward Image:** event2_reward.png
**Map Illustration:** event2_map.png

---

### Event 3: Meeting the Wolf

**Intro Image:** event3_intro.png
**Intro Text:** "Il lupo appare e parla con Little Red Riding Hood. Le chiede dove sta andando. Lei gli dice che sta visitando sua nonna malata."

**Sequence Cards:**
1. event3_card1.png - "Il lupo appare sul sentiero"
2. event3_card2.png - "Il lupo chiede dove sta andando"
3. event3_card3.png - "Little Red Riding Hood risponde"
4. event3_card4.png - "Il lupo pensa a un piano"

**Reward Image:** event3_reward.png
**Map Illustration:** event3_map.png

---

### Event 4: The Wolf Goes to Grandma's House

**Intro Image:** event4_intro.png
**Intro Text:** "Il lupo corre attraverso la foresta e raggiunge la casa della nonna prima di Little Red Riding Hood."

**Sequence Cards:**
1. event4_card1.png - "Il lupo corre attraverso la foresta"
2. event4_card2.png - "Arriva alla casa della nonna"
3. event4_card3.png - "Bussa alla porta"
4. event4_card4.png - "La nonna risponde dall'interno"

**Reward Image:** event4_reward.png
**Map Illustration:** event4_map.png

---

### Event 5: The Wolf Pretends to Be Grandma

**Intro Image:** event5_intro.png
**Intro Text:** "Il lupo entra nella casa della nonna e finge di essere lei. Mette i vestiti della nonna e si sdraia nel suo letto."

**Sequence Cards:**
1. event5_card1.png - "Il lupo entra nella camera della nonna"
2. event5_card2.png - "Mette il berretto della nonna"
3. event5_card3.png - "Si sdraia nel letto della nonna"
4. event5_card4.png - "Aspetta Little Red Riding Hood"

**Reward Image:** event5_reward.png
**Map Illustration:** event5_map.png

---

### Event 6: Little Red Riding Hood Arrives

**Intro Image:** event6_intro.png
**Intro Text:** "Little Red Riding Hood raggiunge la casa della nonna. Bussa alla porta e sente una voce strana che le dice di entrare."

**Sequence Cards:**
1. event6_card1.png - "Little Red Riding Hood arriva alla casa"
2. event6_card2.png - "Bussa alla porta"
3. event6_card3.png - "Una voce strana risponde"
4. event6_card4.png - "Entra nella camera"

**Reward Image:** event6_reward.png
**Map Illustration:** event6_map.png

---

### Event 7: Something Is Strange

**Intro Image:** event7_intro.png
**Intro Text:** "Little Red Riding Hood guarda la 'nonna' e nota che qualcosa non va. La nonna sembra diversa."

**Sequence Cards:**
1. event7_card1.png - "Little Red Riding Hood guarda la nonna"
2. event7_card2.png - "Nota gli orecchi grandi"
3. event7_card3.png - "Nota gli occhi grandi"
4. event7_card4.png - "Nota i denti grandi"

**Reward Image:** event7_reward.png
**Map Illustration:** event7_map.png

---

### Event 8: The Story Is Resolved

**Intro Image:** event8_intro.png
**Intro Text:** "Little Red Riding Hood ha paura, ma arriva l'aiuto. Il lupo viene fermato e la nonna e Little Red Riding Hood sono al sicuro."

**Sequence Cards:**
1. event8_card1.png - "Little Red Riding Hood chiede aiuto"
2. event8_card2.png - "L'aiuto arriva alla casa della nonna"
3. event8_card3.png - "La nonna e Little Red Riding Hood sono salve"
4. event8_card4.png - "Il lupo scappa"

**Reward Image:** event8_reward.png
**Map Illustration:** event8_map.png

---

## 🎮 FLUSSO UTENTE COMPLETO (Step-by-Step)

### Sessione Tipo

1. **Bambino apre l'app** → HOME SCREEN (bottone "Start")
2. **Tap "Start"** → MAPPA PRINCIPALE (personaggio in basso a sinistra)
3. **Tap sulla locazione di Little Red Riding Hood** → Personaggio cammina verso il castello/casa
4. **Personaggio arriva** → TRANSIZIONE NUVOLE (1.5 sec)
5. **Nuvole si dissipano** → SOTTO-MAPPA di Little Red Riding Hood (personaggio all'inizio)
6. **Tap su Event 1 (sbloccato)** → Personaggio cammina al nodo
7. **Personaggio arriva al nodo** → EVENT INTRODUCTION SCREEN
8. **Dopo 2-3 sec o tap "Continua"** → SEQUENCING ACTIVITY SCREEN
9. **Bambino ordina le 4 schede** → Tap "Check"
10. **Se corretto:** REWARD SCREEN (2 sec) → Torna a SOTTO-MAPPA
11. **Event 1 ora è verde con check** → Event 2 è sbloccato
12. **Ripete per Event 2, 3, ... 8**
13. **Dopo Event 8 completato** → FINAL STORYBOOK SCREEN
14. **Bambino sfoglia le 8 pagine** → Tap "Torna alla Mappa Principale"
15. **Torna a MAPPA PRINCIPALE** → Personaggio è ancora dove era, pronto per altre fiabe

---

## ✅ ACCEPTANCE CRITERIA

- [ ] App apre con HOME SCREEN
- [ ] Mappa principale mostra personaggio e fiabe
- [ ] Tap sulla mappa → personaggio cammina (animazione smooth)
- [ ] Raggiungimento fiaba → TRANSIZIONE NUVOLE
- [ ] Sotto-mappa mostra 8 nodi (solo primo sbloccato)
- [ ] Tap su nodo → personaggio cammina, EVENT INTRODUCTION appare
- [ ] Introduction scompare → SEQUENCING ACTIVITY con 4 schede mescolate
- [ ] Drag & Drop (o Tap & Place) funziona
- [ ] "Check" verifica ordine corretto
- [ ] Corretto → REWARD → torna mappa, event diventa verde, prossimo sblocca
- [ ] Sbagliato → messaggio dolce, riprova possibile
- [ ] Dopo Event 8 → FINAL STORYBOOK con 8 pagine
- [ ] Sfoglia pagine, "Torna alla Mappa" funziona
- [ ] Progresso salvato (UserDefaults)
- [ ] Ritorno all'app → stato ripristinato
- [ ] Interface landscape-friendly, grande, colorata
- [ ] Accessibilità VoiceOver funzionante
- [ ] Nessun network call, solo local assets

---

## 📦 COME CONSEGNARE AL TEAM

1. **ZIP con immagini** → organizzate per evento con aspect ratios chiari:
   ```
   Assets/
   ├── littleRedRiddingHood/
   │   ├── submap.png (16:9 landscape - background sotto-mappa)
   │   ├── event1/
   │   │   ├── intro.png (16:9 landscape - introduzione)
   │   │   ├── card1.png (9:16 portrait - sequenza)
   │   │   ├── card2.png (9:16 portrait - sequenza)
   │   │   ├── card3.png (9:16 portrait - sequenza)
   │   │   ├── card4.png (9:16 portrait - sequenza)
   │   │   ├── reward.png (16:9 landscape - reward)
   │   │   └── map_node.png (quadrato 200×200 - nodo sulla mappa)
   │   ├── event2/
   │   │   ├── intro.png (16:9 landscape)
   │   │   ├── card1.png (9:16 portrait)
   │   │   ├── card2.png (9:16 portrait)
   │   │   ├── card3.png (9:16 portrait)
   │   │   ├── card4.png (9:16 portrait)
   │   │   ├── reward.png (16:9 landscape)
   │   │   └── map_node.png (quadrato)
   │   ├── event3/
   │   │   └── ... (stesso pattern)
   │   ├── ... (fino a event8)
   │
   ├── Character/
   │   ├── character_front_frame1.png
   │   ├── character_front_frame2.png
   │   ├── character_front_frame3.png
   │   ├── character_front_frame4.png
   │   ├── character_back_frame1.png
   │   ├── character_back_frame2.png
   │   ├── character_back_frame3.png
   │   ├── character_back_frame4.png
   │   ├── character_left_frame1.png
   │   ├── character_left_frame2.png
   │   ├── character_left_frame3.png
   │   ├── character_left_frame4.png
   │   ├── character_right_frame1.png
   │   ├── character_right_frame2.png
   │   ├── character_right_frame3.png
   │   └── character_right_frame4.png
   │
   ├── MainMap/
   │   └── mappa.png (16:9 landscape - mappa principale)
   │
   ├── UI/
   │   ├── home_background.png
   │   ├── cloud_transition_1.png
   │   ├── cloud_transition_2.png
   │   └── cloud_transition_3.png
   ```

**Aspect Ratio Summary:**
- **Immagini Introduzione:** 16:9 landscape (1920×1080 o 1280×720)
- **Schede Sequenza:** 9:16 portrait (720×1280 o 540×960)
- **Immagini Reward:** 16:9 landscape (1920×1080 o 1280×720)
- **Nodi Mappa:** Quadrato (200×200 o 256×256)
- **Sotto-mappa:** 16:9 landscape (1920×1080 o 1280×720)
- **Mappa Principale:** 16:9 landscape (1920×1080 o 1280×720)

2. **Questo documento** (specifica aggiornata)

3. **SampleData.swift** con mock data (sarà generato in fase di sviluppo)

---

## 🚀 PROSSIMI STEP

1. **Carica ZIP con immagini** così possiamo mappare esattamente i nomi
2. **Definisci posizioni fiabe sulla mappa principale** (quali castelli, montagne, spiaggia, ecc.)
3. **Definisci tipo di personaggio** (sprite animato o immagine statica?)
4. **Inizia sviluppo** con Claude Code usando questa specifica

---

**Versione:** 1.0  
**Data:** Maggio 2026  
**Status:** Pronto per implementazione
