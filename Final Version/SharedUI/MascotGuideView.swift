import SwiftUI

struct MascotGuideView: View {
    let imageName: String
    var animatedImageNames: [String] = []
    let message: String
    let imageHeight: CGFloat
    let bubbleFont: Font
    var mascotFirst = true
    var frameDuration: Duration = .milliseconds(420)

    @State private var frameIndex = 0

    var body: some View {
        HStack(alignment: .bottom, spacing: 14) {
            if mascotFirst {
                mascotImage
                speechBubble
            } else {
                speechBubble
                mascotImage
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(message)
        .task(id: animatedImageNames) {
            guard !animatedImageNames.isEmpty else { return }

            while !Task.isCancelled {
                try? await Task.sleep(for: frameDuration)
                frameIndex = (frameIndex + 1) % animatedImageNames.count
            }
        }
    }

    private var mascotImage: some View {
        Image(currentImageName)
            .resizable()
            .scaledToFit()
            .frame(height: imageHeight)
            .shadow(color: .black.opacity(0.16), radius: 5, y: 3)
            .accessibilityHidden(true)
    }

    private var currentImageName: String {
        guard !animatedImageNames.isEmpty else { return imageName }
        return animatedImageNames[frameIndex % animatedImageNames.count]
    }

    private var speechBubble: some View {
        Text(message)
            .font(bubbleFont)
            .fontWeight(.semibold)
            .foregroundColor(Color.appPrimaryText)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.appSpeechBubble)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.appBorder, lineWidth: 2)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 7, y: 3)
            )
    }
}

#Preview {
    MascotGuideView(
        imageName: "Mascot Waving",
        animatedImageNames: ["Mascot Neutral", "Mascot Talking", "Mascot Waving", "Mascot Talking"],
        message: "A monster destroyed all the fairy tales and scattered their scenes. Help me put them back in order!",
        imageHeight: 220,
        bubbleFont: .app(.title3)
    )
    .padding()
    .background(Color(red: 0.961, green: 0.945, blue: 0.922))
}
