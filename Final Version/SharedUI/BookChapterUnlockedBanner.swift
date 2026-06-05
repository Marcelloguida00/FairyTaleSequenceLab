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
        VStack {
            HStack(spacing: 16) {
                bookIcon
                    .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(headline)
                        .font(.app(.subheadline, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    Text(message)
                        .font(.app(.footnote, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(white: 0.15))
                    .shadow(color: .black.opacity(0.6), radius: 10, y: 5)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color(white: 0.3), lineWidth: 1)
                    )
            )
            .padding(.top, 40)
            .padding(.trailing, 24)
            .offset(y: isVisible ? 0 : -100)
            .opacity(isVisible ? 1.0 : 0.0)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .ignoresSafeArea()
        .allowsHitTesting(false)
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
                .shadow(color: .black.opacity(0.35), radius: 4, y: 2)
        } else {
            Image(systemName: "book.closed.fill")
                .font(.app(size: 32))
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
}
