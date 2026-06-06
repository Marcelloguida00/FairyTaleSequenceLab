import SwiftUI
import Combine

private enum ActiveMap {
    case main
    case redHood

    var imageName: String {
        switch self {
        case .main:
            return "mappa"
        case .redHood:
            return "redhoodisle-2"
        }
    }

    var aspectRatio: CGFloat {
        switch self {
        case .main:
            return MapLayout.worldMapAspectRatio
        case .redHood:
            return MapLayout.redHoodMapAspectRatio
        }
    }

    var contentMode: MapLayout.ContentMode {
        switch self {
        case .main:
            return .fill
        case .redHood:
            return .fill
        }
    }

    var imagePixelSize: CGSize {
        switch self {
        case .main:
            return WorldMapPixel.size
        case .redHood:
            return RedHoodMapGraph.imageSize
        }
    }

    var foregroundImageName: String? {
        switch self {
        case .main:
            return nil
        case .redHood:
            return "Finalmente"
        }
    }

}

private enum MapOverlayMetrics {
    static var chromeButtonSize: CGFloat { GameButtonMetrics.chromeCircleSize }
    static var bookButtonSize: CGFloat { GameButtonMetrics.bookButtonSize }
    static let defaultChromeHorizontalInset: CGFloat = 20
}

struct ContentView: View {
    let isGlobalTransitioning: Bool

    @EnvironmentObject private var lm: LanguageManager

    @State private var activeMap = ActiveMap.main
    @State private var avatarPosition = MapGraph.initialWaypoint.point
    @State private var currentBaseID = MapGraph.initialWaypoint.id
    @State private var avatarDirection = WalkDirection.down
    @State private var isWalking = false
    @State private var markerIsRaised = false
    @State private var isMapTransitioning = false
    @State private var cloudEnterProgress: CGFloat = 0
    @State private var cloudExitProgress: CGFloat = 0
    @State private var completedRedHoodLevels: Set<Int> = []
    @State private var unlockedWorldBaseIDs: Set<Int> = [MapGraph.redRidingHoodBaseID]
    @State private var activeRedHoodLevel: Int? = nil
    @State private var pendingRedHoodLevel: Int? = nil
    @State private var suppressesMapChromeForDialogue = true
    @State private var redHoodPostSequenceReward: (level: Int, attemptCount: Int)? = nil
    @State private var pendingChapterUnlockLevel: Int? = nil
    @State private var currentFrame = 0
    @State private var walkTask: Task<Void, Never>? = nil
    @State private var walkGeneration = 0
    @State private var isBookOpen = false
    @State private var showSettings = false
    @State private var isSettingsTransitionActive = false
    @State private var showsSettingsCloudOverlay = false
    @State private var settingsCloudEnterProgress: CGFloat = 0
    @State private var settingsCloudExitProgress: CGFloat = 0
    @State private var showAdvancedMathGate = false
    @State private var advancedMathProblem = MathAdditionProblem.randomSimple()
    @State private var advancedSettingsUnlocked = false

    @Environment(\.accessibilityReduceMotion) private var sysReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations = false
    private var reduceMotion: Bool { sysReduceMotion || reduceAnimations }

    private static let settingsFadeDuration: TimeInterval = 0.30

    private let spriteTimer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            AdaptiveMapContainer(
                aspectRatio: activeMap.aspectRatio,
                contentMode: activeMap.contentMode
            ) { mapSize in
                mapContent(mapSize: mapSize)
            }

            if isMapTransitioning || cloudEnterProgress > 0.01 || cloudExitProgress > 0.01 {
                CloudTransitionOverlay(
                    enterProgress: cloudEnterProgress,
                    exitProgress: cloudExitProgress
                )
                .ignoresSafeArea()
                .allowsHitTesting(true)
                .zIndex(50)
            }

            if hidesMapChromeForActiveLevel {
                mapChromeBlockerOverlay
                    .zIndex(18)
            }

