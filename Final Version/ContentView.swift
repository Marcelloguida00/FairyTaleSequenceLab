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
            return 1448.0 / 1086.0
        case .redHood:
            return 1535.0 / 1024.0
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

struct ContentView: View {
    @State private var activeMap = ActiveMap.main
    @State private var avatarPosition = MapGraph.initialWaypoint.point
    @State private var currentBaseID = MapGraph.initialWaypoint.id
    @State private var avatarDirection = WalkDirection.down
    @State private var currentFrame = 0
    @State private var isWalking = false
    @State private var markerIsRaised = false
    @State private var isMapTransitioning = false
    @State private var cloudCoverProgress: CGFloat = 0
    @State private var completedRedHoodLevels: Set<Int> = []
    @State private var activeRedHoodLevel: Int? = nil
    @State private var pendingRedHoodLevel: Int? = nil
    @State private var levelBannerLevel: Int? = nil

    private let spriteTimer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let mapSize = fittedMapSize(in: proxy.size)

            ZStack {
                Color(red: 0.10, green: 0.55, blue: 0.78)
                    .ignoresSafeArea()

                ZStack(alignment: .topLeading) {
                    Image(activeMap.imageName)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: mapSize.width, height: mapSize.height)

                    if activeMap == .redHood {
                        ForEach(RedHoodMapGraph.waypoints.filter { $0.id >= 0 && $0.id <= 9 }, id: \.id) { wp in
                            WaypointDot(state: dotState(for: wp.id), size: dotSize(for: mapSize))
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
                        Image(fgName)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: mapSize.width, height: mapSize.height)
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

                    if activeMap == .main, !isWalking, let region = MapGraph.storyRegion(for: currentBaseID) {
                        StoryRegionPlaque(
                            title: region.title,
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
                .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onEnded { value in
                            handleMapTap(value.location, mapSize: mapSize)
                        }
                )

                if isMapTransitioning || cloudCoverProgress > 0.01 {
                    CloudTransitionOverlay(progress: cloudCoverProgress)
                        .ignoresSafeArea()
                        .allowsHitTesting(true)
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

                #if DEBUG
                Button("Reset") { resetProgress() }
                    .font(.system(size: 13, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.red.opacity(0.80)))
                    .padding(.top, 52)
                    .padding(.trailing, 20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .zIndex(35)
                #endif
            }
        }
        .onReceive(spriteTimer) { _ in
            guard isWalking else {
                currentFrame = 0
                return
            }

            currentFrame = (currentFrame + 1) % 4
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

    private func fittedMapSize(in container: CGSize) -> CGSize {
        let containerAspectRatio = container.width / container.height
        let mapAspectRatio = activeMap.aspectRatio

        if containerAspectRatio > mapAspectRatio {
            let height = container.height
            return CGSize(width: height * mapAspectRatio, height: height)
        }

        let width = container.width
        return CGSize(width: width, height: width / mapAspectRatio)
    }

    private func avatarSize(for mapSize: CGSize) -> CGFloat {
        min(mapSize.width, mapSize.height) * 0.11
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

        isMapTransitioning = true

        withAnimation(.easeInOut(duration: 0.75)) { cloudCoverProgress = 1 }
        try? await Task.sleep(nanoseconds: 780_000_000)

        activeMap = .main
        pendingRedHoodLevel = nil
        activeRedHoodLevel = nil
        levelBannerLevel = nil
        avatarPosition = MapGraph.waypoint(id: MapGraph.redRidingHoodBaseID)?.point ?? MapGraph.initialWaypoint.point
        currentBaseID = MapGraph.redRidingHoodBaseID
        avatarDirection = .down
        currentFrame = 0

        try? await Task.sleep(nanoseconds: 180_000_000)
        withAnimation(.easeInOut(duration: 0.75)) { cloudCoverProgress = 0 }
        try? await Task.sleep(nanoseconds: 760_000_000)

        isMapTransitioning = false
    }

    private func levelBannerTitle(for level: Int) -> String {
        if level == 0 { return "Adventure Begins!" }
        return EventLoader.event(id: level)?.bannerTitle ?? "New Scene"
    }

    private func dotSize(for mapSize: CGSize) -> CGFloat {
        min(mapSize.width, mapSize.height) * 0.055
    }

    private func dotState(for waypointId: Int) -> WaypointDot.DotState {
        if completedRedHoodLevels.contains(waypointId) { return .completed }
        let next = completedRedHoodLevels.count
        return (waypointId == next && waypointId <= EventLoader.maxEventId) ? .next : .locked
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
        guard activeRedHoodLevel == nil, pendingRedHoodLevel == nil else { return }
        guard let start = RedHoodMapGraph.waypoint(id: currentBaseID) else { return }
        guard let target = RedHoodMapGraph.waypointHit(by: normalizedTap) else { return }

        if target.id == start.id {
            let next = completedRedHoodLevels.count
            if target.id == next, next <= EventLoader.maxEventId {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    pendingRedHoodLevel = target.id
                }
            }
            return
        }

        let nextUnlocked = completedRedHoodLevels.count
        guard target.id == nextUnlocked, nextUnlocked <= EventLoader.maxEventId else { return }

        guard let route = RedHoodMapGraph.shortestPath(from: start.id, to: target.id) else { return }

        Task {
            await walk(route)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                pendingRedHoodLevel = target.id
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
        } else if let eventData = EventLoader.event(id: level) {
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

        isMapTransitioning = true

        withAnimation(.easeInOut(duration: 0.75)) {
            cloudCoverProgress = 1
        }

        try? await Task.sleep(nanoseconds: 780_000_000)

        activeMap = .redHood
        avatarPosition = RedHoodMapGraph.initialWaypoint.point
        currentBaseID = RedHoodMapGraph.initialWaypoint.id
        avatarDirection = .up
        currentFrame = 0

        try? await Task.sleep(nanoseconds: 180_000_000)

        withAnimation(.easeInOut(duration: 0.75)) {
            cloudCoverProgress = 0
        }

        try? await Task.sleep(nanoseconds: 760_000_000)

        isMapTransitioning = false
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
    let title: String
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

private struct RedHoodPlayButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.98, green: 0.20, blue: 0.18),
                                Color(red: 0.72, green: 0.04, blue: 0.08)
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
            .accessibilityLabel("Play Little Red Riding Hood")
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

private struct LevelStartButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.20, green: 0.82, blue: 0.36), Color(red: 0.06, green: 0.54, blue: 0.20)],
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
            .accessibilityLabel("Start event")
        }
        .buttonStyle(.plain)
    }
}

private struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold))
                Text("Back")
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
        .accessibilityLabel("Go back")
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

private struct CloudTransitionOverlay: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let clampedProgress = min(max(progress, 0), 1)
            let bankWidth = proxy.size.width * 0.82
            let bankHeight = proxy.size.height * 1.22
            let travel = proxy.size.width * 0.72

            ZStack {
                Color.white.opacity(clampedProgress * 0.18)

                CloudBank()
                    .frame(width: bankWidth, height: bankHeight)
                    .position(
                        x: proxy.size.width * 0.25 - travel * (1 - clampedProgress),
                        y: proxy.size.height * 0.5
                    )

                CloudBank()
                    .scaleEffect(x: -1, y: 1)
                    .frame(width: bankWidth, height: bankHeight)
                    .position(
                        x: proxy.size.width * 0.75 + travel * (1 - clampedProgress),
                        y: proxy.size.height * 0.5
                    )
            }
            .opacity(clampedProgress > 0 ? 1 : 0)
        }
    }
}

private struct CloudBank: View {
    private let puffs: [CloudPuff] = [
        CloudPuff(x: 0.20, y: 0.16, size: 0.33),
        CloudPuff(x: 0.47, y: 0.12, size: 0.40),
        CloudPuff(x: 0.78, y: 0.18, size: 0.36),
        CloudPuff(x: 0.14, y: 0.38, size: 0.42),
        CloudPuff(x: 0.50, y: 0.42, size: 0.52),
        CloudPuff(x: 0.86, y: 0.42, size: 0.44),
        CloudPuff(x: 0.24, y: 0.68, size: 0.38),
        CloudPuff(x: 0.58, y: 0.72, size: 0.46),
        CloudPuff(x: 0.88, y: 0.74, size: 0.34)
    ]

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: proxy.size.height * 0.24, style: .continuous)
                    .fill(.white)
                    .frame(width: proxy.size.width * 0.9, height: proxy.size.height * 0.82)
                    .position(x: proxy.size.width * 0.46, y: proxy.size.height * 0.5)

                ForEach(puffs) { puff in
                    Circle()
                        .fill(.white)
                        .frame(
                            width: proxy.size.width * puff.size,
                            height: proxy.size.width * puff.size
                        )
                        .position(
                            x: proxy.size.width * puff.x,
                            y: proxy.size.height * puff.y
                        )
                }
            }
            .shadow(color: .black.opacity(0.10), radius: 22, x: 0, y: 8)
        }
    }
}

