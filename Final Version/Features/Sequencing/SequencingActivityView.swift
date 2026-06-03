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
    @EnvironmentObject private var lm: LanguageManager

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
                Text("🎉").font(.app(size: 72))
                Text(lm.t("celebration.title"))
                    .font(.app(.largeTitle))
                    .foregroundColor(.appPrimaryText)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.opacity(0.88))
            .accessibilityLabel(lm.t("a11y.celebration"))
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
                        Text("🎉").font(.app(size: 80))
                        Text(lm.t("celebration.title"))
                            .font(.app(.largeTitle))
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
            .accessibilityLabel(lm.t("a11y.celebration"))
            .accessibilityAddTraits(.isStaticText)
        }
    }
}

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

private struct SourceCardHintBorder: View {
    let cardW: CGFloat
    let cardH: CGFloat

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(Color(red: 1.0, green: 0.78, blue: 0.16), lineWidth: 5)
            .frame(width: cardW, height: cardH)
            .shadow(
                color: Color(red: 1.0, green: 0.78, blue: 0.16).opacity(pulse ? 0.92 : 0.50),
                radius: pulse ? 16 : 8
            )
            .scaleEffect(pulse ? 1.035 : 1.0)
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

private enum SequencingStageLayout {
    static let aspectRatio: CGFloat = 4.0 / 3.0

    static func stageSize(in container: CGSize) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }

        let containerAspectRatio = container.width / container.height
        if containerAspectRatio > aspectRatio {
            let height = container.height
            return CGSize(width: height * aspectRatio, height: height)
        }

        let width = container.width
        return CGSize(width: width, height: width / aspectRatio)
    }
}

struct SequencingActivityView<Reward: View>: View {
    let event: EventData
    let showsReward: Bool
    let onSuccess: (() -> Void)?
    let onSequencingComplete: ((Int) -> Void)?
    let makeReward: (Int, @escaping () -> Void) -> Reward
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var lm: LanguageManager

    // card ids in source row order (randomized at activity start)
    @State private var shuffledStart: [Int]
    // slot index (0–3) → card id placed there; nil = empty
    @State private var slotContents: [Int?]
    // indexed by card id
    @State private var flippedStates: [Bool]

    @State private var attemptCount = 0
    @State private var showCelebration = false
    @State private var dimForReward = false
    @State private var showReward = false
    @State private var slotVisualStates: [Int: SlotPlacementVisualState] = [:]
    @State private var isRunningCompletionSequence = false

    // Drag state
    @State private var draggingCardId: Int? = nil
    @State private var dragOriginSlot: Int? = nil   // nil → dragged from source deck
    @State private var dragPosition: CGPoint = .zero
    @State private var slotFrames: [Int: CGRect] = [:]
    @State private var sourceTrayFrame: CGRect = .zero
    @State private var hoveredSlot: Int? = nil

    private let cardGap: CGFloat = 14
    private let hPad: CGFloat = 28
    private let chromeButtonSize: CGFloat = 72

    init(
        event: EventData,
        showsReward: Bool = true,
        onSuccess: (() -> Void)? = nil,
        onSequencingComplete: ((Int) -> Void)? = nil,
        @ViewBuilder makeReward: @escaping (Int, @escaping () -> Void) -> Reward
    ) {
        self.event = event
        self.showsReward = showsReward
        self.onSuccess = onSuccess
        self.onSequencingComplete = onSequencingComplete
        self.makeReward = makeReward
        _shuffledStart = State(initialValue: event.makeShuffledStart())
        _slotContents  = State(initialValue: Array(repeating: nil, count: event.cards.count))
        _flippedStates = State(initialValue: Array(repeating: false, count: event.cards.count))
    }

    private var allSlotsFilled: Bool { slotContents.allSatisfy { $0 != nil } }

    private var allSlotsCorrect: Bool {
        slotContents.enumerated().allSatisfy { index, cardId in
            cardId == event.correctOrder[index]
        }
    }

    private var firstWrongSlot: Int? {
        slotContents.indices.first { i in slotContents[i] != event.correctOrder[i] }
    }

