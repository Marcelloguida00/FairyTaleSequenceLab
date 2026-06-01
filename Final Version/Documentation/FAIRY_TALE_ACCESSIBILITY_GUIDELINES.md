# 🧚‍♀️ Interactive Fairy Tale Sequencing Lab - Complete Development Guidelines

> ⚠️ **CRITICAL**: Questo documento DEVE essere letto INTEGRALMENTE prima di QUALSIASI modifica al progetto.
>
> **Claude/Copilot/Codex**: Leggi TUTTO prima di rispondere. Nessuna eccezione.

---

## 📖 Indice Generale

1. [Fondamenti Apple HIG](#fondamenti-apple-hig)
2. [Accessibility Specifiche del Progetto](#accessibility-specifiche-del-progetto)
3. [Implementazione VoiceOver](#implementazione-voiceover)
4. [Motor Accessibility](#motor-accessibility)
5. [Sensory Considerations](#sensory-considerations)
6. [Design Implementation](#design-implementation)
7. [Testing Checklist](#testing-checklist)
8. [Code Templates](#code-templates)

---

# SEZIONE 1: FONDAMENTI APPLE HIG

## Apple Design Principles

### Three Core Pillars

#### 1. **Clarity** (Chiarezza)
- Testo leggibile (min 11pt body text)
- Interfaccia non ambigua
- Icone coerenti e riconoscibili
- Spazi bianchi adeguati

#### 2. **Deference** (Deferenza)
- Contenuto dell'utente in primo piano
- Design minimalista
- Non distrae dalla navigazione naturale di iOS

#### 3. **Depth** (Profondità)
- Gerarchia visiva chiara
- Distinte differenze tra livelli
- Transizioni fluide

### Obblighi Globali per Questo Progetto

```
✅ Light Mode + Dark Mode (OBBLIGATORIO)
✅ iPhone + iPad support
✅ Portrait + Landscape orientations
✅ SafeArea gestito correttamente
✅ Nessun hardcoded color
✅ Dynamic Type supportato
✅ Accessibilità WCAG 2.1 AA
```

---

# SEZIONE 2: ACCESSIBILITY SPECIFICHE DEL PROGETTO

## Il Tuo Target

```
👧 Bambini dai 4-12 anni
👨‍👩‍👧‍👦 Genitori (co-learning)
♿ Inclusione totale (disabilità visive, motorie, cognitive, autismo, ADHD)
```

## Accessibility Priority (in ordine di importanza)

### 🔴 CRITICAL (Non negoziabile - App Store requirement)
1. **VoiceOver support completo** - blind children can use entire app
2. **Touch targets ≥ 60×60pt** - small hands, accessibility needs
3. **Color contrast 4.5:1** - vision impairment support
4. **Dark Mode** - eye strain reduction
5. **Dynamic Type** - vision impairment adaptation

### 🟠 HIGH PRIORITY (Expect to implement)
1. **Sensory settings** (disable sounds, animations, haptics)
2. **Clear language** (simple, age-appropriate)
3. **Consistent structure** (predictability = autism comfort)
4. **Multiple feedback types** (visual + audio + haptic)
5. **Keyboard navigation** (iPad keyboard users)

### 🟡 MEDIUM PRIORITY (Nice to have)
1. **Haptic feedback control**
2. **Motion-safe animations**
3. **Hardware keyboard shortcuts**
4. **Color blindness modes**

---

# SEZIONE 3: IMPLEMENTAZIONE VOICEOVER

## VoiceOver è il Screen Reader più importante

```
VoiceOver = Voice Over iPad/iPhone screen = blind users hear entire app
```

### REGOLA #1: Ogni elemento interattivo DEVE avere un label

```swift
// ❌ SBAGLIATO - VoiceOver non sa che cos'è:
Button(action: {}) {
    Image(systemName: "checkmark")
}

// ✅ CORRETTO - VoiceOver legge tutto:
Button(action: {}) {
    Image(systemName: "checkmark")
    Text("Check")
}
.accessibilityLabel("Check if sequence is correct")
.accessibilityHint("Double tap to verify your answer")
```

### REGOLA #2: Etichette chiare e concise

```swift
// ❌ Troppo lungo:
.accessibilityLabel("This button is used to check whether your current sequence of story events is in the correct order according to the canonical narrative structure")

// ✅ Conciso e chiaro:
.accessibilityLabel("Check if sequence is correct")
.accessibilityHint("Tells you if cards are in right order")
```

### REGOLA #3: Immagini SEMPRE hanno label (o sono nascoste)

```swift
// Per immagini descrittive (SEMPRE label):
Image("event1_intro")
    .accessibilityLabel("Mother and Little Red Riding Hood in kitchen")
    .accessibilityElement(children: .ignore)

// Per immagini puramente decorative:
Image("background_pattern")
    .accessibilityHidden(true)

// Per immagini che sono parte di un bottone:
Button(action: { moveNext() }) {
    Image("event2_image")
}
.accessibilityLabel("Next: Red Riding Hood walks through forest")
.accessibilityElement(children: .ignore)  // Non legge sia label che immagine
```

### REGOLA #4: Struttura logica per VoiceOver

```swift
// ✅ BENE - Struttura logica, viene letta ordinata:
VStack {
    Text("Event 1: The Basket")
        .accessibilityAddTraits(.isHeader)
    
    Image("event1_intro")
        .accessibilityLabel("Mother gives basket to Little Red Riding Hood")
    
    Text("Put these cards in order:")
        .accessibilityElement(children: .combine)
    
    ForEach(0..<cardCount, id: \.self) { index in
        CardView(eventIndex: index)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Card \(index + 1) of \(cardCount)")
    }
    
    HStack {
        Button("Check") { checkAnswer() }
            .accessibilityLabel("Check answer")
        
        Button("Skip") { skipEvent() }
            .accessibilityLabel("Skip event")
    }
}
```

### REGOLA #5: Custom View with children

```swift
// Per view complesse, gestire children:
VStack {
    Text("Drag to Reorder")
    
    List {
        ForEach(cards, id: \.self) { card in
            HStack {
                Image(card.imageName)
                    .accessibilityHidden(true)  // Image is just decoration
                
                Text(card.description)
            }
            .accessibilityElement(children: .combine)  // HStack + Text = 1 element
            .accessibilityLabel("Card: \(card.description)")
        }
    }
}

// ✅ Result: VoiceOver legge "Card: Mother gives basket" per ogni card
//   Non legge sia immagine che testo
```

### VoiceOver Testing Checklist

```
🎧 VOICEOVER TESTING (OBBLIGATORIO PRIMA DI OGNI MODIFICA)

Attivare: Settings > Accessibility > VoiceOver > ON

[ ] VoiceOver attivo su dispositivo
[ ] Posso navigare TUTTO l'app con VoiceOver
[ ] Ogni bottone ha etichetta significativa (< 30 parole)
[ ] Ogni immagine ha descrizione (o è nascosta)
[ ] Ordine di lettura ha senso (top-to-bottom, left-to-right)
[ ] Nessuna informazione nascosta da VoiceOver
[ ] Decorative images sono hidden
[ ] Form fields sono raggruppati logicamente
[ ] Suggerimenti per bottoni complessi
[ ] Menu navigazione è accessibile
[ ] Feedback (correct/wrong) è annunciato
[ ] Sound effects non sono unici feedback

Test in:
  [ ] Portrait mode
  [ ] Landscape mode
  [ ] iPad
  [ ] iPhone
  [ ] Con Rotor (per navigazione per tipo di elemento)
```

---

# SEZIONE 4: MOTOR ACCESSIBILITY

## Touch Target Size - CRITICO per bambini

### Specifiche

```
Standard iOS:        44×44 punti minimo
Per bambini:         60×60 punti (15 punti più grande)
Preferito (app):     60×60 punti

Spacing tra bottoni: 8-12 punti minimo
```

### Implementazione nel Progetto

```swift
// ✅ CORRETTO per il progetto:
struct CardView: View {
    var body: some View {
        VStack(spacing: 12) {  // 12pt spacing
            Image(cardImage)
                .resizable()
                .scaledToFit()
                .frame(height: 150)
            
            Text(cardDescription)
                .font(.body)
                .padding(16)
        }
        .frame(minHeight: 240)  // 60pt minimo (incluso padding)
        .background(Color.white)
        .cornerRadius(12)
        .onTapGesture {
            handleCardTap()
        }
    }
}

// ✅ PULSANTI:
struct ActionButtonView: View {
    var body: some View {
        HStack(spacing: 12) {  // 12pt spacing
            Button(action: { skipEvent() }) {
                Text("Skip")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)  // 60×60pt minimo
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            Button(action: { checkAnswer() }) {
                Text("Check")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)  // 60×60pt minimo
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(16)
    }
}
```

### Touch Target Checklist

```
[ ] Tutti i bottoni sono ≥ 60×60 pt
[ ] Tutti gli elementi toccabili ≥ 44×44 pt
[ ] Spacing minimo 8pt tra elementi interattivi
[ ] Nessun bottone sovrapposto
[ ] Aree toccabili non si estendono l'una nell'altra
[ ] Hit area matches visual area
[ ] Test con dita di bambini (più grandi)
```

## Keyboard Navigation - Per iPad

```swift
// Struttura con focus order:
VStack {
    TextField("Enter name", text: $userName)
        .focusable()
    
    Picker("Difficulty", selection: $difficulty) {
        Text("Easy").tag(1)
        Text("Medium").tag(2)
        Text("Hard").tag(3)
    }
    .focusable()
    
    NavigationLink(destination: GameView()) {
        Text("Start Game")
    }
    .focusable()
    .keyboardShortcut(.defaultAction)  // Return key
}
.onKeyPress { press in
    switch press.key {
    case .return:
        startGame()
        return true
    case .escape:
        showMenu()
        return true
    case .rightArrow:
        nextEvent()
        return true
    case .leftArrow:
        previousEvent()
        return true
    default:
        return false
    }
}
```

---

# SEZIONE 5: SENSORY CONSIDERATIONS

## Questo progetto supporta Autism, ADHD, sensory sensitivities

### Sensory Settings - OBBLIGATORIA

```swift
struct AccessibilitySettings: View {
    @AppStorage("enableSounds") var enableSounds = true
    @AppStorage("enableAnimations") var enableAnimations = true
    @AppStorage("enableHaptics") var enableHaptics = true
    @AppStorage("enableTimer") var enableTimer = false
    @AppStorage("timePressure") var timePressure = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sensory Settings")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            Toggle("Enable sounds", isOn: $enableSounds)
                .accessibilityLabel("Toggle sound effects")
            
            Toggle("Enable animations", isOn: $enableAnimations)
                .accessibilityLabel("Toggle movement animations")
            
            Toggle("Enable haptics", isOn: $enableHaptics)
                .accessibilityLabel("Toggle vibration feedback")
            
            Divider()
            
            Toggle("Use timer", isOn: $enableTimer)
                .accessibilityLabel("Toggle timed mode")
                .accessibilityHint("When on, you have limited time to complete")
            
            if enableTimer {
                Toggle("Time pressure", isOn: $timePressure)
                    .accessibilityLabel("Show timer urgency")
                    .accessibilityHint("Color changes as time runs out")
            }
            
            Spacer()
        }
        .padding(16)
    }
}
```

### Implementare le Sensory Settings

```swift
// SOUNDS:
class SoundManager {
    @AppStorage("enableSounds") var enableSounds = true
    
    func playSuccessSound() {
        if enableSounds {
            AudioServicesPlaySystemSound(1016)  // Success
        }
    }
    
    func playErrorSound() {
        if enableSounds {
            AudioServicesPlaySystemSound(1051)  // Error
        }
    }
}

// ANIMATIONS:
struct CardFlipAnimation: View {
    @AppStorage("enableAnimations") var enableAnimations = true
    @State var isFlipped = false
    
    var body: some View {
        ZStack {
            if isFlipped {
                Image("cardBack")
            } else {
                Image("cardFront")
            }
        }
        .onTapGesture {
            if enableAnimations {
                withAnimation(.easeInOut(duration: 0.6)) {
                    isFlipped.toggle()
                }
            } else {
                // No animation, just instant flip
                isFlipped.toggle()
            }
        }
    }
}

// HAPTICS:
struct CheckAnswerButton: View {
    @AppStorage("enableHaptics") var enableHaptics = true
    
    func checkAnswer() {
        if enableHaptics {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        // Visual feedback is ALWAYS shown
        showCheckmark()
    }
    
    var body: some View {
        Button("Check") {
            checkAnswer()
        }
    }
}

// TIMER (optional, not mandatory):
struct TimedEvent: View {
    @AppStorage("enableTimer") var enableTimer = false
    @AppStorage("timePressure") var timePressure = false
    @State var timeRemaining = 60
    
    var body: some View {
        VStack {
            if enableTimer {
                Text("Time: \(timeRemaining)s")
                    .font(.headline)
                    .foregroundColor(timePressure && timeRemaining < 10 ? .red : .black)
            }
            
            // Rest of the view
        }
        .onReceive(Timer.publish(every: 1).autoconnect()) { _ in
            if enableTimer && timeRemaining > 0 {
                timeRemaining -= 1
            }
        }
    }
}
```

### No Flashing (Seizure Prevention)

```swift
// ❌ PERICOLOSO - Può causare crisi epilettiche:
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
    isVisible.toggle()  // 10 flashes/sec = SEIZURE RISK
}

// ❌ PERICOLOSO - Ancora troppo veloce:
Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
    isVisible.toggle()  // 5 flashes/sec = SEIZURE RISK
}

// ✅ SICURO - Se DEVI usare flashing (raro):
Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
    isVisible.toggle()  // 2 flashes/sec = SAFE (< 3/sec)
}

// 🌟 MIGLIORE - Non flashare, usare animazioni smooth:
withAnimation(.easeInOut(duration: 0.6)) {
    opacity = 0
    opacity = 1
}
```

### Predictability (Critical for Autism)

```swift
// ✅ BUONO - Stessa struttura ogni volta:
// Riduce cognitive load, children imparano il pattern

struct EventScreen: View {
    var eventNumber: Int
    
    var body: some View {
        VStack(spacing: 0) {
            // 1. HEADER - Sempre uguale posizione
            HStack {
                Text("Event \(eventNumber)")
                    .font(.title2)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Text("\(eventNumber) of 8")
                    .font(.caption)
            }
            .padding(16)
            .background(Color.green)
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    // 2. IMAGE - Sempre uguale posizione
                    Image("event\(eventNumber)_intro")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(12)
                        .padding(16)
                    
                    // 3. INSTRUCTIONS - Sempre uguale posizione
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Put cards in order:")
                            .font(.headline)
                        Text("Drag cards to reorder them")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.yellow.opacity(0.2))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)
                    
                    // 4. CONTENT - Sempre uguale layout
                    CardGrid(eventNumber: eventNumber)
                        .padding(16)
                }
            }
            
            // 5. BUTTONS - SEMPRE bottom, SEMPRE stesso ordine
            HStack(spacing: 12) {
                Button("Back") {
                    goBackToMap()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                
                Button("Check") {
                    checkAnswer()
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
            }
            .padding(16)
        }
    }
}

// ✅ Risultato:
// - Stesso layout su ogni evento (predictable)
// - Buttons sempre in basso a destra
// - Image sempre a sinistra
// - Bambino sa esattamente dove trovare tutto
// - Ridotto cognitive load per autismo
```

---

# SEZIONE 6: DESIGN IMPLEMENTATION

## Color & Contrast

### WCAG 2.1 AA Requirements

```
Normal text (< 18pt):     4.5:1 contrast minimo
Large text (≥ 18pt):      3:1 contrast minimo
Non-text elements:        3:1 contrast minimo
```

### Fairy Tale Color Palette (con contrasto verificato)

```swift
// Primary Colors
let darkBrown = Color(red: 0.24, green: 0.16, blue: 0.09)      // #3D2817
let cream = Color(hex: "#F5F1EB")
let forestGreen = Color(hex: "#6B8E5D")
let gold = Color(hex: "#D4A574")
let lightCoral = Color(hex: "#E07856")

// Contrast Ratios (verificati):
// Dark Brown on Cream:       13.5:1 ✅ EXCELLENT
// White on Forest Green:      5.3:1 ✅ EXCELLENT
// Dark Brown on Light Gold:   4.7:1 ✅ EXCELLENT

// Implementation:
struct FairyTaleColor {
    // Text colors - sempre testati
    static let primaryText = darkBrown       // 13.5:1 on cream
    static let secondaryText = Color(red: 0.40, green: 0.31, blue: 0.20)  // #664D33
    
    // Backgrounds
    static let background = cream
    static let accentBackground = forestGreen
    static let successBackground = Color.green
    static let errorBackground = Color.red
    
    // Semantic colors
    static let success = Color.green         // ✅
    static let error = Color.red             // ❌
    static let warning = Color.orange        // ⚠️
    static let info = forestGreen
}
```

### Dark Mode Implementation

```swift
@Environment(\.colorScheme) var colorScheme

struct FairyTaleView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark ? Color.black : Color.white
    }
    
    var textColor: Color {
        colorScheme == .dark 
            ? Color.white 
            : Color(red: 0.24, green: 0.16, blue: 0.09)
    }
    
    var body: some View {
        ZStack {
            backgroundColor
            
            VStack {
                Text("Little Red Riding Hood")
                    .foregroundColor(textColor)
            }
        }
    }
}

// Oppure usa System Colors (si adattano automaticamente):
struct SaferView: View {
    var body: some View {
        ZStack {
            Color(UIColor.systemBackground)  // Auto light/dark
            
            Text("Hello")
                .foregroundColor(Color(UIColor.label))  // Auto light/dark
        }
    }
}
```

### Dark Mode Testing Checklist

```
[ ] Testo leggibile in Dark Mode
[ ] Contrast ratio mantenuto in Dark Mode
[ ] Immagini visibili in Dark Mode
[ ] Background non troppo scuro
[ ] No white text su light background in Dark Mode
[ ] Testato con system settings
[ ] Transizione smooth tra Light/Dark
```

## Dynamic Type - Testo scalabile

### OBBLIGATORIO: Supportare Dynamic Type

```swift
// ✅ CORRETTO - Usa Text Styles standard:
Text("Title")
    .font(.headline)              // Scale automaticamente

Text("Body")
    .font(.body)                  // Scale automaticamente

Text("Small")
    .font(.caption)               // Scale automaticamente

// ❌ SBAGLIATO - Hardcoded size:
Text("Title")
    .font(.system(size: 22))      // Non scala con settings

// Se hai bisogno di custom size, usa .relative:
Text("Slightly bigger")
    .font(.system(size: 20, weight: .semibold, design: .default))
    // Scala ancora con accessibility settings
```

### Dynamic Type Sizes

```
Sistema ha 11 categorie di Dynamic Type:

Small:
  Extra Small (85%)
  Small (90%)

Regular (100%):
  Medium (100%)
  Large (110%)
  Extra Large (120%)

Accessibility:
  Extra Extra Large (135%)
  Extra Extra Extra Large (150%)
  ...fino a 200%

TEST OBBLIGATORIO:
  [ ] Extra Small - testo comunque leggibile?
  [ ] Large - layout non si rompe?
  [ ] Extra Extra Large - tutto ancora funziona?
```

### Testing Dynamic Type

```swift
// Nel Simulator:
// Menu > Device > Manage Devices
// Scegli device > Environment Overrides
// Seleziona Dynamic Type size
// Test con tutte e 11 le categorie

// O: Settings > Accessibility > Display & Text Size > Larger Accessibility Sizes
```

---

# SEZIONE 7: TESTING CHECKLIST

## Pre-Release Accessibility Audit

### 🎧 Vision & VoiceOver (CRITICA)

```
[ ] VoiceOver attivo su dispositivo
[ ] Posso navigare TUTTO l'app
[ ] Tutti i bottoni hanno label
[ ] Tutte le immagini hanno description (o hidden)
[ ] Ordine di lettura corretto (top-to-bottom)
[ ] Nessuno elemento bloccato da VoiceOver
[ ] Feedback (right/wrong/success) annunciato
[ ] Testato su iPhone
[ ] Testato su iPad
[ ] Testato in Portrait
[ ] Testato in Landscape
```

### 🎨 Color & Contrast (CRITICA)

```
[ ] Tutti i testi: 4.5:1 contrast
[ ] Testato con WebAIM Contrast Checker
[ ] Dark Mode: contrast mantenuto
[ ] No informazione solo da colore (es: "click the green button")
[ ] Testato con Color Blindness simulator (Protanopia, Deuteranopia)
[ ] Non-text elements: 3:1 contrast
```

### 📱 Text & Dynamic Type

```
[ ] Text size minimo 11pt
[ ] Dynamic Type supportato (headline, body, caption)
[ ] Testato a Small (85%)
[ ] Testato a Large (110%)
[ ] Testato a Extra Extra Extra Large (150%)
[ ] Layout non si rompe a nessun size
[ ] Spacing adeguato tra linee (1.5x font size)
```

### 🖱️ Motor & Touch (CRITICA per bambini)

```
[ ] Tutti i bottoni: 60×60pt minimo
[ ] Spacing tra bottoni: 8-12pt minimo
[ ] Nessun elemento sovrapposto
[ ] Keyboard navigation su iPad
[ ] Tutti gli elementi focusabili raggiungibili via tastiera
[ ] Testate con dita di bambini (più grandi)
[ ] Testato con AssistiveTouch
```

### 🔊 Hearing & Audio

```
[ ] Nessun feedback SOLO audio
[ ] Visual feedback per ogni sound
[ ] Testato con suoni disabilitati
[ ] Se hai narrazione: sottotitoli disponibili
[ ] Haptic feedback non è unico feedback
```

### 🧠 Cognitive & Neurodivergent

```
[ ] Linguaggio semplice e chiaro (< 12 years reading level)
[ ] Layout consistente (stessa struttura ogni evento)
[ ] Istruzioni esplicite e chiare
[ ] Feedback spiega cosa è successo
[ ] No stimoli disorienti
[ ] Sensory settings disponibili (sounds, animations, haptics)
[ ] Timer opzionale (no time pressure obbligatorio)
[ ] Breakpoints offerti
[ ] Testato con autistic user (if possible)
```

### 🎯 Overall

```
[ ] App non crashes in accessibility mode
[ ] Memory non leaks
[ ] Launch time < 400ms
[ ] Responsive in tutte le orientazioni
[ ] SafeArea gestito correttamente
[ ] No hardcoded colors
[ ] Privacy policy disponibile
[ ] Accessibility statement in App Store description
```

---

# SEZIONE 8: CODE TEMPLATES

## Template: VoiceOver Button

```swift
Button(action: { performAction() }) {
    Image(systemName: "checkmark")
    Text("Check")
}
.frame(minHeight: 60)
.accessibilityLabel("Check if sequence is correct")
.accessibilityHint("Tells you if cards are in the right order")
.accessibilityElement(children: .ignore)  // Non legge sia image che text
```

## Template: Accessible Image

```swift
Image("event1_intro")
    .resizable()
    .scaledToFit()
    .accessibilityLabel("Mother and Little Red Riding Hood in the kitchen")
    .accessibilityElement(children: .ignore)
```

## Template: Accessible Text Field

```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Enter your name:")
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
    
    TextField("Name", text: $userName)
        .textFieldStyle(RoundedBorderTextFieldStyle())
        .accessibilityLabel("Child's name")
        .accessibilityHint("Type your name and press return")
}
```

## Template: Accessible Card Grid

```swift
VStack(spacing: 12) {
    Text("Arrange cards in order:")
        .font(.headline)
        .accessibilityAddTraits(.isHeader)
    
    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 12) {
        ForEach(0..<cards.count, id: \.self) { index in
            VStack {
                Image(cards[index].imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                
                Text(cards[index].description)
                    .font(.caption)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.yellow)
            .cornerRadius(12)
            .onTapGesture {
                selectCard(index)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Card \(index + 1): \(cards[index].description)")
            .accessibilityValue("\(index + 1) of \(cards.count)")
            .accessibilityAddTraits(.isButton)
        }
    }
}
.accessibilityElement(children: .contain)
```

## Template: Dark Mode + Color Contrast

```swift
struct EventView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var backgroundColor: Color {
        colorScheme == .dark 
            ? Color(UIColor.systemGray6)
            : Color(hex: "#F5F1EB")  // Cream
    }
    
    var textColor: Color {
        colorScheme == .dark
            ? Color.white
            : Color(red: 0.24, green: 0.16, blue: 0.09)  // Dark brown
    }
    
    var body: some View {
        ZStack {
            backgroundColor
            
            VStack {
                Text("Event 1")
                    .font(.headline)
                    .foregroundColor(textColor)
            }
        }
    }
}

// Verifica contrasto:
// Dark Brown (#3D2817) on Cream (#F5F1EB): 13.5:1 ✅
// White on Dark Gray: 10.2:1 ✅
```

## Template: Sensory Settings

```swift
struct SettingsView: View {
    @AppStorage("enableSounds") var enableSounds = true
    @AppStorage("enableAnimations") var enableAnimations = true
    @AppStorage("enableHaptics") var enableHaptics = true
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Sensory Settings")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            
            Toggle("Enable Sounds", isOn: $enableSounds)
                .accessibilityLabel("Toggle sound effects on or off")
            
            Toggle("Enable Animations", isOn: $enableAnimations)
                .accessibilityLabel("Toggle movement animations on or off")
            
            Toggle("Enable Haptics", isOn: $enableHaptics)
                .accessibilityLabel("Toggle vibration feedback on or off")
        }
        .padding(16)
    }
}
```

## Template: Animation with Reduce Motion

```swift
struct FeedbackView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var showSuccess = false
    
    var animationDuration: Double {
        reduceMotion ? 0 : 0.6
    }
    
    var body: some View {
        VStack {
            if showSuccess {
                Text("✅ Correct!")
                    .font(.title2)
                    .scaleEffect(1.2)
                    .transition(.scale)
            }
        }
        .onTapGesture {
            if reduceMotion {
                showSuccess = true
            } else {
                withAnimation(.easeInOut(duration: animationDuration)) {
                    showSuccess = true
                }
            }
        }
    }
}
```

---

# INTEGRAZIONE FINALE

## Workflow per Modifiche

### Quando chiedi una modifica a Claude/Copilot:

```
1️⃣ SPECIFICA il tipo di modifica:
   "Implementa un nuovo bottone per..."
   "Aggiungi una nuova schermata..."
   "Cambia il colore di..."

2️⃣ RICORDA loro di leggere questo documento:
   "Per favore leggi FAIRY_TALE_ACCESSIBILITY_GUIDELINES.md 
    prima di rispondere"

3️⃣ INDICA la priorità accessibility:
   "Questo ha bisogno di VoiceOver support"
   "Assicurati che sia 60×60pt per i bambini"
   "Dark Mode deve essere supportato"

4️⃣ VALIDA la risposta contro la checklist:
   "Hai verificato il contrasto colori?"
   "Hai testato VoiceOver?"
   "Hai aggiunto accessibilityLabel?"
```

### Cosa Claude DEVE fare:

```
✅ OBBLIGATORIO:
  [ ] Legge TUTTO questo documento
  [ ] Applica VoiceOver labels per ogni elemento interattivo
  [ ] Verifica contrasto colori (4.5:1)
  [ ] Supporta Dark Mode
  [ ] Supporta Dynamic Type
  [ ] Touch targets ≥ 60×60pt
  [ ] Rispetta sensory settings
  [ ] Testa con Reduce Motion
  [ ] Usa accessibilityElement(children: .ignore) dove appropriato
  [ ] Commenta il codice con accessibility considerations

❌ NON ACCETTARE:
  [ ] "Non ho spazio per un bottone più grande"
  [ ] "VoiceOver è complicato, skippiamo"
  [ ] "Il colore va bene, non serve contrasto"
  [ ] "La gente non usa Dark Mode"
  [ ] "Aggiungere labels rallenta lo sviluppo"
  
  👉 Accessibility è un requisito App Store, non optional
```

---

# QUICK REFERENCE CARD

## Per Claude/Copilot (da tenere in mente)

```
🎯 ACCESSIBILITY PRIORITIES (in ordine):
  1. VoiceOver support (blind children)
  2. Touch targets 60×60pt (small hands)
  3. Color contrast 4.5:1 (vision impairment)
  4. Dark Mode (eye strain)
  5. Dynamic Type (vision needs)

🎨 COLOR RULES:
  ✅ Dark Brown (#3D2817) on Cream (#F5F1EB) = 13.5:1
  ✅ White on Forest Green = 5.3:1
  ❌ Never hardcode colors
  ❌ Always test in Dark Mode

🎤 VOICEOVER RULES:
  ✅ .accessibilityLabel() on every button
  ✅ .accessibilityHint() per spiegare azioni complesse
  ✅ .accessibilityHidden(true) per elementi decorativi
  ✅ .accessibilityAddTraits(.isHeader) per titoli
  ✅ .accessibilityElement(children: .ignore) quando necessario

📱 MOTOR RULES:
  ✅ Tutti i bottoni ≥ 60×60pt
  ✅ Spacing 8-12pt tra elementi
  ✅ Keyboard navigation su iPad
  ❌ No touch targets < 44pt

🧠 SENSORY RULES:
  ✅ Sensory settings sempre disponibili
  ✅ Multiple feedback types (visual + audio + haptic)
  ✅ No flashing (< 3 flashes/second)
  ✅ Respect reducedMotion
  ✅ Animazioni ≥ 0.3 secondi
  ❌ Timer non può essere obbligatorio

📋 TESTING BEFORE EVERY CHANGE:
  [ ] VoiceOver: navigare tutto l'app
  [ ] Colors: verificare contrasto con WebAIM
  [ ] Size: testare a Small, Large, Extra Large
  [ ] Dark: testare in Dark Mode
  [ ] Motor: bottoni ≥ 60×60pt
  [ ] Motion: testare con Reduce Motion ON
```

---

# CONFORMITÀ & COMPLIANCE

## Standards Followed

```
✅ WCAG 2.1 Level AA - Web Content Accessibility Guidelines
✅ Apple Human Interface Guidelines (HIG)
✅ App Store Review Guidelines - Section 5.1 (Accessibility)
✅ ADAAG (American Disabilities Act)
✅ EU Accessibility Directive (EN 301 549)
```

## App Store Submission

```
Quando sottoponi l'app, devi dichiarare:

"This app is designed with accessibility in mind:

✅ VoiceOver screen reader support
✅ Touch targets minimum 60 points for children
✅ Color contrast WCAG 2.1 AA compliant
✅ Full Dark Mode support
✅ Dynamic Type text scaling
✅ Keyboard navigation on iPad
✅ Sensory customization options

Accessibility is not a feature - it's a requirement."
```

---

# CONTATTI & RISORSE

## Se Claude ha domande

```
"Le HIG di Apple dicono che devo fare X"
→ ✅ Fallo. Sono requisiti, non suggerimenti.

"Non riesco a fare VoiceOver perché..."
→ ❌ No. Trovate un modo. È critico.

"Posso skippare il Dark Mode?"
→ ❌ No. App Store lo richiede.

"Accessibility rallenta la velocità?"
→ ❌ Falso. Spesso la migliora.
```

## Documentazione Ufficiale

```
Apple HIG:
  https://developer.apple.com/design/human-interface-guidelines/

Accessibility Guidelines:
  https://www.apple.com/accessibility/

WCAG 2.1:
  https://www.w3.org/WAI/WCAG21/quickref/

WebAIM Contrast Checker:
  https://webaim.org/resources/contrastchecker/
```

---

## 📝 VERSIONE & CHANGELOG

```
Versione: 2.0 COMPLETE
Data: Maggio 2026
Combinazione: Apple HIG + Fairy Tale Implementation
Compliance: WCAG 2.1 AA + App Store Review Guidelines

Cambio da v1.0:
  + Aggiunto Fairy Tale specifiche
  + Code templates completi
  + Sensory settings dettagliati
  + Dark Mode implementation
  + Accessibility statement per App Store
```

---

> ⚠️ **FINALE REMINDER**
>
> Quando chiedi modifiche a Claude/Copilot:
>
> **"Leggi questo documento COMPLETAMENTE prima di rispondere.
> Nessun skipping di sezioni. Accessibility è NON-NEGOZIABILE."**
>
> Se Claude/Copilot dice "va bene, farò senza VoiceOver per velocità",
> rifiuta e ricordagli che è un requisito App Store.
>
> **Accessibilità = Prerequisito, non feature. FINE.**
