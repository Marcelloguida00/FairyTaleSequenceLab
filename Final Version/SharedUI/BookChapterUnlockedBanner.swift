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

/// Slides down from the top center and docks under the map chrome; tap opens the storybook.
struct BookChapterUnlockedBanner: View {
    let chapterTitle: String
    let onFinish: () -> Void
    let onOpenStorybook: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var isVisible = false
    @State private var didDismiss = false
    @State private var autoDismissTask: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let dockedTopPadding: CGFloat = 52
    private let slideDistance: CGFloat = 96
    private let autoDismissDelay: Duration = .seconds(4.5)

    private var headline: String {
        lm.t("book.chapter_unlocked.title")
    }

    private var message: String {
        let format = lm.t("book.chapter_unlocked.message")
        if format.contains("%@") {
            return String(format: format, chapterTitle)
        }
        return format
    }

    private var openHint: String {
        lm.t("book.chapter_unlocked.open_hint")
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                dismiss(openingStorybook: true)
            } label: {
                HStack(spacing: 12) {
                    bookIcon
                        .frame(width: 40, height: 40)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(headline)
                            .font(.app(.subheadline, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(message)
                            .font(.app(.caption, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 4)

                    Image(systemName: "chevron.right")
                        .font(.app(.footnote, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(maxWidth: 520)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color(white: 0.15))
                        .shadow(color: .black.opacity(0.55), radius: 12, y: 6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color(white: 0.32), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.top, dockedTopPadding)
            .offset(y: isVisible ? 0 : -slideDistance)
            .opacity(isVisible ? 1 : 0)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .ignoresSafeArea()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(headline). \(message)")
        .accessibilityHint(openHint)
        .onAppear {
            present()
        }
        .onDisappear {
            autoDismissTask?.cancel()
        }
    }

    @ViewBuilder
    private var bookIcon: some View {
        if UIImage(named: "StoryBookButton") != nil {
            Image("StoryBookButton")
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        } else {
            Image(systemName: "book.closed.fill")
                .font(.app(size: 28))
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
                .shadow(color: .orange.opacity(0.5), radius: 4)
        }
    }

    private func present() {
        AppSettings.hapticSuccess()
        withAnimation(reduceMotion ? nil : .spring(response: 0.46, dampingFraction: 0.78)) {
            isVisible = true
        }

        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor in
            try? await Task.sleep(for: autoDismissDelay)
            guard !Task.isCancelled, !didDismiss else { return }
            dismiss(openingStorybook: false)
        }
    }

    private func dismiss(openingStorybook: Bool) {
        guard !didDismiss else { return }
        didDismiss = true
        autoDismissTask?.cancel()

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