    private var guidedSourceCardID: Int? {
        guard attemptCount >= 2,
              let wrongSlot = firstWrongSlot else { return nil }

        return event.correctOrder[wrongSlot]
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { screenGeo in
            let stageSize = SequencingStageLayout.stageSize(in: screenGeo.size)
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
                    .padding(.horizontal, hPad)
                    .padding(.top, 18)

                Spacer(minLength: 0)

                sourceTray(cardW: cardW, cardH: cardH)
                    .padding(.horizontal, hPad)
                    .padding(.bottom, 18)
            }

            if let cardId = draggingCardId {
                SequenceCardView(
                    card: event.cards[cardId],
                    isFlipped: flippedStates[cardId]
                )
                .frame(width: cardW, height: cardH)
                .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
                .position(dragPosition)
                .allowsHitTesting(false)
                .zIndex(50)
            }

            if showCelebration {
                CelebrationView().allowsHitTesting(false)
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
                        showCelebration = false
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .coordinateSpace(name: "gameBoard")
    }

    // MARK: - Card sizing

    private func computeCardWidth(in size: CGSize) -> CGFloat {
        let n         = CGFloat(event.cards.count)
        let totalGaps = cardGap * (n - 1)
        let framedHorizontalInset: CGFloat = 112
        let traySideInset: CGFloat = 16 + chromeButtonSize + 12
        let maxByStorybookW = (size.width - hPad * 2 - framedHorizontalInset - totalGaps) / n
        let maxByTrayW = (size.width - hPad * 2 - traySideInset * 2 - totalGaps) / n
        let maxByW = min(maxByStorybookW, maxByTrayW)

        // Constrain for the storybook frame, bottom tray, and top padding.
        let topChrome: CGFloat = 18
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

            HStack(spacing: 12) {
                if !showReward && !showCelebration {
                    GameCircleTextButton(title: "i", size: chromeButtonSize, action: flipAllCards)
                        .accessibilityLabel(lm.t("a11y.flip_all"))
                } else {
                    Color.clear
                        .frame(width: chromeButtonSize, height: chromeButtonSize)
                }

                sourceRow(cardW: cardW, cardH: cardH)

                Color.clear
                    .frame(width: chromeButtonSize, height: chromeButtonSize)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
        }
        .frame(maxWidth: .infinity)
        .frame(height: max(cardH + 42, chromeButtonSize + 30))
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
    }

    // MARK: - Storybook frame

    private func storybookPanel(cardW: CGFloat, cardH: CGFloat) -> some View {
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
                .padding(.horizontal, 58)
                .padding(.top, 42)
                .padding(.bottom, 34)
        }
        .frame(maxWidth: .infinity)
        .frame(height: cardH + 82)
        .accessibilityElement(children: .contain)
    }

    // MARK: - Storybook frame

