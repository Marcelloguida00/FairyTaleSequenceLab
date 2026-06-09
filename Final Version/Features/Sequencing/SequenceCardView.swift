import SwiftUI

struct SequenceCardView: View {
    let card: CardData
    let isFlipped: Bool
    @Environment(LanguageManager.self) private var lm

    var body: some View {
        ZStack {
            frontView
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
                .opacity(isFlipped ? 0 : 1)

            backView
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
                .opacity(isFlipped ? 1 : 0)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFlipped ? card.description : lm.t("a11y.story_scene_card"))
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(lm.t("a11y.story_scene_card_hint"))
        .gameMinimumTouchTarget()
    }

    // MARK: - Front (image)

    private var frontView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.93, blue: 0.72),
                            Color(red: 0.82, green: 0.58, blue: 0.27)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            if UIImage(named: card.imageName) != nil {
                Image(card.imageName)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 11))
                    .padding(6)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 11)
                        .fill(Color(red: 0.95, green: 0.90, blue: 0.80))
                        .padding(6)
                    
                    RoundedRectangle(cornerRadius: 11)
                        .strokeBorder(Color(red: 0.6, green: 0.4, blue: 0.2).opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                        .padding(9)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(.title3))
                            .foregroundColor(Color(red: 0.5, green: 0.3, blue: 0.1))
                            .accessibilityHidden(true)

                        Text("Scena \(card.id + 1)")
                            .font(.app(.caption, weight: .bold))
                            .foregroundColor(Color(red: 0.4, green: 0.2, blue: 0.05))
                    }
                }
            }
        }
        .aspectRatio(9 / 16, contentMode: .fit)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.36, green: 0.18, blue: 0.08).opacity(0.50), lineWidth: 1)
                .padding(3)
        )
        .shadow(color: .black.opacity(0.28), radius: 9, x: 0, y: 5)
    }

    // MARK: - Back (description text)

    private var backView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 1.00, green: 0.94, blue: 0.74),
                            Color(red: 0.91, green: 0.74, blue: 0.45)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(red: 0.45, green: 0.24, blue: 0.10), lineWidth: 2)

            VStack(spacing: 14) {
                Image(systemName: "book.pages")
                    .font(.app(.title))
                    .foregroundColor(Color(red: 0.44, green: 0.24, blue: 0.12))

                Text(card.description)
                    .font(.app(.body))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(red: 0.27, green: 0.14, blue: 0.07))
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 12)
            }
        }
        .aspectRatio(9 / 16, contentMode: .fit)
        .shadow(color: .black.opacity(0.28), radius: 9, x: 0, y: 5)
    }
}