            if let reward = redHoodPostSequenceReward,
               let eventData = EventLoader.event(id: reward.level, from: lm.bundle) {
                RedHoodRewardPhaseView(
                    eventData: eventData,
                    attemptCount: reward.attemptCount,
                    onRewardReached: {
                        markRedHoodLevelCompleted(reward.level)
                    },
                    onReplay: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            redHoodPostSequenceReward = nil
                            suppressesMapChromeForDialogue = false
                            activeRedHoodLevel = reward.level
                        }
                    },
                    onChapterUnlockReady: {
                        finishRedHoodPostSequenceReward(for: reward.level, pendingChapterUnlock: true)
                    },
                    onComplete: {
                        finishRedHoodPostSequenceReward(for: reward.level)
                    }
                )
                .ignoresSafeArea()
                .background(Color.clear)
                .zIndex(20)
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }

            if let level = activeRedHoodLevel {
                levelView(for: level)
                    .ignoresSafeArea()
                    .background(Color.clear)
                    .zIndex(20)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                        removal: .scale(scale: 0.92).combined(with: .opacity)
                    ))
            }

            if !hidesMapChromeForActiveLevel {
                topChromeButtons
                    .zIndex(31)
                    .transition(.opacity)
            }

            if let level = pendingChapterUnlockLevel {
                BookChapterUnlockedBanner(
                    onFinish: {
                        pendingChapterUnlockLevel = nil
                        handleRedHoodChapterCompletion(level)
                    },
                    onOpenStorybook: {
                        pendingChapterUnlockLevel = nil
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            isBookOpen = true
                        }
                        handleRedHoodChapterCompletion(level)
                    }
                )
                .environmentObject(lm)
                .zIndex(40)
                .transition(.opacity)
            }

            if shouldShowRedHoodPlayButton {
                MapPlayButton(accessibilityLabel: lm.t("a11y.play_red_hood")) {
                    Task {
                        await openRedHoodSubMap()
                    }
                }
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if activeMap == .redHood,
               activeRedHoodLevel == nil,
               let level = pendingRedHoodLevel {
                MapPlayButton(accessibilityLabel: lm.t("a11y.start_event")) {
                    startRedHoodLevel(level)
                }
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .zIndex(28)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            if showsStorybookButton {
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isBookOpen = true
                    }
                }) {
                    BookIcon3D()
                }
                .buttonStyle(.plain)
                .gameMinimumTouchTarget(
                    minWidth: GameButtonMetrics.bookButtonSize,
                    minHeight: GameButtonMetrics.bookButtonSize
                )
                .padding(.bottom, 24)
                .padding(.trailing, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                .zIndex(35)
                .opacity(isBookInteractionBlocked ? 0 : 1)
                .animation(.easeInOut, value: isWalking)
                .disabled(isBookInteractionBlocked)
            }

        }
        .overlay {
            if isBookOpen {
                BookView(onDismiss: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        isBookOpen = false
                    }
                })
                .transition(.scale(scale: 0.1).combined(with: .opacity))
                .zIndex(100)
            }
        }
        .overlay {
            if showsSettingsCloudOverlay {
                CloudTransitionOverlay(
                    enterProgress: settingsCloudEnterProgress,
                    exitProgress: settingsCloudExitProgress
                )
                .allowsHitTesting(false)
                .zIndex(110)
            }

            if showSettings {
                SettingsFrameOverlay(
                    onClose: { Task { await closeSettings() } },
                    onAdvancedSettingsRequested: {
                        advancedMathProblem = MathAdditionProblem.randomSimple()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAdvancedMathGate = true
                        }
                    },
                    advancedSettingsUnlocked: $advancedSettingsUnlocked
                )
                .environmentObject(lm)
                .transition(.opacity)
                .zIndex(120)
                .allowsHitTesting(!showAdvancedMathGate)
            }

            if showAdvancedMathGate {
                AdvancedSettingsMathGate(
                    problem: advancedMathProblem,
                    onSuccess: {
                        showAdvancedMathGate = false
                        advancedSettingsUnlocked = true
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAdvancedMathGate = false
                        }
                    }
                )
                .environmentObject(lm)
                .transition(.opacity)
                .zIndex(130)
            }
        }
        .onReceive(spriteTimer) { _ in
            if isWalking {
                currentFrame = (currentFrame + 1) % 4
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) {
                markerIsRaised = true
            }

            reloadAllProgress()

        }
        .onChange(of: completedRedHoodLevels) {
            let canonicalLevels = canonicalCompletedRedHoodLevels(from: completedRedHoodLevels)
            if canonicalLevels != completedRedHoodLevels {
                completedRedHoodLevels = canonicalLevels
                return
            }

            persistCompletedRedHoodLevels(canonicalLevels)
            syncWorldUnlocksWithStoryProgress()
        }
        .onChange(of: currentBaseID) {
            if MapGraph.baseIDs.contains(currentBaseID) {
                UserDefaults.standard.set(currentBaseID, forKey: "currentBaseID")
            }
        }
    }

    @ViewBuilder
    private var topChromeButtons: some View {
        if activeMap == .main || activeMap == .redHood {
            GeometryReader { geometry in
                let horizontalInset = topChromeHorizontalInset(for: geometry.size)

                ZStack {
                    if activeMap == .redHood {
                        GameCircleBackButton(size: MapOverlayMetrics.chromeButtonSize) {
                            AppSettings.hapticImpact(.light)
                            handleBackButton()
                        }
                        .disabled(isMapNavigationBlocked)
                        .opacity(isMapNavigationBlocked ? 0.45 : 1)
                        .accessibilityLabel(lm.t("button.back"))
                        .padding(.top, topChromeTopPadding(for: geometry.size))
                        .padding(.leading, horizontalInset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .zIndex(30)
                        .transition(.opacity)
                    }

                    if showsRedHoodChapterTitleChrome {
                        IslandTitlePlaque(
                            title: redHoodChapterTitleChromeText,
                            scale: redHoodChapterTitleChromeScale(for: geometry.size)
                        )
                        .padding(.top, 52)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .allowsHitTesting(false)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(.isHeader)
                        .zIndex(29)
                        .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    }

                    GameCircleSettingsButton(size: MapOverlayMetrics.chromeButtonSize) {
                        Task { await openSettings() }
                    }
                    .disabled(isMapToolbarBlocked)
                    .opacity(isMapToolbarBlocked ? 0.45 : 1)
                    .accessibilityLabel(lm.t("a11y.settings_button"))
                        .padding(.top, topChromeTopPadding(for: geometry.size))
                        .padding(.trailing, horizontalInset)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .zIndex(31)
                    .transition(.opacity)
                }
            }
            .ignoresSafeArea()
        }
    }

    private func topChromeHorizontalInset(for screenSize: CGSize) -> CGFloat {
        guard activeRedHoodLevel != nil else {
            return MapOverlayMetrics.defaultChromeHorizontalInset
        }

        let stageSize = SequencingLayoutMetrics.stageSize(in: screenSize)
        let outerInset = max((screenSize.width - stageSize.width) / 2, 0)
        return max(
            MapOverlayMetrics.defaultChromeHorizontalInset,
            outerInset + SequencingLayoutMetrics.levelChromeHorizontalInset
        )
    }

    private func topChromeTopPadding(for screenSize: CGSize) -> CGFloat {
        guard activeRedHoodLevel != nil else { return 52 }
        return SequencingLayoutMetrics.levelChromeTopPadding(
            screenSize: screenSize,
            chromeButtonSize: MapOverlayMetrics.chromeButtonSize
        )
    }

    @ViewBuilder
    private func mapContent(mapSize: CGSize) -> some View {
        let projection = MapProjection(
            imageSize: activeMap.imagePixelSize,
            containerSize: mapSize,
            contentMode: activeMap.contentMode
        )

        ZStack(alignment: .topLeading) {
            MapBackgroundImage(name: activeMap.imageName, mapSize: mapSize)

            if activeMap == .redHood {
                ForEach(RedHoodMapGraph.storyWaypoints, id: \.id) { wp in
                    WaypointDot(state: dotState(for: wp.id), size: redHoodDotSize(for: mapSize))
                        .position(projection.screenPoint(fromPixel: wp.point))
                        .allowsHitTesting(false)
                }
            }

            if activeMap == .main {
                ForEach(MapGraph.baseWaypoints, id: \.id) { wp in
                    Group {
                        if isWorldBaseUnlocked(wp.id) {
                            MainMapIslandDot(
                                size: dotSize(for: mapSize),
                                isPulsing: wp.id == pulsingWorldBaseID
                            )
                        } else {
                            WaypointDot(state: .locked, size: dotSize(for: mapSize))
                        }
                    }
                    .position(projection.screenPoint(fromPixel: wp.point))
                    .allowsHitTesting(false)
                }
            }

            AvatarWithMarker(
                direction: avatarDirection,
                frame: isWalking ? currentFrame : 0,
                size: avatarSize(for: mapSize),
                markerIsRaised: markerIsRaised
            )
            .position(
                projection.screenPoint(fromPixel: avatarPosition)
            )

            if let fgName = activeMap.foregroundImageName {
                MapBackgroundImage(name: fgName, mapSize: mapSize)
                    .allowsHitTesting(false)
            }

            if activeMap == .main, !isWalking,
               let region = MapGraph.storyRegion(for: currentBaseID),
               !MapGraph.comingSoonBaseIDs.contains(currentBaseID) {
                StoryRegionPlaque(
                    title: lm.t(region.titleKey),
                    mapScale: projection.scale
                )
                .position(projection.screenPoint(fromPixel: region.titlePoint))
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            if activeMap == .main, !isWalking,
               MapGraph.comingSoonBaseIDs.contains(currentBaseID),
               let region = MapGraph.storyRegion(for: currentBaseID) {
                ComingSoonBadge(mapScale: projection.scale)
                    .position(projection.screenPoint(fromPixel: region.titlePoint))
                    .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

        }
        .frame(width: mapSize.width, height: mapSize.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    handleMapTap(value.location, projection: projection)
                }
        )
    }

    private func avatarSize(for mapSize: CGSize) -> CGFloat {
        let multiplier: CGFloat = 0.11
        return min(mapSize.width, mapSize.height) * multiplier
    }

    private func handleBackButton() {
        if activeRedHoodLevel != nil || redHoodPostSequenceReward != nil || pendingChapterUnlockLevel != nil {
            withAnimation(.easeInOut(duration: 0.3)) {
                activeRedHoodLevel = nil
                redHoodPostSequenceReward = nil
                pendingChapterUnlockLevel = nil
                pendingRedHoodLevel = nil
                suppressesMapChromeForDialogue = true
            }
        } else if activeMap == .redHood {
            Task { await closeRedHoodSubMap() }
        }
    }

    @MainActor
    private func closeRedHoodSubMap() async {
        guard !isWalking, !isMapTransitioning else { return }

        await CloudTransitionAnimator.runSceneTransition(
            isActive: $isMapTransitioning,
            enterProgress: $cloudEnterProgress,
            exitProgress: $cloudExitProgress
        ) {
            activeMap = .main
            pendingRedHoodLevel = nil
            activeRedHoodLevel = nil
            avatarPosition = MapGraph.waypoint(id: MapGraph.redRidingHoodBaseID)?.point ?? MapGraph.initialWaypoint.point
            currentBaseID = MapGraph.redRidingHoodBaseID
            avatarDirection = .down
        }
    }

    private func levelBannerTitle(for level: Int) -> String {
        if level == 0 { return lm.t("level.adventure_begins") }
        if level == 9 { return lm.t("redhood.final.title") == "redhood.final.title" ? "Incantesimo Spezzato!" : lm.t("redhood.final.title") }
        return EventLoader.event(id: level, from: lm.bundle)?.bannerTitle ?? lm.t("level.new_scene")
    }

    @MainActor
    private func startRedHoodLevel(_ level: Int) {
        withAnimation(.easeInOut(duration: 0.2)) {
            pendingRedHoodLevel = nil
            activeRedHoodLevel = level
            suppressesMapChromeForDialogue = true
            redHoodPostSequenceReward = nil
        }
    }

    private func dotSize(for mapSize: CGSize) -> CGFloat {
        min(mapSize.width, mapSize.height) * 0.055
    }

    private func redHoodDotSize(for mapSize: CGSize) -> CGFloat {
        min(mapSize.width, mapSize.height) * 0.064
    }

    private func dotHitRadius(for mapSize: CGSize) -> CGFloat {
        max(44, redHoodDotSize(for: mapSize) * 0.72)
    }

    private var isRedHoodIslandComplete: Bool {
        canonicalCompletedRedHoodLevels(from: completedRedHoodLevels).count == redHoodLevelIDs.count
    }

    private var pulsingWorldBaseID: Int {
        if !isRedHoodIslandComplete {
            return MapGraph.redRidingHoodBaseID
        }

        return MapGraph.islandUnlockOrder.last { unlockedWorldBaseIDs.contains($0) } ?? MapGraph.redRidingHoodBaseID
    }

    private func isWorldBaseUnlocked(_ baseID: Int) -> Bool {
        unlockedWorldBaseIDs.contains(baseID)
    }

    private func loadWorldMapProgress() {
        if let saved = UserDefaults.standard.array(forKey: "unlockedWorldBaseIDs") as? [Int] {
            unlockedWorldBaseIDs = Set(saved.filter { MapGraph.baseIDs.contains($0) })
        }

        unlockedWorldBaseIDs.insert(MapGraph.redRidingHoodBaseID)
        syncWorldUnlocksWithStoryProgress()
    }

    private func persistUnlockedWorldBaseIDs() {
        UserDefaults.standard.set(
            MapGraph.islandUnlockOrder.filter { unlockedWorldBaseIDs.contains($0) },
            forKey: "unlockedWorldBaseIDs"
        )
    }

    private func syncWorldUnlocksWithStoryProgress() {
        guard isRedHoodIslandComplete,
              let nextIsland = MapGraph.nextIsland(after: MapGraph.redRidingHoodBaseID) else { return }

        let didChange = !unlockedWorldBaseIDs.contains(nextIsland)
        unlockedWorldBaseIDs.insert(nextIsland)

        if didChange {
            persistUnlockedWorldBaseIDs()
        }
    }

    private func unlockNextWorldIslandIfNeeded() {
        syncWorldUnlocksWithStoryProgress()
    }

    private func reloadAllProgress() {
        let savedCompletedRedHoodLevels = Set(
            UserDefaults.standard.array(forKey: "completedRedHoodLevels") as? [Int] ?? []
        )
        completedRedHoodLevels = canonicalCompletedRedHoodLevels(from: savedCompletedRedHoodLevels)

        if completedRedHoodLevels != savedCompletedRedHoodLevels {
            persistCompletedRedHoodLevels(completedRedHoodLevels)
        }

        loadWorldMapProgress()

        if let savedID = UserDefaults.standard.object(forKey: "currentBaseID") as? Int {
            if activeMap == .redHood {
                if let wp = RedHoodMapGraph.waypoint(id: savedID) {
                    currentBaseID = savedID
                    avatarPosition = wp.point
                    return
                }
            } else {
                if MapGraph.baseIDs.contains(savedID),
                   unlockedWorldBaseIDs.contains(savedID),
                   let wp = MapGraph.waypoint(id: savedID) {
                    currentBaseID = savedID
                    avatarPosition = wp.point
                    return
                }
            }
        }

        if activeMap == .redHood {
            currentBaseID = RedHoodMapGraph.initialWaypoint.id
            avatarPosition = RedHoodMapGraph.initialWaypoint.point
        } else {
            currentBaseID = MapGraph.initialWaypoint.id
            avatarPosition = MapGraph.initialWaypoint.point
        }
    }

    @MainActor
    private func returnToWorldMapAfterRedHoodCompletion() async {
        guard activeMap == .redHood else { return }

        pendingRedHoodLevel = nil

        await CloudTransitionAnimator.runSceneTransition(
            isActive: $isMapTransitioning,
            enterProgress: $cloudEnterProgress,
            exitProgress: $cloudExitProgress
        ) {
            activeMap = .main
            avatarPosition = MapGraph.waypoint(id: MapGraph.redRidingHoodBaseID)?.point ?? MapGraph.initialWaypoint.point
            currentBaseID = MapGraph.redRidingHoodBaseID
            avatarDirection = .down
        }
    }

    private func handleRedHoodChapterCompletion(_ level: Int) {
        if level == 9 {
            handleRedHoodFinalCompletion()
            return
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            markRedHoodLevelCompleted(level)
            activeRedHoodLevel = nil
            pendingRedHoodLevel = nil
        }

        Task { @MainActor in
            await advanceToNextRedHoodChapter(afterCompletedLevel: level)
        }
    }

    @MainActor
    private func advanceToNextRedHoodChapter(afterCompletedLevel level: Int) async {
        guard activeMap == .redHood, level < 9 else { return }

        try? await Task.sleep(nanoseconds: 350_000_000)

        guard activeMap == .redHood,
              activeRedHoodLevel == nil,
              let nextLevel = nextRedHoodLevel,
              nextLevel == level + 1,
              let target = RedHoodMapGraph.waypoint(id: nextLevel),
              let start = nearestWaypoint(to: avatarPosition, among: RedHoodMapGraph.waypoints) else { return }

        if start.id == target.id {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pendingRedHoodLevel = nextLevel
            }
            return
        }

        guard let route = RedHoodMapGraph.shortestPath(from: start.id, to: target.id) else { return }

        startWalking(route) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pendingRedHoodLevel = nextLevel
            }
        }
    }

    private func handleRedHoodFinalCompletion() {
        let wasAlreadyComplete = isRedHoodIslandComplete

        withAnimation(.easeInOut(duration: 0.3)) {
            markRedHoodLevelCompleted(9)
            activeRedHoodLevel = nil
        }

        guard !wasAlreadyComplete else { return }

        unlockNextWorldIslandIfNeeded()
        Task { await returnToWorldMapAfterRedHoodCompletion() }
    }

    private func dotState(for waypointId: Int) -> WaypointDot.DotState {
        if canonicalCompletedRedHoodLevels(from: completedRedHoodLevels).contains(waypointId) { return .completed }
        return waypointId == nextRedHoodLevel ? .next : .locked
    }

    private var nextRedHoodLevel: Int? {
        let completedLevels = canonicalCompletedRedHoodLevels(from: completedRedHoodLevels)
        return redHoodLevelIDs.first { !completedLevels.contains($0) }
    }

    private func isRedHoodWaypointPlayable(_ waypointId: Int) -> Bool {
        canonicalCompletedRedHoodLevels(from: completedRedHoodLevels).contains(waypointId) || waypointId == nextRedHoodLevel
    }

    private func shouldOfferRedHoodLevelStart(for waypointId: Int) -> Bool {
        canonicalCompletedRedHoodLevels(from: completedRedHoodLevels).contains(waypointId) || waypointId == nextRedHoodLevel
    }

    private var redHoodLevelIDs: [Int] {
        Array(0...9)
    }

    private func canonicalCompletedRedHoodLevels(from levels: Set<Int>) -> Set<Int> {
        var canonicalLevels: Set<Int> = []

        for levelID in redHoodLevelIDs {
            guard levels.contains(levelID) else { break }
            canonicalLevels.insert(levelID)
        }

        return canonicalLevels
    }

    private func persistCompletedRedHoodLevels(_ levels: Set<Int>) {
        UserDefaults.standard.set(Array(levels).sorted(), forKey: "completedRedHoodLevels")
    }

    private func markRedHoodLevelCompleted(_ level: Int) {
        var updatedLevels = completedRedHoodLevels
        updatedLevels.insert(level)
        completedRedHoodLevels = canonicalCompletedRedHoodLevels(from: updatedLevels)
    }

    private var showsStorybookButton: Bool {
        (activeMap == .main || activeMap == .redHood) && activeRedHoodLevel == nil
    }

    /// Hides map chrome during intro/reward dialogue; visible during sequencing and the map beat before reward.
    private var hidesMapChromeForActiveLevel: Bool {
        if redHoodPostSequenceReward != nil { return true }
        guard activeRedHoodLevel != nil else { return false }
        return suppressesMapChromeForDialogue
    }

    /// Blocks taps on the top map toolbar region if chrome is hidden but still hit-testable.
    private var mapChromeBlockerOverlay: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(height: MapOverlayMetrics.chromeButtonSize + 72)
                .contentShape(Rectangle())
            Spacer(minLength: 0)
        }
        .ignoresSafeArea()
        .allowsHitTesting(true)
        .accessibilityHidden(true)
    }

    private var isMapNavigationBlocked: Bool {
        isMapTransitioning
            || isGlobalTransitioning
            || isWalking
            || showSettings
            || isSettingsTransitionActive
            || isBookOpen
            || (activeRedHoodLevel != nil && suppressesMapChromeForDialogue)
            || redHoodPostSequenceReward != nil
            || pendingChapterUnlockLevel != nil
    }

    private var isMapToolbarBlocked: Bool {
        isMapNavigationBlocked
    }

    private var isBookInteractionBlocked: Bool {
        isMapToolbarBlocked
    }

    private var settingsFadeAnimation: Animation {
        reduceMotion
            ? .linear(duration: 0.01)
            : .easeInOut(duration: Self.settingsFadeDuration)
    }

    private var settingsCloudEnterDuration: TimeInterval {
        reduceMotion ? 0.01 : CloudTransitionAnimator.enterDuration
    }

    private var settingsCloudExitDuration: TimeInterval {
        reduceMotion ? 0.01 : CloudTransitionAnimator.exitDuration
    }

    @MainActor
    private func openSettings() async {
        guard !isSettingsTransitionActive, !showSettings, !isMapToolbarBlocked else { return }

        isSettingsTransitionActive = true
        AppSettings.hapticImpact(.light)

        showsSettingsCloudOverlay = true
        settingsCloudExitProgress = 0
        settingsCloudEnterProgress = 0

        withAnimation(.easeInOut(duration: settingsCloudEnterDuration)) {
            settingsCloudEnterProgress = 1
        }

        try? await Task.sleep(nanoseconds: UInt64(settingsCloudEnterDuration * 1_000_000_000))

        withAnimation(settingsFadeAnimation) {
            showSettings = true
        }

        if !reduceMotion {
            try? await Task.sleep(nanoseconds: UInt64(Self.settingsFadeDuration * 1_000_000_000))
        }

        isSettingsTransitionActive = false
    }

    @MainActor
    private func closeSettings() async {
        guard showSettings, !isSettingsTransitionActive else { return }

        isSettingsTransitionActive = true
        AppSettings.hapticImpact(.light)

        withAnimation(settingsFadeAnimation) {
            showSettings = false
            showAdvancedMathGate = false
        }

        try? await Task.sleep(nanoseconds: UInt64(Self.settingsFadeDuration * 1_000_000_000))

        withAnimation(.easeInOut(duration: settingsCloudExitDuration)) {
            settingsCloudExitProgress = 1
        }

        try? await Task.sleep(nanoseconds: UInt64(settingsCloudExitDuration * 1_000_000_000))

        settingsCloudEnterProgress = 0
        settingsCloudExitProgress = 0
        showsSettingsCloudOverlay = false
        isSettingsTransitionActive = false
        
        reloadAllProgress()
    }

    private var shouldShowRedHoodPlayButton: Bool {
        activeMap == .main &&
            currentBaseID == MapGraph.redRidingHoodBaseID &&
            !isWalking &&
            !isMapTransitioning &&
            !isGlobalTransitioning
    }

    private var showsRedHoodLevelPlayButton: Bool {
        activeMap == .redHood &&
            activeRedHoodLevel == nil &&
            pendingRedHoodLevel != nil
    }

    /// Chapter title between back and settings on the Red Hood map only (not world map).
    private var showsRedHoodChapterTitleChrome: Bool {
        activeMap == .redHood && showsRedHoodLevelPlayButton
    }

    private var redHoodChapterTitleChromeText: String {
        guard let level = pendingRedHoodLevel else { return "" }
        return levelBannerTitle(for: level)
    }

    private func redHoodChapterTitleChromeScale(for screenSize: CGSize) -> CGFloat {
        let buttonSize = MapOverlayMetrics.chromeButtonSize
        let horizontalInset = topChromeHorizontalInset(for: screenSize)
        let reservedForButtons = (horizontalInset * 2) + (buttonSize * 2) + 20
        let availableWidth = max(160, screenSize.width - reservedForButtons)
        let targetWidth = min(availableWidth, IslandTitleFrameAsset.pixelSize.width * 0.48)
        return max(0.30, targetWidth / IslandTitleFrameAsset.pixelSize.width)
    }

    private func handleMapTap(_ location: CGPoint, projection: MapProjection) {
        guard !isMapTransitioning else { return }

        switch activeMap {
        case .main:
            handleMainMapTap(location, projection: projection)
        case .redHood:
            handleRedHoodMapTap(location, projection: projection)
        }
    }

    private func handleMainMapTap(_ screenTap: CGPoint, projection: MapProjection) {
        let reachableBases = MapGraph.baseWaypoints.filter { isWorldBaseUnlocked($0.id) }

        guard let target = closestWaypoint(
            to: screenTap,
            among: reachableBases,
            projection: projection,
            radius: dotHitRadius(for: projection.renderedSize)
        ) else {
            return
        }

        guard let start = nearestWaypoint(to: avatarPosition, among: MapGraph.waypoints) else {
            return
        }

        if target.id == start.id {
            return
        }

        guard let route = MapGraph.shortestPath(from: start.id, to: target.id) else {
            return
        }

        startWalking(route)
    }

    private func handleRedHoodMapTap(_ screenTap: CGPoint, projection: MapProjection) {
        guard activeRedHoodLevel == nil else { return }
        guard let target = closestWaypoint(
            to: screenTap,
            among: RedHoodMapGraph.storyWaypoints,
            projection: projection,
            radius: dotHitRadius(for: projection.renderedSize)
        ) else {
            if pendingRedHoodLevel != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pendingRedHoodLevel = nil
                }
            }
            return
        }

        guard isRedHoodWaypointPlayable(target.id) else { return }

        guard let start = nearestWaypoint(to: avatarPosition, among: RedHoodMapGraph.waypoints) else { return }

        if target.id == start.id {
            guard !isWalking else { return }

            if shouldOfferRedHoodLevelStart(for: target.id) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    pendingRedHoodLevel = target.id
                }
            } else if pendingRedHoodLevel != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pendingRedHoodLevel = nil
                }
            }
            return
        }

        guard let route = RedHoodMapGraph.shortestPath(from: start.id, to: target.id) else { return }

        if pendingRedHoodLevel != nil {
            withAnimation(.easeInOut(duration: 0.2)) {
                pendingRedHoodLevel = nil
            }
        }

        startWalking(route) {
            if shouldOfferRedHoodLevelStart(for: target.id) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    pendingRedHoodLevel = target.id
                }
            }
        }
    }

    private func closestWaypoint(
        to screenPoint: CGPoint,
        among waypoints: [MapWaypoint],
        projection: MapProjection,
        radius: CGFloat
    ) -> MapWaypoint? {
        waypoints
            .map { waypoint in
                (waypoint: waypoint, distance: projection.screenPoint(fromPixel: waypoint.point).distance(to: screenPoint))
            }
            .filter { $0.distance <= radius }
            .min { first, second in
                first.distance < second.distance
            }?
            .waypoint
    }

    private func nearestWaypoint(to point: CGPoint, among waypoints: [MapWaypoint]) -> MapWaypoint? {
        waypoints.min { first, second in
            first.point.distance(to: point) < second.point.distance(to: point)
        }
    }

    private func startWalking(_ route: [MapWaypoint], onArrival: (() -> Void)? = nil) {
        walkTask?.cancel()
        walkGeneration += 1

        let generation = walkGeneration
        walkTask = Task { @MainActor in
            let completed = await walk(route, generation: generation)

            guard completed, generation == walkGeneration, !Task.isCancelled else { return }

            onArrival?()
            walkTask = nil
        }
    }

    @ViewBuilder
    private func levelView(for level: Int) -> some View {
        if level == 0 {
            RedHoodLevel0View {
                handleRedHoodChapterCompletion(0)
            }
            .environmentObject(lm)
        } else if level == 9 {
            RedHoodLevelFinalView {
                handleRedHoodChapterCompletion(9)
            }
            .environmentObject(lm)
        } else if let eventData = EventLoader.event(id: level, from: lm.bundle) {
            EventFlowView(
                eventData: eventData,
                onPhaseChange: { flowPhase in
                    let shouldSuppress = (flowPhase == .intro)
                    if suppressesMapChromeForDialogue != shouldSuppress {
                        suppressesMapChromeForDialogue = shouldSuppress
                    }
                },
                onCelebrationZoomChange: { isZooming in
                    if suppressesMapChromeForDialogue != isZooming {
                        suppressesMapChromeForDialogue = isZooming
                    }
                },
                onSequencingFinished: { attemptCount in
                    presentRewardAfterMapPause(level: level, attemptCount: attemptCount)
                },
                onRewardReached: {
                    markRedHoodLevelCompleted(level)
                },
                onComplete: {
                    handleRedHoodChapterCompletion(level)
                }
            )
            .environmentObject(lm)
        }
    }

    @MainActor
    private func presentRewardAfterMapPause(level: Int, attemptCount: Int) {
        withAnimation(.easeInOut(duration: 0.35)) {
            activeRedHoodLevel = nil
            suppressesMapChromeForDialogue = false
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)

            guard activeRedHoodLevel == nil, redHoodPostSequenceReward == nil else { return }

            withAnimation(.easeInOut(duration: 0.35)) {
                suppressesMapChromeForDialogue = true
                redHoodPostSequenceReward = (level, attemptCount)
            }
        }
    }

    @MainActor
    private func finishRedHoodPostSequenceReward(for level: Int, pendingChapterUnlock: Bool = false) {
        withAnimation(.easeInOut(duration: 0.3)) {
            redHoodPostSequenceReward = nil
            suppressesMapChromeForDialogue = true
        }

        if pendingChapterUnlock {
            pendingChapterUnlockLevel = level
        } else {
            handleRedHoodChapterCompletion(level)
        }
    }

    @MainActor
    private func openRedHoodSubMap() async {
        guard !isWalking, !isMapTransitioning else { return }

        await CloudTransitionAnimator.runSceneTransition(
            isActive: $isMapTransitioning,
            enterProgress: $cloudEnterProgress,
            exitProgress: $cloudExitProgress
        ) {
            activeMap = .redHood
            avatarPosition = RedHoodMapGraph.initialWaypoint.point
            currentBaseID = RedHoodMapGraph.initialWaypoint.id
            avatarDirection = .up
        }
    }

    @MainActor
    private func walk(_ route: [MapWaypoint], generation: Int) async -> Bool {
        isWalking = true

        for waypoint in route.dropFirst() {
            guard generation == walkGeneration, !Task.isCancelled else {
                return false
            }

            let nextPosition = waypoint.point
            avatarDirection = WalkDirection(from: avatarPosition, to: nextPosition)

            let distance = normalizedMapDistance(from: avatarPosition, to: nextPosition)
            let duration = reduceMotion ? 0.0 : max(0.18, min(1.1, distance * 4.6))

            withAnimation(reduceMotion ? nil : .linear(duration: duration)) {
                avatarPosition = nextPosition
            }

            do {
                if duration > 0 {
                    try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                }
            } catch {
                if generation == walkGeneration {
                    isWalking = false
                }
                return false
            }

            guard generation == walkGeneration, !Task.isCancelled else {
                return false
            }

            currentBaseID = waypoint.id
        }

        if let finalWaypoint = route.last, activeMap == .redHood || MapGraph.baseIDs.contains(finalWaypoint.id) {
            withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.78)) {
                currentBaseID = finalWaypoint.id
            }
        }

        isWalking = false
        return true
    }

    private func normalizedMapDistance(from start: CGPoint, to end: CGPoint) -> CGFloat {
        let imageSize = activeMap.imagePixelSize
        guard imageSize.width > 0, imageSize.height > 0 else { return 0 }

        return hypot(
            (end.x - start.x) / imageSize.width,
            (end.y - start.y) / imageSize.height
        )
    }
}

