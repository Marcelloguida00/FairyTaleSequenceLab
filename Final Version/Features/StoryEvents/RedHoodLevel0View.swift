import SwiftUI

struct RedHoodLevel0View: View {
    let onComplete: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        if let lines = RedHoodDialogueLoader.introLines(waypoint: 0, from: lm.bundle), !lines.isEmpty {
            FairyTaleDialogueView(
                lines: lines,
                waypointID: 0,
                onComplete: onComplete
            )
        } else {
            legacyIntro
        }
    }

    private var legacyIntro: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 36) {
                    Spacer()

                    Text(lm.t("redhood.intro.title"))
                        .font(.app(.largeTitle))
                        .fontWeight(.bold)
                        .foregroundColor(Color.appPrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    MascotGuideView(
                        imageName: "Mascot Talking",
                        animatedImageNames: ["Mascot Talking"],
                        message: lm.t("redhood.intro.mascot"),
                        imageHeight: min(geometry.size.height * 0.28, 220),
                        bubbleFont: .app(.title3)
                    )
                    .padding(.horizontal, 40)

                    Button(action: onComplete) {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.app(.title3))
                            Text(lm.t("redhood.intro.button"))
                                .font(.app(.title3))
                                .fontWeight(.bold)
                            Image(systemName: "star.fill")
                                .font(.app(.title3))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 20)
                        .frame(minHeight: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 18)
                                .fill(Color.appAccent)
                                .shadow(color: .black.opacity(0.22), radius: 8, y: 4)
                        )
                    }
                    .buttonStyle(.plain)
                    .gameMinimumTouchTarget(
                        minHeight: GameButtonMetrics.pillMinHeight(atLeast: 64)
                    )
                    .accessibilityLabel(lm.t("redhood.intro.button"))

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}
