import SwiftUI

// MARK: - Particle layout (deterministic “random” field)

private struct CloudParticle: Identifiable {
    let id: Int
    let anchor: CGPoint
    let scale: CGFloat
    let rotation: Double
    let depth: Double
    let entryVector: CGPoint
    let exitVector: CGPoint
    let speedBias: CGFloat
}

private enum CloudFieldFactory {
    /// Griglia fitta + 3 strati sfalsati + filler su bordi e angoli.
    static let particles: [CloudParticle] = makeDenseField()

    private static let layerOffsets: [(CGFloat, CGFloat)] = [
        (0, 0),
        (0.5, 0.5),
        (0.25, 0.75)
    ]

    private static let edgeAnchors: [CGPoint] = [
        CGPoint(x: 0.04, y: 0.06), CGPoint(x: 0.50, y: 0.03), CGPoint(x: 0.96, y: 0.06),
        CGPoint(x: 0.02, y: 0.50), CGPoint(x: 0.98, y: 0.50),
        CGPoint(x: 0.04, y: 0.94), CGPoint(x: 0.50, y: 0.97), CGPoint(x: 0.96, y: 0.94),
        CGPoint(x: 0.18, y: 0.14), CGPoint(x: 0.82, y: 0.14),
        CGPoint(x: 0.18, y: 0.86), CGPoint(x: 0.82, y: 0.86)
    ]

    private static func makeDenseField() -> [CloudParticle] {
        let columns = 13
        let rows = 8
        let cellCount = columns * rows

        var result: [CloudParticle] = []
        result.reserveCapacity(cellCount * layerOffsets.count + edgeAnchors.count)

        var nextID = 0
        for (layerIndex, offset) in layerOffsets.enumerated() {
            let offsetX = offset.0 / CGFloat(columns)
            let offsetY = offset.1 / CGFloat(rows)

            for index in 0..<cellCount {
                result.append(makeParticle(
                    id: nextID,
                    col: index % columns,
                    row: index / columns,
                    columns: columns,
                    rows: rows,
                    offsetX: offsetX,
                    offsetY: offsetY,
                    layerIndex: layerIndex
                ))
                nextID += 1
            }
        }

        for (index, anchor) in edgeAnchors.enumerated() {
            result.append(makeEdgeParticle(id: nextID + index, anchor: anchor))
        }

        return result
    }

    private static func makeParticle(
        id: Int,
        col: Int,
        row: Int,
        columns: Int,
        rows: Int,
        offsetX: CGFloat,
        offsetY: CGFloat,
        layerIndex: Int
    ) -> CloudParticle {
        let cellX = (CGFloat(col) + 0.5) / CGFloat(columns) + offsetX
        let cellY = (CGFloat(row) + 0.5) / CGFloat(rows) + offsetY

        let jitterX = (hash01(id, 11) - 0.5) * 0.06
        let jitterY = (hash01(id, 23) - 0.5) * 0.06

        let anchor = CGPoint(
            x: min(max(cellX + jitterX, 0.01), 0.99),
            y: min(max(cellY + jitterY, 0.01), 0.99)
        )

        return buildParticle(
            id: id,
            anchor: anchor,
            scaleBoost: CGFloat(layerIndex) * 0.04
        )
    }

    private static func makeEdgeParticle(id: Int, anchor: CGPoint) -> CloudParticle {
        buildParticle(id: id, anchor: anchor, scaleBoost: 0.12)
    }

    private static func buildParticle(id: Int, anchor: CGPoint, scaleBoost: CGFloat) -> CloudParticle {
        CloudParticle(
            id: id,
            anchor: anchor,
            scale: 0.92 + hash01(id, 5) * 0.88 + scaleBoost,
            rotation: Double(hash01(id, 17) - 0.5) * 42,
            depth: Double(hash01(id, 31)),
            entryVector: entryVector(for: anchor, index: id),
            exitVector: exitVector(for: anchor, index: id),
            speedBias: 0.58 + hash01(id, 41) * 0.28
        )
    }

    private static func entryVector(for anchor: CGPoint, index: Int) -> CGPoint {
        var vx: CGFloat = anchor.x < 0.5 ? -1 : 1
        var vy: CGFloat = anchor.y < 0.5 ? -1 : 1

        if anchor.x < 0.22 { vx = -1 }
        if anchor.x > 0.78 { vx = 1 }
        if anchor.y < 0.22 { vy = -1 }
        if anchor.y > 0.78 { vy = 1 }

        if index % 4 == 0 { vx *= 1.15 as CGFloat }
        if index % 5 == 2 { vy *= 1.12 as CGFloat }

        return normalize(CGPoint(x: vx, y: vy))
    }