private struct AvatarWithMarker: View {
    let direction: WalkDirection
    let frame: Int
    let size: CGFloat
    let markerIsRaised: Bool

    var body: some View {
        ZStack {
            AvatarSprite(direction: direction, frame: frame, size: size)

            GameMapLocationMarker(
                width: size * 0.34,
                height: size * 0.28
            )
                .offset(y: markerIsRaised ? -size * 0.76 : -size * 0.62)
        }
        .frame(width: size, height: size)
    }
}

private struct AvatarSprite: View {
    let direction: WalkDirection
    let frame: Int
    let size: CGFloat

    var body: some View {
        Image(direction.assetName)
            .resizable()
            .interpolation(.medium)
            .scaledToFill()
            .frame(width: size * 4, height: size, alignment: .leading)
            .offset(x: -CGFloat(frame) * size)
            .frame(width: size, height: size, alignment: .leading)
            .clipped()
            .shadow(color: .black.opacity(0.35), radius: 5, x: 0, y: 5)
    }
}
private struct StoryRegion {
    let baseID: Int
    let titleKey: String
    let titlePoint: CGPoint
}

private enum IslandTitleFrameAsset {
    static let pixelSize = CGSize(width: 721, height: 201)

    static func frameSize(mapScale: CGFloat) -> CGSize {
        CGSize(
            width: pixelSize.width * mapScale,
            height: pixelSize.height * mapScale
        )
    }