    private func slotsRow(cardW: CGFloat, cardH: CGFloat) -> some View {
        LazyHStack(spacing: cardGap) {
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
            }

            if let id = placedId {
                placedCard(cardId: id, slot: slot, cardW: cardW, cardH: cardH)
                    .scaleEffect(slotVisualScale(for: slot))
                    .rotationEffect(.degrees(slotVisualTilt(for: slot)))
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
        SequenceCardView(card: event.cards[cardId], isFlipped: flippedStates[cardId])
            .frame(width: cardW, height: cardH)
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .simultaneousGesture(
                TapGesture().onEnded {
                    toggleCard(cardId)
                }
            )
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named("gameBoard"))
                    .onChanged { val in
                        updateDrag(cardId: cardId, originSlot: slot, location: val.location)
                    }
                    .onEnded { val in
                        finalizeDrop(at: val.location, originSlot: slot)
                    }
            )
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
        let correctCard = event.cards[event.correctOrder[slot]]
        return EmptySequenceSlotView(
            description: correctCard.description,
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
            ForEach(0..<event.cards.count, id: \.self) { position in
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
    private func sourceCard(cardId: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        SequenceCardView(card: event.cards[cardId], isFlipped: flippedStates[cardId])
            .frame(width: cardW, height: cardH)
            .shadow(color: .black.opacity(0.30), radius: 8, y: 5)
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .overlay(sourceCardHintOverlay(cardId: cardId, cardW: cardW, cardH: cardH))
            .simultaneousGesture(
                TapGesture().onEnded {
                    toggleCard(cardId)
                }
            )
            .gesture(
                DragGesture(minimumDistance: 8, coordinateSpace: .named("gameBoard"))
                    .onChanged { val in
                        updateDrag(cardId: cardId, originSlot: nil, location: val.location)
                    }
                    .onEnded { val in
                        finalizeDrop(at: val.location, originSlot: nil)
                    }
            )
    }

    @ViewBuilder
    private func sourceCardHintOverlay(cardId: Int, cardW: CGFloat, cardH: CGFloat) -> some View {
        if guidedSourceCardID == cardId {
            SourceCardHintBorder(cardW: cardW, cardH: cardH)
        }
    }

    // MARK: - Drop logic

    private func flipAllCards() {
        withAnimation(flipAnimation) {
            flippedStates = flippedStates.map { !$0 }
        }
    }

    private func toggleCard(_ cardId: Int) {
        guard flippedStates.indices.contains(cardId) else { return }
        withAnimation(flipAnimation) {
            flippedStates[cardId].toggle()
        }
    }

    private var flipAnimation: Animation {
        reduceMotion ? .linear(duration: 0.01) : .easeInOut(duration: 0.42)
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
        event.cards.indices.first { slot in
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
        guard let cardId = draggingCardId else { return }

        if let targetSlot = slot(at: location, excluding: originSlot) {
            let didMoveSlots = originSlot != targetSlot

            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                var nextContents = slotContents
                let displaced = nextContents[targetSlot]

                nextContents[targetSlot] = cardId

                if let origin = originSlot {
                    nextContents[origin] = origin == targetSlot ? cardId : displaced
                }

                slotContents = normalizedSlotContents(nextContents, keeping: cardId, in: targetSlot)
            }

            if didMoveSlots {
                handlePlacementFeedback(forSlot: targetSlot, cardId: cardId)
                evaluateAutomaticCompletion()
            }
            return
        }

        if let origin = originSlot, isInSourceTray(location) {
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
                  event.cards.indices.contains(cardId),
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
    }

    private func handlePlacementFeedback(forSlot slot: Int, cardId: Int) {
        let isCorrect = event.correctOrder[slot] == cardId

        if isCorrect {
            AppSettings.hapticImpact(.light)
            PianoChordPlayer.shared.playPlacementTone(.correct(slot: slot))
            playCorrectPlacementAnimation(for: slot)
        } else {
            AppSettings.hapticImpact(.soft)
            PianoChordPlayer.shared.playPlacementTone(.incorrect)
            attemptCount += 1
            playIncorrectPlacementAnimation(for: slot)
        }
    }

    private func playCorrectPlacementAnimation(for slot: Int) {
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

    private func evaluateAutomaticCompletion() {
        guard allSlotsFilled, allSlotsCorrect, !isRunningCompletionSequence, !showCelebration else { return }
        Task { await runCompletionWaveAndCelebrate() }
    }

    @MainActor
    private func runCompletionWaveAndCelebrate() async {
        isRunningCompletionSequence = true

        // Let the fourth card's Do (C5) ring briefly, then start the victory jingle.
        try? await Task.sleep(for: .milliseconds(240))
        PianoChordPlayer.shared.playPlacementTone(.victoryJingle)

        if !reduceMotion {
            for slot in event.cards.indices {
                withAnimation(.spring(response: 0.40, dampingFraction: 0.66)) {
                    var state = slotVisualStates[slot] ?? SlotPlacementVisualState()
                    state.waveScale = 1.08
                    state.bounceScale = 1
                    state.tiltDegrees = 0
                    slotVisualStates[slot] = state
                }

                try? await Task.sleep(for: .milliseconds(210))

                withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                    var state = slotVisualStates[slot] ?? SlotPlacementVisualState()
                    state.waveScale = 1
                    slotVisualStates[slot] = state
                }
            }

            try? await Task.sleep(for: .milliseconds(650))
        } else {
            try? await Task.sleep(for: .milliseconds(1200))
        }

        await triggerCelebration()
        isRunningCompletionSequence = false
    }

    @MainActor
    private func triggerCelebration() async {
        AppSettings.hapticSuccess()
        UIAccessibility.post(notification: .announcement, argument: "Correct! Great job!")

        if let onSequencingComplete {
            withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
                showCelebration = true
            }
            try? await Task.sleep(for: .seconds(1.5))
            onSequencingComplete(attemptCount)
        } else if showsReward {
            withAnimation(.easeIn(duration: 0.3).delay(0.4)) {
                showCelebration = true
            }
            try? await Task.sleep(for: .seconds(1.5))
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
