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
            return .fit
        case .redHood:
            return .fit
        }
    }

    var foregroundImageName: String? {
        switch self {
        case .main:
            return nil
        case .redHood:
            return nil
        }
    }
}

struct ContentView: View {
    let isGlobalTransitioning: Bool
    let onReturnToMainMenu: () -> Void

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
    @State private var activeRedHoodLevel: Int? = nil
    @State private var pendingRedHoodLevel: Int? = nil
    @State private var levelBannerLevel: Int? = nil
    @State private var currentFrame = 0

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

            if let level = activeRedHoodLevel {
                levelView(for: level)
                    .ignoresSafeArea()
                    .zIndex(20)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.94).combined(with: .opacity),
                        removal: .scale(scale: 0.92).combined(with: .opacity)
                    ))
            }

            if let bannerLevel = levelBannerLevel {
                LevelStartBanner(title: levelBannerTitle(for: bannerLevel)) {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.75)) {
                        levelBannerLevel = nil
                        activeRedHoodLevel = bannerLevel
                    }
                }
                .ignoresSafeArea()
                .zIndex(25)
                .transition(.opacity)
            }

            if activeMap == .redHood {
                BackButton { handleBackButton() }
                    .padding(.top, 52)
                    .padding(.leading, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .zIndex(30)
                    .transition(.opacity)
            }

            if activeMap == .main {
                MainMenuButton {
                    onReturnToMainMenu()
                }
                .disabled(isMapTransitioning || isGlobalTransitioning || isWalking || activeRedHoodLevel != nil)
                .opacity(isMapTransitioning || isGlobalTransitioning || isWalking || activeRedHoodLevel != nil ? 0.45 : 1)
                .padding(.top, 52)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .zIndex(30)
            }

            #if DEBUG
            Button("Reset") { resetProgress() }
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Capsule().fill(Color.red.opacity(0.80)))
                .padding(.top, 112)
                .padding(.trailing, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .zIndex(35)
            #endif
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

            completedRedHoodLevels = Set(
                UserDefaults.standard.array(forKey: "completedRedHoodLevels") as? [Int] ?? []
            )

            if let savedID = UserDefaults.standard.object(forKey: "currentBaseID") as? Int,
               MapGraph.baseIDs.contains(savedID),
               let wp = MapGraph.waypoint(id: savedID) {
                currentBaseID = savedID
                avatarPosition = wp.point
            }

        }
        .onChange(of: completedRedHoodLevels) {
            UserDefaults.standard.set(Array(completedRedHoodLevels), forKey: "completedRedHoodLevels")
        }
        .onChange(of: currentBaseID) {
            if MapGraph.baseIDs.contains(currentBaseID) {
                UserDefaults.standard.set(currentBaseID, forKey: "currentBaseID")
            }
        }
    }

    @ViewBuilder
    private func mapContent(mapSize: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            MapBackgroundImage(name: activeMap.imageName, mapSize: mapSize)

            if activeMap == .redHood {
                ForEach(RedHoodMapGraph.waypoints.filter { $0.id >= 0 && $0.id <= 9 }, id: \.id) { wp in
                    WaypointDot(state: dotState(for: wp.id), size: dotSize(for: mapSize))
                        .position(wp.point.scaled(to: mapSize))
                        .allowsHitTesting(false)
                }
            }

            if activeMap == .main {
                ForEach(MapGraph.baseWaypoints, id: \.id) { wp in
                    MainMapIslandDot(
                        size: dotSize(for: mapSize),
                        isPulsing: wp.id == MapGraph.redRidingHoodBaseID
                    )
                    .position(wp.point.scaled(to: mapSize))
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
                x: avatarPosition.x * mapSize.width,
                y: avatarPosition.y * mapSize.height
            )

            if let fgName = activeMap.foregroundImageName {
                MapBackgroundImage(name: fgName, mapSize: mapSize)
                    .allowsHitTesting(false)
            }

            if activeMap == .redHood, let level = pendingRedHoodLevel, let wp = RedHoodMapGraph.waypoint(id: level) {
                LevelStartButton {
                    let l = level
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pendingRedHoodLevel = nil
                        levelBannerLevel = l
                    }
                }
                .frame(width: playButtonSize(for: mapSize), height: playButtonSize(for: mapSize))
                .position(CGPoint(
                    x: wp.point.x * mapSize.width,
                    y: wp.point.y * mapSize.height - dotSize(for: mapSize) * 2.8
                ))
                .transition(.scale(scale: 0.75).combined(with: .opacity))
            }

            if activeMap == .main, !isWalking,
               let region = MapGraph.storyRegion(for: currentBaseID),
               !MapGraph.comingSoonBaseIDs.contains(currentBaseID) {
                StoryRegionPlaque(
                    title: lm.t(region.titleKey),
                    width: titleWidth(for: mapSize),
                    fontSize: titleFontSize(for: mapSize)
                )
                .position(region.titlePoint.scaled(to: mapSize))
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            if activeMap == .main, !isWalking,
               MapGraph.comingSoonBaseIDs.contains(currentBaseID),
               let region = MapGraph.storyRegion(for: currentBaseID) {
                ComingSoonBadge(
                    width: titleWidth(for: mapSize),
                    fontSize: titleFontSize(for: mapSize)
                )
                .position(region.titlePoint.scaled(to: mapSize))
                .transition(.scale(scale: 0.92).combined(with: .opacity))
            }

            if shouldShowRedHoodPlayButton {
                RedHoodPlayButton {
                    Task {
                        await openRedHoodSubMap()
                    }
                }
                .frame(width: playButtonSize(for: mapSize), height: playButtonSize(for: mapSize))
                .position(MapGraph.redRidingHoodPlayPoint.scaled(to: mapSize))
                .transition(.scale(scale: 0.82).combined(with: .opacity))
            }
        }
        .frame(width: mapSize.width, height: mapSize.height)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onEnded { value in
                    handleMapTap(value.location, mapSize: mapSize)
                }
        )
    }

    #if DEBUG
    private func resetProgress() {
        completedRedHoodLevels = []
        currentBaseID = MapGraph.openingStartID
        avatarPosition = MapGraph.initialWaypoint.point
        avatarDirection = .down
        activeMap = .main
        UserDefaults.standard.removeObject(forKey: "completedRedHoodLevels")
        UserDefaults.standard.removeObject(forKey: "currentBaseID")
    }
    #endif

    private func avatarSize(for mapSize: CGSize) -> CGFloat {
        let multiplier: CGFloat = 0.11
        return min(mapSize.width, mapSize.height) * multiplier
    }

    private func titleWidth(for mapSize: CGSize) -> CGFloat {
        min(mapSize.width * 0.28, max(190, mapSize.width * 0.18))
    }

    private func titleFontSize(for mapSize: CGSize) -> CGFloat {
        min(26, max(17, mapSize.width * 0.022))
    }

    private func playButtonSize(for mapSize: CGSize) -> CGFloat {
        min(82, max(54, mapSize.width * 0.07))
    }

    private func handleBackButton() {
        if activeRedHoodLevel != nil {
            withAnimation(.easeInOut(duration: 0.3)) {
                activeRedHoodLevel = nil
                levelBannerLevel = nil
                pendingRedHoodLevel = nil
            }
        } else if pendingRedHoodLevel != nil {
            withAnimation(.easeInOut(duration: 0.25)) {
                pendingRedHoodLevel = nil
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
            levelBannerLevel = nil
            avatarPosition = MapGraph.waypoint(id: MapGraph.redRidingHoodBaseID)?.point ?? MapGraph.initialWaypoint.point
            currentBaseID = MapGraph.redRidingHoodBaseID
            avatarDirection = .down
        }
    }

    private func levelBannerTitle(for level: Int) -> String {
        if level == 0 { return lm.t("level.adventure_begins") }
        return EventLoader.event(id: level, from: lm.bundle)?.bannerTitle ?? lm.t("level.new_scene")
    }

    private func dotSize(for mapSize: CGSize) -> CGFloat {
        min(mapSize.width, mapSize.height) * 0.055
    }

    private func dotState(for waypointId: Int) -> WaypointDot.DotState {
        if completedRedHoodLevels.contains(waypointId) { return .completed }
        return waypointId == nextRedHoodLevel ? .next : .locked
    }

    private var nextRedHoodLevel: Int? {
        (0...EventLoader.maxEventId(from: lm.bundle)).first { !completedRedHoodLevels.contains($0) }
    }

    private func isRedHoodWaypointPlayable(_ waypointId: Int) -> Bool {
        completedRedHoodLevels.contains(waypointId) || waypointId == nextRedHoodLevel
    }

    private func shouldOfferRedHoodLevelStart(for waypointId: Int) -> Bool {
        completedRedHoodLevels.contains(waypointId) || waypointId == nextRedHoodLevel
    }

    private var shouldShowRedHoodPlayButton: Bool {
        activeMap == .main &&
            currentBaseID == MapGraph.redRidingHoodBaseID &&
            !isWalking &&
            !isMapTransitioning
    }

    private func handleMapTap(_ location: CGPoint, mapSize: CGSize) {
        guard !isWalking, !isMapTransitioning else { return }

        let normalizedTap = CGPoint(
            x: min(max(location.x / mapSize.width, 0), 1),
            y: min(max(location.y / mapSize.height, 0), 1)
        )

        switch activeMap {
        case .main:
            handleMainMapTap(normalizedTap)
        case .redHood:
            handleRedHoodMapTap(normalizedTap)
        }
    }

    private func handleMainMapTap(_ normalizedTap: CGPoint) {
        guard let start = MapGraph.waypoint(id: currentBaseID) else {
            return
        }

        guard let target = MapGraph.baseHit(by: normalizedTap) else {
            return
        }

        if target.id == start.id {
            return
        }

        guard let route = MapGraph.shortestPath(from: start.id, to: target.id) else {
            return
        }

        Task {
            await walk(route)
        }
    }

    private func handleRedHoodMapTap(_ normalizedTap: CGPoint) {
        guard activeRedHoodLevel == nil else { return }
        guard let start = RedHoodMapGraph.waypoint(id: currentBaseID) else { return }
        guard let target = RedHoodMapGraph.waypointHit(by: normalizedTap) else {
            if pendingRedHoodLevel != nil {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pendingRedHoodLevel = nil
                }
            }
            return
        }

        guard isRedHoodWaypointPlayable(target.id) else { return }

        if target.id == start.id {
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

        Task {
            await walk(route)
            if shouldOfferRedHoodLevelStart(for: target.id) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    pendingRedHoodLevel = target.id
                }
            }
        }
    }

    @ViewBuilder
    private func levelView(for level: Int) -> some View {
        if level == 0 {
            RedHoodLevel0View {
                withAnimation(.easeInOut(duration: 0.3)) {
                    completedRedHoodLevels.insert(0)
                    activeRedHoodLevel = nil
                }
            }
        } else if let eventData = EventLoader.event(id: level, from: lm.bundle) {
            EventFlowView(eventData: eventData) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    completedRedHoodLevels.insert(level)
                    activeRedHoodLevel = nil
                }
            }
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
    private func walk(_ route: [MapWaypoint]) async {
        isWalking = true

        for waypoint in route.dropFirst() {
            let nextPosition = waypoint.point
            avatarDirection = WalkDirection(from: avatarPosition, to: nextPosition)

            let distance = avatarPosition.distance(to: nextPosition)
            let duration = max(0.18, min(1.1, distance * 4.6))

            withAnimation(.linear(duration: duration)) {
                avatarPosition = nextPosition
            }

            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        }

        if let finalWaypoint = route.last, activeMap == .redHood || MapGraph.baseIDs.contains(finalWaypoint.id) {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                currentBaseID = finalWaypoint.id
            }
        }

        isWalking = false
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

            LocationTriangle()
                .fill(Color(red: 1.0, green: 0.78, blue: 0.16))
                .overlay(
                    LocationTriangle()
                        .stroke(.white, lineWidth: max(1.5, size * 0.035))
                )
                .shadow(color: .black.opacity(0.32), radius: 3, x: 0, y: 2)
                .frame(width: size * 0.30, height: size * 0.24)
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