    static func titleFontSize(mapScale: CGFloat) -> CGFloat {
        46 * mapScale
    }

    static func secondaryFontSize(mapScale: CGFloat) -> CGFloat {
        34 * mapScale
    }
}

private struct IslandTitlePlaque: View {
    let title: String
    let scale: CGFloat

    private var frameSize: CGSize {
        IslandTitleFrameAsset.frameSize(mapScale: scale)
    }

    private var titleFontSize: CGFloat {
        IslandTitleFrameAsset.titleFontSize(mapScale: scale)
    }

    var body: some View {
        ZStack {
            Image("IslandTitleFrame")
                .resizable()
                .renderingMode(.original)
                .interpolation(.high)
                .frame(width: frameSize.width, height: frameSize.height)

            Text(title)
                .font(.app(size: titleFontSize, weight: .semibold))
                .foregroundStyle(Color(hex: "#3D0000"))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
                .padding(.horizontal, frameSize.width * 0.14)
                .frame(width: frameSize.width, height: frameSize.height * 0.68)
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .shadow(color: .black.opacity(0.22), radius: max(4, 7 * scale), x: 0, y: max(2, 4 * scale))
    }
}

private struct StoryRegionPlaque: View {
    let title: String
    let mapScale: CGFloat

    var body: some View {
        IslandTitlePlaque(title: title, scale: mapScale)
    }
}

private struct ComingSoonBadge: View {
    let mapScale: CGFloat

