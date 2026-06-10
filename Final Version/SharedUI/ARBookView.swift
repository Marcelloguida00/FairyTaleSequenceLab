import ARKit
import Observation
import QuartzCore
import SceneKit
import SwiftUI
import UIKit

struct ARStoryCard: Identifiable, Hashable {
    let id: String
    let eventID: Int
    let sequenceNumber: Int
    let eventTitle: String
    let imageName: String
    let description: String
}

/// One unlocked chapter of the fairy tale, used to fill the AR book pages.
struct ARStoryChapter: Equatable {
    let title: String
    let text: String
    let imageNames: [String]
}

/// Bridges SwiftUI controls to the SceneKit flip-book coordinator.
@Observable
final class ARFlipBookController {
    var isGeneratingPages = true
    var isPlaced = false
    var surfaceFound = false
    var canForward = false
    var canBackward = false

    @ObservationIgnored var flipForward: () -> Void = {}
    @ObservationIgnored var flipBackward: () -> Void = {}
    @ObservationIgnored var reposition: () -> Void = {}
}

struct ARBookView: View {
    /// Pre-rendered BookView pages (left/right alternating). Using the exact SwiftUI
    /// pages guarantees the AR book looks identical to the on-screen storybook.
    let pageImages: [UIImage]
    let onClose: () -> Void

    @Environment(LanguageManager.self) private var lm
    @State private var controller = ARFlipBookController()

    var body: some View {
        ZStack {
            if ARWorldTrackingConfiguration.isSupported {
                ARFlipBookSceneView(
                    pageImages: pageImages,
                    controller: controller,
                    lm: lm
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, 18)
                        .padding(.top, 18)

                    Spacer()

                    if controller.isGeneratingPages {
                        loadingState
                            .padding(.bottom, 30)
                    } else if pageImages.isEmpty {
                        emptyState
                            .padding(.bottom, 30)
                    } else if controller.isPlaced {
                        pageControls
                            .padding(.bottom, 28)
                    } else {
                        placementHint
                            .padding(.bottom, 30)
                    }
                }
            } else {
                unsupportedDeviceView
            }
        }
    }

    private var header: some View {
        HStack {
            GameCircleBackButton(size: 64) {
                AppSettings.hapticImpact(.light)
                onClose()
            }
            .accessibilityLabel(lm.t("a11y.go_back"))
            
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
    }

    private var loadingState: some View {
        HStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.2)

            Text(lm.t("book.ar.generating_pages"))
                .font(.app(.subheadline, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .padding(.horizontal, 24)
    }

    private var pageControls: some View {
        GameCircleButton(
            systemImage: "arrow.triangle.2.circlepath",
            size: 64
        ) {
            AppSettings.hapticImpact(.light)
            controller.reposition()
        }
        .accessibilityLabel(lm.t("book.ar.reposition"))
    }

    private var placementHint: some View {
        ZStack {
            Image("IslandTitleFrame")
                .resizable()
                .scaledToFit()
                .frame(width: 380, height: 110)
                .shadow(color: .black.opacity(0.22), radius: 6, x: 0, y: 3)
            
            HStack(spacing: 10) {
                Image(systemName: controller.surfaceFound ? "hand.tap.fill" : "viewfinder")
                    .font(.system(.subheadline, weight: .bold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.13))
                    .accessibilityHidden(true)

                Text(placementHintText)
                    .font(.app(size: 15, weight: .semibold))
                    .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.13))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
            }
            .padding(.horizontal, 44)
            .frame(width: 380, height: 110)
        }
        .padding(.horizontal, 24)
    }

    private var placementHintText: String {
        switch lm.currentLanguage {
        case "it":
            return controller.surfaceFound 
                ? "Superficie trovata! Tocca per posizionare il libro."
                : "Muovi il dispositivo per trovare una superficie piana."
        case "es":
            return controller.surfaceFound
                ? "¡Superficie encontrada! Toca para colocar el libro."
                : "Mueve tu dispositivo para encontrar una superficie plana."
        case "pt":
            return controller.surfaceFound
                ? "Superfície encontrada! Toque para posicionar o livro."
                : "Mova o dispositivo para encontrar uma superfície plana."
        case "fa":
            return controller.surfaceFound
                ? "سطح پیدا شد! برای قرار دادن کتاب ضربه بزنید."
                : "دستگاه خود را حرکت دهید تا یک سطح صاف پیدا شود."
        case "zh-Hans":
            return controller.surfaceFound
                ? "已找到平面！轻点屏幕以放置故事书。"
                : "请移动设备以寻找水平面。"
        case "sq":
            return controller.surfaceFound
                ? "U gjet sipërfaqja! Trokit për të vendosur librin."
                : "Muovi pajisjen për të gjetur një sipërfaqe të sheshtë."
        case "ru":
            return controller.surfaceFound
                ? "Поверхность найдена! Нажмите, чтобы разместить книгу."
                : "Перемещайте устройство, чтобы найти ровную поверхность."
        default: // "en"
            return controller.surfaceFound
                ? "Surface found! Tap to place the book."
                : "Move your device to find a flat surface."
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack")
                .font(.system(.largeTitle, design: .default).weight(.semibold))
                .foregroundColor(Color.appAccent)
                .accessibilityHidden(true)

            Text(lm.t("book.ar.empty"))
                .font(.app(.title3, weight: .bold))
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: 430)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appBackground.opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.appBorder.opacity(0.7), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.24), radius: 18, y: 8)
        )
        .padding(.horizontal, 24)
    }

    private var unsupportedDeviceView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "arkit")
                    .font(.system(.largeTitle))
                    .foregroundColor(Color.appAccent)
                    .accessibilityHidden(true)

                Text(lm.t("book.ar.unsupported"))
                    .font(.app(.title3, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)

                GameCircleBackButton(size: 64) { onClose() }
                    .accessibilityLabel(lm.t("a11y.go_back"))
            }
        }
    }
}