private struct LocationTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

private struct StoryRegion {
    let baseID: Int
    let titleKey: String
    let titlePoint: CGPoint
}

private struct StoryRegionPlaque: View {
    let title: String
    let width: CGFloat
    let fontSize: CGFloat

    var body: some View {
        Text(title)
            .font(.system(size: fontSize, weight: .semibold, design: .serif))
            .italic()
            .foregroundStyle(Color(red: 0.29, green: 0.15, blue: 0.05))
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.72)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .frame(width: width)
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(red: 0.97, green: 0.86, blue: 0.58).opacity(0.94))

                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(red: 0.55, green: 0.31, blue: 0.09), lineWidth: 2)
                }
            }
            .shadow(color: .black.opacity(0.22), radius: 7, x: 0, y: 4)
    }
}

private struct ComingSoonBadge: View {
    let width: CGFloat
    let fontSize: CGFloat

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.system(size: fontSize * 0.85))
                .foregroundStyle(Color(red: 0.72, green: 0.38, blue: 0.04))
            Text(lm.t("map.coming_soon"))
                .font(.system(size: fontSize, weight: .semibold, design: .serif))
                .italic()
                .foregroundStyle(Color(red: 0.29, green: 0.15, blue: 0.05))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .frame(width: width)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(red: 0.97, green: 0.86, blue: 0.58).opacity(0.94))
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(red: 0.55, green: 0.31, blue: 0.09), lineWidth: 2)
            }
        }
        .shadow(color: .black.opacity(0.22), radius: 7, x: 0, y: 4)
    }
}

