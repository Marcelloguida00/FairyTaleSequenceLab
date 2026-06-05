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
    @State private var isScanning = true
    @State private var mappingStatus: ARFrame.WorldMappingStatus = .notAvailable

    var body: some View {
        ZStack {
            if ARWorldTrackingConfiguration.isSupported {
                UnlockedCardsARSceneView(
                    cards: cards,
                    chapterText: chapterText,
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
                    }
                }
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
    @Binding var isScanning: Bool
    @Binding var mappingStatus: ARFrame.WorldMappingStatus

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = SCNScene()
        sceneView.delegate = context.coordinator
        sceneView.session.delegate = context.coordinator
        

        
        context.coordinator.sceneView = sceneView
        context.coordinator.setupMap()
        
        return sceneView
    }

    func updateUIView(_ sceneView: ARSCNView, context: Context) {
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

        let imagePlane = SCNPlane(width: 0.36, height: 0.64)
        imagePlane.cornerRadius = 0.017
        imagePlane.firstMaterial = makeImageMaterial(imageName: card.imageName)

        let cardImage = SCNNode(geometry: imagePlane)
        cardImage.name = "card-image"
        cardImage.position = SCNVector3(0, 0, 0.004)
        root.addChildNode(cardImage)

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
            let size = image.size
            let format = UIGraphicsImageRendererFormat()
            format.opaque = false
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            
            let maskedImage = renderer.image { ctx in
                let cgCtx = ctx.cgContext
                let rect = CGRect(origin: .zero, size: size)
                
                // Draw elliptical radial gradient mask
                cgCtx.saveGState()
                cgCtx.translateBy(x: rect.midX, y: rect.midY)
                cgCtx.scaleBy(x: 1.0, y: rect.height / rect.width)
                
                let colors = [UIColor.black.cgColor, UIColor.clear.cgColor]
                let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.65, 0.95])!
                
                cgCtx.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: rect.width / 2, options: [.drawsBeforeStartLocation])
                cgCtx.restoreGState()
                
                // Blend image inside mask
                cgCtx.setBlendMode(.sourceIn)
                image.draw(in: rect)
            }
            material.diffuse.contents = maskedImage
        } else {
            material.diffuse.contents = UIColor.clear
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
        var isScanningBinding: Binding<Bool>?
        var mappingStatusBinding: Binding<ARFrame.WorldMappingStatus>?
        weak var sceneView: ARSCNView?
        var cardNodes: [SCNNode] = []
        private var hasPlacedCards = false

        var bookBackgroundImage: UIImage?
        
        init(_ parent: UnlockedCardsARSceneView) {
            self.parent = parent
            super.init()
            
            // Generate a reliable book texture using CoreGraphics
            let bgSize = CGSize(width: 1800, height: 1200)
            let imgRenderer = UIGraphicsImageRenderer(size: bgSize)
            self.bookBackgroundImage = imgRenderer.image { ctx in
                let w = bgSize.width
                let h = bgSize.height
                let pw = w / 2
                
                let cgCtx = ctx.cgContext
                
                // Leather Cover Gradient
                let coverRect = CGRect(x: 20, y: 20, width: w - 40, height: h - 40)
                let coverPath = UIBezierPath(roundedRect: coverRect, cornerRadius: 30)
                cgCtx.saveGState()
                coverPath.addClip()
                let coverColors = [UIColor(red: 0.1, green: 0.15, blue: 0.3, alpha: 1).cgColor,
                                   UIColor(red: 0.05, green: 0.08, blue: 0.18, alpha: 1).cgColor]
                let coverGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: coverColors as CFArray, locations: [0, 1])!
                cgCtx.drawLinearGradient(coverGrad, start: CGPoint(x: 20, y: 20), end: CGPoint(x: w, y: h), options: [])
                cgCtx.restoreGState()
                
                // Parchment Gradient
                let parchmentColors = [UIColor(red: 0.98, green: 0.94, blue: 0.86, alpha: 1).cgColor,
                                       UIColor(red: 0.85, green: 0.78, blue: 0.65, alpha: 1).cgColor]
                let parchGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: parchmentColors as CFArray, locations: [0, 1])!
                
                // Left page stack
                for i in 0...3 {
                    let rect = CGRect(x: 40 - CGFloat(i*2), y: 40 + CGFloat(i*2), width: pw - 40, height: h - 80)
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
                    
                    cgCtx.saveGState()
                    path.addClip()
                    cgCtx.drawRadialGradient(parchGrad, startCenter: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0, endCenter: CGPoint(x: rect.midX, y: rect.midY), endRadius: rect.width, options: [])
                    if let watermark = UIImage(named: "FairyTaleBackground.jpg") ?? UIImage(named: "FairyTaleBackground") {
                        watermark.draw(in: rect, blendMode: .multiply, alpha: 0.12)
                    }
                    drawCornerFlourishes(in: rect, ctx: cgCtx)
                    cgCtx.restoreGState()
                    
                    UIColor.black.withAlphaComponent(0.15).setStroke()
                    path.stroke()
                }
                
                // Right page stack
                for i in 0...3 {
                    let rect = CGRect(x: pw + CGFloat(i*2), y: 40 + CGFloat(i*2), width: pw - 40, height: h - 80)
                    let path = UIBezierPath(roundedRect: rect, cornerRadius: 8)
                    
                    cgCtx.saveGState()
                    path.addClip()
                    cgCtx.drawRadialGradient(parchGrad, startCenter: CGPoint(x: rect.midX, y: rect.midY), startRadius: 0, endCenter: CGPoint(x: rect.midX, y: rect.midY), endRadius: rect.width, options: [])
                    if let watermark = UIImage(named: "FairyTaleBackground.jpg") ?? UIImage(named: "FairyTaleBackground") {
                        watermark.draw(in: rect, blendMode: .multiply, alpha: 0.12)
                    }
                    drawCornerFlourishes(in: rect, ctx: cgCtx)
                    cgCtx.restoreGState()
                    
                    UIColor.black.withAlphaComponent(0.15).setStroke()
                    path.stroke()
                }
                
                // Spine Shadow
                let spineRect = CGRect(x: pw - 30, y: 30, width: 60, height: h - 60)
                let spineColors = [UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor, UIColor.clear.cgColor]
                let spineGrad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: spineColors as CFArray, locations: [0, 0.5, 1])!
                cgCtx.saveGState()
                UIBezierPath(rect: spineRect).addClip()
                cgCtx.drawLinearGradient(spineGrad, start: CGPoint(x: pw - 30, y: 0), end: CGPoint(x: pw + 30, y: 0), options: [])
                cgCtx.restoreGState()
            }
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
                // Spawn immediately when tracking is normal to avoid getting stuck scanning
                self.placeCardsIfNeeded(session: session)
            }
        }
        
        private func placeCardsIfNeeded(session: ARSession) {
            guard !hasPlacedCards, sceneView != nil else { return }
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
            
            // --- 1. Book Background Plane ---
            let bookWidth: Float = 1.8
            let bookHeight: Float = 1.2
            let bookPlane = SCNPlane(width: CGFloat(bookWidth), height: CGFloat(bookHeight))
            bookPlane.cornerRadius = 0.05
            
            let bgMaterial = SCNMaterial()
            if let bgImage = bookBackgroundImage {
                bgMaterial.diffuse.contents = bgImage
            }
            bgMaterial.lightingModel = .constant
            bgMaterial.isDoubleSided = true
            bookPlane.firstMaterial = bgMaterial
            
            let bookNode = SCNNode(geometry: bookPlane)
            // Tilt the book back slightly so it's readable
            bookNode.eulerAngles = SCNVector3(-Float.pi / 8, 0, 0)
            containerNode.addChildNode(bookNode)
            
            // --- 2. Left & Right Page: Checkerboard Layout ---
            let leftPageCenterX: Float = -bookWidth / 4.0
            let rightPageCenterX: Float = bookWidth / 4.0
            let cards = Array(renderedCards.prefix(4))
            
            // Split chapter text into 4 chunks
            let words = parent.chapterText.split(separator: " ")
            let wordsPerChunk = Int(ceil(Double(words.count) / 4.0))
            var textChunks: [String] = []
            for i in 0..<4 {
                let start = i * wordsPerChunk
                let end = min((i + 1) * wordsPerChunk, words.count)
                if start < words.count {
                    textChunks.append(words[start..<end].joined(separator: " "))
                } else {
                    textChunks.append("")
                }
            }
            
            // Q1: Left Page, Top Left (Image 1)
            // Q2: Left Page, Top Right (Text 1)
            // Q3: Left Page, Bottom Left (Text 2)
            // Q4: Left Page, Bottom Right (Image 2)
            // Q5: Right Page, Top Left (Text 3)
            // Q6: Right Page, Top Right (Image 3)
            // Q7: Right Page, Bottom Left (Image 4)
            // Q8: Right Page, Bottom Right (Text 4)
            
            let dx: Float = 0.20
            let dy: Float = 0.28
            
            // Define positions for the 4 images and 4 texts
            let positions: [(isImage: Bool, pos: SCNVector3)] = [
                (true, SCNVector3(leftPageCenterX - dx, dy, 0.02)),  // Image 1
                (false, SCNVector3(leftPageCenterX + dx, dy, 0.02)), // Text 1
                (false, SCNVector3(leftPageCenterX - dx, -dy, 0.02)),// Text 2
                (true, SCNVector3(leftPageCenterX + dx, -dy, 0.02)), // Image 2
                (false, SCNVector3(rightPageCenterX - dx, dy, 0.02)),// Text 3
                (true, SCNVector3(rightPageCenterX + dx, dy, 0.02)), // Image 3
                (true, SCNVector3(rightPageCenterX - dx, -dy, 0.02)),// Image 4
                (false, SCNVector3(rightPageCenterX + dx, -dy, 0.02))// Text 4
            ]
            
            var cardIdx = 0
            var textIdx = 0
            
            for item in positions {
                if item.isImage {
                    if cardIdx < cards.count {
                        let cardNode = parent.makeCardNode(card: cards[cardIdx], index: cardIdx, total: 4)
                        cardNode.scale = SCNVector3(0.85, 0.85, 0.85)
                        cardNode.position = item.pos
                        bookNode.addChildNode(cardNode)
                        cardNodes.append(cardNode)
                        cardIdx += 1
                    }
                } else {
                    if textIdx < textChunks.count {
                        let textNode = makeChapterTextNode(text: textChunks[textIdx])
                        textNode.position = item.pos
                        bookNode.addChildNode(textNode)
                        textIdx += 1
                    }
                }
            }
            
            return containerNode
        }
        
        private func drawCornerFlourishes(in rect: CGRect, ctx: CGContext) {
            let color = UIColor(red: 0.76, green: 0.6, blue: 0.3, alpha: 0.6).cgColor
            let padding: CGFloat = 30
            let size: CGFloat = 40
            
            ctx.setFillColor(color)
            
            // Helper to draw a decorative leaf/diamond in the corner
            func drawLeaf(at point: CGPoint) {
                let path = UIBezierPath()
                path.move(to: CGPoint(x: point.x, y: point.y - size/2))
                path.addQuadCurve(to: CGPoint(x: point.x + size/2, y: point.y), controlPoint: CGPoint(x: point.x + size/4, y: point.y - size/4))
                path.addQuadCurve(to: CGPoint(x: point.x, y: point.y + size/2), controlPoint: CGPoint(x: point.x + size/4, y: point.y + size/4))
                path.addQuadCurve(to: CGPoint(x: point.x - size/2, y: point.y), controlPoint: CGPoint(x: point.x - size/4, y: point.y + size/4))
                path.addQuadCurve(to: CGPoint(x: point.x, y: point.y - size/2), controlPoint: CGPoint(x: point.x - size/4, y: point.y - size/4))
                path.fill()
            }
            
            drawLeaf(at: CGPoint(x: rect.minX + padding, y: rect.minY + padding))
            drawLeaf(at: CGPoint(x: rect.maxX - padding, y: rect.minY + padding))
            drawLeaf(at: CGPoint(x: rect.minX + padding, y: rect.maxY - padding))
            drawLeaf(at: CGPoint(x: rect.maxX - padding, y: rect.maxY - padding))
        }
        
        private func makeChapterTextNode(text: String) -> SCNNode {
            let container = SCNNode()
            
            let panelWidth: CGFloat = 0.38
            let panelHeight: CGFloat = 0.52
            let panel = SCNPlane(width: panelWidth, height: panelHeight)
            panel.cornerRadius = 0.02
            
            // Render text to a UIImage
            let size = CGSize(width: 400, height: 550)
            let format = UIGraphicsImageRendererFormat()
            format.opaque = false
            format.scale = 1
            let renderer = UIGraphicsImageRenderer(size: size, format: format)
            
            let image = renderer.image { _ in
                let rect = CGRect(origin: .zero, size: size)
                UIColor.clear.setFill()
                UIBezierPath(rect: rect).fill()
                
                let textRect = rect.insetBy(dx: 15, dy: 15)
                
                let paragraph = NSMutableParagraphStyle()
                paragraph.alignment = .left
                paragraph.lineSpacing = 6
                paragraph.lineBreakMode = .byWordWrapping
                
                let attributed = NSAttributedString(
                    string: text,
                    attributes: [
                        .font: UIFont.systemFont(ofSize: 26, weight: .semibold),
                        .foregroundColor: UIColor(red: 0.3, green: 0.15, blue: 0.1, alpha: 1),
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
    }
}
private extension String {
    var truncatedForARLabel: String {
        guard count > 118 else { return self }
        return String(prefix(115)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
    }
}
