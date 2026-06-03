import SwiftUI

struct EventIntroductionView: View {
    let event: EventData
    let onContinue: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    var body: some View {
        if let lines = RedHoodDialogueLoader.introLines(eventId: event.id, from: lm.bundle), !lines.isEmpty {
            FairyTaleDialogueView(
                lines: lines,
                continueButtonTitle: lm.t("button.continue"),
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
                                    .font(.system(size: 44))
                                    .foregroundColor(Color(red: 0.8, green: 0.6, blue: 0.4))

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
                                fontSize: 16,
                                horizontalPadding: 22,
                                verticalPadding: 14,
                                minWidth: 60,
                                minHeight: 60,
                                trailingIcon: "arrow.right",
                                action: onContinue
                            )
                            .accessibilityLabel(lm.t("a11y.continue_sequencing"))
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