    private static func exitVector(for anchor: CGPoint, index: Int) -> CGPoint {
        var vx: CGFloat = 0
        var vy: CGFloat = 0

        if anchor.x < 0.42 {
            vx = -1
        } else if anchor.x > 0.58 {
            vx = 1
        } else {
            vx = index.isMultiple(of: 2) ? -1 : 1
        }

        if anchor.y < 0.32 {
            vy = -0.42
        } else if anchor.y > 0.68 {
            vy = 0.42
        } else if index % 3 == 0 {
            vy = -0.28
        } else if index % 7 == 0 {
            vy = 0.30
        }

        return normalize(CGPoint(x: vx, y: vy))
    }

    private static func normalize(_ point: CGPoint) -> CGPoint {
        let length = hypot(point.x, point.y)
        guard length > 0.001 else { return CGPoint(x: 0, y: -1) }
        return CGPoint(x: point.x / length, y: point.y / length)
    }

    private static func hash01(_ index: Int, _ salt: Int) -> CGFloat {
        let value = sin(Double(index * 73 + salt * 19)) * 43758.5453
        return CGFloat(value - floor(value))
    }
}

// MARK: - Overlay

enum CloudEntrySideFilter: Equatable {
    case all
    case fromRight
    case fromRightTrailing
    case fromLeft
    case fromLeftTrailing
}

struct CloudTransitionOverlay: View {
    let enterProgress: CGFloat
    let exitProgress: CGFloat
    var cloudImageName: String = "cloud"
    var entrySideFilter: CloudEntrySideFilter = .all
    /// When set, only particles anchored at or above this normalized Y (0 = top) are shown.
    var anchorYMax: CGFloat? = nil
    var opacityScale: CGFloat = 1
    var cloudSizeScale: CGFloat = 1
    var entrySpreadScale: CGFloat = 1

    private static let cloudPeakOpacity: CGFloat = 0.78
    private static let skyBackdropColor = Color(red: 0.55, green: 0.78, blue: 0.95)
    private static let stormBackdropColor = Color(red: 0.05, green: 0.07, blue: 0.11)

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var usesStormBackdrop: Bool {
        cloudImageName == "cloudBlack"
    }

    var body: some View {
        GeometryReader { proxy in
            let baseSize = min(proxy.size.width, proxy.size.height) * 0.35

            ZStack {
                (usesStormBackdrop ? Self.stormBackdropColor : Self.skyBackdropColor)
                    .opacity(backgroundOpacity)
                    .ignoresSafeArea()

                ForEach(CloudFieldFactory.particles) { particle in
                    if matchesEntryFilter(particle), matchesAnchorFilter(particle) {
                        cloudView(
                            particle: particle,
                            in: proxy.size,
                            baseSize: baseSize
                        )
                        .zIndex(particle.depth)
                    }
                }
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }

    private var backgroundOpacity: CGFloat {
        if usesStormBackdrop {
            if exitProgress > 0.01 {
                return max(0, 0.94 * (1 - exitProgress))
            }
            return min(0.94, enterProgress * 0.98)
        }

        if exitProgress > 0.01 {
            return max(0, 0.35 * (1 - exitProgress))
        }
        return min(0.32, enterProgress * 0.38)
    }

    @ViewBuilder
    private func cloudView(particle: CloudParticle, in size: CGSize, baseSize: CGFloat) -> some View {
        let easedEnter = easeInOut(min(1, enterProgress * particle.speedBias))
        let easedExit = easeInOut(exitProgress * particle.speedBias)

        let entrySpread = max(size.width, size.height) * 0.62 * entrySpreadScale
        let exitSpread = max(size.width, size.height) * 0.58

        let entryOffset = CGPoint(
            x: particle.entryVector.x * entrySpread * (1 - easedEnter),
            y: particle.entryVector.y * entrySpread * (1 - easedEnter)
        )

        let exitOffset = CGPoint(
            x: particle.exitVector.x * exitSpread * easedExit,
            y: particle.exitVector.y * exitSpread * easedExit
        )

        let anchorPoint = CGPoint(
            x: particle.anchor.x * size.width,
            y: particle.anchor.y * size.height
        )

        let position = CGPoint(
            x: anchorPoint.x + entryOffset.x + exitOffset.x,
            y: anchorPoint.y + entryOffset.y + exitOffset.y
        )

        let opacity: CGFloat = {
            let fadeIn = min(Self.cloudPeakOpacity, easedEnter * Self.cloudPeakOpacity)
            if exitProgress > 0.001 {
                return fadeIn * max(0, 1 - easedExit * 1.05)
            }
            return fadeIn
        }() * opacityScale

        let dimension = baseSize * particle.scale * cloudSizeScale

        Image(cloudImageName)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: dimension, height: dimension)
            .rotationEffect(.degrees(particle.rotation))
            .opacity(opacity)
            .position(position)
    }

    private func matchesEntryFilter(_ particle: CloudParticle) -> Bool {
        switch entrySideFilter {
        case .all:
            return true
        case .fromRight:
            return particle.entryVector.x > 0.12
        case .fromRightTrailing:
            return particle.entryVector.x > 0.04 || particle.anchor.x > 0.56
        case .fromLeft:
            return particle.entryVector.x < -0.12
        case .fromLeftTrailing:
            return particle.entryVector.x < -0.04 || particle.anchor.x < 0.44
        }
    }

    private func matchesAnchorFilter(_ particle: CloudParticle) -> Bool {
        guard let anchorYMax else { return true }
        return particle.anchor.y <= anchorYMax
    }

    private func easeInOut(_ t: CGFloat) -> CGFloat {
        if reduceMotion { return t }
        return t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }
}

// MARK: - Scene transition driver

enum CloudTransitionAnimator {
    /// Apertura sipario dal Main Menu (solo uscita nuvole).
    nonisolated static let playOpenDuration: TimeInterval = 0.8

