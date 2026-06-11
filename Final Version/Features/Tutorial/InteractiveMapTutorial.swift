import SwiftUI

// MARK: - Tutorial flow

enum InteractiveTutorialStep: Int {
    case inactive = -1
    case worldMapSettings = 0
    case worldMapBook = 1
    case worldMapPlayExplain = 2
    case worldMapLetsPlay = 3
    case worldMapPlayReady = 4
    /// Section 2 — Red Riding Hood map (ends when Play is tapped at waypoint 1).
    case redHoodWaypoints = 5
    case redHoodLetsPlay = 6
    case redHoodWaypointReady = 7
    case redHoodPlay = 8
    /// Section 3 — sequencing game (starts after waypoint 1 Play).
    case sequencingIntro = 9
    case sequencingCoach = 10
    case sequencingFlipHint = 11
    case sequencingCongrats = 12

    var messageKey: String {
        switch self {
        case .worldMapSettings: return "tutorial.coach.settings"
        case .worldMapBook: return "tutorial.coach.book"
        case .worldMapPlayExplain: return "tutorial.coach.world_play_explain"
        case .worldMapLetsPlay: return "tutorial.coach.lets_play"
        case .worldMapPlayReady: return "tutorial.coach.world_play"
        case .redHoodWaypoints: return "tutorial.coach.waypoints"
        case .redHoodLetsPlay: return "tutorial.coach.lets_play"
        case .redHoodWaypointReady: return "tutorial.coach.waypoints"
        case .redHoodPlay: return "tutorial.coach.red_hood_play"
        case .sequencingIntro: return "tutorial.coach.sequencing_intro"
        case .sequencingCoach: return "tutorial.coach.drag"
        case .sequencingFlipHint: return "tutorial.coach.flip"
        case .sequencingCongrats: return "tutorial.coach.sequencing_your_turn"
        case .inactive: return ""
        }
    }

    var isSequencingPhase: Bool {
        switch self {
        case .sequencingIntro, .sequencingCoach, .sequencingFlipHint, .sequencingCongrats:
            return true
        default:
            return false
        }
    }

    /// Full-screen dim + touch hint — tap anywhere to advance.
    var isSequencingOverlayStep: Bool {
        switch self {
        case .sequencingIntro:
            return true
        default:
            return false
        }
    }

    var isWorldMapPhase: Bool {
        switch self {
        case .worldMapSettings, .worldMapBook, .worldMapPlayExplain, .worldMapLetsPlay, .worldMapPlayReady:
            return true
        default:
            return false
        }
    }

    /// Overlay visible — tap anywhere on screen to advance.
    var isWorldMapOverlayStep: Bool {
        switch self {
        case .worldMapSettings, .worldMapBook, .worldMapPlayExplain, .worldMapLetsPlay:
            return true
        default:
            return false
        }
    }

    var highlightedWorldMapAnchor: TutorialAnchorID? {
        switch self {
        case .worldMapSettings: return .settings
        case .worldMapBook: return .book
        case .worldMapPlayExplain, .worldMapPlayReady: return .worldMapPlay
        case .inactive: return .settings
        default: return nil
        }
    }

    var isRedHoodPhase: Bool {
        switch self {
        case .redHoodWaypoints, .redHoodLetsPlay, .redHoodWaypointReady, .redHoodPlay:
            return true
        default:
            return false
        }
    }

    /// Red Riding Hood map — overlay visible, tap screen to advance.
    var isRedHoodOverlayStep: Bool {
        switch self {
        case .redHoodWaypoints, .redHoodLetsPlay:
            return true
        default:
            return false
        }
    }

    var allowsTapAnywhere: Bool {
        switch self {
        case .sequencingCongrats:
            return true
        default:
            return false
        }
    }

    func next() -> InteractiveTutorialStep {
        InteractiveTutorialStep(rawValue: rawValue + 1) ?? .inactive
    }
}

