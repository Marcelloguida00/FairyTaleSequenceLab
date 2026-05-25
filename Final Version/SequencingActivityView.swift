import SwiftUI
import UniformTypeIdentifiers

// MARK: - Drag/Drop payload

struct CardSlot: Codable, Transferable, Sendable {
    let index: Int

    nonisolated static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

// MARK: - Shake animation modifier

struct ShakeModifier: ViewModifier, Animatable {
    var amount: CGFloat = 0

    var animatableData: CGFloat {
        get { amount }
        set { amount = newValue }
    }

    func body(content: Content) -> some View {
        content.offset(x: sin(amount * .pi * 3) * 10)
    }
}

// MARK: - Celebration overlay

struct CelebrationView: View {

    private struct Piece: Identifiable {
        let id: Int
        let xFraction: CGFloat
        let size: CGFloat
        let color: Color
        let startRotation: Double
        let duration: Double
        let delay: Double
        let isRect: Bool
    }

    private let pieces: [Piece]

    init() {
        let palette: [Color] = [
            Color(red: 0.98, green: 0.82, blue: 0.10),
            Color(red: 0.93, green: 0.18, blue: 0.18),
            Color(red: 0.12, green: 0.76, blue: 0.38),
            Color(red: 0.22, green: 0.52, blue: 0.96),
            Color(red: 0.95, green: 0.40, blue: 0.65),
            Color(red: 0.97, green: 0.55, blue: 0.10),
            Color(red: 0.65, green: 0.25, blue: 0.88),
        ]
        pieces = (0..<60).map { i in
            let f = Double(i)
            let x    = CGFloat((sin(f * 6.17 + 1.3) * 0.5 + 0.5) * 0.88 + 0.06)
            let size = CGFloat(10 + (sin(f * 4.33) * 0.5 + 0.5) * 9)
            let dur  = 1.2 + (sin(f * 3.71) * 0.5 + 0.5) * 1.1
            let del  = (sin(f * 2.61 + 0.5) * 0.5 + 0.5) * 0.85
            return Piece(id: i, xFraction: x, size: size,
                         color: palette[i % palette.count],
                         startRotation: f * 43.7,
                         duration: dur, delay: del,
                         isRect: i % 3 == 0)
        }
    }