private struct RedHoodPlayButton: View {
    let action: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(.blue)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(.white, lineWidth: 4)
                    )
                    .shadow(color: .black.opacity(0.28), radius: 7, x: 0, y: 5)

                Image(systemName: "play.fill")
                    .font(.system(size: 28, weight: .black))
                    .foregroundStyle(.white)
                    .offset(x: 2)
            }
            .accessibilityLabel(lm.t("a11y.play_red_hood"))
        }
        .buttonStyle(.plain)
    }
}

private struct WaypointDot: View {
    enum DotState { case completed, next, locked }

    let state: DotState
    let size: CGFloat

    @State private var pulse = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                .font(.system(size: size * 0.46, weight: .bold))
                .foregroundColor(.white)
        case .next:
            Circle()
                .fill(Color.white.opacity(0.75))
                .frame(width: size * 0.32, height: size * 0.32)
        case .locked:
            Image(systemName: "lock.fill")
                .font(.system(size: size * 0.38))
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dotColor = Color(red: 0.98, green: 0.58, blue: 0.08)
    private let borderColor = Color(red: 0.82, green: 0.38, blue: 0.04)

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

private struct LevelStartButton: View {
    let action: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(.blue)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(Circle().stroke(.white, lineWidth: 4))
                    .shadow(color: .black.opacity(0.28), radius: 7, x: 0, y: 5)

