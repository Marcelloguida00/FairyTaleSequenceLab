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

// MARK: - Placement visuals

private struct SlotPlacementVisualState {
    var bounceScale: CGFloat = 1
    var tiltDegrees: Double = 0
    var waveScale: CGFloat = 1
}

// MARK: - Empty target slot

private struct EmptySequenceSlotView: View {
    let description: String
    let slot: Int
    let cardW: CGFloat
    let cardH: CGFloat
    let hovered: Bool

    private var fillColor: Color {
        hovered ? Color.white.opacity(0.28) : Color.white.opacity(0.10)
    }

    private var borderColor: Color {
        hovered ? Color.white : Color.white.opacity(0.45)
    }

    private var borderWidth: CGFloat {
        hovered ? 3 : 2
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(fillColor)

            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    borderColor,
                    style: StrokeStyle(lineWidth: borderWidth, dash: [10, 7])
                )

            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(hovered ? 0.42 : 0.18), lineWidth: 1)
                .padding(8)

            descriptionText
        }
        .frame(width: cardW, height: cardH)
        .animation(.easeInOut(duration: 0.15), value: hovered)
        .accessibilityLabel("Empty slot \(slot + 1). Correct scene: \(description)")
    }

    private var descriptionText: some View {
        Text(description)
            .font(.app(.callout, weight: .black))
            .foregroundColor(Color(red: 0.29, green: 0.15, blue: 0.06))
            .multilineTextAlignment(.center)
            .lineLimit(7)
            .minimumScaleFactor(0.58)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 1.00, green: 0.91, blue: 0.66).opacity(0.54))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(red: 0.50, green: 0.29, blue: 0.11).opacity(0.30), lineWidth: 1)
            )
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct TapRippleEffect: View {
    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.yellow.opacity(0.8), lineWidth: 2)
                .frame(width: 30, height: 30)
                .scaleEffect(pulse ? 2.2 : 0.8)
                .opacity(pulse ? 0.0 : 1.0)
            
            Circle()
                .fill(Color.yellow.opacity(0.35))
                .frame(width: 30, height: 30)
                .scaleEffect(pulse ? 1.6 : 0.8)
                .opacity(pulse ? 0.0 : 1.0)
        }
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(Animation.easeOut(duration: 0.95).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

private struct SourceCardHintBorder: View {
    let cardW: CGFloat
    let cardH: CGFloat

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color(red: 0.22, green: 1.0, blue: 0.08), lineWidth: 7)
            .frame(width: cardW, height: cardH)
            .shadow(
                color: Color(red: 0.22, green: 1.0, blue: 0.08).opacity(pulse ? 1.0 : 0.55),
                radius: pulse ? 22 : 10
            )
            .scaleEffect(pulse ? 1.045 : 1.0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 0.75).repeatForever(autoreverses: true),
                value: pulse
            )
            .onAppear {
                guard !reduceMotion else { return }
                pulse = true
            }
            .allowsHitTesting(false)
    }
}

private struct SourceCardHintWrapper<Content: View>: View {
    let content: Content
    let cardW: CGFloat
    let cardH: CGFloat

    @State private var jumping = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(cardW: CGFloat, cardH: CGFloat, @ViewBuilder content: () -> Content) {
        self.cardW = cardW
        self.cardH = cardH
        self.content = content()
    }

    var body: some View {
        content
            .overlay(SourceCardHintBorder(cardW: cardW, cardH: cardH))
            .offset(y: jumping ? -11 : 0)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 0.52).repeatForever(autoreverses: true)) {
                    jumping = true
                }
            }
    }
}

// MARK: - Storybook chrome

private struct StorybookPageShape: Shape {
    func path(in rect: CGRect) -> Path {
        let width = rect.width
        let height = rect.height
        let cornerRadius = min(width, height) * 0.065
        let spineHalfWidth = min(width * 0.058, 42)
        let spineTopDip = min(height * 0.026, 11)
        let spineBottomDip = min(height * 0.022, 10)
        let pageLift = min(width * 0.016, 12)

        var path = Path()

        path.move(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY))