    @State private var fall = false
    @State private var burstScale: CGFloat = 0.05
    @State private var burstOpacity: Double = 0
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        if reduceMotion {
            // Reduce Motion ON: niente coriandoli, solo testo statico
            VStack(spacing: 12) {
                Text("🎉")
                    .font(.system(size: 72))
                Text("You did it!")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.appPrimaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.opacity(0.88))
            .accessibilityLabel("Congratulations! You did it!")
            .accessibilityAddTraits(.isStaticText)
        } else {
            GeometryReader { geo in
                ZStack {
                    ForEach(pieces) { p in
                        Group {
                            if p.isRect {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(p.color)
                                    .frame(width: p.size * 0.5, height: p.size * 2.0)
                            } else {
                                Circle()
                                    .fill(p.color)
                                    .frame(width: p.size, height: p.size)
                            }
                        }
                        .position(
                            x: geo.size.width * p.xFraction,
                            y: fall ? geo.size.height + 40 : -40
                        )
                        .rotationEffect(.degrees(fall ? p.startRotation + 600 : p.startRotation))
                        .animation(
                            .linear(duration: p.duration).delay(p.delay),
                            value: fall
                        )
                    }

                    VStack(spacing: 10) {
                        Text("🎉")
                            .font(.system(size: 80))
                        Text("You did it!")
                            .font(.system(.largeTitle, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                    }
                    .scaleEffect(burstScale)
                    .opacity(burstOpacity)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                fall = true
                withAnimation(.spring(response: 0.42, dampingFraction: 0.52)) {
                    burstScale   = 1.0
                    burstOpacity = 1.0
                }
            }
            .accessibilityLabel("Congratulations! You did it!")
            .accessibilityAddTraits(.isStaticText)
        }
    }
}

// MARK: - Main view

enum SequenceCheckResult: Equatable {
    case correct, incorrect
}

struct SequencingActivityView<Reward: View>: View {
    let event: EventData
    let makeReward: (Int, @escaping () -> Void) -> Reward

    @State private var cardOrder: [Int]
    @State private var flippedStates: [Bool]
    @State private var checkResult: SequenceCheckResult? = nil
    @State private var attemptCount: Int = 0  // ABA: tracks failed attempts for prompting

    @State private var draggingSlot: Int? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var slotFrames: [Int: CGRect] = [:]
    @State private var hoveredSlot: Int? = nil
    @State private var shakeAmount: CGFloat = 0
    @State private var showCelebration = false
    @State private var dimForReward = false
    @State private var showReward = false

    private let positionLabels = ["1st", "2nd", "3rd", "4th"]

    init(event: EventData, @ViewBuilder makeReward: @escaping (Int, @escaping () -> Void) -> Reward) {
        self.event = event
        self.makeReward = makeReward
        self._cardOrder = State(initialValue: event.shuffledStart)
        self._flippedStates = State(initialValue: Array(repeating: false, count: event.cards.count))
    }

    // First position in the sequence where the current card is wrong
    private var firstWrongPosition: Int? {
        cardOrder.indices.first { cardOrder[$0] != event.correctOrder[$0] }
    }

    // ABA: generates a contextual hint based on the actual current card state.
    // No static text — each hint describes exactly what is wrong right now.
    private func contextualHint(level: Int) -> String {
        guard let wrongPos = firstWrongPosition else { return "Tap Check!" }

        let wrongCardId  = cardOrder[wrongPos]
        let correctCardId = event.correctOrder[wrongPos]
        let wrongCard    = event.cards[wrongCardId]
        let correctCard  = event.cards[correctCardId]
        let posLabel     = positionLabels[wrongPos]

        switch level {
        case 1:
            return "Is '\(wrongCard.description)' really the \(posLabel) scene? Think about when it happens in the story."
        case 2:
            return "The \(posLabel) scene shouldn't be '\(wrongCard.description)'. Look at the other cards and think about what comes here."
        case 3:
            return "The \(posLabel) scene should be '\(correctCard.description)'. Can you find that card?"
        default:
            if let currentPos = cardOrder.firstIndex(of: correctCardId) {
                return "'\(correctCard.description)' is in position \(currentPos + 1) but belongs \(posLabel). Move it there!"
            }
            return "Move '\(correctCard.description)' to position \(wrongPos + 1)."
        }
    }

    // ABA: mascot message escalates with each failed attempt (Least-to-Most prompting)
    private var mascotMessage: String {
        guard attemptCount > 0 else {
            return "Let's put the story back together! Drag the cards into the right order, then tap Check!"
        }
        return "Good try! \(contextualHint(level: attemptCount))"
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                HStack(spacing: 0) {
                    leftPanel
                        .frame(width: geometry.size.width * 0.32)

                    cardGridPanel(geometry: geometry)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if let result = checkResult, result == .incorrect {
                    feedbackBanner(result: result)
                        .padding(.leading, geometry.size.width * 0.32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showCelebration {
                    CelebrationView()
                        .allowsHitTesting(false)
                }

                if dimForReward {
                    Color.black.opacity(0.55)
                        .ignoresSafeArea()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                        .zIndex(9)
                }

                if showReward {
                    makeReward(attemptCount) {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                            showReward = false
                            dimForReward = false
                            showCelebration = false
                            checkResult = nil
                            attemptCount = 0
                            cardOrder = event.shuffledStart
                            flippedStates = Array(repeating: false, count: event.cards.count)
                        }
                    }
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 0.88).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        )
                    )
                    .zIndex(10)
                }
            }
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: checkResult)
    }

    // MARK: - Left panel

