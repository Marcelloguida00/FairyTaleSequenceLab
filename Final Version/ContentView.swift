import SwiftUI
import Combine

struct ContentView: View {
    @State private var avatarPosition = MapGraph.initialWaypoint.point
    @State private var currentBaseID = MapGraph.initialWaypoint.id
    @State private var avatarDirection = WalkDirection.down
    @State private var currentFrame = 0
    @State private var isWalking = false
    @State private var markerIsRaised = false
    @State private var didPlayOpeningWalk = false

    private let mapAspectRatio: CGFloat = 1448.0 / 1086.0
    private let spriteTimer = Timer.publish(every: 0.12, on: .main, in: .common).autoconnect()

    var body: some View {
        GeometryReader { proxy in
            let mapSize = fittedMapSize(in: proxy.size)

            ZStack {
                Color(red: 0.10, green: 0.55, blue: 0.78)
                    .ignoresSafeArea()

                ZStack(alignment: .topLeading) {
                    Image("mappa")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: mapSize.width, height: mapSize.height)

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

                    if !isWalking, let region = MapGraph.storyRegion(for: currentBaseID) {
                        StoryRegionPlaque(
                            title: region.title,
                            width: titleWidth(for: mapSize),
                            fontSize: titleFontSize(for: mapSize)
                        )
                        .position(region.titlePoint.scaled(to: mapSize))
                        .transition(.scale(scale: 0.92).combined(with: .opacity))
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

            playOpeningWalkIfNeeded()
        }
    }

    private func fittedMapSize(in container: CGSize) -> CGSize {
        let containerAspectRatio = container.width / container.height

        if containerAspectRatio > mapAspectRatio {
            let height = container.height
            return CGSize(width: height * mapAspectRatio, height: height)
        }

        let width = container.width
        return CGSize(width: width, height: width / mapAspectRatio)
    }

    private func avatarSize(for mapSize: CGSize) -> CGFloat {
        min(mapSize.width, mapSize.height) * 0.085
    }

    private func titleWidth(for mapSize: CGSize) -> CGFloat {
        min(mapSize.width * 0.28, max(190, mapSize.width * 0.18))
    }

    private func titleFontSize(for mapSize: CGSize) -> CGFloat {
        min(26, max(17, mapSize.width * 0.022))
    }

    private func handleMapTap(_ location: CGPoint, mapSize: CGSize) {
        guard !isWalking else { return }

        let normalizedTap = CGPoint(
            x: min(max(location.x / mapSize.width, 0), 1),
            y: min(max(location.y / mapSize.height, 0), 1)
        )

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

    private func playOpeningWalkIfNeeded() {
        guard !didPlayOpeningWalk else { return }

        didPlayOpeningWalk = true

        guard let route = MapGraph.shortestPath(
            from: MapGraph.openingStartID,
            to: MapGraph.redRidingHoodBaseID
        ) else {
            return
        }

        Task {
            await walk(route)
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

        if let finalWaypoint = route.last, MapGraph.baseIDs.contains(finalWaypoint.id) {
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
