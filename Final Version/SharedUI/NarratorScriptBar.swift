import SwiftUI

/// Narrator caption bar: horizontal frame + dynamic subtitles synced to the narration audio.
/// Lines are revealed progressively; once the box is full the oldest line scrolls out the top.
struct NarratorScriptBar: View {
    let message: String
    let maxWidth: CGFloat
    /// Audio resource driving the subtitle pace; when nil (or not playing) pacing falls back to `narrationDuration`.
    var narrationResource: String? = nil
    /// Expected narration length, used when the audio progress is unavailable.
    var narrationDuration: TimeInterval = 0

    @State private var revealedLineCount = 1

    @Environment(\.accessibilityReduceMotion) private var sysReduceMotion
    @AppStorage("reduceAnimations") private var reduceAnimations = false
    private var reduceMotion: Bool { sysReduceMotion || reduceAnimations }

    /// Wait for the scene curtain (~1.5s) before assuming the audio is missing.
    private static let audioStartGrace: TimeInterval = 3.5
    private static let fallbackSecondsPerLine: TimeInterval = 2.6
    private static let pollIntervalNs: UInt64 = 100_000_000

    var body: some View {
        let lines = wrappedLines
        let window = visibleWindow(lines: lines)

        NarratorFramePanel(visibleLines: window)
            .frame(maxWidth: maxWidth)
            .contentShape(Rectangle())
            .onTapGesture { revealNextLine(totalLines: lines.count) }
            .task(id: message) {
                await runSubtitlePacing(totalLines: lines.count)
            }
            .onChange(of: message) { _, _ in
                revealedLineCount = 1
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(message)
    }

    private var wrappedLines: [String] {
        let fontSize = NarratorFrameMetrics.scaledFontSize(
            NarratorFrameMetrics.dialogueFontSize,
            frameWidth: maxWidth
        )
        let textWidth = max(
            1,
            maxWidth * NarratorFrameMetrics.dialogueTextBoxWidthRatio
                - (NarratorFrameMetrics.scaled(NarratorFrameMetrics.bodyPaddingHorizontal, frameWidth: maxWidth) * 2)
        )
        return DialogueTextPaginator.wrappedLines(
            text: message.trimmingCharacters(in: .whitespacesAndNewlines),
            fontSize: fontSize,
            maxWidth: textWidth
        )
    }

    /// Sliding window: the last `dialogueLineLimit` revealed lines, with stable ids for the scroll animation.
    private func visibleWindow(lines: [String]) -> [NarratorSubtitleLine] {
        guard !lines.isEmpty else { return [] }
        let upper = min(max(revealedLineCount, 1), lines.count)
        let lower = max(0, upper - NarratorFrameMetrics.dialogueLineLimit)
        return (lower..<upper).map { NarratorSubtitleLine(id: $0, text: lines[$0]) }
    }

    private func revealNextLine(totalLines: Int) {
        guard revealedLineCount < totalLines else { return }
        AppSettings.hapticImpact(.light)
        setRevealedLineCount(revealedLineCount + 1)
    }

    private func setRevealedLineCount(_ count: Int) {
        if reduceMotion {
            revealedLineCount = count
        } else {
            withAnimation(.easeInOut(duration: 0.35)) {
                revealedLineCount = count
            }
        }
    }

    @MainActor
    private func runSubtitlePacing(totalLines: Int) async {
        revealedLineCount = 1
        guard totalLines > 1 else { return }

        let estimatedDuration = narrationDuration > 0
            ? narrationDuration
            : Double(totalLines) * Self.fallbackSecondsPerLine
        let startDate = Date()
        var didTrackAudio = false

        while !Task.isCancelled, revealedLineCount < totalLines {
            try? await Task.sleep(nanoseconds: Self.pollIntervalNs)
            if Task.isCancelled { return }

            let progress: Double
            if let narrationResource {
                switch OnboardingNarrationPlayer.shared.playbackState {
                case .playing(let resource, let audioProgress) where resource == narrationResource:
                    didTrackAudio = true
                    progress = audioProgress
                case .finished(let resource) where resource == narrationResource:
                    progress = 1
                default:
                    if didTrackAudio {
                        // Narration was stopped or replaced: show the remaining text.
                        progress = 1
                    } else {
                        progress = estimatedProgress(
                            since: startDate,
                            duration: estimatedDuration,
                            delay: Self.audioStartGrace
                        )
                    }
                }
            } else {
                progress = estimatedProgress(since: startDate, duration: estimatedDuration, delay: 0)
            }

            let target = min(totalLines, Int(floor(progress * Double(totalLines))) + 1)
            if target > revealedLineCount {
                setRevealedLineCount(target)
            }
        }
    }

    private func estimatedProgress(since start: Date, duration: TimeInterval, delay: TimeInterval) -> Double {
        let elapsed = Date().timeIntervalSince(start) - delay
        guard elapsed > 0, duration > 0 else { return 0 }
        return min(elapsed / duration, 1)
    }
}