// MARK: - Replay / show tutorial again

enum TutorialWorldMapReplay {
    static let temporaryModeKey = "isTemporaryTutorialMode"
    private static let redRidingHoodIslandID = 0

    static func backupProgressIfNeeded(
        completedLevels: [Int],
        unlockedWorldIDs: [Int],
        currentBaseID: Int,
        activeMapLabel: String,
        hasSeenTutorial: Bool
    ) {
        guard !UserDefaults.standard.bool(forKey: temporaryModeKey) else { return }

        UserDefaults.standard.set(completedLevels, forKey: "tutorialBackup_completedRedHoodLevels")
        UserDefaults.standard.set(unlockedWorldIDs, forKey: "tutorialBackup_unlockedWorldBaseIDs")
        UserDefaults.standard.set(currentBaseID, forKey: "tutorialBackup_currentBaseID")
        UserDefaults.standard.set(activeMapLabel, forKey: "tutorialBackup_activeMap")
        UserDefaults.standard.set(hasSeenTutorial, forKey: "tutorialBackup_hasSeenTutorial")
        UserDefaults.standard.set(true, forKey: temporaryModeKey)
    }

    static func backupPersistedProgressIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: temporaryModeKey) else { return }

        let completed = UserDefaults.standard.array(forKey: "completedRedHoodLevels") as? [Int] ?? []
        let unlocked = UserDefaults.standard.array(forKey: "unlockedWorldBaseIDs") as? [Int] ?? [redRidingHoodIslandID]
        let currentBase = UserDefaults.standard.integer(forKey: "currentBaseID")
        let hasSeen = UserDefaults.standard.bool(forKey: "hasSeenTutorial")

        backupProgressIfNeeded(
            completedLevels: completed,
            unlockedWorldIDs: unlocked,
            currentBaseID: currentBase,
            activeMapLabel: "main",
            hasSeenTutorial: hasSeen
        )
    }

    static func applyPhase1State() {
        UserDefaults.standard.set(false, forKey: "hasSeenTutorial")
        UserDefaults.standard.set(InteractiveTutorialStep.worldMapSettings.rawValue, forKey: "interactiveTutorialStep")
        UserDefaults.standard.set([Int](), forKey: "completedRedHoodLevels")
        UserDefaults.standard.set([redRidingHoodIslandID], forKey: "unlockedWorldBaseIDs")
        UserDefaults.standard.set(redRidingHoodIslandID, forKey: "currentBaseID")
    }

    static var isWorldMapReplayActive: Bool {
        guard UserDefaults.standard.bool(forKey: temporaryModeKey) else { return false }
        let step = InteractiveTutorialStep(rawValue: UserDefaults.standard.integer(forKey: "interactiveTutorialStep")) ?? .inactive
        return step.isWorldMapPhase
    }

    static var isRedHoodReplayActive: Bool {
        guard UserDefaults.standard.bool(forKey: temporaryModeKey) else { return false }
        let step = InteractiveTutorialStep(rawValue: UserDefaults.standard.integer(forKey: "interactiveTutorialStep")) ?? .inactive
        return step.isRedHoodPhase
    }
}

struct MapTutorialMapSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next.width > 1, next.height > 1 {
            value = next
        }
    }
}

struct MapTutorialContainerSizeKey: PreferenceKey {
    static var defaultValue: CGSize = .zero

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        if next.width > 1, next.height > 1 {
            value = next
        }
    }
}

/// Screen frame of the rendered map content — same coordinate space as live waypoint dots.
struct MapContentFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if TutorialFrameStabilizer.isMeaningful(next) {
            value = next
        }
    }
}

enum TutorialAnchorID: Hashable {
    case worldMapPlay
    case book
    case settings
    case redHoodPlay
    case waypoint
}

struct TutorialFramePreferenceKey: PreferenceKey {
    static var defaultValue: [TutorialAnchorID: CGRect] = [:]

