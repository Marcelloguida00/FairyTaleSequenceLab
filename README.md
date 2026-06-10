# World of Fables 📖✨

**An interactive fairy-tale sequencing app for iPad** that teaches children logical sequencing, cause and effect, and narrative progression through classic fairy tales — starting with *Little Red Riding Hood*.

Built with **SwiftUI** and designed from the ground up with **accessibility** and **inclusivity** at its core.

---

## 🎯 Overview

World of Fables turns storytelling into play. Children explore an illustrated world map, walk a little mascot from island to island, and unlock story events. Each event presents a scene from the fairy tale followed by a **card-sequencing activity**: the child must arrange illustrated story cards in the correct narrative order. Completing all events unlocks the final storybook — including an **AR storybook** experience with a realistic page-bend effect.

### Main flow

```
Onboarding (cinematic intro with villain & sailing ship)
    ↓
Main Menu
    ↓
World Map  →  tap to walk the mascot to a fairy tale island
    ↓
Fairy-tale sub-map (Little Red Riding Hood — 8 story events)
    ↓
Event intro → Dialogue scenes → Sequencing activity → Reward card
    ↓
Final storybook (AR book with page-turn physics)
```

---

## ✨ Features

### 🗺️ Interactive world map
- Tap-to-move mascot with 4-direction sprite walking animation
- Cloud transitions between map and story worlds
- Visual progression on each fairy tale's sub-map (waypoints unlock as you play)

### 🃏 Sequencing game
- Drag-and-drop story cards into the correct narrative order
- Orchestral audio feedback: each correctly placed card adds a musical layer; mistakes and successes have dedicated sound effects
- Two SFX modes (simplified / orchestral)
- Reward cards and chapter-unlocked banners on completion

### 💬 Story & dialogue system
- JSON-driven dialogue (`Resources/Data/redhood_dialogue.json`, `events.json`)
- Character portraits with emotional states (happy, sad, listening, talking…)
- Narrator script bar with audio-synced, progressive multi-line subtitle scrolling
- Speech synthesis narration (`AppSpeechSynthesizer`)

### 📕 AR storybook
- RealityKit/ARKit-powered book (`ARBookView`, `RedHoodARStoryView`)
- Custom paper-bend shader for realistic page turning (drag must complete to turn the page)
- Standard 2D `BookView` fallback

### 🎵 Audio
- Background music with selectable themes and volume control
- Forest ambience layer, piano chord/note feedback, orchestral jingles
- Master audio toggle, separate music/SFX controls

### 🧒 Onboarding & tutorial
- Cinematic onboarding: villain intro, sailing-ship scenes, harbor arrival
- In-game tutorial overlay on first play
- Skippable and replayable from Settings

---

## ♿ Accessibility

Accessibility is a first-class feature, not an afterthought:

- **8 languages**: English, Italian, Spanish, French, Portuguese, Russian, Albanian, Persian, and Simplified Chinese — with full **RTL support** for Persian (including mirrored book layouts)
- **OpenDyslexic font** toggle for dyslexia-friendly reading
- **Reduce animations** — app toggle OR-combined with the system Reduce Motion setting
- **Reduce contrast / increased contrast** support (WCAG-compliant contrast fixes)
- **Differentiate without colour** (WCAG 1.4.1): patterns on map waypoints and buttons so colour is never the only signal
- **Dynamic Type** support with custom fonts (`relativeTo:` scaling)
- **VoiceOver** labels throughout, plus an in-app spoken narration toggle
- In-app settings are protected behind a simple **math gate** so children can't change them accidentally
- See `Final Version/Documentation/FAIRY_TALE_ACCESSIBILITY_GUIDELINES.md` and `Final Version/Documents/Accessibility_Checklist.md`

---

## 🛠 Tech stack

| | |
|---|---|
| **Platform** | iPadOS 26.0+ (iPad only, all orientations) |
| **Language** | Swift 5 |
| **UI** | SwiftUI |
| **AR** | RealityKit / ARKit (custom page-bend shader) |
| **Audio** | AVFoundation (music, ambience, SFX, speech synthesis) |
| **Persistence** | `@AppStorage` / UserDefaults |
| **Localization** | `.lproj` string catalogs + custom `LanguageManager` (in-app language switching) |

