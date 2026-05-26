import SwiftUI

struct RewardView: View {
    let event: EventData
    let attemptCount: Int
    let onDismiss: () -> Void
    let onNext: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    private var stars: String {
        switch attemptCount {
        case 0: return "⭐⭐⭐"
        case 1, 2: return "⭐⭐"
        default: return "⭐"
        }
    }

    private var performanceNote: String {
        switch attemptCount {
        case 0: return lm.t("reward.perfect")
        case 1: return lm.t("reward.well_done")
        default: return lm.t("reward.did_it")
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Image(event.rewardImageName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.65)
                        .clipped()
                        .accessibilityHidden(true)

                    ParchmentView {
                        HStack(alignment: .center, spacing: 24) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(stars)
                                    .font(.title3)

                                Text(performanceNote)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.appSecondaryText)

                                Text(event.rewardText)
                                    .font(.system(.title2, design: .serif))
                                    .foregroundColor(Color.appPrimaryText)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(event.learningOutcome)
                                    .font(.system(.body, design: .rounded))
                                    .italic()
                                    .foregroundColor(Color.appSecondaryText)
                                    .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            VStack(spacing: 10) {
                                Button(action: onNext) {
                                    HStack(spacing: 8) {
                                        Text(event.isLastEvent ? lm.t("button.back_to_map") : lm.t("button.next_event"))
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.semibold)
                                        Image(systemName: event.isLastEvent ? "map" : "arrow.right")
                                            .font(.subheadline)
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                                    .frame(minWidth: 120, minHeight: 48)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(Color.appAccent)
                                            .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
                                    )
                                }
                                .buttonStyle(.plain)

                                Button(action: onDismiss) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.caption)
                                        Text(lm.t("button.play_again"))
                                            .font(.system(.caption, design: .rounded))
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(Color.appSecondaryText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.appPanelBackground)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
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