        path.addQuadCurve(
            to: CGPoint(x: rect.midX - spineHalfWidth, y: rect.minY + spineTopDip),
            control: CGPoint(x: rect.minX + width * 0.30, y: rect.minY - pageLift)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.midX + spineHalfWidth, y: rect.minY + spineTopDip),
            control: CGPoint(x: rect.midX, y: rect.minY + spineTopDip * 1.45)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.minY),
            control: CGPoint(x: rect.maxX - width * 0.30, y: rect.minY - pageLift)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + cornerRadius),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.maxX + pageLift * 0.85, y: rect.midY)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.midX + spineHalfWidth, y: rect.maxY - spineBottomDip),
            control: CGPoint(x: rect.maxX - width * 0.30, y: rect.maxY + pageLift)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.midX - spineHalfWidth, y: rect.maxY - spineBottomDip),
            control: CGPoint(x: rect.midX, y: rect.maxY - spineBottomDip * 1.45)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY),
            control: CGPoint(x: rect.minX + width * 0.30, y: rect.maxY + pageLift)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + cornerRadius),
            control: CGPoint(x: rect.minX - pageLift * 0.85, y: rect.midY)
        )

        path.addQuadCurve(
            to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Main view

struct SequencingActivityView<Reward: View>: View {
    let event: EventData
    let showsReward: Bool
    let onSuccess: (() -> Void)?
    let onSequencingComplete: ((Int) -> Void)?
    let onCelebrationZoomChange: ((Bool) -> Void)?
    let makeReward: (Int, @escaping () -> Void) -> Reward
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var lm: LanguageManager
    @AppStorage("hasSeenTutorial") private var hasSeenTutorial = false
    @State private var sourceCardFrames: [Int: CGRect] = [:]
    @State private var tutorialHandProgress: CGFloat = 0.0
    @State private var tutorialTapBounce = false

    // card ids in source row order (randomized at activity start)
    @State private var shuffledStart: [Int]
    // slot index (0–3) → card id placed there; nil = empty
    @State private var slotContents: [Int?]
    // indexed by card id
    @State private var flippedStates: [Bool]

    @State private var attemptCount = 0
    
    @State private var dimForReward = false
    @State private var showReward = false
    @State private var slotVisualStates: [Int: SlotPlacementVisualState] = [:]
    @State private var isRunningCompletionSequence = false
    @State private var flipToggleUsesFirstSound = true
    @State private var isStorybookExpanded = false

    // Drag state
    @State private var draggingCardId: Int? = nil
    @State private var dragOriginSlot: Int? = nil   // nil → dragged from source deck
    @State private var dragPosition: CGPoint = .zero
    @State private var slotFrames: [Int: CGRect] = [:]
    @State private var sourceTrayFrame: CGRect = .zero
    @State private var hoveredSlot: Int? = nil
    @State private var pressedCardId: Int? = nil

    private let cardGap: CGFloat = 14
    private var hPad: CGFloat { SequencingLayoutMetrics.stageHorizontalPad }
    private let touchedCardScale: CGFloat = 1.10
    private let draggedCardScale: CGFloat = 1.22
    /// Static hold (no drag yet): Re₄ + scale. Drag pickup is immediate once the finger moves.
    private let cardHoldDuration: Double = 0.05
    private let cardHoldMaxJitter: CGFloat = 22
    private let cardDragPickupDistance: CGFloat = 8
    private let tapToFlipMaxDistance: CGFloat = 8
    private let celebrationPostWaveTailCap: TimeInterval = 0.35
    private let celebrationZoomAnimationDelay: TimeInterval = 0.12
    /// > 1 speeds up the post-completion card wave, flip-back, and celebration handoff (both SFX modes).
    private let completionAnimationSpeed: Double = 1.55

    private func completionScaled(_ duration: TimeInterval) -> TimeInterval {
        duration / completionAnimationSpeed
    }

    init(
        event: EventData,
        showsReward: Bool = true,
        onSuccess: (() -> Void)? = nil,
        onSequencingComplete: ((Int) -> Void)? = nil,
        onCelebrationZoomChange: ((Bool) -> Void)? = nil,
        @ViewBuilder makeReward: @escaping (Int, @escaping () -> Void) -> Reward
    ) {
        self.event = event
        self.showsReward = showsReward
        self.onSuccess = onSuccess
        self.onSequencingComplete = onSequencingComplete
        self.onCelebrationZoomChange = onCelebrationZoomChange
        self.makeReward = makeReward
        _shuffledStart = State(initialValue: event.makeShuffledStart())
        _slotContents  = State(initialValue: Array(repeating: nil, count: event.cards.count))
        _flippedStates = State(initialValue: Array(repeating: false, count: event.cards.count))
    }

    private var allSlotsFilled: Bool { slotContents.allSatisfy { $0 != nil } }

    private var allSlotsCorrect: Bool {
        slotContents.enumerated().allSatisfy { index, cardId in
            guard let expectedCardId = correctCardID(forSlot: index) else { return false }
            return cardId == expectedCardId
        }
    }

    private var firstWrongSlot: Int? {
        slotContents.indices.first { slot in
            guard let expectedCardId = correctCardID(forSlot: slot) else { return true }
            return slotContents[slot] != expectedCardId
        }
    }

    private var correctlyPlacedCount: Int {
        slotContents.indices.reduce(into: 0) { count, slot in
            guard let cardId = slotContents[slot],
                  correctCardID(forSlot: slot) == cardId else { return }
            count += 1
        }
    }

    private var wrongFilledSlots: [Int] {
        slotContents.indices.filter { slot in
            guard let cardId = slotContents[slot],
                  let expectedCardId = correctCardID(forSlot: slot) else { return true }
            return cardId != expectedCardId
        }
    }

    private var guidedSourceCardID: Int? {
        guard attemptCount >= 2,
              let wrongSlot = firstWrongSlot else { return nil }

        return correctCardID(forSlot: wrongSlot)
    }

    private func cardData(for cardId: Int) -> CardData? {
        if event.cards.indices.contains(cardId), event.cards[cardId].id == cardId {
            return event.cards[cardId]
        }

        return event.cards.first { $0.id == cardId }
    }

    private func cardStateIndex(for cardId: Int) -> Int? {
        if flippedStates.indices.contains(cardId) {
            return cardId
        }

        guard let cardIndex = event.cards.firstIndex(where: { $0.id == cardId }),
              flippedStates.indices.contains(cardIndex) else { return nil }
        return cardIndex
    }

    private func flippedState(for cardId: Int) -> Bool {
        guard let index = cardStateIndex(for: cardId) else { return false }
        return flippedStates[index]
    }

    private func correctCardID(forSlot slot: Int) -> Int? {
        guard event.correctOrder.indices.contains(slot) else { return nil }
        return event.correctOrder[slot]
    }

    private func correctCard(forSlot slot: Int) -> CardData? {
        guard let cardId = correctCardID(forSlot: slot) else { return nil }
        return cardData(for: cardId)
    }

    private var boardStateNeedsRepair: Bool {
        slotContents.count != event.cards.count ||
        flippedStates.count != event.cards.count ||
        shuffledStart.count != event.cards.count ||
        shuffledStart.contains { cardData(for: $0) == nil } ||
        slotContents.contains { cardId in
            guard let cardId else { return false }
            return cardData(for: cardId) == nil
        }
    }

    private func resetBoardState() {
        shuffledStart = event.makeShuffledStart()
        slotContents = Array(repeating: nil, count: event.cards.count)
        flippedStates = Array(repeating: false, count: event.cards.count)
        slotVisualStates = [:]
        draggingCardId = nil
        dragOriginSlot = nil
        dragPosition = .zero
        hoveredSlot = nil
        pressedCardId = nil
        isRunningCompletionSequence = false
        flipToggleUsesFirstSound = true
        isStorybookExpanded = false
        dimForReward = false
        showReward = false
        SequencingSoundCoordinator.resetSession()
    }

    private func repairBoardStateIfNeeded() {
        guard boardStateNeedsRepair else { return }
        resetBoardState()
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { screenGeo in
            let stageSize = SequencingLayoutMetrics.stageSize(in: screenGeo.size)
            let cardW = computeCardWidth(in: stageSize)
            let cardH = cardW * 16 / 9

            ZStack {
                sequencingBackground(screenSize: screenGeo.size)

                sequencingStage(cardW: cardW, cardH: cardH)
                    .frame(width: stageSize.width, height: stageSize.height)
                    .position(x: screenGeo.size.width / 2, y: screenGeo.size.height / 2)
            }
        }
        .ignoresSafeArea()
        .onAppear {
            repairBoardStateIfNeeded()
            if event.id == 1 && !hasSeenTutorial {
                withAnimation(Animation.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    tutorialTapBounce = true
                }
            }
        }
        .onChange(of: event.id) { _, _ in
            resetBoardState()
        }
        .onChange(of: isStorybookExpanded) { _, expanded in
            onCelebrationZoomChange?(expanded)
        }
        .onDisappear {
            SequencingSoundCoordinator.cardPickupEnded()
            onCelebrationZoomChange?(false)
        }
    }

    @ViewBuilder
    private func sequencingBackground(screenSize: CGSize) -> some View {
        Image("background-redhood")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()

        Color.black.opacity(0.22)
            .ignoresSafeArea()

        RadialGradient(
            colors: [
                Color.clear,
                Color.black.opacity(0.32)
            ],
            center: .center,
            startRadius: min(screenSize.width, screenSize.height) * 0.18,
            endRadius: max(screenSize.width, screenSize.height) * 0.70
        )
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func sequencingStage(cardW: CGFloat, cardH: CGFloat) -> some View {
        ZStack {
            VStack(spacing: 10) {
                storybookPanel(cardW: cardW, cardH: cardH)
                    .padding(.horizontal, isStorybookExpanded ? 0 : hPad)
                    .padding(.top, isStorybookExpanded ? 0 : SequencingLayoutMetrics.stageStorybookTopPad)
                    .frame(maxWidth: .infinity, maxHeight: isStorybookExpanded ? .infinity : nil)
                    .zIndex(100)

                if !isStorybookExpanded {
                    Spacer(minLength: 0)

                    sourceTray(cardW: cardW, cardH: cardH)
                        .padding(.horizontal, hPad)
                        .padding(.bottom, SequencingLayoutMetrics.stageDeckBottomPad)
                        .transition(.opacity)
                }
            }

            if let cardId = draggingCardId,
               let card = cardData(for: cardId) {
                SequenceCardView(
                    card: card,
                    isFlipped: flippedState(for: cardId)
                )
                .frame(width: cardW, height: cardH)
                .scaleEffect(draggedCardScale)
                .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
                .position(dragPosition)
                .allowsHitTesting(false)
                .zIndex(50)
            }

            if dimForReward {
                Color.black.opacity(0.55)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .zIndex(9)
            }

            if showReward {
                makeReward(attemptCount) {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        showReward      = false
                        dimForReward    = false
                        isStorybookExpanded = false
                        attemptCount    = 0
                        shuffledStart   = event.makeShuffledStart()
                        slotContents    = Array(repeating: nil, count: event.cards.count)
                        flippedStates   = Array(repeating: false, count: event.cards.count)
                        slotVisualStates = [:]
                    }
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.88).combined(with: .opacity),
                    removal:   .scale(scale: 0.95).combined(with: .opacity)
                ))
                .zIndex(10)
            }

            if event.id == 1 && !hasSeenTutorial {
                if let targetCardID = event.correctOrder.first,
                   let cardFrame = sourceCardFrames[targetCardID],
                   let slotFrame = slotFrames[0] {
                    
                    let isCardPlaced = (slotContents[0] == targetCardID)
                    
                    let startPoint = CGPoint(x: cardFrame.midX, y: cardFrame.midY)
                    let endPoint = CGPoint(x: slotFrame.midX, y: slotFrame.midY)
                    
                    let currentX = isCardPlaced ? endPoint.x : startPoint.x + (endPoint.x - startPoint.x) * tutorialHandProgress
                    let currentY = isCardPlaced ? endPoint.y : startPoint.y + (endPoint.y - startPoint.y) * tutorialHandProgress
                    
                    ZStack {
                        VStack(spacing: 4) {
                            let msg = isCardPlaced ? lm.t("tutorial.tap_to_flip") : lm.t("tutorial.drag_first_scene")
                            Text(msg)
                                .font(.app(.title3, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.black)
                                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.yellow, lineWidth: 1.5))
                                )
                                .shadow(color: .black.opacity(0.35), radius: 5)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 320)
                            
                            ZStack {
                                if isCardPlaced {
                                    TapRippleEffect()
                                        .offset(y: -18)
                                }
                                
                                Image(systemName: isCardPlaced ? "hand.tap.fill" : "hand.draw.fill")
                                     .font(.system(size: 40, weight: .bold))
                                     .foregroundColor(.white)
                                     .shadow(color: .black.opacity(0.4), radius: 5, x: 2, y: 3)
                                     .scaleEffect(isCardPlaced ? (tutorialTapBounce ? 0.85 : 1.05) : 1.0)
                                     .offset(y: isCardPlaced ? (tutorialTapBounce ? 10 : -8) : 0)
                            }
                        }
                        .position(x: currentX, y: currentY - 60)
                    }
                    .zIndex(200)
                    .allowsHitTesting(false)
                    .onAppear {
                        tutorialHandProgress = 0.0
                        withAnimation(Animation.linear(duration: 2.2).repeatForever(autoreverses: false)) {
                            tutorialHandProgress = 1.0
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: "gameBoard")
    }

    // MARK: - Card sizing

    private func computeCardWidth(in size: CGSize) -> CGFloat {
        let n = max(CGFloat(event.cards.count), 1)
        let totalGaps = cardGap * max(n - 1, 0)
        let framedHorizontalInset = SequencingLayoutMetrics.storybookSlotsHorizontalPad * 2
        let traySideInset: CGFloat = 16
        let maxByStorybookW = (size.width - hPad * 2 - framedHorizontalInset - totalGaps) / n
        let maxByTrayW = (size.width - hPad * 2 - traySideInset * 2 - totalGaps) / n
        let maxByW = min(maxByStorybookW, maxByTrayW)

        // Constrain for the storybook frame, bottom tray, and top padding.
        let topChrome = SequencingLayoutMetrics.stageStorybookTopPad
        let storybookChrome: CGFloat = 78
        let trayChrome: CGFloat = 40
        let verticalBreathingRoom: CGFloat = 56
        let availRowH = (size.height - topChrome - storybookChrome - trayChrome - verticalBreathingRoom) / 2
        let maxByH    = availRowH * 9 / 16

        return max(104, min(maxByW, maxByH))
    }

    // MARK: - Source tray

    private func sourceTray(cardW: CGFloat, cardH: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.94, green: 0.70, blue: 0.34),
                            Color(red: 0.76, green: 0.42, blue: 0.16)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Color(red: 0.25, green: 0.12, blue: 0.06), lineWidth: 5)
                )
                .shadow(color: .black.opacity(0.38), radius: 14, y: 7)

            sourceRow(cardW: cardW, cardH: cardH)
                .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardH + 42)
        .background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        updateSourceTrayFrame(geometry.frame(in: .named("gameBoard")))
                    }
                    .onChange(of: geometry.frame(in: .named("gameBoard"))) { _, newFrame in
                        updateSourceTrayFrame(newFrame)
                    }
            }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(lm.t("a11y.source_tray"))
        .accessibilityHint(lm.t("a11y.source_tray_hint"))
    }

    // MARK: - Storybook frame

    private func storybookPanel(cardW: CGFloat, cardH: CGFloat) -> some View {
        Group {
            if isStorybookExpanded {
                expandedCelebrationPanel(cardW: cardW, cardH: cardH)
            } else {
                framedStorybookPanel(cardW: cardW, cardH: cardH)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: isStorybookExpanded)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: isStorybookExpanded ? .infinity : nil)
        .frame(height: isStorybookExpanded ? nil : cardH + 82)
        .accessibilityElement(children: .contain)
    }

    private func framedStorybookPanel(cardW: CGFloat, cardH: CGFloat) -> some View {
        ZStack {
            StorybookPageShape()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.86, blue: 0.52),
                            Color(red: 0.93, green: 0.72, blue: 0.36),
                            Color(red: 0.88, green: 0.62, blue: 0.28)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            StorybookPageShape()
                .stroke(Color(red: 0.23, green: 0.10, blue: 0.06), lineWidth: 12)
                .shadow(color: .black.opacity(0.42), radius: 16, y: 8)

            slotsRow(cardW: cardW, cardH: cardH)
                .padding(.horizontal, SequencingLayoutMetrics.storybookSlotsHorizontalPad)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, SequencingLayoutMetrics.storybookSlotsTopPad)
                .padding(.bottom, SequencingLayoutMetrics.storybookSlotsBottomPad)
        }
    }

    private func expandedCelebrationPanel(cardW: CGFloat, cardH: CGFloat) -> some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            slotsRow(cardW: cardW, cardH: cardH)
                .padding(.horizontal, 32)
                .frame(maxWidth: .infinity, alignment: .center)
                .scaleEffect(1.2)

            Text(lm.t("celebration.title"))
                .font(.app(size: 48, weight: .black))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
                .padding(.horizontal, hPad)

            celebrationContinueButton

            Spacer(minLength: 0)
        }
        .padding(.bottom, 48)
        .transition(.opacity)
    }

    private var celebrationContinueButton: some View {
        GamePillButton(
            title: event.isLastEvent ? lm.t("button.back_to_map") : lm.t("button.next_event"),
            minWidth: GameButtonMetrics.primaryPillWidth,
            minHeight: GameButtonMetrics.primaryPillHeight,
            trailingIcon: "arrow.right",
            action: handleCelebrationContinue
        )
        .accessibilityLabel(lm.t("a11y.continue_button"))
        .accessibilityHint(lm.t("a11y.continue_hint"))
        .accessibilityAddTraits(.isButton)
    }

    private func handleCelebrationContinue() {
        AppSettings.hapticImpact(.light)
        onSequencingComplete?(attemptCount)
    }

    // MARK: - Storybook frame

    private func slotsRow(cardW: CGFloat, cardH: CGFloat) -> some View {
        LazyHStack(spacing: cardGap) {
            ForEach(slotContents.indices, id: \.self) { slot in
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
            }

            if let id = placedId {
                placedCard(cardId: id, slot: slot, cardW: cardW, cardH: cardH)
                .opacity(isDraggingThis ? 0.001 : 1)
            } else {
                emptySlot(slot: slot, cardW: cardW, cardH: cardH, hovered: isHovered)
            }
        }
        .frame(width: cardW, height: cardH)
        // Slot number badge
        .overlay(
            Text("\(slot + 1)")
                .font(.app(size: 13, weight: .bold))
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
                let frame = g.frame(in: .named("gameBoard"))
                Color.clear
                    .onAppear { updateSlotFrame(slot: slot, frame: frame) }
                    .onChange(of: frame) { _, newFrame in
                        updateSlotFrame(slot: slot, frame: newFrame)
                    }
            }
        )
    }

    // Card sitting in a slot: drag to move
    @ViewBuilder
    private func placedCard(cardId: Int, slot: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        if let card = cardData(for: cardId) {
            cardInteractionGestures(
                SequenceCardView(card: card, isFlipped: flippedState(for: cardId))
                    .frame(width: cardW, height: cardH)
                    .scaleEffect(slotVisualScale(for: slot) * cardTouchScale(for: cardId))
                    .rotationEffect(.degrees(slotVisualTilt(for: slot)))
                    .contentShape(RoundedRectangle(cornerRadius: 16)),
                cardId: cardId,
                originSlot: slot
            )
        } else {
            ghostCard(cardW: cardW, cardH: cardH)
        }
    }

    private var cardTouchAnimation: Animation? {
        reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.12)
    }

    private func slotVisualScale(for slot: Int) -> CGFloat {
        let state = slotVisualStates[slot] ?? SlotPlacementVisualState()
        return state.bounceScale * state.waveScale
    }

    private func slotVisualTilt(for slot: Int) -> Double {
        slotVisualStates[slot]?.tiltDegrees ?? 0
    }

    // Dashed empty slot
    private func emptySlot(slot: Int, cardW: CGFloat, cardH: CGFloat, hovered: Bool) -> some View {
        let correctDescription = correctCard(forSlot: slot)?.description ?? ""
        return EmptySequenceSlotView(
            description: correctDescription,
            slot: slot,
            cardW: cardW,
            cardH: cardH,
            hovered: hovered
        )
    }

    // Semi-transparent ghost while card is being dragged away
    private func ghostCard(cardW: CGFloat, cardH: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.12))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.30), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
            )
            .frame(width: cardW, height: cardH)
    }

    // MARK: - Source row (bottom)

    private func sourceRow(cardW: CGFloat, cardH: CGFloat) -> some View {
        let placedCardIds = Set(slotContents.compactMap { $0 })

        return LazyHStack(spacing: cardGap) {
            ForEach(shuffledStart.indices, id: \.self) { position in
                let cardId    = shuffledStart[position]
                let isPlaced  = placedCardIds.contains(cardId)
                let isDragged = draggingCardId == cardId && dragOriginSlot == nil

                if isPlaced {
                    ghostCard(cardW: cardW, cardH: cardH)
                } else {
                    ZStack {
                        if isDragged {
                            ghostCard(cardW: cardW, cardH: cardH)
                        }

                        sourceCard(cardId: cardId, cardW: cardW, cardH: cardH)
                            .opacity(isDragged ? 0.001 : 1)
                    }
                }
            }
        }
    }

    // Card in the source deck: drag to place
    @ViewBuilder
    private func sourceCard(cardId: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        if let card = cardData(for: cardId) {
            let cardView = Group {
                if guidedSourceCardID == cardId {
                    cardInteractionGestures(
                        SourceCardHintWrapper(cardW: cardW, cardH: cardH) {
                            SequenceCardView(card: card, isFlipped: flippedState(for: cardId))
                                .frame(width: cardW, height: cardH)
                                .scaleEffect(cardTouchScale(for: cardId))
                                .shadow(color: .black.opacity(0.30), radius: 8, y: 5)
                                .contentShape(RoundedRectangle(cornerRadius: 16))
                        },
                        cardId: cardId,
                        originSlot: nil
                    )
                } else {
                    cardInteractionGestures(
                        SequenceCardView(card: card, isFlipped: flippedState(for: cardId))
                            .frame(width: cardW, height: cardH)
                            .scaleEffect(cardTouchScale(for: cardId))
                            .shadow(color: .black.opacity(0.30), radius: 8, y: 5)
                            .contentShape(RoundedRectangle(cornerRadius: 16)),
                        cardId: cardId,
                        originSlot: nil
                    )
                }
            }

            cardView
                .background(
                    GeometryReader { g in
                        let frame = g.frame(in: .named("gameBoard"))
                        Color.clear
                            .onAppear { sourceCardFrames[cardId] = frame }
                            .onChange(of: frame) { _, newFrame in
                                sourceCardFrames[cardId] = newFrame
                            }
                    }
                )
        } else {
            ghostCard(cardW: cardW, cardH: cardH)
        }
    }

    // MARK: - Drop logic

    private func toggleCard(_ cardId: Int) {
        guard let index = cardStateIndex(for: cardId) else { return }
        playFlipToggleSound()
        withAnimation(flipAnimation) {
            flippedStates[index].toggle()
        }

        if !hasSeenTutorial && cardId == event.correctOrder.first && slotContents[0] == cardId {
            withAnimation(.easeInOut(duration: 0.35)) {
                hasSeenTutorial = true
            }
        }
    }

    /// Alternates flip sounds for every card toggle (simplified or orchestral).
    private func playFlipToggleSound() {
        SequencingSoundCoordinator.cardFlipped(usesAlternateFlipSound: !flipToggleUsesFirstSound)
        flipToggleUsesFirstSound.toggle()
    }

    private var flipAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.42)
    }

    private var completionFlipAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: completionScaled(0.42))
    }

    private func cardTouchScale(for cardId: Int) -> CGFloat {
        if draggingCardId == cardId { return draggedCardScale }
        if pressedCardId == cardId { return touchedCardScale }
        return 1.0
    }

    @ViewBuilder
    private func cardInteractionGestures<Content: View>(
        _ content: Content,
        cardId: Int,
        originSlot: Int?
    ) -> some View {
        let isLockedByTutorial = (event.id == 1 && !hasSeenTutorial && cardId != event.correctOrder.first)

        if allSlotsCorrect || isRunningCompletionSequence || isStorybookExpanded || isLockedByTutorial {
            content
                .allowsHitTesting(false)
        } else {
            content
                .onLongPressGesture(
                    minimumDuration: cardHoldDuration,
                    maximumDistance: cardHoldMaxJitter,
                    pressing: { isPressing in
                        if !isPressing, draggingCardId == nil {
                            endCardTouch()
                        }
                    },
                    perform: { beginCardHold(cardId: cardId) }
                )
                .highPriorityGesture(cardDragGesture(cardId: cardId, originSlot: originSlot))
                .animation(cardTouchAnimation, value: pressedCardId)
                .animation(cardTouchAnimation, value: draggingCardId)
        }
    }

    private func cardDragGesture(cardId: Int, originSlot: Int?) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named("gameBoard"))
            .onChanged { value in
                let distance = hypot(value.translation.width, value.translation.height)
                guard distance > cardDragPickupDistance else { return }
                if pressedCardId != cardId {
                    beginCardHold(cardId: cardId)
                }
                updateDrag(cardId: cardId, originSlot: originSlot, location: value.location)
            }
            .onEnded { value in
                if draggingCardId == cardId {
                    finalizeDrop(at: value.location, originSlot: originSlot)
                } else if isTapToFlip(value), pressedCardId == nil {
                    toggleCard(cardId)
                } else {
                    endCardTouch()
                }
            }
    }

    private func isTapToFlip(_ value: DragGesture.Value) -> Bool {
        hypot(value.translation.width, value.translation.height) <= tapToFlipMaxDistance
    }

    /// Pickup feedback after hold completes — not on finger-down (see long-press `pressing`).
    private func beginCardHold(cardId: Int) {
        guard pressedCardId != cardId else { return }
        pressedCardId = cardId
        AppSettings.hapticImpact(.light)
        SequencingSoundCoordinator.cardPickupStarted(correctPlacements: correctlyPlacedCount)
    }

    private func endCardTouch() {
        pressedCardId = nil
        SequencingSoundCoordinator.cardPickupEnded()
    }

    private func updateDrag(cardId: Int, originSlot: Int?, location: CGPoint) {
        let nextHoveredSlot = slot(at: location, excluding: originSlot)
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            if draggingCardId == nil {
                draggingCardId = cardId
                dragOriginSlot = originSlot
            }
            dragPosition = location
            if hoveredSlot != nextHoveredSlot {
                hoveredSlot = nextHoveredSlot
            }
        }
    }

    private func slot(at location: CGPoint, excluding excludedSlot: Int? = nil) -> Int? {
        slotContents.indices.first { slot in
            slot != excludedSlot && slotFrames[slot]?.contains(location) == true
        }
    }

    private func updateSlotFrame(slot: Int, frame: CGRect) {
        guard slotFrames[slot] != frame else { return }
        slotFrames[slot] = frame
    }

    private func updateSourceTrayFrame(_ frame: CGRect) {
        guard sourceTrayFrame != frame else { return }
        sourceTrayFrame = frame
    }

    private func isInSourceTray(_ location: CGPoint) -> Bool {
        sourceTrayFrame.width > 0 && sourceTrayFrame.contains(location)
    }

    private func finalizeDrop(at location: CGPoint, originSlot: Int?) {
        defer { clearDragState() }
        guard let cardId = draggingCardId,
              cardData(for: cardId) != nil else { return }

        if let targetSlot = slot(at: location, excluding: originSlot) {
            let didMoveSlots = originSlot != targetSlot
            guard didMoveSlots else { return }


            var nextContents = slotContents
            let displaced = nextContents[targetSlot]

            nextContents[targetSlot] = cardId

            if let origin = originSlot {
                guard nextContents.indices.contains(origin) else { return }
                nextContents[origin] = origin == targetSlot ? cardId : displaced
            }

            let normalizedContents = normalizedSlotContents(nextContents, keeping: cardId, in: targetSlot)

            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                slotContents = normalizedContents
            }

            handlePlacement(forSlot: targetSlot)
            evaluateCompletedBoardIfReady()
            return
        }

        if let origin = originSlot,
           slotContents.indices.contains(origin),
           isInSourceTray(location) {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                slotContents[origin] = nil
            }
        }
    }

    private func normalizedSlotContents(_ contents: [Int?], keeping keptCardId: Int, in keptSlot: Int) -> [Int?] {
        var normalized = contents
        var seen: Set<Int> = []

        if normalized.indices.contains(keptSlot) {
            normalized[keptSlot] = keptCardId
            seen.insert(keptCardId)
        }

        for index in normalized.indices where index != keptSlot {
            guard let cardId = normalized[index],
                  cardData(for: cardId) != nil,
                  !seen.contains(cardId) else {
                normalized[index] = nil
                continue
            }

            seen.insert(cardId)
        }

        return normalized
    }

    private func clearDragState() {
        draggingCardId = nil
        dragOriginSlot = nil
        dragPosition   = .zero
        hoveredSlot    = nil
        endCardTouch()
    }

    private func handlePlacement(forSlot slot: Int) {
        AppSettings.hapticImpact(.light)
        SequencingSoundCoordinator.correctPlacement(
            slot: slot,
            correctPlacementsAfter: correctlyPlacedCount
        )
        playPlacementAnimation(for: slot)
    }



    private var incorrectRevertDelayNanoseconds: UInt64 {
        if reduceMotion { return 0 }
        if SequencingSFXMode.current == .orchestral {
            let clip = OrchestralAudioMetrics.wrongClipDuration
            return UInt64(min(clip * 0.72, 1.45) * 1_000_000_000)
        }
        return 650_000_000
    }

    private func playPlacementAnimation(for slot: Int) {
        guard !reduceMotion else { return }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.58)) {
            var state = slotVisualStates[slot] ?? SlotPlacementVisualState()
            state.bounceScale = 1.06
            state.tiltDegrees = 0
            slotVisualStates[slot] = state
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(360))
            withAnimation(.spring(response: 0.34, dampingFraction: 0.72)) {
                var state = slotVisualStates[slot] ?? SlotPlacementVisualState()
                state.bounceScale = 1
                slotVisualStates[slot] = state
            }
        }
    }

    private func handleIncorrectCompletedBoard() {
        let slots = wrongFilledSlots
        guard !slots.isEmpty else { return }
        let misplacedCards = slots.compactMap { slot -> (slot: Int, cardId: Int)? in
            guard let cardId = slotContents[slot] else { return nil }
            return (slot, cardId)
        }

        AppSettings.hapticImpact(.soft)
        SequencingSoundCoordinator.incorrectPlacement()
        attemptCount += 1

        for slot in slots {
            playIncorrectPlacementAnimation(for: slot)
        }

        let returnDelayNs = incorrectRevertDelayNanoseconds
        Task { @MainActor in
            if returnDelayNs > 0 {
                try? await Task.sleep(nanoseconds: returnDelayNs)
            }

            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                for misplacedCard in misplacedCards {
                    guard slotContents.indices.contains(misplacedCard.slot),
                          slotContents[misplacedCard.slot] == misplacedCard.cardId else { continue }
                    slotContents[misplacedCard.slot] = nil
                }
            }

            for slot in slots {
                slotVisualStates[slot] = SlotPlacementVisualState()
            }
        }
    }

    private func playIncorrectPlacementAnimation(for slot: Int) {
        guard !reduceMotion else { return }

        animateSlotTilt(slot, degrees: -4.5, duration: 0.12)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(120))
            animateSlotTilt(slot, degrees: 4.5, duration: 0.16)
            try? await Task.sleep(for: .milliseconds(160))
            animateSlotTilt(slot, degrees: -2.2, duration: 0.14)
            try? await Task.sleep(for: .milliseconds(140))
            animateSlotTilt(slot, degrees: 0, duration: 0.18)
        }
    }

    private func animateSlotTilt(_ slot: Int, degrees: Double, duration: TimeInterval) {
        withAnimation(.easeInOut(duration: duration)) {
            var state = slotVisualStates[slot] ?? SlotPlacementVisualState()
            state.tiltDegrees = degrees
            slotVisualStates[slot] = state
        }
    }

    private func evaluateCompletedBoardIfReady() {
        guard allSlotsFilled, !isRunningCompletionSequence, !isStorybookExpanded else { return }

        if allSlotsCorrect {
            Task { await runCompletionWaveAndCelebrate() }
        } else {
            handleIncorrectCompletedBoard()
        }
    }

    @MainActor
    private func runCompletionWaveAndCelebrate() async {
        isRunningCompletionSequence = true
        
        withAnimation(completionFlipAnimation) {
            for index in flippedStates.indices {
                flippedStates[index] = false
            }
        }

        let isOrchestral = SequencingSFXMode.current == .orchestral

        if isOrchestral {
            let correctLead = OrchestralAudioMetrics.correctClipDuration
            try? await Task.sleep(for: .seconds(completionScaled(correctLead * 0.28)))
        } else {
            let beat = OrchestralAudioMetrics.simplifiedVictoryArpeggioBeat
            try? await Task.sleep(for: .seconds(completionScaled(beat * 0.5)))
        }

        SequencingSoundCoordinator.victoryJingle()

        let jingleDuration = isOrchestral
            ? OrchestralAudioMetrics.victoryJingleDuration
            : OrchestralAudioMetrics.simplifiedVictoryJingleDuration
        let slotCount = max(slotContents.count, 1)

        if !reduceMotion {
            let pulseUp: Double
            let pulseDown: Double
            let swellHold: TimeInterval
            let settleHold: TimeInterval

            if isOrchestral {
                let waveWindow = completionScaled(jingleDuration * 0.88)
                let slotCycle = waveWindow / Double(slotCount)
                pulseUp = completionScaled(0.46)
                pulseDown = completionScaled(0.36)
                swellHold = max(0.08, slotCycle * 0.42)
                settleHold = max(0.07, slotCycle * 0.38)
            } else {
                // Match the four quick arpeggio hits in SequencingVictory_Jingle (~0.20 s apart).
                let beat = OrchestralAudioMetrics.simplifiedVictoryArpeggioBeat
                pulseUp = completionScaled(0.26)
                pulseDown = completionScaled(0.22)
                swellHold = completionScaled(beat * 0.52)
                settleHold = completionScaled(beat * 0.48)
            }

            for slot in slotContents.indices {
                withAnimation(.spring(response: pulseUp, dampingFraction: 0.66)) {
                    var state = slotVisualStates[slot] ?? SlotPlacementVisualState()
                    state.waveScale = isOrchestral ? 1.10 : 1.08
                    state.bounceScale = 1
                    state.tiltDegrees = 0
                    slotVisualStates[slot] = state
                }

                try? await Task.sleep(for: .seconds(swellHold))

                withAnimation(.spring(response: pulseDown, dampingFraction: 0.78)) {
                    var state = slotVisualStates[slot] ?? SlotPlacementVisualState()
                    state.waveScale = 1
                    slotVisualStates[slot] = state
                }

                if slot < slotContents.count - 1 {
                    try? await Task.sleep(for: .seconds(settleHold))
                }
            }

            let waveElapsed = (swellHold + settleHold) * Double(max(slotCount - 1, 0)) + swellHold
            let naturalTail = max(0.12, jingleDuration - waveElapsed)
            let tail = min(completionScaled(naturalTail), completionScaled(celebrationPostWaveTailCap))
            try? await Task.sleep(for: .seconds(tail))
        } else {
            try? await Task.sleep(for: .seconds(completionScaled(jingleDuration)))
        }

        await triggerCelebration()
        isRunningCompletionSequence = false
    }

    @MainActor
    private func triggerCelebration() async {
        AppSettings.hapticSuccess()
        UIAccessibility.post(notification: .announcement, argument: "Correct! Great job!")

        let zoomAnimation = Animation.spring(response: completionScaled(0.6), dampingFraction: 0.8)
            .delay(reduceMotion ? 0 : completionScaled(celebrationZoomAnimationDelay))

        if onSequencingComplete != nil {
            withAnimation(zoomAnimation) {
                isStorybookExpanded = true
            }
        } else if showsReward {
            withAnimation(zoomAnimation) {
                isStorybookExpanded = true
            }
            try? await Task.sleep(for: .seconds(2.5))
            withAnimation(.easeIn(duration: 0.4)) { dimForReward = true }
            try? await Task.sleep(for: .seconds(0.45))
            withAnimation(.spring(response: 0.65, dampingFraction: 0.82)) { showReward = true }
        } else {
            onSuccess?()
        }
    }
}

// MARK: - Previews

private struct SequencingActivityPreview: View {
    let eventId: Int

    init(eventId: Int) {
        PreviewSetup.registerFontsIfNeeded()
        self.eventId = eventId
    }

    private var event: EventData? {
        EventLoader.event(id: eventId, from: .main)
    }

    var body: some View {
        Group {
            if let event {
                SequencingActivityView(event: event) { _, _ in
                    Color.black.opacity(0.55)
                        .overlay {
                            Text("Reward")
                                .font(.app(.title, weight: .bold))
                                .foregroundStyle(.white)
                        }
                }
            } else {
                ContentUnavailableView(
                    "Event \(eventId) not found",
                    systemImage: "book.closed",
                    description: Text("Check events.json in Resources/Data.")
                )
            }
        }
        .environmentObject(LanguageManager())
    }
}

#Preview("Sequencing – Chapter 1", traits: .fixedLayout(width: 1194, height: 834)) {
    SequencingActivityPreview(eventId: 1)
}

#Preview("Sequencing – Chapter 4", traits: .fixedLayout(width: 1194, height: 834)) {
    SequencingActivityPreview(eventId: 4)
}