                Image(systemName: "play.fill")
                    .font(.system(size: 26, weight: .black))
                    .foregroundStyle(.white)
                    .offset(x: 2)
            }
            .accessibilityLabel(lm.t("a11y.start_event"))
        }
        .buttonStyle(.plain)
    }
}

private struct BackButton: View {
    let action: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                Text(lm.t("button.back"))
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(minWidth: 90, minHeight: 48)
            .background(
                Capsule()
                    .fill(Color(red: 0.10, green: 0.06, blue: 0.02).opacity(0.82))
                    .overlay(Capsule().stroke(Color.white.opacity(0.70), lineWidth: 2))
            )
            .shadow(color: .black.opacity(0.50), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lm.t("a11y.go_back"))
    }
}

private struct MainMenuButton: View {
    let action: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "house.fill")
                    .font(.system(size: 15, weight: .bold))
                Text(lm.t("button.menu"))
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .frame(minWidth: 90, minHeight: 48)
            .background(
                Capsule()
                    .fill(Color(red: 0.10, green: 0.06, blue: 0.02).opacity(0.82))
                    .overlay(Capsule().stroke(Color.white.opacity(0.70), lineWidth: 2))
            )
            .shadow(color: .black.opacity(0.50), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lm.t("a11y.return_to_menu"))
        .accessibilityHint(lm.t("a11y.menu_hint"))
    }
}