    static func reduce(
        value: inout [TutorialAnchorID: CGRect],
        nextValue: () -> [TutorialAnchorID: CGRect]
    ) {
        for (key, frame) in nextValue() where TutorialFrameStabilizer.isMeaningful(frame) {
            if let existing = value[key], TutorialFrameStabilizer.isApproximatelyEqual(existing, frame) {
                continue
            }
            value[key] = frame
        }
    }
}

enum TutorialFrameStabilizer {
    static func isMeaningful(_ rect: CGRect) -> Bool {
        rect.width > 8 && rect.height > 8
    }

    static func isApproximatelyEqual(_ lhs: CGRect, _ rhs: CGRect, threshold: CGFloat = 2.5) -> Bool {
        abs(lhs.minX - rhs.minX) <= threshold
            && abs(lhs.minY - rhs.minY) <= threshold
            && abs(lhs.width - rhs.width) <= threshold
            && abs(lhs.height - rhs.height) <= threshold
    }

    static func merge(
        stored: [TutorialAnchorID: CGRect],
        incoming: [TutorialAnchorID: CGRect]
    ) -> [TutorialAnchorID: CGRect]? {
        var next = stored
        var changed = false

        for (key, frame) in incoming {
            if let existing = next[key], isApproximatelyEqual(existing, frame) {
                continue
            }
            guard isMeaningful(frame) else { continue }
            next[key] = frame
            changed = true
        }

        return changed ? next : nil
    }
}

extension View {
    func tutorialAnchor(_ id: TutorialAnchorID, in space: CoordinateSpace) -> some View {
        background(
            GeometryReader { proxy in
                Color.clear.preference(
                    key: TutorialFramePreferenceKey.self,
                    value: [id: proxy.frame(in: space)]
                )
            }
        )
    }

    @ViewBuilder
    func tutorialAnchor(_ id: TutorialAnchorID?, in space: CoordinateSpace) -> some View {
        if let id {
            tutorialAnchor(id, in: space)
        } else {
            self
        }
    }
}

// MARK: - Section 1 — world map (full dim behind Play + plaque)

/// Fades tutorial coach UI in when it appears or when its identity changes.
struct TutorialOverlayFadeIn: ViewModifier {
    let identity: AnyHashable

    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .onAppear {
                runFadeIn()
            }
            .onChange(of: identity) { _, _ in
                appeared = false
                runFadeIn()
            }
    }

    private func runFadeIn() {
        withAnimation(.easeInOut(duration: 0.4)) {
            appeared = true
        }
    }
}

extension View {
    func tutorialOverlayFadeIn(identity: AnyHashable = "tutorial-overlay") -> some View {
        modifier(TutorialOverlayFadeIn(identity: identity))
    }
}

/// Full-screen dim blocker. Place interactive UI above this layer (higher zIndex).
struct TutorialFullScreenDim: View {
    var opacity: CGFloat = 0.92
    var onTap: (() -> Void)? = nil
    var blocksHitTesting: Bool = true

    var body: some View {
        Color.black.opacity(opacity)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            .contentShape(Rectangle())
            .allowsHitTesting(blocksHitTesting)
            .onTapGesture {
                onTap?()
            }
            .tutorialOverlayFadeIn(identity: "tutorial-dim")
    }
}

/// Locks a target frame so the coach plaque does not jump between layout passes.
struct TutorialLockedPlaqueHost: View {
    let proposedFrame: CGRect?
    let message: String
    let plaqueScale: CGFloat
    var centersOnScreen: Bool = false
    var placement: TutorialPlaquePlacement = .leftOfTarget

    @State private var lockedFrame: CGRect = .zero

    private var resolvedFrame: CGRect {
        if TutorialFrameStabilizer.isMeaningful(lockedFrame) {
            return lockedFrame
        }
        if let proposedFrame, TutorialFrameStabilizer.isMeaningful(proposedFrame) {
            return proposedFrame
        }
        return .zero
    }