    private var leftPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 14) {
                Text("Put the story\nin order")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimaryText)

                MascotGuideView(
                    imageName: "Mascot Talking",
                    animatedImageNames: ["Mascot Neutral", "Mascot Talking", "Mascot Waving", "Mascot Talking"],
                    message: mascotMessage,
                    imageHeight: 136,
                    bubbleFont: .system(.callout, design: .rounded),
                    frameDuration: .milliseconds(340)
                )
            }
            .padding(.top, 32)
            .padding(.horizontal, 22)

            Divider()
                .background(Color(red: 0.7, green: 0.6, blue: 0.45))
                .padding(.horizontal, 22)
                .padding(.vertical, 14)

            VStack(alignment: .leading, spacing: 10) {
                ForEach(0..<event.cards.count, id: \.self) { position in
                    let cardId = cardOrder[position]
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(position + 1).")
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(Color.appAccent)
                            .frame(width: 20, alignment: .leading)
                        Text(event.cards[cardId].description)
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(Color.appPrimaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(.horizontal, 22)
            .animation(.spring(response: 0.3), value: cardOrder)

            Spacer()

            Button(action: checkOrder) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check!")
                        .fontWeight(.bold)
                }
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.appAccent)
                        .shadow(color: .black.opacity(0.2), radius: 6, y: 3)
                )
            }
            .buttonStyle(.plain)
            .frame(minHeight: 60)
            .padding(.horizontal, 22)
            .padding(.bottom, 32)
            .accessibilityLabel("Check your story order")
            .modifier(ShakeModifier(amount: shakeAmount))
        }
        .background(Color.appPanelBackground)
    }

    // MARK: - Card grid panel

    @ViewBuilder
    private func cardGridPanel(geometry: GeometryProxy) -> some View {
        let panelW = geometry.size.width * 0.68
        let panelH = geometry.size.height

        let outerPad: CGFloat = 20
        let innerPad: CGFloat = 16
        let spacing: CGFloat = 14
        let labelH: CGFloat = 22

        let maxW = (panelW - outerPad * 2 - innerPad * 2 - spacing) / 2
        let maxH = (panelH - outerPad * 2 - innerPad * 2 - spacing - labelH * 2) / 2
        let cardW = min(maxW, maxH * 9 / 16)
        let cardH = cardW * 16 / 9

        VStack {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.appGridBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.appBorder.opacity(0.55), lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.08), radius: 12, y: 4)

                LazyVGrid(
                    columns: [
                        GridItem(.fixed(cardW), spacing: spacing),
                        GridItem(.fixed(cardW), spacing: spacing)
                    ],
                    spacing: spacing
                ) {
                    ForEach(0..<event.cards.count, id: \.self) { slot in
                        cardSlotView(slot: slot, cardW: cardW, cardH: cardH)
                    }
                }
                .padding(innerPad)

                let allFlipped = flippedStates.allSatisfy { $0 }
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        let target = !allFlipped
                        flippedStates = Array(repeating: target, count: event.cards.count)
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: allFlipped ? "eye.slash" : "eye")
                        Text(allFlipped ? "Hide" : "Reveal")
                            .fontWeight(.semibold)
                    }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(Color.appSecondaryText)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.appBackground)
                            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, outerPad + 10)
                .padding(.trailing, outerPad + 10)

                if let dragged = draggingSlot, let frame = slotFrames[dragged] {
                    let cardId = cardOrder[dragged]
                    SequenceCardView(card: event.cards[cardId], isFlipped: $flippedStates[cardId])
                        .frame(width: cardW, height: cardH)
                        .scaleEffect(1.06)
                        .shadow(color: .black.opacity(0.35), radius: 14, y: 8)
                        .position(x: frame.midX + dragOffset.width, y: frame.midY + dragOffset.height)
                        .allowsHitTesting(false)
                        .zIndex(99)
                }
            }
            .coordinateSpace(name: "cardGrid")
            .padding(outerPad)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func cardSlotView(slot: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        let cardId = cardOrder[slot]
        let card = event.cards[cardId]
        let isDragging = draggingSlot == slot
        let isHovered = hoveredSlot == slot

        VStack(spacing: 6) {
            SequenceCardView(card: card, isFlipped: $flippedStates[cardId])
                .frame(width: cardW, height: cardH)
                .opacity(isDragging ? 0.25 : 1.0)
                .scaleEffect(isHovered ? 1.04 : 1.0)
                .shadow(
                    color: isGoldHintSlot(slot)
                        ? Color(red: 1.0, green: 0.78, blue: 0.0).opacity(0.7)
                        : .clear,
                    radius: 14
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 13)
                        .stroke(slotBorderColor(slot: slot, isHovered: isHovered),
                                lineWidth: slotBorderWidth(slot: slot, isHovered: isHovered))
                        .padding(-1)
                )
                .background(
                    GeometryReader { geo in
                        Color.clear.onAppear {
                            slotFrames[slot] = geo.frame(in: .named("cardGrid"))
                        }
                    }
                )
                .gesture(
                    DragGesture(minimumDistance: 1, coordinateSpace: .named("cardGrid"))
                        .onChanged { value in
                            if draggingSlot == nil { draggingSlot = slot }
                            dragOffset = value.translation
                            let loc = value.location
                            hoveredSlot = slotFrames.first(where: { $0.key != slot && $0.value.contains(loc) })?.key
                        }
                        .onEnded { _ in
                            if let target = hoveredSlot, target != slot {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                    cardOrder.swapAt(slot, target)
                                }
                                checkResult = nil
                            }
                            draggingSlot = nil
                            dragOffset = .zero
                            hoveredSlot = nil
                        }
                )
                .animation(.easeOut(duration: 0.15), value: isHovered)
                .animation(.easeOut(duration: 0.25), value: checkResult)

            Text(positionLabels[slot])
                .font(.system(.caption, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(Color.appSecondaryText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Position \(slot + 1): \(card.description)")
    }

    // MARK: - Gestural hint helpers

    // True quando questo slot contiene la carta da spostare per prima (prompt oro)
    private func isGoldHintSlot(_ slot: Int) -> Bool {
        guard attemptCount >= 3, let wrongPos = firstWrongPosition else { return false }
        let targetCardId = event.correctOrder[wrongPos]
        return cardOrder[slot] == targetCardId && slot != wrongPos
    }

    // MARK: - Border color logic

    private func slotBorderColor(slot: Int, isHovered: Bool) -> Color {
        if isHovered { return Color.appAccent }

        // Il bordo oro ha la priorità assoluta dal 3° tentativo in poi:
        // rimane visibile sia durante il feedback rosso/verde sia dopo.
        if isGoldHintSlot(slot) {
            return Color(red: 1.0, green: 0.78, blue: 0.0)
        }

        // Post-check feedback: verde = posizione corretta, rosso = sbagliata
        if checkResult == .incorrect {
            return cardOrder[slot] == event.correctOrder[slot]
                ? Color(red: 0.15, green: 0.65, blue: 0.35)
                : .red
        }

        return .clear
    }

    private func slotBorderWidth(slot: Int, isHovered: Bool) -> CGFloat {
        isGoldHintSlot(slot) ? 5 : 3
    }

    // MARK: - Check logic

    private func checkOrder() {
        let correct = cardOrder == event.correctOrder

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            checkResult = correct ? .correct : .incorrect
        }

        if correct {
            AppSettings.hapticSuccess()
            UIAccessibility.post(notification: .announcement, argument: "Correct! Great job!")
            withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
                showCelebration = true
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1.5))
                withAnimation(.easeIn(duration: 0.4)) {
                    dimForReward = true
                }
                try? await Task.sleep(for: .seconds(0.45))
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) {
                    showReward = true
                }
            }
        } else {
            // ABA: track each wrong attempt to escalate the prompt level
            attemptCount += 1
            AppSettings.hapticError()
            UIAccessibility.post(notification: .announcement, argument: feedbackBannerText)
            withAnimation(.linear(duration: 0.5)) {
                shakeAmount += 1
            }
        }
    }

    // MARK: - Feedback banner

    // ABA: feedback banner softens the correction with a warm acknowledgment first
    private var feedbackBannerText: String {
        "Good try! \(contextualHint(level: attemptCount))"
    }

    @ViewBuilder
    private func feedbackBanner(result: SequenceCheckResult) -> some View {
        VStack {
            Spacer()
            Text(feedbackBannerText)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(Color.appAccent)
                        .shadow(color: .black.opacity(0.25), radius: 10, y: 4)
                )
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(feedbackBannerText)
    }
}

