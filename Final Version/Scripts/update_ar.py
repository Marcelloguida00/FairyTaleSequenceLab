import sys
import re

file_path = "/Users/marcelloguida/Desktop/Progetto FInale/Final Version/Final Version/SharedUI/ARBookView.swift"

with open(file_path, "r") as f:
    content = f.read()

# Replace ARBookView struct
new_arbookview = """struct ARBookView: View {
    let cards: [ARStoryCard]
    let onClose: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var targetIndex = 0
    @State private var showSuccessMessage = false

    var body: some View {
        ZStack {
            if ARWorldTrackingConfiguration.isSupported {
                UnlockedCardsARSceneView(cards: cards, targetIndex: $targetIndex, showSuccessMessage: $showSuccessMessage)
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

                if ARWorldTrackingConfiguration.isSupported, !cards.isEmpty, targetIndex < cards.count {
                    targetBanner
                        .padding(.bottom, 26)
                } else if targetIndex >= cards.count && !cards.isEmpty {
                    completionBanner
                        .padding(.bottom, 26)
                }
            }
            
            if showSuccessMessage {
                VStack {
                    Spacer()
                    Text(lm.t("Esatto!"))
                        .font(.app(.title1, weight: .black))
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

    private var targetBanner: some View {
        let targetCard = cards[targetIndex]
        return VStack(spacing: 4) {
            Text(lm.t("Cerca la carta:"))
                .font(.app(.subheadline, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
            Text("\\(targetCard.eventID).\\(targetCard.sequenceNumber) - \\(targetCard.eventTitle)")
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
            Text(lm.t("Bravissimo!"))
                .font(.app(.title3, weight: .bold))
                .foregroundColor(.white)
            Text(lm.t("Hai trovato tutte le carte."))
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

    private var header: some View {"""

content = re.sub(r'struct ARBookView: View \{.*?(?=private var header: some View \{)', new_arbookview, content, flags=re.DOTALL)

# Replace UnlockedCardsARSceneView
new_sceneview = """private struct UnlockedCardsARSceneView: UIViewRepresentable {
    let cards: [ARStoryCard]
    @Binding var targetIndex: Int
    @Binding var showSuccessMessage: Bool

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = SCNScene()
        
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        sceneView.addGestureRecognizer(tapGesture)
        
        return sceneView
    }

    func updateUIView(_ sceneView: ARSCNView, context: Context) {
        if context.coordinator.renderedCards != cards {
            context.coordinator.reset()
            context.coordinator.renderedCards = cards
            context.coordinator.targetIndexBinding = _targetIndex
            context.coordinator.showSuccessMessageBinding = _showSuccessMessage
            context.coordinator.sceneView = sceneView
            rebuildScene(in: sceneView, coordinator: context.coordinator)
            return
        }
        
        context.coordinator.targetIndexBinding = _targetIndex
        context.coordinator.showSuccessMessageBinding = _showSuccessMessage
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIView(_ sceneView: ARSCNView, coordinator: Coordinator) {
        sceneView.session.pause()
    }

    private func rebuildScene(in sceneView: ARSCNView, coordinator: Coordinator) {"""

content = re.sub(r'private struct UnlockedCardsARSceneView: UIViewRepresentable \{.*?(?=private func rebuildScene\(in sceneView: ARSCNView, coordinator: Coordinator\) \{)', new_sceneview, content, flags=re.DOTALL)

# Replace Coordinator and cardPosition
new_cardpos_and_coord = """    private func cardPosition(index: Int, total: Int) -> SCNVector3 {
        // Scatter the cards around the user
        let goldenRatio = 1.61803398875
        let angle = Float(index) * Float(goldenRatio) * 2.0 * .pi
        
        // Radius between 1.2 and 2.5 meters
        let minRadius: Float = 1.2
        let maxRadius: Float = 2.5
        let radiusRange = maxRadius - minRadius
        let normalizedIndex = Float(index) / Float(max(total - 1, 1))
        
        // Shuffle the radius a bit based on index parity
        let radius = minRadius + (index % 2 == 0 ? radiusRange * normalizedIndex : radiusRange * (1 - normalizedIndex))
        
        let x = cos(angle) * radius
        let z = sin(angle) * radius
        
        // Slight height variations
        let y = 0.05 + Float(index % 3) * 0.1
        
        return SCNVector3(x, y, z)
    }

    private func makeBillboardConstraint() -> SCNBillboardConstraint {
        let constraint = SCNBillboardConstraint()
        constraint.freeAxes = .Y
        return constraint
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
                "\\(card.eventID).\\(card.sequenceNumber)",
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

    final class Coordinator: NSObject {
        var renderedCards: [ARStoryCard] = []
        var targetIndexBinding: Binding<Int>?
        var showSuccessMessageBinding: Binding<Bool>?
        weak var sceneView: ARSCNView?
        var cardNodes: [SCNNode] = []

        func reset() {
            cardNodes.removeAll()
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let sceneView = sceneView,
                  let targetIndex = targetIndexBinding?.wrappedValue,
                  targetIndex < renderedCards.count else { return }

            let location = gesture.location(in: sceneView)
            let hitResults = sceneView.hitTest(location, options: [.boundingBoxOnly: true])
            
            // Find if any of the hit nodes belongs to a card
            for hit in hitResults {
                var node: SCNNode? = hit.node
                while let current = node {
                    if let name = current.name, name.hasPrefix("unlocked-card-") {
                        let cardId = name.replacingOccurrences(of: "unlocked-card-", with: "")
                        let targetCard = renderedCards[targetIndex]
                        
                        if cardId == targetCard.id {
                            // Correct card!
                            targetIndexBinding?.wrappedValue += 1
                            AppSettings.hapticImpact(.heavy)
                            
                            // Success visual feedback
                            showSuccessFeedback()
                            
                            // Highlight node
                            let scaleUp = SCNAction.scale(to: 1.3, duration: 0.2)
                            let scaleDown = SCNAction.scale(to: 1.0, duration: 0.2)
                            let seq = SCNAction.sequence([scaleUp, scaleDown, scaleUp, scaleDown])
                            current.runAction(seq)
                            
                            return
                        } else {
                            // Wrong card
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
"""

content = re.sub(r'    private func cardPosition\(index: Int, total: Int\) -> SCNVector3 \{.*?(?=private extension String \{)', new_cardpos_and_coord, content, flags=re.DOTALL)

with open(file_path, "w") as f:
    f.write(content)
