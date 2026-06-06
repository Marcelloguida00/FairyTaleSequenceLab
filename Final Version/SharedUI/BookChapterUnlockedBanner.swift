import SwiftUI

enum BookChapterTitles {
    static func title(for eventId: Int, lm: LanguageManager) -> String {
        guard (1...8).contains(eventId) else { return "" }
        if let banner = EventLoader.event(id: eventId, from: lm.bundle)?.bannerTitle, !banner.isEmpty {
            return banner
        }
        let key = "story.redhood.scene\(eventId).title"
        let localized = lm.t(key)
        if localized != key { return localized }
        return ""
    }
}

/// Full-screen overlay on the map, shown after the reward dialogue and before the avatar walks to the next waypoint.
struct BookChapterUnlockedBanner: View {
    let onFinish: () -> Void
    let onOpenStorybook: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var isVisible = false
    @State private var didDismiss = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var headline: String {
        lm.t("book.chapter_unlocked.title")
    }

    private var openButtonTitle: String {
        lm.t("book.chapter_unlocked.open_button")
    }

    private var tapHint: String {
        lm.t("book.chapter_unlocked.tap_hint")
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture {
                    dismiss(openingStorybook: false)
                }

            VStack(spacing: 24) {
                bookIcon

                Text(headline)
                    .font(.app(.title, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
                    .fixedSize(horizontal: false, vertical: true)

                GamePillButton(
                    title: openButtonTitle,
                    leadingIcon: "book.closed.fill"
                ) {
                    dismiss(openingStorybook: true)
                }
            }
            .padding(.horizontal, 24)
            .scaleEffect(isVisible ? 1.0 : (reduceMotion ? 1.0 : 0.88))
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityLabel(headline)
        .accessibilityHint("\(openButtonTitle). \(tapHint)")
        .onAppear {
            present()
        }
    }

    @ViewBuilder
    private var bookIcon: some View {
        if UIImage(named: "StoryBookButton") != nil {
            Image("StoryBookButton")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
        } else {
            Image(systemName: "book.closed.fill")
                .font(.app(size: 56))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.78, blue: 0.35),
                            Color(red: 0.75, green: 0.45, blue: 0.12)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .orange.opacity(0.5), radius: 12)
        }
    }

    private func present() {
        AppSettings.hapticSuccess()
        withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.68)) {
            isVisible = true
        }
    }

    private func dismiss(openingStorybook: Bool) {
        guard !didDismiss else { return }
        didDismiss = true

        if openingStorybook {
            AppSettings.hapticImpact(.light)
        }

        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.32)) {
            isVisible = false
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 320_000_000)
            if openingStorybook {
                onOpenStorybook()
            } else {
                onFinish()
            }
        }
    }
}