private struct CloudPuff: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
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

private enum MapGraph {
    static let openingStartID = 23
    static let redRidingHoodBaseID = 0
    static let redRidingHoodPlayPoint = CGPoint(x: 0.210, y: 0.420)
    static let initialWaypoint = waypoint(id: openingStartID) ?? waypoints[0]
    static let baseIDs: Set<Int> = [0, 7, 14, 18, 22]
    static let baseTapRadius: CGFloat = 0.055

    static let storyRegions: [StoryRegion] = [
        StoryRegion(baseID: 0, title: "Little Red Riding Hood", titlePoint: CGPoint(x: 0.232, y: 0.226)),
        StoryRegion(baseID: 22, title: "The Princess and the Frog", titlePoint: CGPoint(x: 0.270, y: 0.612)),
        StoryRegion(baseID: 18, title: "Aladdin", titlePoint: CGPoint(x: 0.790, y: 0.704)),
        StoryRegion(baseID: 14, title: "Beauty and the Beast", titlePoint: CGPoint(x: 0.548, y: 0.462)),
        StoryRegion(baseID: 7, title: "Coming Soon", titlePoint: CGPoint(x: 0.620, y: 0.205))
    ]

    static let waypoints: [MapWaypoint] = [
        MapWaypoint(id: 0, name: "Upper left target", point: CGPoint(x: 0.165, y: 0.417), neighbors: [1, 23]),
        MapWaypoint(id: 1, name: "Left island climb", point: CGPoint(x: 0.180, y: 0.372), neighbors: [0, 2]),
        MapWaypoint(id: 2, name: "Village outer curve", point: CGPoint(x: 0.233, y: 0.319), neighbors: [1, 3]),
        MapWaypoint(id: 3, name: "Village upper path", point: CGPoint(x: 0.284, y: 0.314), neighbors: [2, 4]),
        MapWaypoint(id: 4, name: "Mill bend", point: CGPoint(x: 0.330, y: 0.287), neighbors: [3, 5]),
        MapWaypoint(id: 5, name: "Bridge to mine west", point: CGPoint(x: 0.420, y: 0.276), neighbors: [4, 6]),
        MapWaypoint(id: 6, name: "Bridge to mine middle", point: CGPoint(x: 0.491, y: 0.275), neighbors: [5, 7]),
        MapWaypoint(id: 7, name: "Mine target", point: CGPoint(x: 0.564, y: 0.275), neighbors: [6, 8]),
        MapWaypoint(id: 8, name: "Mine exit", point: CGPoint(x: 0.612, y: 0.291), neighbors: [7, 9]),
        MapWaypoint(id: 9, name: "Mountain descent", point: CGPoint(x: 0.644, y: 0.354), neighbors: [8, 10]),
        MapWaypoint(id: 10, name: "Right island path", point: CGPoint(x: 0.684, y: 0.389), neighbors: [9, 11]),
        MapWaypoint(id: 11, name: "Factory meadow", point: CGPoint(x: 0.738, y: 0.404), neighbors: [10, 12]),
        MapWaypoint(id: 12, name: "Lower right bend", point: CGPoint(x: 0.805, y: 0.422), neighbors: [11, 13]),
        MapWaypoint(id: 13, name: "Right bridge approach", point: CGPoint(x: 0.807, y: 0.478), neighbors: [12, 14]),
        MapWaypoint(id: 14, name: "Central bridge target", point: CGPoint(x: 0.718, y: 0.543), neighbors: [13, 15]),
        MapWaypoint(id: 15, name: "Central right shore", point: CGPoint(x: 0.677, y: 0.596), neighbors: [14, 16]),
        MapWaypoint(id: 16, name: "Central lower bend", point: CGPoint(x: 0.604, y: 0.682), neighbors: [15, 17]),
        MapWaypoint(id: 17, name: "Desert neck", point: CGPoint(x: 0.654, y: 0.736), neighbors: [16, 18]),
        MapWaypoint(id: 18, name: "Desert target", point: CGPoint(x: 0.657, y: 0.779), neighbors: [17, 29]),
        MapWaypoint(id: 19, name: "Lower desert curve", point: CGPoint(x: 0.609, y: 0.834), neighbors: [29, 20]),
        MapWaypoint(id: 20, name: "South stones east", point: CGPoint(x: 0.547, y: 0.864), neighbors: [19, 21]),
        MapWaypoint(id: 21, name: "South stones middle", point: CGPoint(x: 0.469, y: 0.862), neighbors: [20, 30]),
        MapWaypoint(id: 22, name: "Bottom left target", point: CGPoint(x: 0.356, y: 0.831), neighbors: [32]),
        MapWaypoint(id: 23, name: "Red Riding Hood bridge start", point: CGPoint(x: 0.118, y: 0.501), neighbors: [0]),
        MapWaypoint(id: 29, name: "Desert lower exit", point: CGPoint(x: 0.646, y: 0.806), neighbors: [18, 19]),
        MapWaypoint(id: 30, name: "South stones west", point: CGPoint(x: 0.428, y: 0.853), neighbors: [21, 31]),
        MapWaypoint(id: 31, name: "Bottom island stones", point: CGPoint(x: 0.390, y: 0.842), neighbors: [30, 32]),
        MapWaypoint(id: 32, name: "Bottom island approach", point: CGPoint(x: 0.369, y: 0.833), neighbors: [31, 22])
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
    static let openingStartID = 10
    static let initialWaypoint = waypoint(id: openingStartID) ?? waypoints[0]
    static let tapRadius: CGFloat = 0.09

    static let waypoints: [MapWaypoint] = [
        MapWaypoint(id: 10, name: "Bridge entry", point: CGPoint(x: 0.419, y: 0.940), neighbors: [0]),
        MapWaypoint(id: 0, name: "Village dock", point: CGPoint(x: 0.419, y: 0.829), neighbors: [1, 10]),
        MapWaypoint(id: 1, name: "Lower forest path", point: CGPoint(x: 0.400, y: 0.695), neighbors: [0, 2]),
        MapWaypoint(id: 2, name: "Crossroads", point: CGPoint(x: 0.322, y: 0.604), neighbors: [1, 3, 4]),
        MapWaypoint(id: 3, name: "Wolf clearing", point: CGPoint(x: 0.121, y: 0.608), neighbors: [2]),
        MapWaypoint(id: 4, name: "Cottage bend", point: CGPoint(x: 0.326, y: 0.487), neighbors: [2, 5]),
        MapWaypoint(id: 5, name: "Forest cottage", point: CGPoint(x: 0.532, y: 0.302), neighbors: [4, 6]),
        MapWaypoint(id: 6, name: "Mill road", point: CGPoint(x: 0.587, y: 0.402), neighbors: [5, 7]),
        MapWaypoint(id: 7, name: "Grandmother path", point: CGPoint(x: 0.535, y: 0.537), neighbors: [6, 8]),
        MapWaypoint(id: 8, name: "Village entry", point: CGPoint(x: 0.606, y: 0.607), neighbors: [7, 9]),
        MapWaypoint(id: 9, name: "Bridge lookout", point: CGPoint(x: 0.838, y: 0.510), neighbors: [8])
    ]

    static func waypoint(id: Int) -> MapWaypoint? {
        waypoints.first { $0.id == id }
    }

    static func waypointHit(by point: CGPoint) -> MapWaypoint? {
        waypoints
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
        ContentView()
    }
}