    @EnvironmentObject private var lm: LanguageManager

    private var frameSize: CGSize {
        IslandTitleFrameAsset.frameSize(mapScale: mapScale)
    }

    private var titleFontSize: CGFloat {
        IslandTitleFrameAsset.titleFontSize(mapScale: mapScale)
    }

    private var dateFontSize: CGFloat {
        IslandTitleFrameAsset.secondaryFontSize(mapScale: mapScale)
    }

    private var releaseDateText: String {
        MapReleaseSchedule.formattedComingSoonDate(languageCode: lm.currentLanguage)
    }

    var body: some View {
        ZStack {
            Image("IslandTitleFrame")
                .resizable()
                .renderingMode(.original)
                .interpolation(.high)
                .frame(width: frameSize.width, height: frameSize.height)

            VStack(spacing: 4 * mapScale) {
                Text(lm.t("map.coming_soon"))
                    .font(.app(size: titleFontSize, weight: .semibold))
                    .foregroundStyle(Color(hex: "#3D0000"))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(releaseDateText)
                    .font(.app(size: dateFontSize, weight: .regular))
                    .foregroundStyle(Color(hex: "#3D0000").opacity(0.82))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            .padding(.horizontal, frameSize.width * 0.12)
            .frame(width: frameSize.width, height: frameSize.height * 0.72)
        }
        .frame(width: frameSize.width, height: frameSize.height)
        .shadow(color: .black.opacity(0.22), radius: max(4, 7 * mapScale), x: 0, y: max(2, 4 * mapScale))
    }
}

private struct MapPlayButton: View {
    let accessibilityLabel: String
    let action: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        GamePrimaryPillButton(title: lm.t("button.play"), action: action)
            .accessibilityLabel(accessibilityLabel)
    }
}

private struct BookIcon3D: View {
    var size: CGFloat = MapOverlayMetrics.bookButtonSize

