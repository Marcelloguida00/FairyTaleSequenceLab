import SwiftUI
import UIKit

struct RewardPackOpeningView: View {
    let onComplete: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var isOpened = false
    @State private var dragOffset: CGFloat = 0
    @State private var contentRevealProgress: CGFloat = 0
    @State private var sparkleProgress: CGFloat = 0
    @State private var idleGlow = false

    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let successHaptic = UINotificationFeedbackGenerator()

    var body: some View {
        GeometryReader { geometry in
            let packWidth = min(geometry.size.width * 0.76, 380)
            let packHeight = packWidth * 4 / 3
            let openDistance = packHeight * 0.46
            let threshold = packHeight * 0.14
            let activeDrag = isOpened ? -openDistance : dragOffset
            let dragProgress = min(max(abs(activeDrag) / openDistance, 0), 1)
            let revealProgress = max(contentRevealProgress, dragProgress * 0.38)

            ZStack {
                Color.black.opacity(isOpened ? 0.34 : 0.52)
                    .ignoresSafeArea()

                ZStack {
                    magicalGlow(width: packWidth, progress: revealProgress)

                    // Same frame for all SVG layers: the shared viewBox stays perfectly aligned.
                    Image("reward_content")
                        .resizable()
                        .scaledToFit()
                        .frame(width: packWidth, height: packHeight)
                        .offset(y: packHeight * 0.18 - revealProgress * packHeight * 0.52)
                        .scaleEffect(0.88 + revealProgress * 0.18)
                        .opacity(0.2 + revealProgress * 0.8)
                        .shadow(color: Color.yellow.opacity(0.28 * revealProgress), radius: 18, y: 2)
                        .zIndex(0)

                    Image("reward_pack_bottom")
                        .resizable()
                        .scaledToFit()
                        .frame(width: packWidth, height: packHeight)
                        .shadow(color: .black.opacity(0.26), radius: 14, y: 10)
                        .zIndex(1)

                    Image("reward_pack_top")
                        .resizable()
                        .scaledToFit()
                        .frame(width: packWidth, height: packHeight)
                        .offset(x: topHorizontalOffset(progress: dragProgress),
                                y: activeDrag)
                        .rotationEffect(.degrees(topRotation(progress: dragProgress)))
                        .opacity(isOpened ? 0.2 : 1)
                        .scaleEffect(isOpened ? 0.97 : 1)
                        .shadow(color: .black.opacity(0.18), radius: 10, y: 6)
                        .zIndex(2)

                    SparkleBurst(progress: sparkleProgress)
                        .frame(width: packWidth, height: packHeight)
                        .opacity(Double(sparkleProgress))
                        .zIndex(3)
                }
                .frame(width: packWidth, height: packHeight)
                .contentShape(Rectangle())
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 18)
                .gesture(openDragGesture(threshold: threshold))
                .onTapGesture {
                    openPack()
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Reward pack")
                .accessibilityHint("Tap or drag upward to open the reward pack")
                .accessibilityAddTraits(.isButton)
            }
            .onAppear {
                lightHaptic.prepare()
                successHaptic.prepare()

                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.35).repeatForever(autoreverses: true)) {
                    idleGlow = true
                }
            }
        }
    }

    private func magicalGlow(width: CGFloat, progress: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        Color.yellow.opacity(0.34),
                        Color.orange.opacity(0.16),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: width * 0.08,
                    endRadius: width * 0.55
                )
            )
            .frame(width: width * 1.18, height: width * 1.18)
            .scaleEffect((idleGlow ? 1.08 : 0.96) + progress * 0.18)
            .opacity((isOpened ? 0.95 : 0.42) + progress * 0.25)
            .blur(radius: 2)
            .offset(y: -width * 0.18)
            .allowsHitTesting(false)
    }

    private func openDragGesture(threshold: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                guard !isOpened else { return }

                // Only upward movement opens the booster, keeping the interaction predictable.
                dragOffset = min(value.translation.height, 0)
                lightHaptic.impactOccurred(intensity: min(0.18 + abs(dragOffset) / 220, 0.55))
                lightHaptic.prepare()
            }
            .onEnded { value in
                guard !isOpened else { return }

                if abs(value.translation.height) >= threshold {
                    openPack()
                } else {
                    closePack()
                }
            }
    }

    private func openPack() {
        guard !isOpened else { return }

        successHaptic.notificationOccurred(.success)

        if reduceMotion {
            isOpened = true
            dragOffset = -120
            contentRevealProgress = 1
            sparkleProgress = 1
            completeAfterDelay(0.35)
            return
        }

        withAnimation(.spring(response: 0.58, dampingFraction: 0.74)) {
            isOpened = true
            dragOffset = -170
        }

        withAnimation(.spring(response: 0.72, dampingFraction: 0.72).delay(0.12)) {
            contentRevealProgress = 1
        }

        withAnimation(.easeOut(duration: 0.55).delay(0.12)) {
            sparkleProgress = 1
        }

        completeAfterDelay(1.25)
    }

    private func closePack() {
        withAnimation(.spring(response: 0.42, dampingFraction: 0.76)) {
            dragOffset = 0
            contentRevealProgress = 0
        }
    }

    private func completeAfterDelay(_ delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            onComplete()
        }
    }

    private func topHorizontalOffset(progress: CGFloat) -> CGFloat {
        isOpened ? 18 : progress * 8
    }

    private func topRotation(progress: CGFloat) -> Double {
        isOpened ? -10 : Double(progress) * -4
    }
}

struct PackOpeningView: View {
    let onComplete: () -> Void

    var body: some View {
        RewardPackOpeningView(onComplete: onComplete)
    }
}

private struct SparkleBurst: View {
    let progress: CGFloat

    private let sparkles: [(x: CGFloat, y: CGFloat, size: CGFloat, delay: CGFloat)] = [
        (0.18, 0.20, 8, 0.00),
        (0.34, 0.08, 5, 0.08),
        (0.67, 0.14, 7, 0.12),
        (0.82, 0.26, 5, 0.18),
        (0.26, 0.42, 6, 0.22),
        (0.74, 0.45, 8, 0.26),
        (0.50, 0.02, 6, 0.04)
    ]

    var body: some View {
        GeometryReader { geometry in
            ForEach(sparkles.indices, id: \.self) { index in
                let sparkle = sparkles[index]
                let localProgress = min(max((progress - sparkle.delay) / 0.72, 0), 1)

                SparkleShape()
                    .fill(Color.yellow.opacity(Double(1 - localProgress * 0.55)))
                    .frame(width: sparkle.size, height: sparkle.size)
                    .scaleEffect(0.45 + localProgress * 1.35)
                    .rotationEffect(.degrees(Double(localProgress) * 95))
                    .position(
                        x: geometry.size.width * sparkle.x,
                        y: geometry.size.height * (sparkle.y - localProgress * 0.16)
                    )
            }
        }
        .allowsHitTesting(false)
    }
}

private struct SparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.midY - rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX + rect.width * 0.12, y: rect.midY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.midY + rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX - rect.width * 0.12, y: rect.midY - rect.height * 0.12))
        path.closeSubpath()
        return path
    }
}

#Preview {
    RewardPackOpeningView {}
}
