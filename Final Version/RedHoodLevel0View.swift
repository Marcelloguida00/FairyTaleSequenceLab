import SwiftUI

struct RedHoodLevel0View: View {
    let onComplete: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 36) {
                    Spacer()

                    Text("Little Red Riding Hood")
                        .font(.system(.largeTitle, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color.appPrimaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    MascotGuideView(
                        imageName: "Mascot Waving",
                        animatedImageNames: ["Mascot Neutral", "Mascot Talking", "Mascot Waving", "Mascot Talking"],
                        message: "Oh no! A monster has destroyed all the fairy tales and scattered their scenes! Can you help me put the story of Little Red Riding Hood back together?",
                        imageHeight: min(geometry.size.height * 0.28, 220),
                        bubbleFont: .system(.title3, design: .rounded)
                    )
                    .padding(.horizontal, 40)

                    Button(action: onComplete) {
                        HStack(spacing: 10) {
                            Image(systemName: "star.fill")
                                .font(.title3)
                            Text("Start the Adventure!")
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
                    .accessibilityLabel("Start the adventure")

                    Spacer()
                }
            }
        }
        .ignoresSafeArea()
    }
}
