import SwiftUI

struct SequenceCardView: View {
    let card: CardData
    @Binding var isFlipped: Bool

    var body: some View {
        ZStack {
            frontView
                .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
                .opacity(isFlipped ? 0 : 1)

            backView
                .rotation3DEffect(.degrees(isFlipped ? 0 : -180), axis: (x: 0, y: 1, z: 0), perspective: 0.3)
                .opacity(isFlipped ? 1 : 0)
        }
        .accessibilityLabel(isFlipped ? card.description : "Story scene card.")
        .accessibilityHint("")
    }

    // MARK: - Front (image)

    private var frontView: some View {
        Image(card.imageName)
            .resizable()
            .aspectRatio(9 / 16, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.appBorder, lineWidth: 2)
            )
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }

    // MARK: - Back (description text)

    private var backView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appCardBack)
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.appBorder, lineWidth: 2)

            VStack(spacing: 14) {
                Image(systemName: "book.pages")
                    .font(.system(.title))
                    .foregroundColor(Color.appSecondaryText)

                Text(card.description)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(Color.appPrimaryText)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 12)
            }
        }
        .aspectRatio(9 / 16, contentMode: .fit)
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}