    var body: some View {
        Image("StoryBookButton")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.32), radius: 8, x: 0, y: 5)
            .accessibilityHidden(true)
    }
}


private struct WaypointDot: View {
    enum DotState { case completed, next, locked }

    let state: DotState
    let size: CGFloat

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var sysReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations = false
    private var reduceMotion: Bool { sysReduceMotion || reduceAnimations }

    var body: some View {
        ZStack {
            if state == .next {
                Circle()
                    .fill(nextColor.opacity(0.30))
                    .frame(width: size * (pulse ? 1.8 : 1.2), height: size * (pulse ? 1.8 : 1.2))
            }

            Circle()
                .fill(fillColor)
                .overlay(Circle().stroke(borderColor, lineWidth: max(1.5, size * 0.08)))
                .shadow(color: .black.opacity(0.30), radius: 4, y: 2)
                .frame(width: size, height: size)

            icon
                .frame(width: size, height: size)
        }
        .onAppear {
            guard state == .next, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    @ViewBuilder
    private var icon: some View {
        switch state {
        case .completed:
            Image(systemName: "checkmark")
                .font(.app(size: size * 0.46, weight: .bold))
                .foregroundColor(.white)
        case .next:
            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: size * 0.32, height: size * 0.32)
        case .locked:
            Image(systemName: "lock.fill")
                .font(.app(size: size * 0.38))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private var fillColor: Color {
        switch state {
        case .completed: return Color(red: 0.18, green: 0.72, blue: 0.28)
        case .next:      return nextColor
        case .locked:    return Color(red: 0.48, green: 0.48, blue: 0.50)
        }
    }

    private var borderColor: Color {
        switch state {
        case .completed: return Color(red: 0.08, green: 0.50, blue: 0.18)
        case .next:      return Color(red: 0.82, green: 0.38, blue: 0.04)
        case .locked:    return Color(red: 0.30, green: 0.30, blue: 0.32)
        }
    }

    private var nextColor: Color { Color(red: 0.98, green: 0.58, blue: 0.08) }
}

private struct MainMapIslandDot: View {
    let size: CGFloat
    let isPulsing: Bool

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var sysReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations = false
    private var reduceMotion: Bool { sysReduceMotion || reduceAnimations }

    private let dotColor = Color(red: 0.12, green: 0.64, blue: 0.92)
    private let borderColor = Color(red: 0.03, green: 0.36, blue: 0.68)

    var body: some View {
        ZStack {
            if isPulsing {
                Circle()
                    .fill(dotColor.opacity(0.30))
                    .frame(width: size * (pulse ? 1.8 : 1.2), height: size * (pulse ? 1.8 : 1.2))
            }

            Circle()
                .fill(dotColor)
                .overlay(Circle().stroke(borderColor, lineWidth: max(1.5, size * 0.08)))
                .shadow(color: .black.opacity(0.30), radius: 4, y: 2)
                .frame(width: size, height: size)

            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: size * 0.32, height: size * 0.32)
        }
        .onAppear {
            guard isPulsing, !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

private enum WalkDirection {
    case up
    case down
    case left
    case right

    init(from start: CGPoint, to end: CGPoint) {
        let dx = end.x - start.x
        let dy = end.y - start.y

        if abs(dx) > abs(dy) {
            self = dx >= 0 ? .right : .left
        } else {
            self = dy >= 0 ? .down : .up
        }
    }

    var assetName: String {
        switch self {
        case .up:
            return "avatar_walk_up"
        case .down:
            return "avatar_walk_down"
        case .left:
            return "avatar_walk_left"
        case .right:
            return "avatar_walk_right"
        }
    }
}

private struct MapWaypoint: Identifiable {
    let id: Int
    let name: String
    let point: CGPoint
    let neighbors: [Int]
}

private struct MapProjection {
    let imageSize: CGSize
    let containerSize: CGSize
    let contentMode: MapLayout.ContentMode

    var renderedSize: CGSize {
        guard imageSize.width > 0, imageSize.height > 0 else { return .zero }
        return CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
    }

    var contentOrigin: CGPoint {
        CGPoint(
            x: (containerSize.width - renderedSize.width) / 2,
            y: (containerSize.height - renderedSize.height) / 2
        )
    }

    var scale: CGFloat {
        guard imageSize.width > 0,
              imageSize.height > 0,
              containerSize.width > 0,
              containerSize.height > 0 else { return 1 }

        let widthScale = containerSize.width / imageSize.width
        let heightScale = containerSize.height / imageSize.height

        switch contentMode {
        case .fit:
            return min(widthScale, heightScale)
        case .fill:
            return max(widthScale, heightScale)
        }
    }

    func canvasLength(fromScreen length: CGFloat) -> CGFloat {
        guard scale > 0 else { return length }
        return length / scale
    }

    func screenPoint(fromPixel point: CGPoint) -> CGPoint {
        CGPoint(
            x: contentOrigin.x + point.x * scale,
            y: contentOrigin.y + point.y * scale
        )
    }

    func pixelPoint(fromScreen point: CGPoint) -> CGPoint {
        guard scale > 0 else { return .zero }

        return CGPoint(
            x: min(max((point.x - contentOrigin.x) / scale, 0), imageSize.width),
            y: min(max((point.y - contentOrigin.y) / scale, 0), imageSize.height)
        )
    }
}

private enum WorldMapPixel {
    static let width: CGFloat = 2784
    static let height: CGFloat = 1882
    static let size = CGSize(width: width, height: height)

    static func point(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: x, y: y)
    }
}

private enum MapReleaseSchedule {
    /// Target release for locked map regions (one month from May 29, 2026).
    static let comingSoonDate = Calendar.current.date(from: DateComponents(year: 2026, month: 6, day: 29))!

    static func formattedComingSoonDate(languageCode: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: languageCode)
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: comingSoonDate)
    }
}

private enum MapGraph {
    static let redRidingHoodBaseID = 0
    static let openingStartID = redRidingHoodBaseID
    static let redRidingHoodPlayPoint = WorldMapPixel.point(x: 641, y: 799)
    static let initialWaypoint = waypoint(id: openingStartID) ?? waypoints[0]
    static let baseIDs: Set<Int> = [0, 7, 14, 18, 22]
    static let comingSoonBaseIDs: Set<Int> = [7, 14, 18, 22]
    static let islandUnlockOrder: [Int] = [0, 7, 14, 18, 22]
    static let playableBaseIDs: Set<Int> = [0]
    static let baseTapRadius: CGFloat = 190

    static func nextIsland(after baseID: Int) -> Int? {
        guard let index = islandUnlockOrder.firstIndex(of: baseID),
              index + 1 < islandUnlockOrder.count else { return nil }
        return islandUnlockOrder[index + 1]
    }

    static let storyRegions: [StoryRegion] = [
        StoryRegion(baseID: 0,  titleKey: "map.region.red_riding_hood", titlePoint: WorldMapPixel.point(x: 794, y: 341)),
        StoryRegion(baseID: 7,  titleKey: "map.coming_soon",            titlePoint: WorldMapPixel.point(x: 1955, y: 341)),
        StoryRegion(baseID: 14, titleKey: "map.region.beauty_beast",    titlePoint: WorldMapPixel.point(x: 1476, y: 772)),
        StoryRegion(baseID: 22, titleKey: "map.region.princess_frog",   titlePoint: WorldMapPixel.point(x: 731, y: 1034)),
        StoryRegion(baseID: 18, titleKey: "map.region.aladdin",         titlePoint: WorldMapPixel.point(x: 2145, y: 1132))
    ]

    static let waypoints: [MapWaypoint] = [
        MapWaypoint(id: 0, name: "Red Riding Hood target", point: WorldMapPixel.point(x: 641, y: 799), neighbors: [1]),
        MapWaypoint(id: 1, name: "Forest path lower bend", point: WorldMapPixel.point(x: 700, y: 735), neighbors: [0, 2]),
        MapWaypoint(id: 2, name: "Forest path middle bend", point: WorldMapPixel.point(x: 805, y: 685), neighbors: [1, 3]),
        MapWaypoint(id: 3, name: "Forest path upper bend", point: WorldMapPixel.point(x: 930, y: 635), neighbors: [2, 4]),
        MapWaypoint(id: 4, name: "Mill road", point: WorldMapPixel.point(x: 1065, y: 575), neighbors: [3, 5]),
        MapWaypoint(id: 5, name: "Upper bridge center", point: WorldMapPixel.point(x: 1235, y: 560), neighbors: [4, 6]),
        MapWaypoint(id: 6, name: "Upper bridge landing", point: WorldMapPixel.point(x: 1370, y: 575), neighbors: [5, 7]),
        MapWaypoint(id: 7, name: "Mountain target", point: WorldMapPixel.point(x: 1454, y: 581), neighbors: [6, 8]),
        MapWaypoint(id: 8, name: "Mountain road descent", point: WorldMapPixel.point(x: 1525, y: 660), neighbors: [7, 9]),
        MapWaypoint(id: 9, name: "Cottage road curve", point: WorldMapPixel.point(x: 1645, y: 750), neighbors: [8, 10]),
        MapWaypoint(id: 10, name: "Right island path", point: WorldMapPixel.point(x: 1815, y: 805), neighbors: [9, 11]),
        MapWaypoint(id: 11, name: "Right bridge entry", point: WorldMapPixel.point(x: 2025, y: 870), neighbors: [10, 12]),
        MapWaypoint(id: 12, name: "Right bridge center", point: WorldMapPixel.point(x: 1960, y: 935), neighbors: [11, 13]),
        MapWaypoint(id: 13, name: "Right bridge landing", point: WorldMapPixel.point(x: 1870, y: 1005), neighbors: [12, 14]),
        MapWaypoint(id: 14, name: "Beauty and Beast target", point: WorldMapPixel.point(x: 1788, y: 1031), neighbors: [13, 15]),
        MapWaypoint(id: 15, name: "Central island road", point: WorldMapPixel.point(x: 1705, y: 1115), neighbors: [14, 16]),
        MapWaypoint(id: 16, name: "Lower central road", point: WorldMapPixel.point(x: 1595, y: 1205), neighbors: [15, 17]),
        MapWaypoint(id: 17, name: "Lower bridge center", point: WorldMapPixel.point(x: 1615, y: 1305), neighbors: [16, 18]),
        MapWaypoint(id: 18, name: "Aladdin target", point: WorldMapPixel.point(x: 1678, y: 1357), neighbors: [17, 19]),
        MapWaypoint(id: 19, name: "South road east", point: WorldMapPixel.point(x: 1575, y: 1425), neighbors: [18, 20]),
        MapWaypoint(id: 20, name: "South stepping stones east", point: WorldMapPixel.point(x: 1430, y: 1495), neighbors: [19, 21]),
        MapWaypoint(id: 21, name: "South stepping stones west", point: WorldMapPixel.point(x: 1215, y: 1500), neighbors: [20, 22]),
        MapWaypoint(id: 22, name: "Frog target", point: WorldMapPixel.point(x: 1041, y: 1465), neighbors: [21])
    ]

    static func waypoint(id: Int) -> MapWaypoint? {
        waypoints.first { $0.id == id }
    }

    static var baseWaypoints: [MapWaypoint] {
        waypoints.filter { baseIDs.contains($0.id) }
    }

    static func storyRegion(for baseID: Int) -> StoryRegion? {
        storyRegions.first { $0.baseID == baseID }
    }

    static func baseHit(by point: CGPoint) -> MapWaypoint? {
        baseWaypoints
            .filter { $0.point.distance(to: point) <= baseTapRadius }
            .min { first, second in
                first.point.distance(to: point) < second.point.distance(to: point)
            }
    }

    static func shortestPath(from startID: Int, to targetID: Int) -> [MapWaypoint]? {
        var distances = Dictionary(uniqueKeysWithValues: waypoints.map { ($0.id, CGFloat.greatestFiniteMagnitude) })
        var previous: [Int: Int] = [:]
        var unvisited = Set(waypoints.map(\.id))

        distances[startID] = 0

        while let currentID = unvisited.min(by: { distances[$0, default: .greatestFiniteMagnitude] < distances[$1, default: .greatestFiniteMagnitude] }) {
            if currentID == targetID { break }

            unvisited.remove(currentID)

            guard let current = waypoint(id: currentID) else { continue }

            for neighborID in current.neighbors where unvisited.contains(neighborID) {
                guard let neighbor = waypoint(id: neighborID) else { continue }

                let distance = distances[currentID, default: .greatestFiniteMagnitude] + current.point.distance(to: neighbor.point)

                if distance < distances[neighborID, default: .greatestFiniteMagnitude] {
                    distances[neighborID] = distance
                    previous[neighborID] = currentID
                }
            }
        }

        guard distances[targetID, default: .greatestFiniteMagnitude] < .greatestFiniteMagnitude else {
            return nil
        }

        var routeIDs = [targetID]
        var cursor = targetID

        while cursor != startID {
            guard let previousID = previous[cursor] else { return nil }

            routeIDs.append(previousID)
            cursor = previousID
        }

        return routeIDs.reversed().compactMap { waypoint(id: $0) }
    }
}

private enum RedHoodMapGraph {
    private enum Pixel {
        static let width: CGFloat = 2509
        static let height: CGFloat = 1881

        static func point(x: CGFloat, y: CGFloat) -> CGPoint {
            CGPoint(x: x, y: y)
        }
    }

    static let imageSize = CGSize(width: Pixel.width, height: Pixel.height)
    static let openingStartID = 10
    static let initialWaypoint = waypoint(id: openingStartID) ?? waypoints[0]
    static let tapRadius: CGFloat = 190
    static let storyWaypointIDs = Set(0...9)

    static var storyWaypoints: [MapWaypoint] {
        waypoints.filter { storyWaypointIDs.contains($0.id) }
    }

    static let waypoints: [MapWaypoint] = [
        MapWaypoint(id: 10, name: "Bridge entry", point: Pixel.point(x: 1108, y: 1490), neighbors: [0]),
        MapWaypoint(id: 0, name: "Bridge base", point: Pixel.point(x: 1108, y: 1391), neighbors: [10, 20]),
        MapWaypoint(id: 20, name: "Bridge path climb", point: Pixel.point(x: 1082, y: 1374), neighbors: [0, 21]),
        MapWaypoint(id: 21, name: "Lower path climb", point: Pixel.point(x: 1012, y: 1199), neighbors: [20, 1]),
        MapWaypoint(id: 1, name: "Lower forest base", point: Pixel.point(x: 1063, y: 1141), neighbors: [21, 22]),
        MapWaypoint(id: 22, name: "Lower forest bend", point: Pixel.point(x: 980, y: 1055), neighbors: [1, 23]),
        MapWaypoint(id: 23, name: "Crossroads approach", point: Pixel.point(x: 930, y: 1017), neighbors: [22, 2]),
        MapWaypoint(id: 2, name: "Crossroads base", point: Pixel.point(x: 885, y: 975), neighbors: [23, 24, 27]),
        MapWaypoint(id: 24, name: "Wolf path east", point: Pixel.point(x: 746, y: 970), neighbors: [2, 25]),
        MapWaypoint(id: 25, name: "Wolf path middle", point: Pixel.point(x: 604, y: 949), neighbors: [24, 26]),
        MapWaypoint(id: 26, name: "Wolf path west", point: Pixel.point(x: 465, y: 943), neighbors: [25, 3]),
        MapWaypoint(id: 3, name: "Wolf base", point: Pixel.point(x: 440, y: 981), neighbors: [26]),
        MapWaypoint(id: 27, name: "Cottage climb", point: Pixel.point(x: 898, y: 858), neighbors: [2, 4]),
        MapWaypoint(id: 4, name: "Cottage left base", point: Pixel.point(x: 898, y: 776), neighbors: [27, 28]),
        MapWaypoint(id: 28, name: "Cottage path left", point: Pixel.point(x: 959, y: 726), neighbors: [4, 29]),
        MapWaypoint(id: 29, name: "Cottage path roof", point: Pixel.point(x: 1037, y: 636), neighbors: [28, 30]),
        MapWaypoint(id: 30, name: "Cottage path upper", point: Pixel.point(x: 1110, y: 570), neighbors: [29, 31]),
        MapWaypoint(id: 31, name: "Cottage path ridge", point: Pixel.point(x: 1183, y: 504), neighbors: [30, 32]),
        MapWaypoint(id: 32, name: "Cottage path treeline", point: Pixel.point(x: 1259, y: 478), neighbors: [31, 33]),
        MapWaypoint(id: 33, name: "Cottage top approach", point: Pixel.point(x: 1338, y: 481), neighbors: [32, 5]),
        MapWaypoint(id: 5, name: "Cottage top base", point: Pixel.point(x: 1404, y: 494), neighbors: [33, 34]),
        MapWaypoint(id: 34, name: "Mill road upper", point: Pixel.point(x: 1490, y: 500), neighbors: [5, 35]),
        MapWaypoint(id: 35, name: "Mill road bend", point: Pixel.point(x: 1530, y: 560), neighbors: [34, 36]),
        MapWaypoint(id: 36, name: "Mill road approach", point: Pixel.point(x: 1540, y: 610), neighbors: [35, 6]),
        MapWaypoint(id: 6, name: "Mill road base", point: Pixel.point(x: 1519, y: 643), neighbors: [36, 37]),
        MapWaypoint(id: 37, name: "Grandmother curve upper", point: Pixel.point(x: 1531, y: 736), neighbors: [6, 38]),
        MapWaypoint(id: 38, name: "Grandmother curve middle", point: Pixel.point(x: 1475, y: 808), neighbors: [37, 39]),
        MapWaypoint(id: 39, name: "Grandmother curve lower", point: Pixel.point(x: 1425, y: 845), neighbors: [38, 7]),
        MapWaypoint(id: 7, name: "Grandmother base", point: Pixel.point(x: 1380, y: 859), neighbors: [39, 40]),
        MapWaypoint(id: 40, name: "Village road bend", point: Pixel.point(x: 1461, y: 892), neighbors: [7, 41]),
        MapWaypoint(id: 41, name: "Village road lower", point: Pixel.point(x: 1530, y: 917), neighbors: [40, 8]),
        MapWaypoint(id: 8, name: "Village road base", point: Pixel.point(x: 1545, y: 976), neighbors: [41, 42]),
        MapWaypoint(id: 42, name: "Bridge road meadow", point: Pixel.point(x: 1687, y: 987), neighbors: [8, 43]),
        MapWaypoint(id: 43, name: "Bridge road rise", point: Pixel.point(x: 1838, y: 946), neighbors: [42, 44]),
        MapWaypoint(id: 44, name: "Bridge road east", point: Pixel.point(x: 1911, y: 901), neighbors: [43, 45]),
        MapWaypoint(id: 45, name: "Bridge road approach", point: Pixel.point(x: 1987, y: 857), neighbors: [44, 9]),
        MapWaypoint(id: 9, name: "Bridge lookout base", point: Pixel.point(x: 2066, y: 817), neighbors: [45])
    ]

    static func waypoint(id: Int) -> MapWaypoint? {
        waypoints.first { $0.id == id }
    }

    static func waypointHit(by point: CGPoint) -> MapWaypoint? {
        waypoints
            .filter { storyWaypointIDs.contains($0.id) }
            .filter { $0.point.distance(to: point) <= tapRadius }
            .min { first, second in
                first.point.distance(to: point) < second.point.distance(to: point)
            }
    }

    static func shortestPath(from startID: Int, to targetID: Int) -> [MapWaypoint]? {
        var distances = Dictionary(uniqueKeysWithValues: waypoints.map { ($0.id, CGFloat.greatestFiniteMagnitude) })
        var previous: [Int: Int] = [:]
        var unvisited = Set(waypoints.map(\.id))

        distances[startID] = 0

        while let currentID = unvisited.min(by: { distances[$0, default: .greatestFiniteMagnitude] < distances[$1, default: .greatestFiniteMagnitude] }) {
            if currentID == targetID { break }

            unvisited.remove(currentID)

            guard let current = waypoint(id: currentID) else { continue }

            for neighborID in current.neighbors where unvisited.contains(neighborID) {
                guard let neighbor = waypoint(id: neighborID) else { continue }

                let distance = distances[currentID, default: .greatestFiniteMagnitude] + current.point.distance(to: neighbor.point)

                if distance < distances[neighborID, default: .greatestFiniteMagnitude] {
                    distances[neighborID] = distance
                    previous[neighborID] = currentID
                }
            }
        }

        guard distances[targetID, default: .greatestFiniteMagnitude] < .greatestFiniteMagnitude else {
            return nil
        }

        var routeIDs = [targetID]
        var cursor = targetID

        while cursor != startID {
            guard let previousID = previous[cursor] else { return nil }

            routeIDs.append(previousID)
            cursor = previousID
        }

        return routeIDs.reversed().compactMap { waypoint(id: $0) }
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isGlobalTransitioning: false)
    }
}
