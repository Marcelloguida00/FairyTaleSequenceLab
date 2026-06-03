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

/// Brief overlay after reward dialogue (waypoints 1–8, first completion) when the storybook chapter unlocks.
struct BookChapterUnlockedBanner: View {
    let chapterTitle: String
    let onFinish: () -> Void

    @EnvironmentObject private var lm: LanguageManager
    @State private var isVisible = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                bookIcon

                Text(headline)
                    .font(.app(.largeTitle, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.app(.title3, weight: .medium))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .scaleEffect(isVisible ? 1.0 : (reduceMotion ? 1.0 : 0.88))
            .opacity(isVisible ? 1.0 : 0.0)
        }
        .opacity(isVisible ? 1.0 : 0.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(headline). \(message)")
        .task {
            AppSettings.hapticSuccess()
            withAnimation(reduceMotion ? nil : .spring(response: 0.42, dampingFraction: 0.68)) {
                isVisible = true
            }
            try? await Task.sleep(nanoseconds: 2_200_000_000)
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.35)) {
                isVisible = false
            }
            try? await Task.sleep(nanoseconds: 380_000_000)
            onFinish()
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
}
