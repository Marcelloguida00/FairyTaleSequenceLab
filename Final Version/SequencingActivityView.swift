import SwiftUI
import UniformTypeIdentifiers

// MARK: - Transferable payload (kept for compatibility)

struct CardSlot: Codable, Transferable, Sendable {
    let index: Int

    nonisolated static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .json)
    }
}

// MARK: - Shake modifier

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
            let x   = CGFloat((sin(f * 6.17 + 1.3) * 0.5 + 0.5) * 0.88 + 0.06)
            let sz  = CGFloat(10 + (sin(f * 4.33) * 0.5 + 0.5) * 9)
            let dur = 1.2 + (sin(f * 3.71) * 0.5 + 0.5) * 1.1
            let del = (sin(f * 2.61 + 0.5) * 0.5 + 0.5) * 0.85
            return Piece(id: i, xFraction: x, size: sz,
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
            VStack(spacing: 12) {
                Text("🎉").font(.system(size: 72))
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
                        .position(x: geo.size.width * p.xFraction,
                                  y: fall ? geo.size.height + 40 : -40)
                        .rotationEffect(.degrees(fall ? p.startRotation + 600 : p.startRotation))
                        .animation(.linear(duration: p.duration).delay(p.delay), value: fall)
                    }

                    VStack(spacing: 10) {
                        Text("🎉").font(.system(size: 80))
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

// MARK: - Check result

enum SequenceCheckResult: Equatable {
    case correct, incorrect
}

// MARK: - Main view

struct SequencingActivityView<Reward: View>: View {
    let event: EventData
    let makeReward: (Int, @escaping () -> Void) -> Reward

    // slot index (0–3) → card id placed there; nil = empty
    @State private var slotContents: [Int?]
    // indexed by card id
    @State private var flippedStates: [Bool]

    @State private var checkResult: SequenceCheckResult? = nil
    @State private var attemptCount = 0
    @State private var shakeAmount: CGFloat = 0
    @State private var showCelebration = false
    @State private var dimForReward = false
    @State private var showReward = false

    // Drag state
    @State private var draggingCardId: Int? = nil
    @State private var dragOriginSlot: Int? = nil   // nil → dragged from source deck
    @State private var dragPosition: CGPoint = .zero
    @State private var slotFrames: [Int: CGRect] = [:]
    @State private var hoveredSlot: Int? = nil

    private let cardGap: CGFloat = 14
    private let hPad: CGFloat = 28
    private let positionLabels = ["1st", "2nd", "3rd", "4th"]

    init(event: EventData, @ViewBuilder makeReward: @escaping (Int, @escaping () -> Void) -> Reward) {
        self.event = event
        self.makeReward = makeReward
        _slotContents  = State(initialValue: Array(repeating: nil, count: event.cards.count))
        _flippedStates = State(initialValue: Array(repeating: false, count: event.cards.count))
    }

    // Unplaced cards, preserved in their original shuffled order
    private var sourceDeck: [Int] {
        let placed = Set(slotContents.compactMap { $0 })
        return event.shuffledStart.filter { !placed.contains($0) }
    }

    private var allSlotsFilled: Bool { slotContents.allSatisfy { $0 != nil } }

    private var firstWrongSlot: Int? {
        slotContents.indices.first { i in slotContents[i] != event.correctOrder[i] }
    }

    // ABA contextual hint
    private func contextualHint(level: Int) -> String {
        guard let wrongSlot = firstWrongSlot else { return "Tap Check!" }
        let correctCardId = event.correctOrder[wrongSlot]
        let correctCard   = event.cards[correctCardId]
        let posLabel      = positionLabels[wrongSlot]

        if let wrongCardId = slotContents[wrongSlot] {
            let wrongCard = event.cards[wrongCardId]
            switch level {
            case 1:  return "Is '\(wrongCard.description)' really the \(posLabel) scene? Think about when it happens."
            case 2:  return "The \(posLabel) scene shouldn't be '\(wrongCard.description)'. Look for another one."
            default: return "The \(posLabel) scene should be '\(correctCard.description)'. Can you find it?"
            }
        } else {
            switch level {
            case 1:  return "Position \(wrongSlot + 1) is still empty. Try placing a card there!"
            default: return "The \(posLabel) scene should be '\(correctCard.description)'."
            }
        }
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geo in
            let cardW = computeCardWidth(geo)
            let cardH = cardW * 16 / 9

            ZStack {
                // Full-screen background
                Image("background-redhood")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Subtle dark scrim so cards remain readable
                Color.black.opacity(0.18).ignoresSafeArea()

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, hPad)
                        .padding(.top, 18)
                        .padding(.bottom, 14)

                    // ── Target slots ──────────────────────────────────
                    slotsRow(cardW: cardW, cardH: cardH)
                        .padding(.horizontal, hPad)

                    Spacer(minLength: 10)

                    // ── Source cards ──────────────────────────────────
                    sourceRow(cardW: cardW, cardH: cardH)
                        .padding(.horizontal, hPad)
                        .padding(.bottom, 20)
                }

                // Floating drag ghost
                if let cardId = draggingCardId {
                    SequenceCardView(
                        card: event.cards[cardId],
                        isFlipped: .constant(flippedStates[cardId])
                    )
                    .frame(width: cardW, height: cardH)
                    .scaleEffect(1.07)
                    .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
                    .position(dragPosition)
                    .allowsHitTesting(false)
                    .zIndex(50)
                }

                // Incorrect feedback banner
                if checkResult == .incorrect {
                    feedbackBanner
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showCelebration {
                    CelebrationView().allowsHitTesting(false)
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
                            showReward      = false
                            dimForReward    = false
                            showCelebration = false
                            checkResult     = nil
                            attemptCount    = 0
                            slotContents    = Array(repeating: nil, count: event.cards.count)
                            flippedStates   = Array(repeating: false, count: event.cards.count)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.88).combined(with: .opacity),
                        removal:   .scale(scale: 0.95).combined(with: .opacity)
                    ))
                    .zIndex(10)
                }
            }
            .coordinateSpace(name: "gameBoard")
        }
        .ignoresSafeArea()
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: checkResult)
        .animation(.spring(response: 0.35, dampingFraction: 0.8),  value: slotContents.map { $0 ?? -1 })
    }

    // MARK: - Card sizing

    private func computeCardWidth(_ geo: GeometryProxy) -> CGFloat {
        let n         = CGFloat(event.cards.count)
        let totalGaps = cardGap * (n - 1)
        let maxByW    = (geo.size.width - hPad * 2 - totalGaps) / n

        // Also constrain so two rows + top bar fit vertically
        let topBarH: CGFloat = 60
        let rowSpacing: CGFloat = 10
        let vPad: CGFloat = 38
        let availRowH = (geo.size.height - topBarH - rowSpacing - vPad) / 2
        let maxByH    = availRowH * 9 / 16

        return min(maxByW, maxByH)
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Put the story in order")
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                Text("Tap a card to flip it and read the hint, then drag it to the right spot")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.white.opacity(0.80))
                    .shadow(color: .black.opacity(0.4), radius: 3, y: 1)
            }

            Spacer()

            Button(action: checkOrder) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Check!")
                        .fontWeight(.bold)
                }
                .font(.system(.headline, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 26)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(allSlotsFilled
                              ? Color(red: 0.12, green: 0.62, blue: 0.22)
                              : Color.white.opacity(0.22))
                        .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                )
            }
            .buttonStyle(.plain)
            .disabled(!allSlotsFilled)
            .frame(minWidth: 44, minHeight: 52)
            .accessibilityLabel("Check your story order")
            .modifier(ShakeModifier(amount: shakeAmount))
        }
    }

    // MARK: - Slots row (top)

    private func slotsRow(cardW: CGFloat, cardH: CGFloat) -> some View {
        HStack(spacing: cardGap) {
            ForEach(0..<event.cards.count, id: \.self) { slot in
                targetSlot(slot: slot, cardW: cardW, cardH: cardH)
            }
        }
    }

    @ViewBuilder
    private func targetSlot(slot: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        let placedId       = slotContents[slot]
        let isDraggingThis = draggingCardId != nil && draggingCardId == placedId && dragOriginSlot == slot
        let isHovered      = hoveredSlot == slot

        ZStack {
            if isDraggingThis {
                ghostCard(cardW: cardW, cardH: cardH)
            } else if let id = placedId {
                placedCard(cardId: id, slot: slot, cardW: cardW, cardH: cardH)
            } else {
                emptySlot(slot: slot, cardW: cardW, cardH: cardH, hovered: isHovered)
            }
        }
        .frame(width: cardW, height: cardH)
        // Slot number badge
        .overlay(
            Text("\(slot + 1)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.black.opacity(0.50)))
                .shadow(color: .black.opacity(0.25), radius: 2)
                .padding(.bottom, 8),
            alignment: .bottom
        )
        // Register frame for drop detection
        .background(
            GeometryReader { g in
                Color.clear.onAppear {
                    slotFrames[slot] = g.frame(in: .named("gameBoard"))
                }
            }
        )
    }

    // Card sitting in a slot: flip on tap, drag to move
    @ViewBuilder
    private func placedCard(cardId: Int, slot: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        SequenceCardView(card: event.cards[cardId], isFlipped: $flippedStates[cardId])
            .frame(width: cardW, height: cardH)
            .overlay(borderOverlay(slot: slot, cardW: cardW, cardH: cardH), alignment: .center)
            .overlay(removeButton(slot: slot), alignment: .topTrailing)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) {
                    flippedStates[cardId].toggle()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named("gameBoard"))
                    .onChanged { val in
                        if draggingCardId == nil {
                            draggingCardId  = cardId
                            dragOriginSlot  = slot
                        }
                        dragPosition = val.location
                        hoveredSlot  = slotFrames.first {
                            $0.key != slot && $0.value.contains(val.location)
                        }?.key
                    }
                    .onEnded { val in
                        finalizeDrop(at: val.location, originSlot: slot)
                    }
            )
    }

    // Border feedback after Check
    @ViewBuilder
    private func borderOverlay(slot: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        if checkResult == .incorrect {
            let isCorrectHere = slotContents[slot] == event.correctOrder[slot]
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isCorrectHere ? Color(red: 0.15, green: 0.75, blue: 0.30) : Color.red,
                    lineWidth: 4
                )
                .frame(width: cardW, height: cardH)
        }
    }

    // Small X button to return a card to the source deck
    private func removeButton(slot: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                slotContents[slot] = nil
                checkResult = nil
            }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .background(Circle().fill(Color.red.opacity(0.85)).padding(3))
                .shadow(color: .black.opacity(0.3), radius: 3)
        }
        .buttonStyle(.plain)
        .padding(6)
        .accessibilityLabel("Remove card from slot \(slot + 1)")
    }

    // Dashed empty slot
    private func emptySlot(slot: Int, cardW: CGFloat, cardH: CGFloat, hovered: Bool) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(hovered ? Color.white.opacity(0.28) : Color.white.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        hovered ? Color.white : Color.white.opacity(0.45),
                        style: StrokeStyle(lineWidth: hovered ? 3 : 2, dash: [9, 6])
                    )
            )
            .frame(width: cardW, height: cardH)
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.to.line")
                        .font(.system(size: 22))
                        .foregroundColor(.white.opacity(hovered ? 1.0 : 0.50))
                }
            )
            .animation(.easeInOut(duration: 0.15), value: hovered)
            .accessibilityLabel("Empty slot \(slot + 1)")
    }

    // Semi-transparent ghost while card is being dragged away
    private func ghostCard(cardW: CGFloat, cardH: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.white.opacity(0.10))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.white.opacity(0.25), lineWidth: 2)
            )
            .frame(width: cardW, height: cardH)
    }

    // MARK: - Source row (bottom)

    private func sourceRow(cardW: CGFloat, cardH: CGFloat) -> some View {
        HStack(spacing: cardGap) {
            ForEach(0..<event.cards.count, id: \.self) { position in
                let cardId    = event.shuffledStart[position]
                let isPlaced  = slotContents.compactMap { $0 }.contains(cardId)
                let isDragged = draggingCardId == cardId && dragOriginSlot == nil

                if isPlaced || isDragged {
                    ghostCard(cardW: cardW, cardH: cardH)
                } else {
                    sourceCard(cardId: cardId, cardW: cardW, cardH: cardH)
                }
            }
        }
    }

    // Card in the source deck: flip on tap, drag to place
    private func sourceCard(cardId: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        SequenceCardView(card: event.cards[cardId], isFlipped: $flippedStates[cardId])
            .frame(width: cardW, height: cardH)
            .shadow(color: .black.opacity(0.30), radius: 8, y: 5)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.35)) {
                    flippedStates[cardId].toggle()
                }
            }
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named("gameBoard"))
                    .onChanged { val in
                        if draggingCardId == nil {
                            draggingCardId = cardId
                            dragOriginSlot = nil
                        }
                        dragPosition = val.location
                        hoveredSlot  = slotFrames.first { $0.value.contains(val.location) }?.key
                    }
                    .onEnded { val in
                        finalizeDrop(at: val.location, originSlot: nil)
                    }
            )
    }

    // MARK: - Drop logic

    private func finalizeDrop(at location: CGPoint, originSlot: Int?) {
        defer { clearDragState() }
        guard let cardId = draggingCardId else { return }

        guard let targetSlot = slotFrames.first(where: { $0.value.contains(location) })?.key else {
            // Dropped outside any slot → card returns to its origin (no state change needed)
            return
        }

        withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
            let displaced = slotContents[targetSlot]

            slotContents[targetSlot] = cardId

            if let origin = originSlot {
                // Moved from one slot to another: swap displaced card into origin
                slotContents[origin] = displaced
            }
            // If from source deck and target had a card, that card returns to source
            // (removing it from slotContents is enough — sourceDeck is derived)

            checkResult = nil
        }
    }

    private func clearDragState() {
        draggingCardId = nil
        dragOriginSlot = nil
        dragPosition   = .zero
        hoveredSlot    = nil
    }

    // MARK: - Check

    private func checkOrder() {
        guard allSlotsFilled else { return }
        let correct = slotContents.enumerated().allSatisfy { i, id in id == event.correctOrder[i] }

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
                withAnimation(.easeIn(duration: 0.4)) { dimForReward = true }
                try? await Task.sleep(for: .seconds(0.45))
                withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) { showReward = true }
            }
        } else {
            attemptCount += 1
            AppSettings.hapticError()
            UIAccessibility.post(notification: .announcement, argument: feedbackBannerText)
            withAnimation(.linear(duration: 0.5)) { shakeAmount += 1 }
        }
    }

    // MARK: - Feedback banner

    private var feedbackBannerText: String {
        "Good try! \(contextualHint(level: attemptCount))"
    }

    private var feedbackBanner: some View {
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
                        .fill(Color(red: 0.80, green: 0.22, blue: 0.10))
                        .shadow(color: .black.opacity(0.28), radius: 10, y: 4)
                )
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel(feedbackBannerText)
    }
}
