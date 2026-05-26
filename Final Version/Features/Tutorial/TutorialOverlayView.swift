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
            bodyKey:  "tutorial.step1.body",
            villainImageName: "villain_lair"
        ),
        StepData(
            mascotFrames: ["Mascot Talking", "Mascot Neutral", "Mascot Talking"],
            titleKey: "tutorial.step2.title",
            bodyKey:  "tutorial.step2.body"
        ),
        StepData(
            mascotFrames: ["Mascot Neutral", "Mascot Talking"],
            titleKey: "tutorial.step3.title",
            bodyKey:  "tutorial.step3.body"
        ),
        StepData(
            mascotFrames: ["Mascot Talking", "Mascot Neutral"],
            titleKey: "tutorial.step4.title",
            bodyKey:  "tutorial.step4.body"
        ),
        StepData(
            mascotFrames: ["Mascot Cheer", "Mascot Waving", "Mascot Cheer"],
            titleKey: "tutorial.step5.title",
            bodyKey:  "tutorial.step5.body"
        ),
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottom) {
                Color.black.opacity(0.55)
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                Button(lm.t("tutorial.skip")) { onFinish() }
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 11)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.28))
                            .overlay(Capsule().stroke(Color.white.opacity(0.50), lineWidth: 1))
                    )
                    .shadow(color: .black.opacity(0.30), radius: 6, y: 2)
                    .padding(.top, geo.safeAreaInsets.top + 16)
                    .padding(.trailing, 24)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)

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
                bubbleFont: .system(.body, design: .rounded)
            )
            .padding(.horizontal, 28)
            .padding(.top, step.villainImageName == nil ? 24 : 0)

            Text(lm.t(step.titleKey))
                .font(.system(.title3, design: .rounded))
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
