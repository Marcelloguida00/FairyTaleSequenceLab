import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    @AppStorage("musicVolume") private var musicVolume: Double = 0.32
    @AppStorage("musicMuted")  private var musicMuted:  Bool   = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, 28)
                    .padding(.top, 24)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 28) {
                        languageSection
                        musicSection
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
                }
            }
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

    // MARK: - Music section

    private var musicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lm.t("settings.music"))
                .font(.system(.caption, design: .rounded))
                .fontWeight(.black)
                .textCase(.uppercase)
                .foregroundStyle(Color.appSecondaryText)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                // Volume slider row
                HStack(spacing: 14) {
                    Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(musicMuted ? Color.appSecondaryText : Color.appAccent)
                        .frame(width: 28)
                        .animation(.easeInOut(duration: 0.2), value: musicMuted)

                    Slider(value: Binding(
                        get: { musicMuted ? 0 : musicVolume },
                        set: { newValue in
                            musicVolume = newValue
                            if musicMuted && newValue > 0 {
                                musicMuted = false
                                BackgroundMusicPlayer.shared.setMuted(false)
                            }
                            BackgroundMusicPlayer.shared.setVolume(Float(newValue))
                        }
                    ), in: 0...1)
                    .tint(Color.appAccent)
                    .disabled(musicMuted)
                    .opacity(musicMuted ? 0.4 : 1)
                    .animation(.easeInOut(duration: 0.2), value: musicMuted)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)

                Divider()
                    .padding(.leading, 60)

                // Mute toggle row
                Button {
                    AppSettings.hapticImpact(.light)
                    musicMuted.toggle()
                    BackgroundMusicPlayer.shared.setMuted(musicMuted)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(musicMuted ? Color.appSecondaryText : Color.appAccent)
                            .frame(width: 28)

                        Text(musicMuted ? lm.t("settings.music.unmute") : lm.t("settings.music.mute"))
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(Color.appPrimaryText)

                        Spacer()

                        // Toggle indicator
                        RoundedRectangle(cornerRadius: 14)
                            .fill(musicMuted ? Color.appSecondaryText.opacity(0.3) : Color.appAccent)
                            .frame(width: 48, height: 28)
                            .overlay(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 22, height: 22)
                                    .offset(x: musicMuted ? -10 : 10)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: musicMuted)
                            )
                            .animation(.easeInOut(duration: 0.2), value: musicMuted)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
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
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager())
}