    var body: some View {
        Group {
            if centersOnScreen {
                GeometryReader { proxy in
                    TutorialCoachPlaque(title: message, scale: plaqueScale)
                        .position(x: proxy.size.width * 0.5, y: proxy.size.height * 0.30)
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            } else if resolvedFrame.width > 1 {
                GeometryReader { proxy in
                    TutorialCoachPlaque(title: message, scale: plaqueScale)
                        .position(
                            TutorialPlaqueLayout.position(
                                near: resolvedFrame,
                                in: proxy.size,
                                scale: plaqueScale,
                                placement: placement
                            )
                        )
                }
                .ignoresSafeArea()
                .allowsHitTesting(false)
            }
        }
        .onAppear {
            if let proposedFrame, TutorialFrameStabilizer.isMeaningful(proposedFrame) {
                lockedFrame = proposedFrame
            }
        }
        .onChange(of: proposedFrame) { _, newFrame in
            guard let newFrame, TutorialFrameStabilizer.isMeaningful(newFrame) else { return }
            guard !TutorialFrameStabilizer.isApproximatelyEqual(lockedFrame, newFrame) else { return }
            lockedFrame = newFrame
        }
        .tutorialOverlayFadeIn(identity: plaqueFadeIdentity)
    }

    private var plaqueFadeIdentity: String {
        if centersOnScreen {
            return "center-\(message)"
        }
        return "\(message)-\(placement)-\(Int(resolvedFrame.minX))-\(Int(resolvedFrame.minY))"
    }
}

/// Waypoint demo + coach plaque in a fixed bottom row (plaque to the right of the dot).
struct TutorialWaypointCoachRow<Waypoint: View>: View {
    let message: String
    let plaqueScale: CGFloat
    let bottomPadding: CGFloat
    @ViewBuilder let waypoint: () -> Waypoint

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)

            HStack(alignment: .center, spacing: max(18, 24 * plaqueScale)) {
                waypoint()

                TutorialCoachPlaque(title: message, scale: plaqueScale)
            }
            .padding(.horizontal, max(24, 32 * plaqueScale))
            .padding(.bottom, bottomPadding)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .allowsHitTesting(false)
        .tutorialOverlayFadeIn(identity: message)
    }
}

/// Always-visible hint above the dim overlay — tap passes through to the overlay.
struct TutorialTouchScreenPrompt: View {
    let text: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 48, weight: .medium))
                .symbolRenderingMode(.hierarchical)
                .accessibilityHidden(true)

            Text(text)
                .font(.app(size: 22, weight: .semibold, relativeTo: .title3))
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.45), radius: 8, y: 3)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .allowsHitTesting(false)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .tutorialOverlayFadeIn(identity: text)
    }
}

enum TutorialPlaqueFallbackLayout {
    static func frame(for anchor: TutorialAnchorID, in size: CGSize) -> CGRect {
        let settingsSize = GameButtonMetrics.chromeCircleSize
        let bookSize = GameButtonMetrics.bookButtonSize
        let topPadding = max(24, size.height * 0.05)
        let trailingInset = max(24, size.width * 0.04)
        let bottomInset: CGFloat = 28

        switch anchor {
        case .settings:
            return CGRect(
                x: size.width - trailingInset - settingsSize,
                y: topPadding,
                width: settingsSize,
                height: settingsSize
            )
        case .book:
            return CGRect(
                x: size.width - trailingInset - bookSize,
                y: size.height - bottomInset - 24 - bookSize,
                width: bookSize,
                height: bookSize
            )
        case .worldMapPlay:
            let playWidth: CGFloat = min(240, size.width * 0.34)
            let playHeight: CGFloat = 56
            return CGRect(
                x: (size.width - playWidth) * 0.5,
                y: size.height - bottomInset - playHeight,
                width: playWidth,
                height: playHeight
            )
        default:
            return CGRect(x: size.width * 0.5 - 60, y: size.height * 0.5 - 30, width: 120, height: 60)
        }
    }
}

