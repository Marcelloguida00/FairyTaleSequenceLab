import SwiftUI

struct RedHoodLevelFinalView: View {
    let onComplete: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    private var congratulatoryMessage: String {
        let text = lm.t("redhood.final.mascot")
        // If translation is not set, use Italian as primary per user's request
        return text == "redhood.final.mascot" ? "Bravissimo, hai rimesso in ordine tutta la storia di Cappuccetto Rosso spezzando l'incantesimo." : text
    }

    private var buttonText: String {
        let text = lm.t("redhood.final.button")
        return text == "redhood.final.button" ? "Evviva!" : text
    }

    private var titleText: String {
        let text = lm.t("redhood.final.title")
        return text == "redhood.final.title" ? "Incantesimo Spezzato!" : text
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 36) {
                    Spacer()

                    Text(titleText)
                        .font(.app(.largeTitle))
                        .fontWeight(.bold)
                        .foregroundColor(Color.appPrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    MascotGuideView(
                        imageName: "Mascot Talking",
                        animatedImageNames: ["Mascot Talking"],
                        message: congratulatoryMessage,
                        imageHeight: min(geometry.size.height * 0.28, 220),
                        bubbleFont: .app(.title3)
                    )
                    .padding(.horizontal, 40)

                    Button(action: onComplete) {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.app(.title3))
                            Text(buttonText)
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
                    .accessibilityLabel(buttonText)

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}
