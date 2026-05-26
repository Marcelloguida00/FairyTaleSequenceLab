import SwiftUI

struct TutorialOverlayView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var currentStep = 0

    private struct StepData {
        let mascotFrames: [String]
        let titleKey: String
        let bodyKey: String
    }

    private let steps: [StepData] = [
        StepData(mascotFrames: ["Mascot Waving", "Mascot Neutral", "Mascot Waving"],
                 titleKey: "tutorial.step1.title", bodyKey: "tutorial.step1.body"),
        StepData(mascotFrames: ["Mascot Talking", "Mascot Neutral", "Mascot Talking"],
                 titleKey: "tutorial.step2.title", bodyKey: "tutorial.step2.body"),
        StepData(mascotFrames: ["Mascot Neutral", "Mascot Talking"],
                 titleKey: "tutorial.step3.title", bodyKey: "tutorial.step3.body"),
        StepData(mascotFrames: ["Mascot Talking", "Mascot Neutral"],
                 titleKey: "tutorial.step4.title", bodyKey: "tutorial.step4.body"),
        StepData(mascotFrames: ["Mascot Cheer", "Mascot Waving", "Mascot Cheer"],
                 titleKey: "tutorial.step5.title", bodyKey: "tutorial.step5.body"),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                // Overlay scuro
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                // Skip in alto a destra
                Button(lm.t("tutorial.skip")) { onFinish() }
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.80))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Capsule().fill(Color.white.opacity(0.14)))
                    .padding(.top, geo.safeAreaInsets.top + 16)
                    .padding(.trailing, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

                // Bottom sheet
                bottomSheet(geo: geo)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Bottom sheet

    private func bottomSheet(geo: GeometryProxy) -> some View {
        let step = steps[currentStep]

        return VStack(spacing: 0) {
            // Mascot + speech bubble
            MascotGuideView(
                imageName: step.mascotFrames[0],
                animatedImageNames: step.mascotFrames,
                message: lm.t(step.bodyKey),
                imageHeight: min(geo.size.height * 0.15, 120),
                bubbleFont: .system(.body, design: .rounded)
            )
            .padding(.horizontal, 28)
            .padding(.top, 24)

            // Titolo step
            Text(lm.t(step.titleKey))
                .font(.system(.title3, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 14)

            // Dots + bottoni
            HStack(alignment: .center) {
                // Dots
                HStack(spacing: 7) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentStep
                                  ? Color.appAccent
                                  : Color.appSecondaryText.opacity(0.30))
                            .frame(width: i == currentStep ? 20 : 7, height: 7)
                            .animation(.spring(response: 0.35, dampingFraction: 0.7),
                                       value: currentStep)
                    }
                }

                Spacer()

                // Next / Done
                Button {
                    if currentStep < steps.count - 1 {
                        withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
                    } else {
                        onFinish()
                    }
                } label: {
                    Text(currentStep < steps.count - 1
                         ? lm.t("tutorial.next")
                         : lm.t("tutorial.done"))
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 13)
                        .background(Capsule().fill(Color.appAccent))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 32)
            .padding(.top, 18)
            .padding(.bottom, max(28, geo.safeAreaInsets.bottom + 12))
        }
        .background(
            RoundedRectangle(cornerRadius: 32)
                .fill(Color.appBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 32)
                        .stroke(Color.appBorder.opacity(0.60), lineWidth: 1.5)
                )
                .shadow(color: .black.opacity(0.30), radius: 24, y: -4)
        )
        .padding(.horizontal, 12)
        .id(currentStep)
    }
}