enum TutorialPlaquePlacement {
    case leftOfTarget
    case rightOfTarget
    case aboveTarget
}

enum TutorialPlaqueLayout {
    static func position(
        near target: CGRect,
        in containerSize: CGSize,
        scale: CGFloat,
        placement: TutorialPlaquePlacement = .leftOfTarget
    ) -> CGPoint {
        let plaqueWidth = TutorialTitleFrameMetrics.pixelSize.width * scale
        let plaqueHeight = TutorialTitleFrameMetrics.pixelSize.height * scale
        let horizontalGap = max(14, 18 * scale)

        switch placement {
        case .leftOfTarget:
            let preferredX = target.minX - horizontalGap - plaqueWidth * 0.5
            let x = max(plaqueWidth * 0.5 + 12, min(preferredX, containerSize.width - plaqueWidth * 0.5 - 12))
            let y = max(
                plaqueHeight * 0.5 + 12,
                min(target.midY, containerSize.height - plaqueHeight * 0.5 - 12)
            )
            return CGPoint(x: x, y: y)

        case .rightOfTarget:
            let preferredX = target.maxX + horizontalGap + plaqueWidth * 0.5
            let x = min(max(preferredX, plaqueWidth * 0.5 + 12), containerSize.width - plaqueWidth * 0.5 - 12)
            let y = max(
                plaqueHeight * 0.5 + 12,
                min(target.midY, containerSize.height - plaqueHeight * 0.5 - 12)
            )
            return CGPoint(x: x, y: y)

        case .aboveTarget:
            let preferredY = target.minY - plaqueHeight * 0.62
            let y = max(plaqueHeight * 0.5 + 12, min(preferredY, containerSize.height - plaqueHeight * 0.5 - 12))
            let x = min(max(target.midX, plaqueWidth * 0.5 + 12), containerSize.width - plaqueWidth * 0.5 - 12)
            return CGPoint(x: x, y: y)
        }
    }
}

// MARK: - Coach overlay (dim + frame + tap proxy) — sections 2+

/// Host that locks the highlight rect so the overlay does not flicker between layout passes.
struct TutorialCoachOverlayHost: View {
    let proposedRect: CGRect
    let stepID: Int
    let message: String
    let plaqueScale: CGFloat
    let allowsTapAnywhere: Bool
    let onHighlightTap: () -> Void
    let onTapOutside: () -> Void

    @State private var lockedRect: CGRect = .zero

    var body: some View {
        Group {
            if lockedRect.width > 1 {
                TutorialCoachOverlay(
                    highlightRect: lockedRect,
                    message: message,
                    plaqueScale: plaqueScale,
                    allowsTapAnywhere: allowsTapAnywhere,
                    onHighlightTap: onHighlightTap,
                    onTapOutside: onTapOutside
                )
            }
        }
        .id(stepID)
        .onAppear {
            lockedRect = proposedRect
        }
        .onChange(of: proposedRect) { _, newRect in
            guard TutorialFrameStabilizer.isMeaningful(newRect) else { return }
            guard !TutorialFrameStabilizer.isApproximatelyEqual(lockedRect, newRect) else { return }
            lockedRect = newRect
        }
    }
}

struct TutorialCoachOverlay: View {
    let highlightRect: CGRect
    let message: String
    let plaqueScale: CGFloat
    let allowsTapAnywhere: Bool
    let onHighlightTap: () -> Void
    let onTapOutside: () -> Void

    private let dimOpacity: CGFloat = 0.78
    private let highlightPadding: CGFloat = 10
    private let cornerRadius: CGFloat = 14