// MARK: - SceneKit flip-book

private struct ARFlipBookSceneView: UIViewRepresentable {
    var pageImages: [UIImage]
    var controller: ARFlipBookController
    var lm: LanguageManager

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = SCNScene()
        sceneView.delegate = context.coordinator
        sceneView.session.delegate = context.coordinator
        sceneView.antialiasingMode = .multisampling4X

        context.coordinator.sceneView = sceneView
        context.coordinator.startSession()

        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        sceneView.addGestureRecognizer(tap)

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        sceneView.addGestureRecognizer(pan)

        controller.flipForward = { [weak coordinator = context.coordinator] in
            coordinator?.flipForward()
        }
        controller.flipBackward = { [weak coordinator = context.coordinator] in
            coordinator?.flipBackward()
        }
        controller.reposition = { [weak coordinator = context.coordinator] in
            coordinator?.reposition()
        }

        return sceneView
    }

    func updateUIView(_ sceneView: ARSCNView, context: Context) {
        if context.coordinator.pageImages.count != pageImages.count {
            context.coordinator.pageImages = pageImages
            context.coordinator.rebuildPagesIfPlaced()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            pageImages: pageImages,
            controller: controller,
            lm: lm
        )
    }

    static func dismantleUIView(_ sceneView: ARSCNView, coordinator: Coordinator) {
        sceneView.session.pause()
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        weak var sceneView: ARSCNView?
        let controller: ARFlipBookController
        let lm: LanguageManager

        var pageImages: [UIImage]

        // Geometry constants (meters)
        private let pageW: CGFloat = 0.30
        private let pageD: CGFloat = 0.42
        private let gap: CGFloat = 0.004
        private let coverThk: CGFloat = 0.012
        private let stackH: CGFloat = 0.028
        private let overhang: CGFloat = 0.014

        /// How much the turning page bends (radians of arc, peaks at mid-flip).
        /// 0 = rigid board, ~1.1 = soft paper curl. Tweak on device for taste.
        private let pageCurlAmount: Float = 1.15
        /// Number of segments across the page width — more = smoother bend.
        private let pageSegments = 48

        private var bookNode: SCNNode?
        private var leftPageNode: SCNNode?
        private var rightPageNode: SCNNode?
        private var anchor: ARAnchor?

        private var pageTextures: [UIImage] = []
        private var currentSpread = 0
        private var isFlipping = false
        private var isPlaced = false

        private enum FlipDirection {
            case forward
            case backward
        }

        /// A page-turn currently in flight (driven by `progress` 0→1).
        private struct ActiveFlip {
            let node: SCNNode
            let frontMat: SCNMaterial
            let backMat: SCNMaterial
            let flipSign: Float           // +1 = page turns left, -1 = page turns right
            let completion: () -> Void    // commits destination textures + spread index
        }
        private var activeFlip: ActiveFlip?
        private var activeProgress: Float = 0

        private var parchment: UIImage = UIImage()
        private var contactShadow: UIImage = UIImage()

        private var topY: CGFloat { coverThk + stackH }
        private var halfOffset: CGFloat { pageW / 2 + gap / 2 }
        private var spreadCount: Int { max(1, pageTextures.count / 2) }

        private var isRTL: Bool {
            lm.currentLanguage == "fa"
        }

        init(pageImages: [UIImage],
             controller: ARFlipBookController,
             lm: LanguageManager) {
            self.pageImages = pageImages
            self.controller = controller
            self.lm = lm
            super.init()
            generatePages()
        }

        func startSession() {
            guard let sceneView = sceneView else { return }
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            configuration.environmentTexturing = .automatic
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }

        // MARK: - Page generation
        
        private func generatePages() {
            let shadow = Self.makeContactShadow(size: CGSize(width: 512, height: 512)).scnSafe
            self.contactShadow = shadow

            var textures = pageImages.map { $0.scnSafe }
            if textures.count % 2 != 0 {
                textures.append(Self.makeParchment(size: CGSize(width: 1024, height: 1434)).scnSafe)
            }
            self.pageTextures = textures
            self.parchment = textures.first ?? Self.makeParchment(size: CGSize(width: 1024, height: 1434)).scnSafe

            DispatchQueue.main.async {
                self.controller.isGeneratingPages = false
            }

            if self.isPlaced {
                DispatchQueue.main.async {
                    let s = self.currentSpread
                    if self.isRTL {
                        self.setPageTexture(self.leftPageNode, self.pageTextures[safe: 2 * s + 1])
                        self.setPageTexture(self.rightPageNode, self.pageTextures[safe: 2 * s])
                    } else {
                        self.setPageTexture(self.leftPageNode, self.pageTextures[safe: 2 * s])
                        self.setPageTexture(self.rightPageNode, self.pageTextures[safe: 2 * s + 1])
                    }
                }
            }
        }

        // MARK: Placement

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = sceneView else { return }
            guard !controller.isGeneratingPages else { return }

            let point = gesture.location(in: sceneView)

            // Once the book is placed, pages turn only via a completed drag or the
            // arrow buttons — a stray tap (e.g. an aborted drag) must not flip pages.
            if isPlaced { return }

            guard let query = sceneView.raycastQuery(
                from: point,
                allowing: .estimatedPlane,
                alignment: .horizontal
            ), let result = sceneView.session.raycast(query).first else { return }

            placeBook(at: result.worldTransform)
        }

        private func placeBook(at worldTransform: simd_float4x4) {
            guard let sceneView = sceneView else { return }

            if let anchor = anchor {
                sceneView.session.remove(anchor: anchor)
            }
            bookNode?.removeFromParentNode()
            bookNode = nil

            var transform = worldTransform
            if let camera = sceneView.session.currentFrame?.camera {
                let camPos = camera.transform.columns.3
                let bookPos = worldTransform.columns.3
                let dx = camPos.x - bookPos.x
                let dz = camPos.z - bookPos.z
                let yaw = atan2(dx, dz)
                let c = cos(yaw)
                let s = sin(yaw)
                var rot = matrix_identity_float4x4
                rot.columns.0 = simd_float4(c, 0, -s, 0)
                rot.columns.1 = simd_float4(0, 1, 0, 0)
                rot.columns.2 = simd_float4(s, 0, c, 0)
                transform = rot
                transform.columns.3 = worldTransform.columns.3
            }

            let newAnchor = ARAnchor(name: "flip-book", transform: transform)
            anchor = newAnchor
            currentSpread = 0
            sceneView.session.add(anchor: newAnchor)

            isPlaced = true
            AppSettings.hapticImpact(.medium)
            DispatchQueue.main.async {
                self.controller.isPlaced = true
                self.updateNavState()
            }
        }

        func reposition() {
            guard let sceneView = sceneView else { return }
            if let anchor = anchor {
                sceneView.session.remove(anchor: anchor)
            }
            bookNode?.removeFromParentNode()
            bookNode = nil
            leftPageNode = nil
            rightPageNode = nil
            anchor = nil
            isPlaced = false
            isFlipping = false
            DispatchQueue.main.async {
                self.controller.isPlaced = false
                self.controller.canForward = false
                self.controller.canBackward = false
            }
        }

        func rebuildPagesIfPlaced() {
            generatePages()
        }

        // MARK: Node creation

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard anchor.name == "flip-book" else { return nil }

            let containerNode = SCNNode()

            DispatchQueue.main.async {
                let book = self.buildBook()
                self.bookNode = book
                containerNode.addChildNode(book)
                self.updateNavState()
            }

            return containerNode
        }

        func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
            if anchor is ARPlaneAnchor, controller.surfaceFound == false {
                DispatchQueue.main.async { self.controller.surfaceFound = true }
            }
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            guard !isPlaced else { return }
            guard let sceneView = sceneView else { return }
            
            let center = CGPoint(x: sceneView.bounds.midX, y: sceneView.bounds.midY)
            if let query = sceneView.raycastQuery(from: center, allowing: .estimatedPlane, alignment: .horizontal) {
                let results = session.raycast(query)
                let found = !results.isEmpty
                if controller.surfaceFound != found {
                    DispatchQueue.main.async {
                        self.controller.surfaceFound = found
                    }
                }
            } else {
                if controller.surfaceFound {
                    DispatchQueue.main.async {
                        self.controller.surfaceFound = false
                    }
                }
            }
        }

        private func buildBook() -> SCNNode {
            let book = SCNNode()

            let coverW = 2 * pageW + gap + 2 * overhang
            let coverD = pageD + 2 * overhang

            // Contact shadow sul tavolo.
            let shadowPlane = SCNPlane(width: coverW * 1.7, height: coverD * 1.7)
            let shadowMat = SCNMaterial()
            shadowMat.diffuse.contents = contactShadow
            shadowMat.lightingModel = .constant
            shadowMat.blendMode = .alpha
            shadowMat.writesToDepthBuffer = false
            shadowMat.isDoubleSided = true
            shadowPlane.firstMaterial = shadowMat
            let shadowNode = SCNNode(geometry: shadowPlane)
            shadowNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            shadowNode.position = SCNVector3(0, 0.0008, 0)
            shadowNode.renderingOrder = -10
            book.addChildNode(shadowNode)

            // Copertina rigida.
            let cover = SCNBox(width: coverW, height: coverThk, length: coverD, chamferRadius: 0.0035)
            cover.firstMaterial = leatherMaterial()
            let coverNode = SCNNode(geometry: cover)
            coverNode.position = SCNVector3(0, Float(coverThk / 2), 0)
            book.addChildNode(coverNode)

            // Stack pagine (sinistra e destra).
            let leftStack = SCNNode(geometry: stackBox())
            leftStack.position = SCNVector3(Float(-halfOffset), Float(coverThk + stackH / 2), 0)
            book.addChildNode(leftStack)

            let rightStack = SCNNode(geometry: stackBox())
            rightStack.position = SCNVector3(Float(halfOffset), Float(coverThk + stackH / 2), 0)
            book.addChildNode(rightStack)

            // Dorso.
            let spine = SCNBox(width: gap + 0.003, height: stackH * 0.96, length: pageD, chamferRadius: 0.001)
            spine.firstMaterial = leatherMaterial(darker: true)
            let spineNode = SCNNode(geometry: spine)
            spineNode.position = SCNVector3(0, Float(coverThk + stackH / 2), 0)
            book.addChildNode(spineNode)

            // Pagine visibili (cima di ogni stack).
            let leftTexture = isRTL ? pageTextures[safe: 1] : pageTextures[safe: 0]
            let rightTexture = isRTL ? pageTextures[safe: 0] : pageTextures[safe: 1]
            
            let left = makeStaticPage(texture: leftTexture)
            left.position = SCNVector3(Float(-halfOffset), Float(topY + 0.0006), 0)
            book.addChildNode(left)
            leftPageNode = left

            let right = makeStaticPage(texture: rightTexture)
            right.position = SCNVector3(Float(halfOffset), Float(topY + 0.0006), 0)
            book.addChildNode(right)
            rightPageNode = right

            return book
        }

        private func stackBox() -> SCNBox {
            let box = SCNBox(width: pageW, height: stackH, length: pageD, chamferRadius: 0.0008)
            let cream = SCNMaterial()
            cream.diffuse.contents = UIColor(red: 0.94, green: 0.90, blue: 0.80, alpha: 1)
            cream.roughness.contents = 0.95
            cream.metalness.contents = 0.0
            box.firstMaterial = cream
            return box
        }

        private func makeStaticPage(texture: UIImage?) -> SCNNode {
            // A flat page lying on top of a stack. Built as a subdivided plane so it
            // shares the exact same texture orientation as the (bendable) turning page.
            let plane = SCNPlane(width: pageW, height: pageD)
            let mat = pageMaterial(texture)
            mat.isDoubleSided = true
            plane.firstMaterial = mat
            let node = SCNNode(geometry: plane)
            // Lay the plane flat on the table: +Y normal up, image top toward the far edge.
            node.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
            return node
        }

        private func setPageTexture(_ node: SCNNode?, _ texture: UIImage?) {
            guard let plane = node?.geometry as? SCNPlane,
                  let mat = plane.firstMaterial else { return }
            mat.diffuse.contents = texture ?? parchment
        }

        private func pageMaterial(_ texture: UIImage?) -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = texture ?? parchment
            material.lightingModel = .constant
            material.isDoubleSided = true
            material.diffuse.wrapS = .clamp
            material.diffuse.wrapT = .clamp

            return material
        }

        private func leatherMaterial(darker: Bool = false) -> SCNMaterial {
            let material = SCNMaterial()
            // Blue leather, matching the on-screen book cover (OpenBookBackground).
            material.diffuse.contents = darker
                ? UIColor(red: 0.05, green: 0.15, blue: 0.35, alpha: 1)
                : UIColor(red: 0.10, green: 0.25, blue: 0.50, alpha: 1)
            material.roughness.contents = 0.65
            material.metalness.contents = 0.0
            return material
        }

        // MARK: Flipping (soft page bend)

        /// Drag-to-turn. The page bends like real paper while the finger moves,
        /// and snaps open/closed (or completes/cancels) when the finger lifts.
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            guard isPlaced, let sceneView = sceneView else { return }

            let translation = gesture.translation(in: sceneView)
            let velocity = gesture.velocity(in: sceneView)
            let viewWidth = sceneView.bounds.width > 0 ? sceneView.bounds.width : 375.0
            let threshold = viewWidth * 0.6

            switch gesture.state {
            case .began:
                guard !isFlipping else { return }

                // Decide direction from the initial motion (velocity is reliable here).
                let goingLeft = velocity.x != 0 ? velocity.x < 0 : translation.x < 0
                let direction: FlipDirection = goingLeft
                    ? (isRTL ? .backward : .forward)
                    : (isRTL ? .forward : .backward)
                beginFlip(direction)   // no-op if there is no page that way

            case .changed:
                guard let flip = activeFlip else { return }
                setFlipProgress(panProgress(flip: flip, translation: translation, threshold: threshold))

            case .ended, .cancelled:
                guard let flip = activeFlip else { return }

                let progress = panProgress(flip: flip, translation: translation, threshold: threshold)
                let pageMovesLeft = flip.flipSign > 0
                // Turn only when the gesture is genuinely completed: either the drag
                // crossed most of the page, or it ended with a decisive fling in the
                // turn direction. A drag that stalls short of the threshold snaps back.
                let fling = pageMovesLeft ? velocity.x < -600 : velocity.x > 600
                let shouldComplete = progress > 0.6 || (fling && progress > 0.15)
                // Faster snap when there is little distance left to cover.
                let remaining = shouldComplete ? Double(1 - progress) : Double(progress)
                let duration = max(0.18, remaining * 0.5)
                finishFlip(complete: shouldComplete, duration: duration)

            default:
                break
            }
        }

        /// Maps the horizontal drag onto a 0…1 turn progress for the active page.
        private func panProgress(flip: ActiveFlip, translation: CGPoint, threshold: CGFloat) -> Float {
            let pageMovesLeft = flip.flipSign > 0
            let dragged = pageMovesLeft ? -translation.x : translation.x
            return Float(max(0.0, min(1.0, dragged / threshold)))
        }

        func flipForward() {
            guard beginFlip(.forward) else { return }
            AppSettings.hapticImpact(.light)
            finishFlip(complete: true, duration: 0.7)
        }

        func flipBackward() {
            guard beginFlip(.backward) else { return }
            AppSettings.hapticImpact(.light)
            finishFlip(complete: true, duration: 0.7)
        }

        /// Spawns the bendable turning page for `direction` and records how to commit
        /// the result. Returns false if there is no page to turn that way.
        @discardableResult
        private func beginFlip(_ direction: FlipDirection) -> Bool {
            guard isPlaced, !isFlipping, bookNode != nil else { return false }
            let s = currentSpread

            let flipSign: Float
            let front: UIImage?
            let back: UIImage?
            let applyBehind: () -> Void
            let applyComplete: () -> Void

            switch (direction, isRTL) {
            case (.forward, false):
                guard s < spreadCount - 1 else { return false }
                flipSign = 1
                front = pageTextures[safe: 2 * s + 1]          // current right page
                back  = pageTextures[safe: 2 * s + 2]          // revealed left page
                let nextRight = pageTextures[safe: 2 * s + 3]
                applyBehind = { [weak self] in self?.setPageTexture(self?.rightPageNode, nextRight) }
                applyComplete = { [weak self] in
                    guard let self else { return }
                    self.setPageTexture(self.leftPageNode, back)
                    self.currentSpread += 1
                }

            case (.forward, true):                              // RTL: page on the left turns right
                guard s < spreadCount - 1 else { return false }
                flipSign = -1
                front = pageTextures[safe: 2 * s + 1]
                back  = pageTextures[safe: 2 * s + 2]
                let nextLeft = pageTextures[safe: 2 * s + 3]
                applyBehind = { [weak self] in self?.setPageTexture(self?.leftPageNode, nextLeft) }
                applyComplete = { [weak self] in
                    guard let self else { return }
                    self.setPageTexture(self.rightPageNode, back)
                    self.currentSpread += 1
                }

            case (.backward, false):                            // LTR: page on the left turns right
                guard s > 0 else { return false }
                flipSign = -1
                front = pageTextures[safe: 2 * s]               // current left page
                back  = pageTextures[safe: 2 * s - 1]           // revealed right page
                let prevLeft = pageTextures[safe: 2 * s - 2]
                applyBehind = { [weak self] in self?.setPageTexture(self?.leftPageNode, prevLeft) }
                applyComplete = { [weak self] in
                    guard let self else { return }
                    self.setPageTexture(self.rightPageNode, back)
                    self.currentSpread -= 1
                }

            case (.backward, true):                             // RTL: page on the right turns left
                guard s > 0 else { return false }
                flipSign = 1
                front = pageTextures[safe: 2 * s]
                back  = pageTextures[safe: 2 * s - 1]
                let prevRight = pageTextures[safe: 2 * s - 2]
                applyBehind = { [weak self] in self?.setPageTexture(self?.rightPageNode, prevRight) }
                applyComplete = { [weak self] in
                    guard let self else { return }
                    self.setPageTexture(self.leftPageNode, back)
                    self.currentSpread -= 1
                }
            }

            let (flipperNode, frontMat, backMat) = makeBendingFlipper(front: front, back: back, flipSign: flipSign)
            bookNode?.addChildNode(flipperNode)
            applyBehind()   // reveal the page that sits underneath the turning sheet

            activeFlip = ActiveFlip(node: flipperNode, frontMat: frontMat, backMat: backMat,
                                    flipSign: flipSign, completion: applyComplete)
            isFlipping = true
            setFlipProgress(0)
            return true
        }

        /// Pushes the turn progress (0…1) into the bend shader on both page faces.
        private func setFlipProgress(_ p: Float) {
            activeProgress = max(0, min(1, p))
            let value = NSNumber(value: activeProgress)
            activeFlip?.frontMat.setValue(value, forKey: "progress")
            activeFlip?.backMat.setValue(value, forKey: "progress")
        }

        /// Animates the active page to fully turned (`complete`) or back to rest,
        /// then commits textures and removes the temporary sheet.
        private func finishFlip(complete: Bool, duration: TimeInterval) {
            guard let flip = activeFlip else { isFlipping = false; return }

            let from = activeProgress
            let target: Float = complete ? 1 : 0
            let dur = max(0.12, duration)

            let animate = SCNAction.customAction(duration: dur) { [weak self] _, elapsed in
                guard let self else { return }
                let t = Float(min(1.0, elapsed / CGFloat(dur)))
                let eased = 1 - (1 - t) * (1 - t)            // ease-out
                self.setFlipProgress(from + (target - from) * eased)
            }

            flip.node.runAction(animate) { [weak self] in
                DispatchQueue.main.async {
                    guard let self else { return }
                    if complete {
                        flip.completion()
                        AppSettings.hapticImpact(.light)
                    }
                    flip.node.removeFromParentNode()
                    self.activeFlip = nil
                    self.isFlipping = false
                    self.activeProgress = 0
                    self.updateNavState()
                }
            }
        }

        // MARK: Bendable page construction

        /// Builds the turning sheet: two stacked subdivided planes (front + back face)
        /// that share one bend shader. Back-face culling means only the side currently
        /// facing the camera is drawn, so the correct page shows before/after the fold.
        private func makeBendingFlipper(front: UIImage?, back: UIImage?, flipSign: Float)
            -> (SCNNode, SCNMaterial, SCNMaterial) {
            let flipper = SCNNode()
            flipper.position = SCNVector3(0, Float(topY + 0.0012), 0)

            // Mirror the artwork as needed so text always reads upright:
            // a left-turning sheet (flipSign < 0) is mirrored by the shader, and the
            // back face is seen from behind — both cases need a horizontal flip.
            let frontTex = flipSign < 0 ? front?.flippedHorizontally : front
            let backTex  = flipSign < 0 ? back : back?.flippedHorizontally

            let (frontNode, frontMat) = makeBendablePlane(texture: frontTex, isBack: false, flipSign: flipSign)
            let (backNode, backMat)   = makeBendablePlane(texture: backTex,  isBack: true,  flipSign: flipSign)
            flipper.addChildNode(frontNode)
            flipper.addChildNode(backNode)
            return (flipper, frontMat, backMat)
        }

        private func makeBendablePlane(texture: UIImage?, isBack: Bool, flipSign: Float)
            -> (SCNNode, SCNMaterial) {
            let plane = SCNPlane(width: pageW, height: pageD)
            plane.widthSegmentCount = pageSegments
            plane.heightSegmentCount = 1

            let mat = SCNMaterial()
            mat.diffuse.contents = texture ?? parchment
            mat.lightingModel = .constant
            mat.isDoubleSided = false
            mat.cullMode = isBack ? .front : .back      // each face shows only from its own side
            mat.diffuse.wrapS = .clamp
            mat.diffuse.wrapT = .clamp
            mat.shaderModifiers = [.geometry: Self.pageBendShader]
            mat.setValue(NSNumber(value: Float(0)), forKey: "progress")
            mat.setValue(NSNumber(value: Float(pageW)), forKey: "uPageW")
            mat.setValue(NSNumber(value: pageCurlAmount), forKey: "curlAmount")
            mat.setValue(NSNumber(value: flipSign), forKey: "flipSign")
            mat.setValue(NSNumber(value: Float(gap / 2)), forKey: "innerGap")
            plane.firstMaterial = mat

            let node = SCNNode(geometry: plane)
            node.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)   // lay flat; +Z bend becomes up
            return (node, mat)
        }

        /// Geometry shader: bends a flat page around the spine into a circular arc whose
        /// base angle is the turn angle (progress·π) and whose curvature peaks mid-turn,
        /// so the sheet lifts and curls like paper instead of rotating as a rigid board.
        private static let pageBendShader = """
        #pragma arguments
        float progress;
        float uPageW;
        float curlAmount;
        float flipSign;
        float innerGap;
        #pragma body
        float pi = 3.14159265359;
        float s = _geometry.position.x + uPageW * 0.5;   // 0 at spine, uPageW at free edge
        float phi = progress * pi;                       // overall turn angle
        float curl = sin(phi) * curlAmount;              // bend, 0 at the start/end
        float nx;
        float nz;
        if (abs(curl) < 0.0001) {
            nx = s * cos(phi);
            nz = s * sin(phi);
        } else {
            float kappa = curl / uPageW;                 // constant curvature
            nx = (sin(phi + kappa * s) - sin(phi)) / kappa;
            nz = (cos(phi) - cos(phi + kappa * s)) / kappa;
        }
        // The spine offset must rotate with the page: +innerGap at rest, -innerGap
        // once fully turned, so the sheet lands exactly on the opposite page with
        // no visible seam at the spine.
        nx = flipSign * (nx + innerGap * cos(phi));
        _geometry.position.x = nx;
        _geometry.position.z = nz;                       // out-of-plane lift (becomes world up)
        """

        private func updateNavState() {
            controller.canForward  = isPlaced && currentSpread < spreadCount - 1
            controller.canBackward = isPlaced && currentSpread > 0
        }

        // MARK: Static texture builders

        private static func makeParchment(size: CGSize) -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = true
            format.scale = 1
            return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
                let rect = CGRect(origin: .zero, size: size)
                let cgCtx = ctx.cgContext
                let colors = [
                    UIColor(red: 0.98, green: 0.95, blue: 0.87, alpha: 1).cgColor,
                    UIColor(red: 0.90, green: 0.84, blue: 0.70, alpha: 1).cgColor
                ]
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors as CFArray,
                    locations: [0, 1]
                )!
                cgCtx.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: rect.midX, y: rect.midY * 0.8),
                    startRadius: 0,
                    endCenter: CGPoint(x: rect.midX, y: rect.midY),
                    endRadius: rect.height,
                    options: [.drawsAfterEndLocation]
                )
            }
        }

        private static func makeContactShadow(size: CGSize) -> UIImage {
            let format = UIGraphicsImageRendererFormat()
            format.opaque = false
            format.scale = 1
            return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
                let rect = CGRect(origin: .zero, size: size)
                let cgCtx = ctx.cgContext
                let colors = [
                    UIColor.black.withAlphaComponent(0.42).cgColor,
                    UIColor.black.withAlphaComponent(0.0).cgColor
                ]
                let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors as CFArray,
                    locations: [0.0, 1.0]
                )!
                cgCtx.drawRadialGradient(
                    gradient,
                    startCenter: CGPoint(x: rect.midX, y: rect.midY),
                    startRadius: 0,
                    endCenter: CGPoint(x: rect.midX, y: rect.midY),
                    endRadius: rect.width / 2,
                    options: []
                )
            }
        }
    }
}

// MARK: - UIImage + SceneKit safety

private extension UIImage {
    var scnSafe: UIImage {
        guard let data = self.pngData(), let safeImage = UIImage(data: data) else { return self }
        return safeImage
    }

    /// Mirrored left-to-right. Used so a turning page's back face (seen from behind)
    /// and left-side sheets (mirrored by the bend shader) still read upright.
    var flippedHorizontally: UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = self.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: self.size, format: format).image { ctx in
            let cgCtx = ctx.cgContext
            cgCtx.translateBy(x: self.size.width, y: 0)
            cgCtx.scaleBy(x: -1, y: 1)
            self.draw(in: CGRect(origin: .zero, size: self.size))
        }
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
