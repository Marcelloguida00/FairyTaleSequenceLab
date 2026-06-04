import ARKit
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

struct ARBookView: View {
    let cards: [ARStoryCard]
    let chapterText: String
    let onClose: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var targetIndex = 0
    @State private var showSuccessMessage = false
    @State private var isScanning = true
    @State private var mappingStatus: ARFrame.WorldMappingStatus = .notAvailable

    var body: some View {
        ZStack {
            if ARWorldTrackingConfiguration.isSupported {
                UnlockedCardsARSceneView(
                    cards: cards,
                    chapterText: chapterText,
                    targetIndex: $targetIndex,
                    showSuccessMessage: $showSuccessMessage,
                    isScanning: $isScanning,
                    mappingStatus: $mappingStatus
                )
                .ignoresSafeArea()
            } else {
                unsupportedDeviceView
            }

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                if cards.isEmpty {
                    emptyState
                        .padding(.top, 34)
                }

                Spacer()

                if ARWorldTrackingConfiguration.isSupported, !cards.isEmpty {
                    if isScanning {
                        scanningBanner
                            .padding(.bottom, 26)
                    } else if targetIndex < cards.count {
                        targetBanner
                            .padding(.bottom, 26)
                    } else {
                        completionBanner
                            .padding(.bottom, 26)
                    }
                }
            }
            
            if showSuccessMessage {
                VStack {
                    Spacer()
                    Text(lm.t("ar.scan.correct"))
                        .font(.app(.title, weight: .black))
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(16)
                        .padding(.bottom, 120)
                }
                .transition(.scale.combined(with: .opacity))
                .zIndex(2)
            }
        }
    }

    private var scanningBanner: some View {
        VStack(spacing: 4) {
            Text(lm.t("ar.scan.title"))
                .font(.app(.subheadline, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
            Text(mappingStatusText)
                .font(.app(.headline, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.orange.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }

    private var mappingStatusText: String {
        switch mappingStatus {
        case .notAvailable: return lm.t("ar.scan.not_available")
        case .limited: return lm.t("ar.scan.limited")
        case .extending: return lm.t("ar.scan.extending")
        case .mapped: return lm.t("ar.scan.mapped")
        @unknown default: return ""
        }
    }

    private var targetBanner: some View {
        let targetCard = cards[targetIndex]
        return VStack(spacing: 4) {
            Text(lm.t("ar.scan.find_card"))
                .font(.app(.subheadline, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
            Text("\(targetCard.eventID).\(targetCard.sequenceNumber) - \(targetCard.eventTitle)")
                .font(.app(.headline, weight: .black))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appAccent.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
    
    private var completionBanner: some View {
        VStack(spacing: 4) {
            Text(lm.t("ar.scan.congrats"))
                .font(.app(.title3, weight: .bold))
                .foregroundColor(.white)
            Text(lm.t("ar.scan.found_all"))
                .font(.app(.subheadline, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.green.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(.white.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
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

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 42, weight: .semibold))
                .foregroundColor(Color.appAccent)

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
                    .font(.system(size: 72))
                    .foregroundColor(Color.appAccent)

                Text(lm.t("book.ar.unsupported"))
                    .font(.app(.title3, weight: .bold))
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
            }
        }
    }
}

private struct UnlockedCardsARSceneView: UIViewRepresentable {
    var cards: [ARStoryCard]
    var chapterText: String
    @Binding var targetIndex: Int
    @Binding var showSuccessMessage: Bool
    @Binding var isScanning: Bool
    @Binding var mappingStatus: ARFrame.WorldMappingStatus

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = SCNScene()
        sceneView.delegate = context.coordinator
        sceneView.session.delegate = context.coordinator
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        context.coordinator.sceneView = sceneView
        context.coordinator.setupMap()
        
        return sceneView
    }

    func updateUIView(_ sceneView: ARSCNView, context: Context) {
        context.coordinator.targetIndexBinding = _targetIndex
        context.coordinator.showSuccessMessageBinding = _showSuccessMessage
        context.coordinator.isScanningBinding = _isScanning
        context.coordinator.mappingStatusBinding = _mappingStatus
        
        if context.coordinator.renderedCards != cards {
            context.coordinator.renderedCards = cards
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    static func dismantleUIView(_ sceneView: ARSCNView, coordinator: Coordinator) {
        sceneView.session.pause()
    }

    func addLighting(to root: SCNNode) {
        let ambient = SCNNode()
        ambient.light = SCNLight()
        ambient.light?.type = .ambient
        ambient.light?.intensity = 260
        root.addChildNode(ambient)

        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .omni
        key.light?.intensity = 650
        key.position = SCNVector3(0, 0.7, -0.6)
        root.addChildNode(key)
    }

    func makeCardNode(card: ARStoryCard, index: Int, total: Int) -> SCNNode {
        let root = SCNNode()
        root.name = "unlocked-card-\(card.id)"
        root.position = SCNVector3Zero

        let framePlane = SCNPlane(width: 0.34, height: 0.61)
        framePlane.cornerRadius = 0.022
        framePlane.firstMaterial = makeMaterial(UIColor(red: 0.24, green: 0.10, blue: 0.04, alpha: 1))

        let frame = SCNNode(geometry: framePlane)
        frame.name = "card-frame"
        frame.position = SCNVector3(0, 0, -0.006)
        root.addChildNode(frame)

        let imagePlane = SCNPlane(width: 0.30, height: 0.533)
        imagePlane.cornerRadius = 0.017
        imagePlane.firstMaterial = makeImageMaterial(imageName: card.imageName)

        let cardImage = SCNNode(geometry: imagePlane)
        cardImage.name = "card-image"
        cardImage.position = SCNVector3(0, 0, 0.004)
        root.addChildNode(cardImage)

        let borderPlane = SCNPlane(width: 0.36, height: 0.64)
        borderPlane.cornerRadius = 0.027
        borderPlane.firstMaterial = makeOverlayMaterial(makeBorderTexture())

        let border = SCNNode(geometry: borderPlane)
        border.name = "card-border"
        border.position = SCNVector3(0, 0, 0.008)
        root.addChildNode(border)

        let badgePlane = SCNPlane(width: 0.09, height: 0.036)
        badgePlane.cornerRadius = 0.011
        badgePlane.firstMaterial = makeMaterial(makeBadgeTexture(for: card))

        let badge = SCNNode(geometry: badgePlane)
        badge.name = "card-badge"
        badge.position = SCNVector3(-0.105, 0.24, 0.012)
        root.addChildNode(badge)

        let labelPlane = SCNPlane(width: 0.42, height: 0.15)
        labelPlane.cornerRadius = 0.018
        labelPlane.firstMaterial = makeMaterial(makeLabelTexture(for: card))

        let label = SCNNode(geometry: labelPlane)
        label.name = "card-label"
        label.position = SCNVector3(0, -0.43, 0.014)
        root.addChildNode(label)

        return root
    }



    private func makeMaterial(_ contents: Any) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = contents
        material.diffuse.mipFilter = .none
        material.diffuse.minificationFilter = .linear
        material.diffuse.magnificationFilter = .linear
        material.roughness.contents = 0.72
        material.metalness.contents = 0
        material.lightingModel = .constant
        material.isDoubleSided = true
        return material
    }

    private func makeImageMaterial(imageName: String) -> SCNMaterial {
        let material = SCNMaterial()

        if let image = UIImage(named: imageName) {
            material.diffuse.contents = image
        } else {
            material.diffuse.contents = UIColor(red: 0.86, green: 0.78, blue: 0.58, alpha: 1)
        }

        material.diffuse.mipFilter = .none
        material.diffuse.minificationFilter = .linear
        material.diffuse.magnificationFilter = .linear
        material.lightingModel = .constant
        material.isDoubleSided = true
        material.writesToDepthBuffer = true
        return material
    }

    private func makeOverlayMaterial(_ contents: Any) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = contents
        material.diffuse.mipFilter = .none
        material.diffuse.minificationFilter = .linear
        material.diffuse.magnificationFilter = .linear
        material.lightingModel = .constant
        material.blendMode = .alpha
        material.isDoubleSided = true
        material.writesToDepthBuffer = false
        return material
    }

    private func makeBorderTexture() -> UIImage {
        let size = CGSize(width: 1080, height: 1920)
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 42, dy: 42)
            UIColor.clear.setFill()
            UIRectFill(CGRect(origin: .zero, size: size))

            UIColor(red: 1.0, green: 0.84, blue: 0.20, alpha: 1).setStroke()
            let outerBorder = UIBezierPath(roundedRect: rect, cornerRadius: 76)
            outerBorder.lineWidth = 44
            outerBorder.stroke()

            UIColor.white.withAlphaComponent(0.9).setStroke()
            let innerBorder = UIBezierPath(roundedRect: rect.insetBy(dx: 38, dy: 38), cornerRadius: 48)
            innerBorder.lineWidth = 10
            innerBorder.stroke()
        }
    }

    private func makeBadgeTexture(for card: ARStoryCard) -> UIImage {
        let size = CGSize(width: 360, height: 144)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.02, green: 0.04, blue: 0.06, alpha: 0.94).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 42).fill()

            drawText(
                "\(card.eventID).\(card.sequenceNumber)",
                in: rect.insetBy(dx: 24, dy: 22),
                font: UIFont.systemFont(ofSize: 64, weight: .heavy),
                color: .white,
                alignment: .center
            )
        }
    }

    private func makeLabelTexture(for card: ARStoryCard) -> UIImage {
        let size = CGSize(width: 1680, height: 600)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.015, green: 0.028, blue: 0.045, alpha: 0.96).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 46).fill()

            UIColor(red: 0.47, green: 0.78, blue: 0.98, alpha: 1).setStroke()
            let border = UIBezierPath(roundedRect: rect.insetBy(dx: 12, dy: 12), cornerRadius: 38)
            border.lineWidth = 8
            border.stroke()

            drawText(
                card.eventTitle,
                in: CGRect(x: 88, y: 62, width: rect.width - 176, height: 96),
                font: UIFont.systemFont(ofSize: 64, weight: .heavy),
                color: UIColor(red: 0.80, green: 0.92, blue: 1.0, alpha: 1),
                alignment: .center
            )

            drawText(
                card.description.truncatedForARLabel,
                in: CGRect(x: 96, y: 192, width: rect.width - 192, height: 300),
                font: UIFont.systemFont(ofSize: 76, weight: .bold),
                color: .white,
                alignment: .center
            )
        }
    }

    private func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        color: UIColor,
        alignment: NSTextAlignment
    ) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = alignment
        paragraph.lineSpacing = 7
        paragraph.lineBreakMode = .byTruncatingTail

        let attributed = NSAttributedString(
            string: text,
            attributes: [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: paragraph
            ]
        )

        attributed.draw(with: rect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
    }

    private func drawAspectFill(_ image: UIImage, in rect: CGRect) {
        let imageSize = image.size
        guard imageSize.width > 0, imageSize.height > 0 else { return }

        let scale = max(rect.width / imageSize.width, rect.height / imageSize.height)
        let drawSize = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        let drawOrigin = CGPoint(
            x: rect.midX - drawSize.width / 2,
            y: rect.midY - drawSize.height / 2
        )

        image.draw(in: CGRect(origin: drawOrigin, size: drawSize))
    }

    final class Coordinator: NSObject, ARSCNViewDelegate, ARSessionDelegate {
        var parent: UnlockedCardsARSceneView
        var renderedCards: [ARStoryCard] = []
        var targetIndexBinding: Binding<Int>?
        var showSuccessMessageBinding: Binding<Bool>?
        var isScanningBinding: Binding<Bool>?
        var mappingStatusBinding: Binding<ARFrame.WorldMappingStatus>?
        weak var sceneView: ARSCNView?
        var cardNodes: [SCNNode] = []
        private var hasPlacedCards = false

        init(_ parent: UnlockedCardsARSceneView) {
            self.parent = parent
            super.init()
        }

        func setupMap() {
            guard let sceneView = sceneView else { return }
            sceneView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }
            parent.addLighting(to: sceneView.scene.rootNode)
            
            let configuration = ARWorldTrackingConfiguration()
            configuration.planeDetection = [.horizontal]
            configuration.environmentTexturing = .automatic
            
            DispatchQueue.main.async {
                self.isScanningBinding?.wrappedValue = true
            }
            hasPlacedCards = false
            
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        }

        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            DispatchQueue.main.async {
                self.mappingStatusBinding?.wrappedValue = frame.worldMappingStatus
            }
            
            if isScanningBinding?.wrappedValue == true, frame.camera.trackingState == .normal {
                if frame.worldMappingStatus == .mapped || frame.worldMappingStatus == .extending {
                    self.placeCardsIfNeeded(session: session)
                }
            }
        }
        
        private func placeCardsIfNeeded(session: ARSession) {
            guard !hasPlacedCards, let sceneView = sceneView else { return }
            hasPlacedCards = true
            DispatchQueue.main.async {
                self.isScanningBinding?.wrappedValue = false
            }
            
            // Place a single anchor for the chapter gallery directly in front of the user
            guard let camera = session.currentFrame?.camera else { return }
            
            let cameraPos = camera.transform.columns.3
            let cameraEulerY = camera.eulerAngles[1] // Yaw
            
            var transform = matrix_identity_float4x4
            // Rotate around Y axis to face exactly the same direction as the camera
            transform.columns.0 = simd_float4(cos(cameraEulerY), 0, -sin(cameraEulerY), 0)
            transform.columns.1 = simd_float4(0, 1, 0, 0)
            transform.columns.2 = simd_float4(sin(cameraEulerY), 0, cos(cameraEulerY), 0)
            
            // Move 1.2 meters away in the direction the camera is facing horizontally
            let distance: Float = 1.2
            transform.columns.3 = simd_float4(
                cameraPos.x - sin(cameraEulerY) * distance,
                cameraPos.y, // Keep at camera height
                cameraPos.z - cos(cameraEulerY) * distance,
                1
            )
            
            let anchor = ARAnchor(name: "chapter-gallery", transform: transform)
            session.add(anchor: anchor)
        }

        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            guard anchor.name == "chapter-gallery" else { return nil }
            
            let containerNode = SCNNode()
            
            // Layout 4 cards side by side
            let cardWidth: Float = 0.36
            let spacing: Float = 0.06
            let totalCards = renderedCards.prefix(4).count
            let totalWidth = Float(totalCards) * cardWidth + Float(totalCards - 1) * spacing
            let startX = -totalWidth / 2.0 + cardWidth / 2.0
            
            for (index, card) in renderedCards.prefix(4).enumerated() {
                let cardNode = parent.makeCardNode(card: card, index: index, total: totalCards)
                // Orient cards to face the camera (which is +Z relative to the anchor)
                // In SCNNode, local front is +Z. To face the camera (which is in +Z direction), they should have Y rotation 0
                cardNode.position = SCNVector3(startX + Float(index) * (cardWidth + spacing), 0, 0)
                containerNode.addChildNode(cardNode)
                cardNodes.append(cardNode)
            }
            
            // Add Chapter Text below the cards
            let textNode = makeChapterTextNode(text: parent.chapterText)
            textNode.position = SCNVector3(0, -0.6, 0.05)
            containerNode.addChildNode(textNode)
            
            return containerNode
        }
        
        private func makeChapterTextNode(text: String) -> SCNNode {
            let container = SCNNode()
            
            let panelWidth: CGFloat = 1.6
            let panelHeight: CGFloat = 0.5
            let panel = SCNPlane(width: panelWidth, height: panelHeight)
            panel.cornerRadius = 0.05
            
            // Render text to a UIImage to avoid freezing SceneKit with complex SCNText geometry
            let size = CGSize(width: 1600, height: 500)
            let format = UIGraphicsImageRendererFormat()
            format.opaque = false
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            
            let image = renderer.image { _ in
                let rect = CGRect(origin: .zero, size: size)
                
                // Background
                UIColor.black.withAlphaComponent(0.85).setFill()
                UIBezierPath(roundedRect: rect, cornerRadius: 50).fill()
                
                let textRect = rect.insetBy(dx: 60, dy: 60)
                
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .center
                paragraph.lineSpacing = 12
                paragraph.lineBreakMode = .byWordWrapping
                
                let attributed = NSAttributedString(
                    string: text,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 42, weight: .medium),
                        .foregroundColor: UIColor.white,
                        .paragraphStyle: paragraph
                    ]
                )
                
                attributed.draw(with: textRect, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
            }
            
            let material = SCNMaterial()
            material.diffuse.contents = image
            material.lightingModel = .constant
            material.isDoubleSided = true
            panel.firstMaterial = material
            
            let panelNode = SCNNode(geometry: panel)
            panelNode.position = SCNVector3(0, 0, 0)
            container.addChildNode(panelNode)
            
            return container
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = sceneView,
                  let targetIndex = targetIndexBinding?.wrappedValue,
                  targetIndex < renderedCards.count else { return }

            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [.boundingBoxOnly: true])
            
            for hit in hitResults {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name, name.hasPrefix("unlocked-card-") {
                        let cardId = name.replacingOccurrences(of: "unlocked-card-", with: "")
                        let targetCard = renderedCards[targetIndex]
                        
                        if cardId == targetCard.id {
                            targetIndexBinding?.wrappedValue += 1
                            AppSettings.hapticImpact(.heavy)
                            showSuccessFeedback()
                            
                            let scaleUp = SCNAction.scale(to: 1.3, duration: 0.2)
                            let scaleDown = SCNAction.scale(to: 1.0, duration: 0.2)
                            let seq = SCNAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
                            current.runAction(seq)
                            return
                        } else {
                            AppSettings.hapticImpact(.light)
                            let moveLeft = SCNAction.moveBy(x: -0.05, y: 0, z: 0, duration: 0.05)
                            let moveRight = SCNAction.moveBy(x: 0.1, y: 0, z: 0, duration: 0.1)
                            let moveCenter = SCNAction.moveBy(x: -0.05, y: 0, z: 0, duration: 0.05)
                            current.runAction(.sequence([moveLeft, moveRight, moveCenter]))
                            return
                        }
                    }
                    node = current.parent
                }
            }
        }
        
        private func showSuccessFeedback() {
            showSuccessMessageBinding?.wrappedValue = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    self.showSuccessMessageBinding?.wrappedValue = false
                }
            }
        }
    }
}
private extension String {
    var truncatedForARLabel: String {
        guard count > 118 else { return self }
        return String(prefix(115)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}
