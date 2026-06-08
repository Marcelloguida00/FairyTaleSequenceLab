import SwiftUI

struct TutorialOverlayView: View {
    let onFinish: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var currentStep = 0

    private struct StepData {
        let mascotFrames: [String]
        let titleKey: String
        let bodyKey: String
        var villainImageName: String? = nil
    }

    private let steps: [StepData] = [
        StepData(
            mascotFrames: ["Mascot Neutral", "Mascot Talking", "Mascot Neutral"],
            titleKey: "tutorial.step1.title",
            bodyKey:  "tutorial.step1.body"
        )
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.25)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
                    .allowsHitTesting(false)

                Button(lm.t("tutorial.skip")) { onFinish() }
                    .font(.app(.title3))
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .padding(.horizontal, 34)
                    .padding(.vertical, 16)
                    .gameMinimumTouchTarget()
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.58))
                            .overlay(Capsule().stroke(Color.white.opacity(0.72), lineWidth: 2))
                    )
                    .shadow(color: .black.opacity(0.40), radius: 12, y: 5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .zIndex(2)
                    .accessibilityLabel(lm.t("a11y.tutorial_skip_button"))
                    .accessibilityHint(lm.t("a11y.tutorial_skip_hint"))
                    .accessibilityAddTraits(.isButton)

                bottomSheet(geo: geo)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Bottom sheet

    private func bottomSheet(geo: GeometryProxy) -> some View {
        let step = steps[currentStep]

        return VStack(spacing: 0) {
            if let villainName = step.villainImageName {
                Image(villainName)
                    .resizable()
                    .scaledToFill()
                    .frame(width: min(geo.size.width * 0.80, 460),
                           height: min(geo.size.height * 0.20, 160))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(red: 0.6, green: 0.1, blue: 0.1).opacity(0.7),
                                             Color(red: 0.4, green: 0.0, blue: 0.5).opacity(0.7)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: Color(red: 0.5, green: 0.0, blue: 0.5).opacity(0.4),
                            radius: 12, y: 4)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
                    .accessibilityHidden(true)
            }

            MascotGuideView(
                imageName: step.mascotFrames[0],
                animatedImageNames: step.mascotFrames,
                message: lm.t(step.bodyKey),
                imageHeight: min(geo.size.height * 0.15, 120),
                bubbleFont: .app(.body)
            )
            .padding(.horizontal, 28)
            .padding(.top, step.villainImageName == nil ? 24 : 0)

            Text(lm.t(step.titleKey))
                .font(.app(.title3))
                .fontWeight(.black)
                .foregroundColor(Color.appPrimaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
                .padding(.top, 14)

            HStack(alignment: .center) {
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

                GamePillButton(
                    title: currentStep < steps.count - 1
                        ? lm.t("tutorial.next")
                        : lm.t("tutorial.done"),
                    accessibilityHint: currentStep < steps.count - 1
                        ? lm.t("a11y.tutorial_next_hint")
                        : lm.t("a11y.tutorial_done_hint"),
                    action: {
                        if currentStep < steps.count - 1 {
                            withAnimation(.easeInOut(duration: 0.25)) { currentStep += 1 }
                        } else {
                            onFinish()
                        }
                    }
                )
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