    // Timeline (totale ~2.55s):
    // 0.0s        → overlay attivo
    // 0.0–1.05s   → nuvole entrano e coprono (più lento)
    // 1.05s       → cambio scena (schermo coperto)
    // 1.05–1.40s  → pausa
    // 1.40–2.55s  → nuvole escono (sx/dx) + fade-out
    // 2.55s       → overlay rimosso

    static let enterDuration: TimeInterval = 1.05
    static let holdAfterSceneChange: TimeInterval = 0.35
    static let exitDuration: TimeInterval = 1.15
    static let totalDuration: TimeInterval = enterDuration + holdAfterSceneChange + exitDuration

    /// Main Menu → gioco: nuvole già visibili, solo apertura + fade.
    @MainActor
    static func runCurtainOpen(
        exitProgress: Binding<CGFloat>,
        duration: TimeInterval = playOpenDuration,
        whenOpen: () async -> Void
    ) async {
        exitProgress.wrappedValue = 0

        withAnimation(.easeInOut(duration: duration)) {
            exitProgress.wrappedValue = 1
        }
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

        await whenOpen()
    }

    /// Copre la scena con le nuvole e poi rimuove l’overlay senza animazione di uscita.
    /// Usato per tornare al main menu (evita la doppia transizione entrata + uscita).
    @MainActor
    static func runCoverTransition(
        isActive: Binding<Bool>,
        enterProgress: Binding<CGFloat>,
        whenCovered: () async -> Void
    ) async {
        isActive.wrappedValue = true
        enterProgress.wrappedValue = 0

        withAnimation(.easeInOut(duration: enterDuration)) {
            enterProgress.wrappedValue = 1
        }
        try? await Task.sleep(nanoseconds: UInt64(enterDuration * 1_000_000_000))

        await whenCovered()

        enterProgress.wrappedValue = 0
        isActive.wrappedValue = false
    }

    @MainActor
    static func runSceneTransition(
        isActive: Binding<Bool>,
        enterProgress: Binding<CGFloat>,
        exitProgress: Binding<CGFloat>,
        between: () async -> Void
    ) async {
        // 0.0s — crea overlay
        isActive.wrappedValue = true
        enterProgress.wrappedValue = 0
        exitProgress.wrappedValue = 0

        // 0.0s–1.05s — entrata
        withAnimation(.easeInOut(duration: enterDuration)) {
            enterProgress.wrappedValue = 1
        }
        try? await Task.sleep(nanoseconds: UInt64(enterDuration * 1_000_000_000))

        // 1.05s — cambio scena a schermo coperto
        await between()

        // 1.05s–1.40s — pausa
        try? await Task.sleep(nanoseconds: UInt64(holdAfterSceneChange * 1_000_000_000))

        // 1.40s–2.55s — uscita con fade (gestito dall’overlay via exitProgress)
        withAnimation(.easeInOut(duration: exitDuration)) {
            exitProgress.wrappedValue = 1
        }
        try? await Task.sleep(nanoseconds: UInt64(exitDuration * 1_000_000_000))

        // 2.55s — elimina overlay
        enterProgress.wrappedValue = 0
        exitProgress.wrappedValue = 0
        isActive.wrappedValue = false
    }
}