    var body: some View {
        GeometryReader { proxy in
            let hole = expandedHole(in: proxy.size)

            ZStack {
                TutorialStableDimmingLayer(
                    hole: hole,
                    containerSize: proxy.size,
                    opacity: dimOpacity
                )

                if allowsTapAnywhere {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onTapOutside)
                }

                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.95), lineWidth: 3)
                    .shadow(color: .white.opacity(0.30), radius: 6)
                    .frame(width: hole.width, height: hole.height)
                    .position(x: hole.midX, y: hole.midY)
                    .allowsHitTesting(false)

                if !allowsTapAnywhere {
                    Button(action: onHighlightTap) {
                        Color.clear
                    }
                    .buttonStyle(.plain)
                    .frame(width: hole.width, height: hole.height)
                    .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .position(x: hole.midX, y: hole.midY)
                }

                TutorialCoachPlaque(title: message, scale: plaqueScale)
                    .position(plaquePosition(for: hole, in: proxy.size))
                    .tutorialOverlayFadeIn(identity: message)
            }
        }
        .ignoresSafeArea()
        .accessibilityAddTraits(.isModal)
    }

    private func expandedHole(in containerSize: CGSize) -> CGRect {
        guard highlightRect.width > 1, highlightRect.height > 1 else {
            return CGRect(
                x: containerSize.width * 0.5 - 60,
                y: containerSize.height * 0.5 - 30,
                width: 120,
                height: 60
            )
        }

        return highlightRect.insetBy(dx: -highlightPadding, dy: -highlightPadding)
    }

    private func plaquePosition(for hole: CGRect, in containerSize: CGSize) -> CGPoint {
        let plaqueHeight: CGFloat = 110 * plaqueScale
        let preferredY = hole.minY - plaqueHeight * 0.55
        let y = max(plaqueHeight * 0.5 + 12, min(preferredY, containerSize.height - plaqueHeight * 0.5 - 12))
        let x = min(max(hole.midX, 120), containerSize.width - 120)
        return CGPoint(x: x, y: y)
    }
}

/// Single canvas dimming layer — drawn once per stable rect, no multi-rect flicker.
private struct TutorialStableDimmingLayer: View {
    let hole: CGRect
    let containerSize: CGSize
    let opacity: CGFloat

    var body: some View {
        Canvas { context, size in
            var path = Path(CGRect(origin: .zero, size: size))
            path.addRoundedRect(
                in: hole,
                cornerSize: CGSize(width: 14, height: 14)
            )
            context.fill(
                path,
                with: .color(.black.opacity(opacity)),
                style: FillStyle(eoFill: true)
            )
        }
        .frame(width: containerSize.width, height: containerSize.height)
        .allowsHitTesting(false)
        .drawingGroup()
    }
}

struct TutorialCoachPlaque: View {
    let title: String
    let scale: CGFloat

    private var frameSize: CGSize {
        CGSize(
            width: TutorialTitleFrameMetrics.pixelSize.width * scale,
            height: TutorialTitleFrameMetrics.pixelSize.height * scale
        )
    }

    private var titleFontSize: CGFloat {
        TutorialTitleFrameMetrics.titleFontSize(mapScale: scale) * 0.82
    }

    var body: some View {
        ZStack {
            Image("IslandTitleFrame")
                .resizable()
                .renderingMode(.original)
                .interpolation(.high)
                .frame(width: frameSize.width, height: frameSize.height)
                .accessibilityHidden(true)

            Text(title)
                .font(.app(size: titleFontSize, weight: .semibold, relativeTo: .title3))
                .foregroundStyle(Color(hex: "#262521"))
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .minimumScaleFactor(0.45)
                .padding(.horizontal, frameSize.width * 0.12)
                .frame(width: frameSize.width, alignment: .center)
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .shadow(color: .black.opacity(0.28), radius: max(4, 7 * scale), x: 0, y: max(2, 4 * scale))
        .allowsHitTesting(false)
    }
}

enum TutorialTitleFrameMetrics {
    static let pixelSize = CGSize(width: 721, height: 201)

    static func titleFontSize(mapScale: CGFloat) -> CGFloat {
        46 * mapScale
    }
}
