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
                    controller: controller
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
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lm.t("book.ar.title"))
                    .font(.app(.headline, weight: .black))
                    .foregroundColor(.white)

                Text(lm.t("book.ar.body"))
                    .font(.app(.caption))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            GameCircleBackButton(size: 72) {
                AppSettings.hapticImpact(.light)
                onClose()
            }
            .accessibilityLabel(lm.t("a11y.go_back"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.78))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.24), lineWidth: 1)
                )
        )
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
        HStack(spacing: 22) {
            GameCircleButton(
                systemImage: "chevron.left",
                size: 64,
                isDisabled: !controller.canBackward
            ) {
                controller.flipBackward()
            }
            .accessibilityLabel(lm.t("book.ar.prev_page"))

            GameCircleButton(
                systemImage: "arrow.triangle.2.circlepath",
                size: 56
            ) {
                AppSettings.hapticImpact(.light)
                controller.reposition()
            }
            .accessibilityLabel(lm.t("book.ar.reposition"))

            GameCircleButton(
                systemImage: "chevron.right",
                size: 64,
                isDisabled: !controller.canForward
            ) {
                controller.flipForward()
            }
            .accessibilityLabel(lm.t("book.ar.next_page"))
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
        .background(
            Capsule()
                .fill(.black.opacity(0.7))
                .overlay(Capsule().stroke(.white.opacity(0.2), lineWidth: 1))
        )
    }

    private var placementHint: some View {
        HStack(spacing: 12) {
            Image(systemName: controller.surfaceFound ? "hand.tap.fill" : "viewfinder")
                .font(.system(.title3, weight: .bold))
                .foregroundColor(.white)
                .accessibilityHidden(true)

            Text(controller.surfaceFound
                 ? lm.t("book.ar.tap_to_place")
                 : lm.t("book.ar.searching_surface"))
                .font(.app(.subheadline, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.orange.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
        .padding(.horizontal, 24)
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
            controller: controller
        )
    }

    static func dismantleUIView(_ sceneView: ARSCNView, coordinator: Coordinator) {
        sceneView.session.pause()
    }

    // MARK: Coordinator

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        weak var sceneView: ARSCNView?
        let controller: ARFlipBookController

        var pageImages: [UIImage]

        // Geometry constants (meters)
        private let pageW: CGFloat = 0.15
        private let pageD: CGFloat = 0.21
        private let gap: CGFloat = 0.006
        private let coverThk: CGFloat = 0.006
        private let stackH: CGFloat = 0.014
        private let overhang: CGFloat = 0.007

        private var bookNode: SCNNode?
        private var leftPageNode: SCNNode?
        private var rightPageNode: SCNNode?
        private var anchor: ARAnchor?

        private var pageTextures: [UIImage] = []
        private var currentSpread = 0
        private var isFlipping = false
        private var isPlaced = false

        private var parchment: UIImage = UIImage()
        private var contactShadow: UIImage = UIImage()

        private var topY: CGFloat { coverThk + stackH }
        private var halfOffset: CGFloat { pageW / 2 + gap / 2 }
        private var spreadCount: Int { max(1, pageTextures.count / 2) }

        init(pageImages: [UIImage],
             controller: ARFlipBookController) {
            self.pageImages = pageImages
            self.controller = controller
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

            // Le pagine sono già renderizzate da SwiftUI (identiche a BookView):
            // le serializziamo per SceneKit e le impaginiamo a coppie (sinistra/destra).
            var textures = pageImages.map { $0.scnSafe }
            if textures.count % 2 != 0 {
                textures.append(Self.makeParchment(size: CGSize(width: 1024, height: 1434)).scnSafe)
            }
            self.pageTextures = textures
            // Fallback usato solo se una texture manca.
            self.parchment = textures.first ?? Self.makeParchment(size: CGSize(width: 1024, height: 1434)).scnSafe

            DispatchQueue.main.async {
                self.controller.isGeneratingPages = false
            }

            if self.isPlaced {
                DispatchQueue.main.async {
                    let s = self.currentSpread
                    self.setPageTexture(self.leftPageNode, self.pageTextures[safe: 2 * s])
                    self.setPageTexture(self.rightPageNode, self.pageTextures[safe: 2 * s + 1])
                }
            }
        }

        // MARK: Placement

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = sceneView else { return }
            guard !controller.isGeneratingPages else { return }

            let point = gesture.location(in: sceneView)

            if isPlaced {
                if point.x < sceneView.bounds.midX {
                    flipBackward()
                } else {
                    flipForward()
                }
                return
            }

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
            let left = makeStaticPage(texture: pageTextures[safe: 0])
            left.position = SCNVector3(Float(-halfOffset), Float(topY + 0.0006), 0)
            book.addChildNode(left)
            leftPageNode = left

            let right = makeStaticPage(texture: pageTextures[safe: 1])
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
            let box = SCNBox(width: pageW, height: 0.0008, length: pageD, chamferRadius: 0)
            box.materials = pageBoxMaterials(top: texture, bottom: nil)
            return SCNNode(geometry: box)
        }

        private func pageBoxMaterials(top: UIImage?, bottom: UIImage?) -> [SCNMaterial] {
            // L'ordine delle facce di SCNBox non è affidabile tra dispositivi/versioni:
            // invece di indovinare quale indice corrisponde alla faccia visibile (+Y),
            // applichiamo la texture della pagina a TUTTE le facce. Le facce-bordo sono
            // spesse 0.0008 m (invisibili), quindi non c'è alcun effetto collaterale, e
            // la faccia rivolta verso la camera mostra sempre il contenuto della pagina.
            let topMat = pageMaterial(top)
            let backMat = bottom != nil ? pageMaterial(bottom) : topMat
            // Tutte le facce mostrano il fronte, tranne la faccia inferiore (-Y) che mostra il retro.
            return [topMat, topMat, topMat, topMat, topMat, backMat]
        }

        private func setPageTexture(_ node: SCNNode?, _ texture: UIImage?) {
            guard let box = node?.geometry as? SCNBox else { return }
            let mat = pageMaterial(texture)
            // Applica la texture a tutte le facce così è visibile a prescindere dall'orientamento.
            for i in 0..<box.materials.count {
                box.materials[i] = mat
            }
        }

        private func edgeMaterial() -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = UIColor(red: 0.94, green: 0.90, blue: 0.80, alpha: 1)
            material.lightingModel = .constant
            return material
        }

        private func pageMaterial(_ texture: UIImage?) -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = texture ?? parchment
            material.lightingModel = .constant
            material.isDoubleSided = true
            material.diffuse.wrapS = .clamp
            material.diffuse.wrapT = .clamp

            // FIX #3: Traslazione al centro -> Rotazione -> Traslazione all'origine
            var transform = SCNMatrix4MakeTranslation(-0.5, -0.5, 0)
            transform = SCNMatrix4Rotate(transform, Float.pi, 0, 0, 1)
            transform = SCNMatrix4Translate(transform, 0.5, 0.5, 0)
            
            material.diffuse.contentsTransform = transform

            return material
        }

        private func leatherMaterial(darker: Bool = false) -> SCNMaterial {
            let material = SCNMaterial()
            material.diffuse.contents = darker
                ? UIColor(red: 0.32, green: 0.05, blue: 0.06, alpha: 1)
                : UIColor(red: 0.46, green: 0.09, blue: 0.10, alpha: 1)
            material.roughness.contents = 0.65
            material.metalness.contents = 0.0
            return material
        }

        // MARK: Flipping

        func flipForward() {
            guard isPlaced, !isFlipping, currentSpread < spreadCount - 1 else { return }
            let s = currentSpread
            let curRight  = pageTextures[safe: 2 * s + 1]
            let nextLeft  = pageTextures[safe: 2 * s + 2]
            let nextRight = pageTextures[safe: 2 * s + 3]

            isFlipping = true
            AppSettings.hapticImpact(.light)

            setPageTexture(rightPageNode, nextRight)

            let flipper = makeFlipper(frontTexture: curRight, backTexture: nextLeft)
            flipper.eulerAngles = SCNVector3(0, 0, 0)
            bookNode?.addChildNode(flipper)

            let rotate = SCNAction.rotate(by: .pi, around: SCNVector3(0, 0, 1), duration: 0.8)
            rotate.timingMode = .easeInEaseOut
            flipper.runAction(rotate) { [weak self] in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.setPageTexture(self.leftPageNode, nextLeft)
                    flipper.removeFromParentNode()
                    self.currentSpread += 1
                    self.isFlipping = false
                    self.updateNavState()
                }
            }
        }

        func flipBackward() {
            guard isPlaced, !isFlipping, currentSpread > 0 else { return }
            let s = currentSpread
            let curLeft  = pageTextures[safe: 2 * s]
            let prevLeft = pageTextures[safe: 2 * s - 2]
            let prevRight = pageTextures[safe: 2 * s - 1]

            isFlipping = true
            AppSettings.hapticImpact(.light)

            setPageTexture(leftPageNode, prevLeft)

            let flipper = makeFlipper(frontTexture: prevRight, backTexture: curLeft)
            flipper.eulerAngles = SCNVector3(0, 0, Float.pi)
            bookNode?.addChildNode(flipper)

            let rotate = SCNAction.rotate(by: -.pi, around: SCNVector3(0, 0, 1), duration: 0.8)
            rotate.timingMode = .easeInEaseOut
            flipper.runAction(rotate) { [weak self] in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.setPageTexture(self.rightPageNode, prevRight)
                    flipper.removeFromParentNode()
                    self.currentSpread -= 1
                    self.isFlipping = false
                    self.updateNavState()
                }
            }
        }

        private func makeFlipper(frontTexture: UIImage?, backTexture: UIImage?) -> SCNNode {
            let flipper = SCNNode()
            flipper.position = SCNVector3(0, Float(topY + 0.0012), 0)

            let box = SCNBox(width: pageW, height: 0.0008, length: pageD, chamferRadius: 0)
            box.materials = pageBoxMaterials(top: frontTexture, bottom: backTexture)
            let paper = SCNNode(geometry: box)
            paper.position = SCNVector3(Float(halfOffset), 0, 0)

            flipper.addChildNode(paper)
            return flipper
        }

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
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