No third-party dependencies.

---

## 📁 Project structure

```
Final Version/
├── Final Version.xcodeproj
├── LICENSE                        # MIT
└── Final Version/
    ├── App/                       # App entry point & root view
    │   ├── Final_VersionApp.swift
    │   └── RootView.swift
    ├── Configuration/             # App-wide settings & design system
    │   ├── AppSettings.swift          # Sensory preference helpers
    │   ├── AppColors.swift            # Color palette
    │   ├── AppTypography.swift        # Custom font registration & scaling
    │   ├── AppFontSettings.swift      # Dyslexia font state
    │   ├── AppAudioSettings.swift     # Audio master switch
    │   ├── AccessibilityEnvironment.swift
    │   ├── AppFeatureFlags.swift
    │   └── LanguageManager.swift      # In-app language switching (incl. RTL)
    ├── Features/
    │   ├── Onboarding/            # Cinematic intro (villain, ship, harbor)
    │   ├── MainMenu/              # Main menu
    │   ├── Map/                   # World map, mascot movement, cloud transitions
    │   ├── StoryEvents/           # Event flow, dialogues, rewards, AR story
    │   ├── Sequencing/            # Card-sequencing activity
    │   ├── Tutorial/              # First-play tutorial overlay
    │   └── Settings/              # Settings UI + math gate
    ├── Services/                  # Audio players, speech synthesis, SFX coordination
    ├── SharedUI/                  # Reusable views (BookView, ARBookView, dialogue UI…)
    ├── Resources/
    │   ├── Audio/                 # Music, ambience, SFX, narration
    │   ├── Data/                  # events.json, redhood_dialogue.json
    │   └── Fonts/                 # Alegreya, Fredoka, OpenDyslexic, Uncial Antiqua
    ├── Assets.xcassets            # Maps, portraits, event art, sprites
    ├── AppIcon1.icon / AppIcon2.icon
    ├── Documentation/             # App specification & accessibility guidelines
    ├── Documents/                 # Accessibility checklist
    └── *.lproj                    # en, it, es, fr, pt, ru, sq, fa, zh-Hans
```

---

## 🚀 Getting started

### Requirements
- **Xcode 26** or later
- **iPadOS 26.0+** device or simulator (the app targets iPad only)

### Build & run
1. Clone the repository:
   ```bash
   git clone <repository-url>
   ```
2. Open `Final Version.xcodeproj` in Xcode.
3. Select an iPad simulator (or a connected iPad).
4. Build and run (`⌘R`).

No additional setup, package resolution, or API keys required.

> **Note:** AR features require a physical iPad with a camera; on the simulator the standard 2D book is used.

---

## 📖 Content

| Fairy tale | Status |
|---|---|
| Little Red Riding Hood | ✅ Fully playable (8 events + final AR storybook) |
| The Three Little Pigs | 🔒 Planned |
| Cinderella | 🔒 Planned |
| Hansel and Gretel | 🔒 Planned |
| The Ugly Duckling | 🔒 Planned |
| Goldilocks and the Three Bears | 🔒 Planned |

---

## 🗺 Roadmap

- Different white-noise / ambience options in accessibility settings
- Star-rating game design (how the player sees which levels earned 3 stars)
- Special collectible card for completing a level with 3 stars
- A book chapter collecting every story's special cards
- Lock cards once a level is completed
- Test on additional iPad screen sizes

---

## 👥 Credits

Developed by **Marcello Guida** with the team:
Adolfo Torcicollo, Alberto Razzino, Albi Karameta, Bobur, Ciro Callisto, Francesca De Marco, Giulia Chiappetta.

Fonts: [Alegreya](https://fonts.google.com/specimen/Alegreya), [Fredoka](https://fonts.google.com/specimen/Fredoka), [Uncial Antiqua](https://fonts.google.com/specimen/Uncial+Antiqua) (SIL OFL), [OpenDyslexic](https://opendyslexic.org) (SIL OFL — see `Resources/Fonts/OFL-OpenDyslexic.txt`).

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
