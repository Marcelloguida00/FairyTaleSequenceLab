import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                languageSection
                Spacer()
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Color.appAccent)

                Text(lm.t("settings.title"))
                    .font(.system(.title2, design: .serif))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.appPrimaryText)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Text(lm.t("button.done"))
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.appAccent)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(lm.t("button.done"))
        }
        .padding(.bottom, 24)
    }

    // MARK: - Language section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lm.t("settings.language"))
                .font(.system(.caption, design: .rounded))
                .fontWeight(.black)
                .textCase(.uppercase)
                .foregroundStyle(Color.appSecondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                ForEach(Array(LanguageManager.supported.enumerated()), id: \.element.code) { index, lang in
                    languageRow(lang: lang, isLast: index == LanguageManager.supported.count - 1)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appPanelBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.appBorder, lineWidth: 1.5)
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
    }

    @ViewBuilder
    private func languageRow(lang: LanguageManager.Language, isLast: Bool) -> some View {
        let isSelected = lm.currentLanguage == lang.code

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                lm.currentLanguage = lang.code
            }
            AppSettings.hapticImpact(.light)
        } label: {
            HStack(spacing: 14) {
                Text(lang.flag)
                    .font(.system(size: 28))

                Text(lang.nativeName)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.appPrimaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.appAccent)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                isSelected
                    ? Color.appAccent.opacity(0.10)
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])

        if !isLast {
            Divider()
                .padding(.leading, 60)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager())
}
