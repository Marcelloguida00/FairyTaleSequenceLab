import SwiftUI

struct RedHoodLevel0View: View {
    let onComplete: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 36) {
                    Spacer()

                    Text(lm.t("redhood.intro.title"))
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color.appPrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    MascotGuideView(
                        imageName: "Mascot Talking",
                        animatedImageNames: ["Mascot Talking"],
                        message: lm.t("redhood.intro.mascot"),
                        imageHeight: min(geometry.size.height * 0.28, 220),
                        bubbleFont: .system(.title3, design: .rounded)
                    )
                    .padding(.horizontal, 40)

                    Button(action: onComplete) {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.title3)
                            Text(lm.t("redhood.intro.button"))
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                            Image(systemName: "star.fill")
                                .font(.title3)
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
                    .accessibilityLabel(lm.t("redhood.intro.button"))

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}
