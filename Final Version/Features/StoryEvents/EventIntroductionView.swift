import SwiftUI

struct EventIntroductionView: View {
    let event: EventData
    let onContinue: () -> Void

    @Environment(LanguageManager.self) private var lm

    var body: some View {
        if let lines = RedHoodDialogueLoader.introLines(eventId: event.id, from: lm.bundle), !lines.isEmpty {
            FairyTaleDialogueView(
                lines: lines,
                onComplete: onContinue
            )
        } else {
            legacyIntroduction
        }
    }

    private var legacyIntroduction: some View {
        GeometryReader { geometry in
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    if UIImage(named: event.introImageName) != nil {
                        Image(event.introImageName)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height * 0.65)
                            .clipped()
                            .accessibilityHidden(true)
                    } else {
                        ZStack {
                            LinearGradient(
                                colors: [Color(red: 0.15, green: 0.08, blue: 0.05), Color(red: 0.25, green: 0.15, blue: 0.10)],
                                startPoint: .top, endPoint: .bottom
                            )

                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(.largeTitle))
                                    .foregroundColor(Color(red: 0.8, green: 0.6, blue: 0.4))
                                    .accessibilityHidden(true)

                                Text(event.bannerTitle)
                                    .font(.app(.title, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Placeholder: 16:9 Introduction Image")
                                    .font(.app(.body))
                                    .foregroundColor(Color(red: 0.8, green: 0.7, blue: 0.6))
                            }
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height * 0.65)
                    }

                    ParchmentView {
                        HStack(alignment: .center, spacing: 24) {
                            Text(event.introText)
                                .font(.app(.title2))
                                .foregroundColor(Color.appPrimaryText)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            GamePillButton(
                                title: lm.t("button.continue"),
                                minWidth: 120,
                                minHeight: GameButtonMetrics.pillMinHeight(atLeast: 52),
                                trailingIcon: "arrow.right",
                                action: onContinue
                            )
                            .accessibilityLabel(lm.t("a11y.continue_button"))
                            .accessibilityHint(lm.t("a11y.continue_hint"))
                            .accessibilityAddTraits(.isButton)
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
