import ARKit
import QuartzCore
import SceneKit
import SwiftUI
import UIKit

struct RedHoodARCard: Identifiable, Hashable {
    let id: String
    let eventID: Int
    let position: Int
    let title: String
    let imageName: String
    let description: String
}

struct RedHoodARStoryView: View {
    let cards: [RedHoodARCard]
    let onClose: () -> Void

    @Environment(LanguageManager.self) private var lm

    var body: some View {
        ZStack(alignment: .top) {
            if ARWorldTrackingConfiguration.isSupported {
                RedHoodARSceneView(cards: cards)
                    .ignoresSafeArea()
            } else {
                unsupportedDeviceView
            }

            VStack(spacing: 14) {
                header

                if cards.isEmpty {
                    emptyState
                        .padding(.top, 40)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(lm.t("redhood.ar.title"))
                    .font(.app(.headline))
                    .fontWeight(.black)
                    .foregroundColor(.white)

                Text(lm.t("redhood.ar.body"))
                    .font(.app(.caption))
                    .foregroundColor(.white.opacity(0.82))
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)
            }

            Spacer()

            GameCircleBackButton(size: GameButtonMetrics.chromeCircleSize) {
                AppSettings.hapticImpact(.light)
                onClose()
            }
            .accessibilityLabel(lm.t("a11y.go_back"))
            .accessibilityHint(lm.t("a11y.ar_back_hint"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.18), lineWidth: 1)
                )
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.open")
                .font(.system(.largeTitle, design: .default).weight(.semibold))
                .foregroundColor(Color.appAccent)
                .accessibilityHidden(true)

            Text(lm.t("redhood.ar.empty"))
                .font(.app(.title3))
                .fontWeight(.bold)
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(26)
        .frame(maxWidth: 420)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.appBackground.opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.appBorder.opacity(0.7), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.24), radius: 18, y: 8)
        )
    }

    private var unsupportedDeviceView: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                Image(systemName: "arkit")
                    .font(.system(.largeTitle))
                    .foregroundColor(Color.appAccent)
                    .accessibilityHidden(true)

                Text(lm.t("redhood.ar.unsupported"))
                    .font(.app(.title3))
                    .fontWeight(.bold)
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 34)
            }
        }
    }
}

private struct RedHoodARSceneView: UIViewRepresentable {
    let cards: [RedHoodARCard]

    func makeUIView(context: Context) -> ARSCNView {
        let sceneView = ARSCNView(frame: .zero)
        sceneView.automaticallyUpdatesLighting = true
        sceneView.autoenablesDefaultLighting = true
        sceneView.scene = SCNScene()
        return sceneView
    }

    func updateUIView(_ sceneView: ARSCNView, context: Context) {
        guard context.coordinator.renderedCards != cards else { return }

        context.coordinator.renderedCards = cards
        sceneView.scene.rootNode.childNodes.forEach { $0.removeFromParentNode() }

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        let visibleCards = cards
            .sorted {
                if $0.eventID == $1.eventID { return $0.position < $1.position }
                return $0.eventID < $1.eventID
            }
            .prefix(12)

        for (index, card) in visibleCards.enumerated() {
            sceneView.scene.rootNode.addChildNode(makeCardNode(for: card, index: index, total: visibleCards.count))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    static func dismantleUIView(_ sceneView: ARSCNView, coordinator: Coordinator) {
        sceneView.session.pause()
    }

    private func makeCardNode(for card: RedHoodARCard, index: Int, total: Int) -> SCNNode {
        let cardNode = SCNNode()
        let columns = min(4, max(total, 1))
        let row = index / columns
        let column = index % columns
        let cardsInThisRow = min(columns, total - row * columns)
        let centeredColumn = Float(column) - Float(cardsInThisRow - 1) / 2

        cardNode.position = SCNVector3(
            centeredColumn * 0.26,
            0.18 - Float(row) * 0.34,
            -0.92 - Float(row) * 0.08
        )
        cardNode.eulerAngles = SCNVector3(0, centeredColumn * -0.08, 0)

        let plane = SCNPlane(width: 0.16, height: 0.27)
        plane.cornerRadius = 0.012
        plane.firstMaterial?.diffuse.contents = makeCardImage(for: card)
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.lightingModel = .physicallyBased

        let imageNode = SCNNode(geometry: plane)
        cardNode.addChildNode(imageNode)

        let titleNode = makeTextNode(card.title, size: 0.009, y: -0.165)
        cardNode.addChildNode(titleNode)

        let delay = Double(index) * 0.12
        let floatUp = SCNAction.moveBy(x: 0, y: 0.045, z: 0, duration: 1.4)
        floatUp.timingMode = .easeInEaseOut
        let floatDown = floatUp.reversed()
        let turn = SCNAction.rotateBy(x: 0, y: 0.16, z: 0, duration: 1.9)
        turn.timingMode = .easeInEaseOut

        cardNode.runAction(.sequence([
            .wait(duration: delay),
            .repeatForever(.sequence([floatUp, floatDown]))
        ]))
        imageNode.runAction(.sequence([
            .wait(duration: delay),
            .repeatForever(.sequence([turn, turn.reversed()]))
        ]))

        return cardNode
    }

    private func makeTextNode(_ text: String, size: CGFloat, y: Float) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.001)
        textGeometry.font = UIFont.systemFont(ofSize: 0.08, weight: .bold)
        textGeometry.alignmentMode = CATextLayerAlignmentMode.center.rawValue
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        textGeometry.firstMaterial?.isDoubleSided = true

        let node = SCNNode(geometry: textGeometry)
        let bounds = textGeometry.boundingBox
        let width = max(bounds.max.x - bounds.min.x, 0.001)
        let nodeScale = Float(size)
        node.scale = SCNVector3(nodeScale, nodeScale, nodeScale)
        node.position = SCNVector3(-(width * nodeScale) / 2, y, 0.004)
        return node
    }

    private func makeCardImage(for card: RedHoodARCard) -> UIImage {
        let size = CGSize(width: 540, height: 900)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size)
            UIColor(red: 0.99, green: 0.90, blue: 0.66, alpha: 1).setFill()
            UIBezierPath(roundedRect: rect, cornerRadius: 42).fill()

            let imageRect = rect.insetBy(dx: 28, dy: 28)
            let imageClip = UIBezierPath(roundedRect: imageRect, cornerRadius: 30)
            imageClip.addClip()

            if let image = UIImage(named: card.imageName) {
                drawAspectFill(image, in: imageRect)
            } else {
                UIColor(red: 0.18, green: 0.36, blue: 0.50, alpha: 1).setFill()
                UIRectFill(imageRect)
            }

            context.cgContext.resetClip()

            UIColor.white.withAlphaComponent(0.92).setStroke()
            let border = UIBezierPath(roundedRect: rect.insetBy(dx: 10, dy: 10), cornerRadius: 36)
            border.lineWidth = 8
            border.stroke()

            UIColor(red: 0.27, green: 0.13, blue: 0.05, alpha: 0.45).setStroke()
            let innerBorder = UIBezierPath(roundedRect: rect.insetBy(dx: 21, dy: 21), cornerRadius: 28)
            innerBorder.lineWidth = 4
            innerBorder.stroke()
        }
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

    final class Coordinator {
        var renderedCards: [RedHoodARCard] = []
    }
}