private struct LevelStartBanner: View {
    let title: String
    let onFinish: () -> Void

    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "sparkles")
                    .font(.system(size: 56))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(red: 1, green: 0.88, blue: 0.1), Color(red: 1, green: 0.50, blue: 0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: .orange.opacity(0.6), radius: 12)

                Text(title)
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.45), radius: 6)
            }
            .scaleEffect(isVisible ? 1.0 : (reduceMotion ? 1.0 : 0.4))
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .task {
            withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.62)) {
                isVisible = true
            }
            try? await Task.sleep(nanoseconds: 1_050_000_000)
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.38)) {
                isVisible = false
            }
            try? await Task.sleep(nanoseconds: 400_000_000)
            onFinish()
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

private enum WorldMapPixel {
    static let width: CGFloat = 3344
    static let height: CGFloat = 1882

    static func point(x: CGFloat, y: CGFloat) -> CGPoint {
        CGPoint(x: x / width, y: y / height)
    }
}

private enum MapGraph {
    static let redRidingHoodBaseID = 0
    static let openingStartID = redRidingHoodBaseID
    static let redRidingHoodPlayPoint = WorldMapPixel.point(x: 575, y: 730)
    static let initialWaypoint = waypoint(id: openingStartID) ?? waypoints[0]
    static let baseIDs: Set<Int> = [0, 7, 14, 18, 22]
    static let comingSoonBaseIDs: Set<Int> = [7, 14, 18, 22]
    static let baseTapRadius: CGFloat = 0.055

    static let storyRegions: [StoryRegion] = [
        StoryRegion(baseID: 0,  titleKey: "map.region.red_riding_hood", titlePoint: WorldMapPixel.point(x: 700, y: 300)),
        StoryRegion(baseID: 22, titleKey: "map.region.princess_frog",   titlePoint: WorldMapPixel.point(x: 1045, y: 1550)),
        StoryRegion(baseID: 18, titleKey: "map.region.aladdin",         titlePoint: WorldMapPixel.point(x: 2038, y: 1455)),
        StoryRegion(baseID: 14, titleKey: "map.region.beauty_beast",    titlePoint: WorldMapPixel.point(x: 2195, y: 1030)),
        StoryRegion(baseID: 7,  titleKey: "map.coming_soon",            titlePoint: WorldMapPixel.point(x: 1785, y: 450))
    ]

