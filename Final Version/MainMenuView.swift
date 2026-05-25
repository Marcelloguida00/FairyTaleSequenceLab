import SwiftUI

struct MainMenuView: View {
    let onPlay: () -> Void

    private static let imageAspectRatio: CGFloat = 1024.0 / 768.0

    @State private var imageOpacity: Double = 0
    @State private var showControls = false
    @State private var isStarting = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { proxy in
            let imageSize = fittedImageSize(in: proxy.size)

            ZStack {
                Color(red: 0.10, green: 0.55, blue: 0.78)
                    .ignoresSafeArea()

                Image("world_of_fable_menu")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .frame(width: imageSize.width, height: imageSize.height)
                    .clipped()
                    .opacity(imageOpacity)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .accessibilityHidden(true)

                if showControls {
                    VStack(spacing: 28) {
                        Text("World of Fable")
                            .font(.system(.largeTitle, design: .serif))
                            .fontWeight(.bold)
                            .italic()
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                            .shadow(color: .black.opacity(0.55), radius: 8, y: 3)
                            .accessibilityAddTraits(.isHeader)

                        Button(action: startGame) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.fill")
                                    .font(.title2.weight(.bold))
                                Text("Play")
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.bold)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 48)
                            .padding(.vertical, 18)
                            .frame(minWidth: 200, minHeight: 64)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.98, green: 0.20, blue: 0.18),
                                                Color(red: 0.72, green: 0.04, blue: 0.08)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .black.opacity(0.35), radius: 10, y: 5)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .stroke(.white.opacity(0.85), lineWidth: 3)
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isStarting)
                        .opacity(isStarting ? 0.6 : 1)
                        .accessibilityLabel("Play World of Fable")
                        .accessibilityHint("Starts the adventure and clears the clouds")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            revealMenu()
        }
    }

    private func fittedImageSize(in container: CGSize) -> CGSize {
        let containerAspectRatio = container.width / container.height

        if containerAspectRatio > Self.imageAspectRatio {
            let height = container.height
            return CGSize(width: height * Self.imageAspectRatio, height: height)
        }

        let width = container.width
        return CGSize(width: width, height: width / Self.imageAspectRatio)
    }

    private func revealMenu() {
        if reduceMotion {
            imageOpacity = 1
            showControls = true
            return
        }

        withAnimation(.easeOut(duration: 0.9)) {
            imageOpacity = 1
        }

        Task { @MainActor in
            try? await Task.sleep(for: .seconds(0.85))
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82)) {
                showControls = true
            }
        }
    }

    private func startGame() {
        guard !isStarting else { return }
        isStarting = true
        AppSettings.hapticImpact(.medium)

        withAnimation(.easeOut(duration: 0.25)) {
            showControls = false
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            onPlay()
        }
    }
}
