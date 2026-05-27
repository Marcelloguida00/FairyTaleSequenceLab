import SwiftUI

private enum SettingsTheme {
    static let background = Color(red: 0.976, green: 0.957, blue: 0.890)
    static let panelFill = Color(red: 0.976, green: 0.957, blue: 0.890)
    static let panelBorder = Color(red: 0.722, green: 0.631, blue: 0.420)
    static let primaryText = Color(red: 0.290, green: 0.204, blue: 0.180)
    static let secondaryText = Color(red: 0.549, green: 0.451, blue: 0.333)
    static let selectionFill = Color(red: 0.910, green: 0.851, blue: 0.710)
    static let controlFill = Color(red: 0.945, green: 0.918, blue: 0.827)
    static let divider = Color(red: 0.722, green: 0.631, blue: 0.420).opacity(0.35)
    static let sliderTrack = Color(red: 0.910, green: 0.851, blue: 0.710)
}

struct SettingsView: View {
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.dismiss) private var dismiss

    var onClose: (() -> Void)? = nil
    var inFrameMode: Bool = false

    @AppStorage("musicVolume") private var musicVolume: Double = 0.32
    @AppStorage("musicMuted")  private var musicMuted:  Bool   = false

    var body: some View {
        ZStack {
            if !inFrameMode {
                SettingsTheme.background.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, inFrameMode ? 8 : 28)
                    .padding(.top, inFrameMode ? 6 : 24)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: inFrameMode ? 20 : 28) {
                        languageSection
                        musicSection
                    }
                    .padding(.horizontal, inFrameMode ? 8 : 28)
                    .padding(.bottom, inFrameMode ? 8 : 32)
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
                    .foregroundStyle(SettingsTheme.secondaryText)

                Text(lm.t("settings.title"))
                    .font(.system(.title2, design: .serif))
                    .fontWeight(.bold)
                    .foregroundStyle(SettingsTheme.primaryText)
            }

            Spacer()

            Button {
                closeSettings()
            } label: {
                Text(lm.t("button.done"))
                    .font(.system(.body, design: .serif))
                    .fontWeight(.semibold)
                    .foregroundStyle(SettingsTheme.primaryText)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(SettingsTheme.controlFill)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(SettingsTheme.panelBorder, lineWidth: 1.5)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(lm.t("button.done"))
        }
        .padding(.bottom, inFrameMode ? 16 : 24)
    }

    private func closeSettings() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            sectionLine
            Text(title)
                .font(.system(.caption, design: .serif))
                .fontWeight(.semibold)
                .textCase(.uppercase)
                .foregroundStyle(SettingsTheme.secondaryText)
                .tracking(1.1)
            sectionLine
        }
        .padding(.horizontal, 4)
    }

    private var sectionLine: some View {
        Rectangle()
            .fill(SettingsTheme.divider)
            .frame(height: 1)
    }

    // MARK: - Language section

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lm.t("settings.language"))

            VStack(spacing: 0) {
                ForEach(Array(LanguageManager.supported.enumerated()), id: \.element.code) { index, lang in
                    languageRow(lang: lang, isLast: index == LanguageManager.supported.count - 1)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SettingsTheme.panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SettingsTheme.panelBorder, lineWidth: 1.5)
                    )
            )
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
                    .font(.system(.body, design: .serif))
                    .fontWeight(.regular)
                    .italic(isSelected)
                    .foregroundStyle(SettingsTheme.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SettingsTheme.secondaryText)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? SettingsTheme.selectionFill
                    : Color.clear
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])

        if !isLast {
            SettingsTheme.divider
                .frame(height: 1)
                .padding(.leading, 56)
        }
    }

    // MARK: - Music section

    private var musicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lm.t("settings.music"))

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(SettingsTheme.secondaryText)
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
                    .tint(SettingsTheme.secondaryText)
                    .disabled(musicMuted)
                    .opacity(musicMuted ? 0.45 : 1)
                    .animation(.easeInOut(duration: 0.2), value: musicMuted)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)

                SettingsTheme.divider
                    .frame(height: 1)
                    .padding(.leading, 56)

                Button {
                    AppSettings.hapticImpact(.light)
                    musicMuted.toggle()
                    BackgroundMusicPlayer.shared.setMuted(musicMuted)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .frame(width: 28)

                        Text(musicMuted ? lm.t("settings.music.unmute") : lm.t("settings.music.mute"))
                            .font(.system(.body, design: .serif))
                            .fontWeight(.regular)
                            .italic()
                            .foregroundStyle(SettingsTheme.primaryText)

                        Spacer()

                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(SettingsTheme.controlFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(SettingsTheme.panelBorder.opacity(0.7), lineWidth: 1)
                            )
                            .frame(width: 48, height: 28)
                            .overlay(
                                Circle()
                                    .fill(SettingsTheme.selectionFill)
                                    .overlay(
                                        Circle()
                                            .stroke(SettingsTheme.panelBorder.opacity(0.5), lineWidth: 1)
                                    )
                                    .frame(width: 22, height: 22)
                                    .offset(x: musicMuted ? 10 : -10)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: musicMuted)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(SettingsTheme.panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(SettingsTheme.panelBorder, lineWidth: 1.5)
                    )
            )
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager())
}