    static let waypoints: [MapWaypoint] = [
        MapWaypoint(id: 0, name: "Red Riding Hood base", point: WorldMapPixel.point(x: 575, y: 775), neighbors: [1]),
        MapWaypoint(id: 1, name: "Forest path entry", point: WorldMapPixel.point(x: 650, y: 715), neighbors: [0, 2]),
        MapWaypoint(id: 2, name: "Forest climb", point: WorldMapPixel.point(x: 760, y: 650), neighbors: [1, 3]),
        MapWaypoint(id: 3, name: "Village curve", point: WorldMapPixel.point(x: 930, y: 610), neighbors: [2, 4]),
        MapWaypoint(id: 4, name: "Village road", point: WorldMapPixel.point(x: 1125, y: 600), neighbors: [3, 5]),
        MapWaypoint(id: 5, name: "Bridge west road", point: WorldMapPixel.point(x: 1435, y: 535), neighbors: [4, 6]),
        MapWaypoint(id: 6, name: "Bridge west landing", point: WorldMapPixel.point(x: 1625, y: 535), neighbors: [5, 7]),
        MapWaypoint(id: 7, name: "Mountain base", point: WorldMapPixel.point(x: 1785, y: 525), neighbors: [6, 8]),
        MapWaypoint(id: 8, name: "Mountain exit", point: WorldMapPixel.point(x: 1920, y: 585), neighbors: [7, 9]),
        MapWaypoint(id: 9, name: "Mountain descent", point: WorldMapPixel.point(x: 2025, y: 675), neighbors: [8, 10]),
        MapWaypoint(id: 10, name: "Right island upper road", point: WorldMapPixel.point(x: 2165, y: 725), neighbors: [9, 11]),
        MapWaypoint(id: 11, name: "Right island road", point: WorldMapPixel.point(x: 2325, y: 775), neighbors: [10, 12]),
        MapWaypoint(id: 12, name: "Orchard road", point: WorldMapPixel.point(x: 2475, y: 840), neighbors: [11, 13]),
        MapWaypoint(id: 13, name: "Right island bend", point: WorldMapPixel.point(x: 2495, y: 925), neighbors: [12, 24]),
        MapWaypoint(id: 24, name: "Right bridge approach", point: WorldMapPixel.point(x: 2395, y: 1000), neighbors: [13, 25]),
        MapWaypoint(id: 25, name: "Right bridge road", point: WorldMapPixel.point(x: 2270, y: 1065), neighbors: [24, 14]),
        MapWaypoint(id: 14, name: "Right bridge base", point: WorldMapPixel.point(x: 2195, y: 1105), neighbors: [25, 15]),
        MapWaypoint(id: 15, name: "Central island descent", point: WorldMapPixel.point(x: 2120, y: 1245), neighbors: [14, 16]),
        MapWaypoint(id: 16, name: "Central island road", point: WorldMapPixel.point(x: 1985, y: 1335), neighbors: [15, 17]),
        MapWaypoint(id: 17, name: "Desert approach", point: WorldMapPixel.point(x: 1845, y: 1375), neighbors: [16, 26]),
        MapWaypoint(id: 26, name: "Desert bridge approach", point: WorldMapPixel.point(x: 1945, y: 1465), neighbors: [17, 18]),
        MapWaypoint(id: 18, name: "Desert base", point: WorldMapPixel.point(x: 2038, y: 1532), neighbors: [26, 19]),
        MapWaypoint(id: 19, name: "Desert lower exit", point: WorldMapPixel.point(x: 1945, y: 1465), neighbors: [18, 20]),
        MapWaypoint(id: 20, name: "South coast curve", point: WorldMapPixel.point(x: 1805, y: 1375), neighbors: [19, 21]),
        MapWaypoint(id: 21, name: "South coast road", point: WorldMapPixel.point(x: 1575, y: 1350), neighbors: [20, 27]),
        MapWaypoint(id: 27, name: "South stones east", point: WorldMapPixel.point(x: 1340, y: 1295), neighbors: [21, 28]),
        MapWaypoint(id: 28, name: "South stones middle", point: WorldMapPixel.point(x: 1135, y: 1345), neighbors: [27, 29]),
        MapWaypoint(id: 29, name: "South stones west", point: WorldMapPixel.point(x: 930, y: 1515), neighbors: [28, 22]),
        MapWaypoint(id: 22, name: "Frog base", point: WorldMapPixel.point(x: 1045, y: 1630), neighbors: [29])
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

        return routeIDs.reversed().compactMap(waypoint)
    }
}

private enum RedHoodMapGraph {
    private enum Pixel {
        static let width: CGFloat = 2509
        static let height: CGFloat = 1882

        static func point(x: CGFloat, y: CGFloat) -> CGPoint {
            CGPoint(x: x / width, y: y / height)
        }
    }

    static let openingStartID = 10
    static let initialWaypoint = waypoint(id: openingStartID) ?? waypoints[0]
    static let tapRadius: CGFloat = 0.09
    static let storyWaypointIDs = Set(0...9)

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

        return routeIDs.reversed().compactMap(waypoint)
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }

    func scaled(to size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(isGlobalTransitioning: false, onReturnToMainMenu: {})
    }
}
