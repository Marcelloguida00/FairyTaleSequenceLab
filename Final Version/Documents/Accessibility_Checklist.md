# 🎮 App Accessibility Checklist
## Apple Human Interface Guidelines Compliance

**Last Updated:** June 2026  
**Target Platforms:** iOS, iPadOS, macOS  
**Reference:** [Apple HIG Accessibility Guidelines](https://developer.apple.com/design/human-interface-guidelines/accessibility)

---

## 📋 Pre-Release Accessibility Audit

Use this checklist **before every app update**. Test on real devices, not just simulators. Mark completion with ✅ and document any issues found.

---

## 1️⃣ VoiceOver & Screen Reader Support

### Core Requirements
- [ ] **All interactive elements have VoiceOver labels** (buttons, icons, links)
  - Example: `MenuPlayButton` ✅ has `.accessibilityLabel(lm.t("a11y.play_button"))`
  - Example: `MenuSettingsButton` ✅ has `.accessibilityLabel(lm.t("a11y.settings_button"))`
  - [ ] **Info button** needs accessibility label
  - [ ] **Settings close button** ✅ has label

- [ ] **VoiceOver hints provided for non-obvious actions**
  - Example: `MenuPlayButton` ✅ has `.accessibilityHint(lm.t("a11y.play_hint"))`
  - [ ] Settings button should include hint about available options
  - [ ] Info/About button should indicate what information it contains

- [ ] **Decorative images are hidden from VoiceOver**
  - Example: Frame images ✅ use `.accessibilityHidden(true)`
  - Example: Cloud overlay ✅ uses `.allowsHitTesting(false)`
  - [ ] Background world map should be hidden: `.accessibilityHidden(true)`
  - [ ] Settings frame image should be hidden: ✅ already hidden

- [ ] **Heading hierarchy is logical**
  - [ ] Section headers (Developers, Collaborators, Contacts) are marked as headers
  - [ ] Title "Info" is marked as main heading

- [ ] **VoiceOver reading order matches visual order**
  - [ ] Use `.accessibilityElement(children: .combine)` for grouped content
  - [ ] Test with VoiceOver rotor navigation
  - [ ] Developer list should be read as one group, not individual names

- [ ] **Custom components announce their state**
  - [ ] Disabled buttons announce "disabled" status
  - [ ] Toggle switches announce on/off state
  - [ ] Math gate problem announces correct/incorrect feedback

- [ ] **Links are clearly identifiable**
  - [ ] Email contact link ✅ has accessibility label
  - [ ] External link indicator is described

### Testing Protocol
```swift
// Enable VoiceOver: Settings > Accessibility > VoiceOver > On
// Test these interactions:
1. Navigate all buttons using VoiceOver gestures
2. Verify each button announces its purpose
3. Confirm hints explain what will happen
4. Check reading order with rotor navigation
5. Test with VoiceOver enabled at maximum speech rate
```

**Test Date:** ___________  
**Tested On:** iPhone ___ | iPad ___ | Mac ___  
**Issues Found:** ___________________________  

---

## 2️⃣ Dynamic Type & Text Scaling

### Core Requirements
- [ ] **All text respects Dynamic Type settings**
  - [ ] `.font(.app(...))` is properly configured for scaling
  - [ ] Test at these sizes: Small, Medium (default), Large, Extra Large, Accessibility (1-3)
  - [ ] No hardcoded font sizes

- [ ] **Layout adapts to Large Accessibility text sizes**
  - [ ] MenuPanelView limits size with `.dynamicTypeSize(...DynamicTypeSize.accessibility1)` ✅
  - [ ] Buttons remain tappable and properly proportioned
  - [ ] Text doesn't overflow or get cut off
  - [ ] Spacing increases appropriately with text size

- [ ] **Minimum readable font sizes**
  - [ ] Body text: minimum 17pt (verify `.app(.body)`)
  - [ ] Captions/labels: minimum 12pt (verify `.app(.caption)`)
  - [ ] Buttons: minimum 17pt or proportional scaling ✅

- [ ] **Line spacing accommodates large text**
  - [ ] Line spacing is at least 1.5x font size
  - [ ] No vertical truncation in expanded sizes
  - [ ] Scroll areas work with large text

- [ ] **No essential information conveyed by size alone**
  - [ ] Visual hierarchy uses color, weight, and spacing too
  - [ ] Developers list is readable at all sizes

### Testing Protocol
```swift
// Enable Dynamic Type: Settings > Accessibility > Display & Text Size
// Test at: Small → Medium (default) → Accessibility 2 → Accessibility 3
// Verify:
1. All text visible without horizontal scrolling
2. Buttons remain at least 44x44 points
3. Layout reorganizes gracefully
4. No text overlap or clipping
5. Scroll performance is maintained
```

**Test Sizes Verified:**  
- [ ] Small
- [ ] Default (Medium)
- [ ] Large
- [ ] Extra Large  
- [ ] Accessibility 1
- [ ] Accessibility 2
- [ ] Accessibility 3

**Issues Found:** ___________________________  

---

## 3️⃣ Color Contrast & Visual Design

### Core Requirements
- [ ] **Color contrast ratios meet WCAG AA standards**
  - [ ] Normal text (body): minimum 4.5:1 contrast ratio
  - [ ] Large text (18pt+ bold or 14pt+): minimum 3:1 contrast ratio
  - [ ] UI components (borders, icons): minimum 3:1 contrast ratio

**Color Audit for Your App:**

| Component | Foreground | Background | Current Ratio | Target | Status |
|-----------|-----------|-----------|--------------|--------|--------|
| Primary Text | `rgb(74, 52, 46)` | `rgb(249, 244, 227)` | ✅ 9.2:1 | ≥4.5:1 | PASS |
| Secondary Text | `rgb(140, 115, 85)` | `rgb(249, 244, 227)` | ✅ 5.1:1 | ≥4.5:1 | PASS |
| Button Text | White | Blue `rgb(77, 123, 210)` | ⚠️ 4.8:1 | ≥4.5:1 | PASS |
| Button Border | Gold `rgb(230, 184, 56)` | Blue | ⚠️ Check | ≥3:1 | TEST |
| Divider Lines | Border `rgb(184, 161, 107)` @ 35% | Panel Fill | ✅ 3.2:1 | ≥3:1 | PASS |

- [ ] **Test colors in both Light and Dark modes**
  - [ ] App supports system appearance (light/dark)
  - [ ] All colors meet contrast in both modes
  - [ ] Use Accessibility Inspector to verify

- [ ] **Color is not the only indicator of state**
  - [ ] Disabled buttons use opacity + label, not color alone
  - [ ] Success/error states include icons or text
  - [ ] Form field states use icons, labels, or pattern changes

- [ ] **High contrast mode is supported**
  - [ ] Settings > Accessibility > Display & Text Size > Increase Contrast
  - [ ] Borders become more prominent
  - [ ] Text colors are adjusted
  - [ ] Contrast modifications must start only when the option in settings is activated.

### Testing Tools
```
Accessibility Inspector:
1. Open in Xcode: Xcode > Open Developer Tools > Accessibility Inspector
2. Run your app in simulator
3. Select "Color Contrast Calculator"
4. Click UI elements to check ratios
5. Verify minimum ratios met

Alternative: WebAIM Contrast Checker (online)
- Input hex colors: #1A0C09, #F9F4E3, etc.
```

**Contrast Testing Date:** ___________  
**Tool Used:** Xcode Accessibility Inspector ☐ | WebAIM ☐  
**Light Mode:** PASS ☐ FAIL ☐  
**Dark Mode:** PASS ☐ FAIL ☐  
**High Contrast:** PASS ☐ FAIL ☐  

---

## 4️⃣ Touch Targets & Motor Accessibility

### Core Requirements
- [ ] **All interactive elements are 44×44 points minimum**
  - [ ] Play button: 44pt minimum ✅ (verified with `.gameMinimumTouchTarget()`)
  - [ ] Settings button: 44pt minimum ✅
  - [ ] Close/Done button: 44pt minimum ✅
  - [ ] Info button: 44pt minimum ✅
  - [ ] Email link: 44pt minimum ✅ (with `.gameMinimumTouchTarget()`)
  - [ ] Developer list items: 44pt minimum height

- [ ] **Adequate spacing between touch targets**
  - [ ] Minimum 8pt padding between interactive elements
  - [ ] Reduce accidental taps on wrong target
  - [ ] Verify in layout: `padding()` and `Spacer()` values

- [ ] **No hover-only or pointer-precision elements**
  - [ ] All interactions work with finger taps
  - [ ] No right-click context menus required
  - [ ] No small precise gestures required

- [ ] **Gesture alternatives provided**
  - [ ] Swiping has button alternative (use buttons for navigation)
  - [ ] Long-press has menu alternative
  - [ ] Custom gestures have documented fallbacks

- [ ] **Haptic feedback respects preferences**
  - [ ] Settings > Accessibility > Sound & Haptics > Haptic Strength
  - [ ] Uses `AppSettings.hapticImpact()` appropriately ✅
  - [ ] Haptics are not required for functionality
  - [ ] Alternative audio/visual feedback provided

### Testing Protocol
```swift
// Enable Large Pointer: Settings > Accessibility > Pointer Control > Enable Pointer
// Simulate tremor: Enable "Shake to Undo" and test fine motor control

// Test on device:
1. Tap each button with thumb only
2. Attempt buttons with one hand
3. Test with pointer cursor enabled
4. Verify no accidental overlapping hits
5. Check haptic intensity at various settings
```

**Touch Target Audit:**

| Element | Width | Height | Min 44pt? | Padding | Status |
|---------|-------|--------|-----------|---------|--------|
| Play Button | TBD | 44pt | ✅ | 8pt | |
| Settings Button | TBD | 44pt | ✅ | 8pt | |
| Close Button | TBD | 44pt | ✅ | 8pt | |
| Info Button | 44pt | 44pt | ✅ | TBD | |
| Email Link | TBD | 44pt | ✅ | TBD | |
| Developer Row | 100% | 48pt | ✅ | 12pt | |

**Test Date:** ___________  
**Issues Found:** ___________________________  

---

## 5️⃣ Motion & Animation Accessibility

### Core Requirements
- [ ] **Respect prefers-reduced-motion setting**
  - [ ] Settings > Accessibility > Motion > Reduce Motion
  - [ ] Code: `@Environment(\.accessibilityReduceMotion) private var reduceMotion` ✅
  - [ ] Animations disabled/shortened when enabled
  - [ ] Functionality preserved without animation

**Motion Audit for Your Code:**

| Animation | Current Duration | Reduced Duration | Respects Setting? |
|-----------|-----------------|------------------|------------------|
| Panel fade in | 0.30s | 0.01s | ✅ Yes |
| Panel scale | 0.30s | 0.01s | ✅ Yes |
| Settings cloud enter | Variable | 0.01s | ✅ Yes |
| Settings cloud exit | Variable | 0.01s | ✅ Yes |
| Settings fade | 0.30s | 0.01s | ✅ Yes |

- [ ] **No autoplay of video/animation on launch**
  - [ ] Panel reveal animation starts on `.onAppear` with duration
  - [ ] User can interrupt transitions
  - [ ] Background animations are optional

- [ ] **No flashing or rapid strobing**
  - [ ] Nothing flashes more than 3 times per second
  - [ ] Pause transitions for users with photosensitivity

- [ ] **Parallax and depth effects are subtle**
  - [ ] Cloud transitions don't cause visual distortion
  - [ ] Depth doesn't require sustained focus

### Testing Protocol
```swift
// Enable Reduce Motion:
Settings > Accessibility > Motion > Reduce Motion > On

// Test:
1. Launch app with Reduce Motion enabled
2. Verify all animations complete instantly (0.01s)
3. Confirm all functionality works without motion
4. Test transitions between screens
5. Verify visual feedback still works (opacity, color change)
```

**Motion Testing Date:** ___________  
**Reduce Motion Enabled:** PASS ☐ FAIL ☐  
**All Features Work Without Animation:** YES ☐ NO ☐  
**Issues Found:** ___________________________  

---

## 6️⃣ Audio & Hearing Accessibility

### Core Requirements
- [ ] **No essential information conveyed by sound alone**
  - [ ] Button taps use haptic feedback (visual alternative) ✅
  - [ ] Success/error states show visual indicator
  - [ ] Audio cues have corresponding visual feedback

- [ ] **Background sounds are optional**
  - [ ] Settings > Accessibility > Audio/Visual
  - [ ] Menu music/ambient sound is toggleable
  - [ ] Music doesn't interfere with VoiceOver

- [ ] **Captions for audio content** (if applicable)
  - [ ] In-game dialog has subtitles option
  - [ ] Voiceovers have captions
  - [ ] Background music description available

- [ ] **Mono audio support**
  - [ ] Settings > Accessibility > Audio/Visual > Mono Audio
  - [ ] Stereo-only content has mono fallback
  - [ ] Balance slider available for stereo content

### Testing Protocol
```swift
// Enable Mono Audio:
Settings > Accessibility > Audio/Visual > Mono Audio > On

// Test:
1. All sounds work in mono
2. UI feedback is visible without sound
3. No information lost with audio disabled
4. Speech is clearly audible
```

**Audio Testing Date:** ___________  
**Mono Audio Compatible:** YES ☐ NO ☐  
**Issues Found:** ___________________________  

---

## 7️⃣ Visual Accessibility & Zoom

### Core Requirements
- [ ] **Content works with zoom enabled**
  - [ ] Settings > Accessibility > Zoom > Enable Zoom
  - [ ] Pinch-to-zoom magnifies interface 2-15x
  - [ ] No content hidden when zoomed
  - [ ] Scrolling works smoothly at zoom levels

- [ ] **Bold text rendering**
  - [ ] Settings > Accessibility > Display & Text Size > Bold Text
  - [ ] Font weights respond: `.font(.app(.body, weight: .regular))` → `.semibold`
  - [ ] UI elements remain aligned with bold text

- [ ] **Invert colors compatibility**
  - [ ] Settings > Accessibility > Display & Text Size > Smart Invert (or Classic)
  - [ ] Colors remain readable when inverted
  - [ ] Images still identifiable
  - [ ] Color symbolism changes are handled

- [ ] **On/Off labels support**
  - [ ] Settings > Accessibility > Display & Text Size > On/Off Labels
  - [ ] Toggle switches show text labels ("On"/"Off")
  - [ ] All switch semantics are clear

### Testing Protocol
```swift
// Test with Zoom enabled:
1. Pinch to zoom 200%, 300%, 400%
2. Verify menu buttons remain accessible
3. Check scrolling performance
4. Ensure no permanent zoom-only states

// Test with Bold Text enabled:
1. Verify font weights increase
2. Check button labels remain readable
3. Confirm layout doesn't break with bold
```

**Zoom Testing Date:** ___________  
**Works at 2x Zoom:** YES ☐ NO ☐  
**Works at 3x Zoom:** YES ☐ NO ☐  
**Bold Text Rendering:** PASS ☐ FAIL ☐  

---

## 8️⃣ Input & Voice Control

### Voice Control Support (iOS 13+)
- [ ] **All interactive elements can be voice-activated**
  - [ ] Settings > Accessibility > Voice Control > Enable
  - [ ] Buttons can be spoken to activate: "Tap Play" or "Tap Settings"
  - [ ] Use auto-generated labels from `.accessibilityLabel()`

- [ ] **Voice Control labels are unique**
  - [ ] No two buttons with identical voice labels
  - [ ] Labels are short (2-3 words max)
  - [ ] Avoid homonyms or easily confused words

- [ ] **Voice commands flow naturally**
  - [ ] "Play" button responds to "Play"
  - [ ] "Settings" button responds to "Settings"
  - [ ] "Close" button responds to "Close"
  - [ ] "Send Email" link responds to voice

**Voice Control Testing:**

| Element | Voice Label | Works? | Alternative |
|---------|------------|--------|-------------|
| Play Button | "Play" | ☐ | "Tap Play" |
| Settings Button | "Settings" | ☐ | "Tap Settings" |
| Close Button | "Done" | ☐ | "Tap Done" |
| Info Button | "Info" | ☐ | "Tap Info" |
| Email Link | "Email" | ☐ | "Tap Email" |

### Voice Typing / Dictation
- [ ] **Text fields support voice input**
  - [ ] If math gate has input, dictation works
  - [ ] Keyboard shows dictation button
  - [ ] Punctuation can be spoken: "period", "comma", "question mark"

**Voice Testing Date:** ___________  
**Voice Control Tested:** YES ☐ NO ☐  
**Issues Found:** ___________________________  

---

## 9️⃣ Keyboard Navigation & Hardware Keyboards

### Core Requirements
- [ ] **Full keyboard navigation support**
  - [ ] Settings > Accessibility > Keyboard > Full Keyboard Access
  - [ ] Tab/Shift+Tab cycles through all interactive elements
  - [ ] Focus indicator is visible (highlight or outline)
  - [ ] Reading order matches visual layout

- [ ] **Tab order is logical**
  - [ ] Play button first
  - [ ] Settings button second
  - [ ] Close/Info buttons third (in visual order)
  - [ ] Test with rotor: Set Keyboard Rotor to "All Items"

- [ ] **Hardware keyboard shortcuts**
  - [ ] Return key: activate focused button
  - [ ] Space bar: activate focused button
  - [ ] Arrow keys: navigate between options
  - [ ] Escape key: close modals/settings

- [ ] **Focus indicators are always visible**
  - [ ] Use `.focusable()` and `.focused(_:equals:)`
  - [ ] Default focus highlight is adequate
  - [ ] Custom focus color has 3:1 contrast against background

- [ ] **Keyboard does not trap focus**
  - [ ] All elements are reachable
  - [ ] No infinite loops
  - [ ] Escape/Back returns to previous context

### Testing Protocol
```swift
// Enable Full Keyboard Access:
Settings > Accessibility > Keyboard > Full Keyboard Access > On

// Test on iPad with Magic Keyboard:
1. Tap Tab key multiple times
2. Verify focus moves to each button
3. Press Return to activate focused button
4. Test Escape to close modal
5. Verify reading order is logical

// Code changes needed:
- Add .keyboardShortcut() for common actions
- Ensure all buttons are keyboard accessible
- Use .focusable() for custom controls
```

**Keyboard Testing Date:** ___________  
**Tab Navigation:** PASS ☐ FAIL ☐  
**Focus Visible:** PASS ☐ FAIL ☐  
**Focus Trapping:** NONE ☐ SOME ☐  

---

## 🔟 Internationalization & Localization

### Core Requirements
- [ ] **All text is localized (not hardcoded)**
  - [ ] Uses `lm.t()` localization manager ✅
  - [ ] English strings defined
  - [ ] Other languages supported (French, Spanish, Italian, etc.)
  - [ ] RTL languages tested (Arabic, Hebrew if supported)

- [ ] **Accessibility labels are localized**
  - [ ] `.accessibilityLabel(lm.t("a11y.play_button"))` ✅
  - [ ] `.accessibilityHint(lm.t("a11y.play_hint"))` ✅
  - [ ] All a11y strings in translation files
  - [ ] Verified in all languages

- [ ] **RTL language support** (if applicable)
  - [ ] Layout flips for RTL (Arabic, Hebrew)
  - [ ] Icons and images orient correctly
  - [ ] Text alignment matches language direction

- [ ] **Number and date formatting**
  - [ ] Locale-appropriate number formats
  - [ ] Date formats respect system locale
  - [ ] Currency displays correctly

**Localization Audit:**

| String Key | English | French | Spanish | Italian | German |
|-----------|---------|--------|---------|---------|--------|
| `a11y.play_button` | Play | Jouer | Jugar | Giocare | Spielen |
| `a11y.settings_button` | Settings | Paramètres | Configuración | Impostazioni | Einstellungen |
| `a11y.info_button` | Info | Informations | Información | Informazioni | Information |
| `button.done` | Done | Terminé | Hecho | Fatto | Fertig |

**Localization Testing Date:** ___________  
**Languages Tested:** ___________________  
**RTL Support:** Not Required ☐ Implemented ☐  
**Issues Found:** ___________________________  

---

## 1️⃣1️⃣ Cognitive Accessibility

### Core Requirements
- [ ] **Clear, simple language**
  - [ ] Button labels are clear and descriptive
  - [ ] No jargon or technical terms
  - [ ] Avoid abbreviations without explanation
  - [ ] Button labels: "Play", "Settings", "Info" ✅ (clear)

- [ ] **Consistent navigation patterns**
  - [ ] Play always leads to game
  - [ ] Settings always opens settings
  - [ ] Close/Done always returns to menu
  - [ ] No surprises or hidden actions

- [ ] **Clear visual hierarchy**
  - [ ] Primary action (Play) is most prominent
  - [ ] Secondary actions (Settings) are less prominent
  - [ ] Tertiary actions (Info) are smallest
  - [ ] Visual weight matches importance

- [ ] **Predictable interactions**
  - [ ] Tapping buttons produces expected results
  - [ ] Animations don't confuse or distract
  - [ ] Confirmation dialogs for destructive actions
  - [ ] Undo available when possible

- [ ] **Error prevention & recovery**
  - [ ] Form validation is clear (if applicable)
  - [ ] Error messages are specific, not technical
  - [ ] Math gate gives helpful feedback
  - [ ] Users can correct mistakes easily

- [ ] **Help & documentation available**
  - [ ] Info section explains app purpose
  - [ ] Instructions are simple and visual
  - [ ] Help button or guide accessible
  - [ ] Contact support available: `mguida2604@gmail.com` ✅

### Testing Protocol
```
Ask 3 people unfamiliar with the app to:
1. Launch and identify main action
2. Find settings
3. Explain what each button does
4. Predict what happens when they tap Play
5. Return to menu

Success: 100% can complete tasks without confusion
```

**Cognitive Testing Date:** ___________  
**Test Participants:** 3 ☐ 5 ☐  
**Success Rate:** ____ % (target: 90%+)  
**Issues Found:** ___________________________  

---

## 1️⃣2️⃣ Testing Accessibility Inspector (Xcode)

### Automated Checks
- [ ] **Run Accessibility Inspector regularly**
  1. Open Xcode
  2. Xcode → Open Developer Tools → Accessibility Inspector
  3. Select your app in the simulator
  4. Review: Issues, Audit, Colors, Rotor

- [ ] **Common Issues Reported**
  - [ ] Missing accessibility labels on buttons
  - [ ] Insufficient color contrast ratios
  - [ ] Touch targets smaller than 44×44 pt
  - [ ] Images without alt text
  - [ ] VoiceOver order issues

### Audit Checklist
```
Accessibility Inspector Audit:
☐ No "Error" level issues
☐ No "Warning" level issues (minor issues acceptable)
☐ All color contrasts pass
☐ All touch targets 44pt+
☐ All images have labels/hidden status set
☐ Rotor navigation works logically
```

**Last Accessibility Inspector Run:** ___________  
**Errors Found:** _____  
**Warnings Found:** _____  
**All Critical Issues Resolved:** YES ☐ NO ☐  

---

## 1️⃣3️⃣ Device Testing Checklist

### Required Test Devices
- [ ] iPhone 12/13/14 mini (small screen)
- [ ] iPhone 14/15 Pro (standard screen)
- [ ] iPhone 14/15 Pro Max (large screen)
- [ ] iPad Air (tablet, multi-window)
- [ ] Mac (external keyboard, mouse)

### Accessibility Settings to Test On Each
- [ ] VoiceOver enabled
- [ ] Dynamic Type: Extra Large
- [ ] Reduce Motion enabled
- [ ] High Contrast enabled
- [ ] Full Keyboard Access enabled
- [ ] One-Handed Keyboard enabled (iPhone only)
- [ ] Voice Control enabled
- [ ] Zoom enabled (up to 5x)
- [ ] Invert Colors enabled
- [ ] Mono Audio enabled

**Device Testing Matrix:**

| Device | VoiceOver | DynamicType | ReduceMotion | Contrast | Keyboard | VoiceControl | Status |
|--------|-----------|-------------|--------------|----------|----------|--------------|--------|
| iPhone 14 | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | |
| iPhone 12 mini | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | |
| iPad Air | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | |
| Mac | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | |

**Testing Date:** ___________  
**All Devices Tested:** YES ☐ NO ☐  
**Critical Issues Found:** _____  

---

## 1️⃣4️⃣ Code Quality Checklist

### SwiftUI Accessibility Best Practices
- [ ] **Use semantic views**
  - [ ] `Button` instead of `ZStack` with gesture
  - [ ] `Link` for navigation ✅ (email link)
  - [ ] `Toggle` for on/off states
  - [ ] `Picker` for selections

- [ ] **Proper accessibility modifiers**
  ```swift
  ✅ Good:
  Button(action: onPlay) {
      Text("Play")
  }
  .accessibilityLabel("Play Button")
  .accessibilityHint("Start a new game")
  
  ❌ Bad:
  ZStack { ... }
  .onTapGesture { onPlay() }
  // No labels, VoiceOver can't interact
  ```

- [ ] **Custom components have accessibility**
  ```swift
  ✅ Good in your code:
  .gameMinimumTouchTarget() // Ensures 44pt minimum
  .accessibilityLabel(lm.t("a11y.play_button"))
  
  ❌ Missing in code:
  InfoFrameOverlay // Should hide decorative frame image
  // Add: .accessibilityHidden(true) to frame image
  ```

- [ ] **Proper environment setup**
  - [ ] `@EnvironmentObject var lm: LanguageManager` ✅
  - [ ] `@Environment(\.accessibilityReduceMotion)` ✅
  - [ ] Consider: `@Environment(\.sizeCategory)`

### Code Review Checklist
```swift
// Before committing UI code:
☐ All buttons have .accessibilityLabel()
☐ Complex buttons have .accessibilityHint()
☐ Decorative elements have .accessibilityHidden(true)
☐ Images have alternative text or are hidden
☐ Colors meet 4.5:1 contrast (body text)
☐ Touch targets are ≥44x44 points
☐ Animations respect reduceMotion
☐ Text uses Dynamic Type fonts
☐ No hardcoded string values (use localization)
☐ Layout adapts to all Dynamic Type sizes
```

---

## 1️⃣5️⃣ Known Issues & Recommendations for Your App

### Current Implementation Status ✅

**What's Already Good:**
1. ✅ VoiceOver labels on all main buttons (Play, Settings)
2. ✅ VoiceOver hints provided (play button, info button)
3. ✅ Decorative images hidden from accessibility (frame, clouds)
4. ✅ Dynamic Type scaling limited appropriately
5. ✅ Haptic feedback with fallback visual feedback
6. ✅ Respect for reduceMotion setting
7. ✅ Localization manager integration (`lm.t()`)
8. ✅ Color contrast verified for main UI elements
9. ✅ Touch target minimums implemented (`.gameMinimumTouchTarget()`)

### Items to Address ⚠️

1. **Info Section Accessibility**
   - [ ] Section headers (Developers, Collaborators, Contacts) need `.accessibilityElement(children: .contain)` grouping
   - [ ] Developer list items should announce as "Person, [Name]"
   - [ ] Email link contrast: verify gold border on blue still meets 3:1 for UI components

2. **Advanced Settings Math Gate**
   - [ ] Math problem feedback should announce "Correct!" or "Try again" to VoiceOver
   - [ ] Problem text should be readable at largest Dynamic Type size
   - [ ] Ensure answer input field is keyboard accessible
   - [ ] Provide clear instructions for solving problem

3. **Settings Frame Modal**
   - [ ] Verify focus moves to first settings option when modal opens
   - [ ] Escape key should close settings (keyboard navigation)
   - [ ] Settings close button needs accessibility label ✅ (appears to be implemented)
   - [ ] All settings controls need VoiceOver labels

4. **Missing Accessibility Audits**
   - [ ] World map background: add `.accessibilityHidden(true)` if decorative
   - [ ] Cloud transition overlay: confirm is not interactive
   - [ ] Info frame border image: verify `.accessibilityHidden(true)`

5. **Voice Control Readiness**
   - [ ] Verify no duplicate accessibility labels (Voice Control requires unique voice labels)
   - [ ] All buttons can be activated by voice: "Tap Play", "Tap Settings", "Tap Close"
   - [ ] Consider adding customizable voice commands for power users

---

## 1️⃣6️⃣ Testing & Sign-Off

### Pre-Release Checklist Summary
- [ ] **Mandatory:** All 10 core accessibility categories tested
- [ ] **Mandatory:** Accessibility Inspector audit completed (0 critical errors)
- [ ] **Mandatory:** VoiceOver testing on real device
- [ ] **Mandatory:** Dynamic Type tested at Accessibility 3 size
- [ ] **Mandatory:** Color contrast verified (4.5:1 normal, 3:1 large)
- [ ] **Mandatory:** Touch targets verified (44×44 minimum)
- [ ] **Mandatory:** Reduce Motion animations tested
- [ ] **Recommended:** Tested on 3+ devices
- [ ] **Recommended:** Keyboard navigation tested on iPad
- [ ] **Recommended:** Voice Control tested on iOS device

### Sign-Off
**App Version:** _________  
**Release Date:** _________  

**Accessibility Lead:**  
Name: ____________________________  
Date: ____________________________  
Signature/Initials: ____________________________  

**QA Tester:**  
Name: ____________________________  
Date: ____________________________  
Signature/Initials: ____________________________  

---

## 1️⃣7️⃣ Resources & References

### Official Apple Documentation
- [Apple HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [SwiftUI Accessibility](https://developer.apple.com/documentation/swiftui/view/accessibility)
- [WCAG 2.1 Guidelines (AA level)](https://www.w3.org/WAI/WCAG21/quickref/)

---

## 📝 Changelog

| Version | Date | Changes | Tester |
|---------|------|---------|--------|
| 1.0 | June 2026 | Initial checklist creation | [Name] |
| 1.1 | | | |

---

## ✅ Quick Reference: Copy for Every Release

### Before Submitting to App Store:
```
CRITICAL ACCESSIBILITY CHECKS:
☐ Run Accessibility Inspector (Xcode) → 0 critical errors
☐ Test VoiceOver on iPhone (enable: Settings > Accessibility > VoiceOver)
☐ Test at largest Dynamic Type (Accessibility 3 size)
☐ Verify 4.5:1 contrast with Contrast Checker tool
☐ Confirm all buttons are 44×44 points minimum
☐ Test Reduce Motion enabled (Settings > Accessibility > Motion)
☐ Keyboard test on iPad (Settings > Accessibility > Keyboard > Full Keyboard Access)
☐ Verify all interactive elements have accessibility labels
☐ Confirm decorative images have .accessibilityHidden(true)
☐ Check localization for all a11y strings
```
