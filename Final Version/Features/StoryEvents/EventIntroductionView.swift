import SwiftUI

struct EventIntroductionView: View {
    let event: EventData
    let onContinue: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Image(event.introImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.65)
                        .clipped()
                        .accessibilityHidden(true)

                    ParchmentView {
                        HStack(alignment: .center, spacing: 24) {
                            Text(event.introText)
                                .font(.system(.body, design: .serif))
                                .foregroundColor(Color.appPrimaryText)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: onContinue) {
                                HStack(spacing: 8) {
                                    Text("Continue")
                                        .font(.system(.headline, design: .rounded))
                                    Image(systemName: "arrow.right")
                                        .font(.headline)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 16)
                                .frame(minWidth: 60, minHeight: 60)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.appAccent)
                                        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Continue to the sequencing activity")
                        }
                        .padding(.horizontal, 32)
                        .padding(.vertical, 20)
                    }
                    .frame(height: geometry.size.height * 0.35)
                }
            }
        }
        .ignoresSafeArea()
    }
}


