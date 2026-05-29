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
    @Environment(\.openURL) private var openURL

    var onClose: (() -> Void)? = nil
    var inFrameMode: Bool = false

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("musicVolume") private var musicVolume: Double = 0.32
    @AppStorage("musicMuted")  private var musicMuted:  Bool   = false
    @AppStorage("dyslexiaFontEnabled") private var dyslexiaFontEnabled = false

    @State private var showResetProgressConfirmation = false
    @State private var selectedDetail: SettingsDetail?

    var body: some View {
        ZStack {
            if !inFrameMode {
                SettingsTheme.background.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, inFrameMode ? 8 : 28)
                    .padding(.top, inFrameMode ? 6 : 24)

                Group {
                    if let selectedDetail {
                        settingsDetailView(selectedDetail)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: inFrameMode ? 20 : 28) {
                                appSection
                                supportSection
                            }
                            .padding(.horizontal, inFrameMode ? 8 : 28)
                            .padding(.bottom, inFrameMode ? 8 : 32)
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                .id(lm.currentLanguage)
                .animation(.easeInOut(duration: 0.22), value: selectedDetail?.id)
            }
        }
        .alert(lm.t("settings.reset_progress.confirm.title"), isPresented: $showResetProgressConfirmation) {
            Button(lm.t("button.cancel"), role: .cancel) { }
            Button(lm.t("settings.reset_progress.confirm.action"), role: .destructive) {
                resetProgress()
            }
        } message: {
            Text(lm.t("settings.reset_progress.confirm.message"))
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            if let selectedDetail {
                Button {
                    AppSettings.hapticImpact(.light)
                    withAnimation(.easeInOut(duration: 0.22)) {
                        self.selectedDetail = nil
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.app(size: 18, weight: .bold))

                        Text(selectedDetail.title(using: lm))
                            .font(.app(.title2))
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                    .foregroundStyle(SettingsTheme.primaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lm.t("button.back"))
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "gearshape.fill")
                        .font(.app(size: 22, weight: .bold))
                        .foregroundStyle(SettingsTheme.secondaryText)

                    Text(lm.t("settings.title"))
                        .font(.app(.title2))
                        .foregroundStyle(SettingsTheme.primaryText)
                }
            }

            Spacer()

            Button {
                closeSettings()
            } label: {
                Text(lm.t("button.done"))
                    .font(.app(.body))
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
        if selectedDetail != nil {
            withAnimation(.easeInOut(duration: 0.22)) {
                selectedDetail = nil
            }
            return
        }

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
                .font(.app(.caption))
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
                    .font(.app(size: 28))

                Text(lang.nativeName)
                    .font(.app(.body))
                    .foregroundStyle(SettingsTheme.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.app(size: 20, weight: .semibold))
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

    // MARK: - Accessibility section

    private var accessibilitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lm.t("settings.accessibility"))

            VStack(spacing: 0) {
                Button {
                    AppSettings.hapticImpact(.light)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dyslexiaFontEnabled.toggle()
                    }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "textformat")
                            .font(.app(size: 20, weight: .semibold))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(lm.t("settings.dyslexia_font"))
                                .font(.app(.body))
                                .foregroundStyle(SettingsTheme.primaryText)

                            Text(lm.t("settings.dyslexia_font.description"))
                                .font(.app(.caption))
                                .foregroundStyle(SettingsTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        settingsToggle(isOn: dyslexiaFontEnabled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lm.t("settings.dyslexia_font"))
                .accessibilityHint(lm.t("settings.dyslexia_font.description"))
                .accessibilityAddTraits(dyslexiaFontEnabled ? [.isSelected] : [])
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

    // MARK: - Music section

    private var musicSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lm.t("settings.sound"))

            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.app(size: 20, weight: .semibold))
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
                            .font(.app(size: 20, weight: .semibold))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .frame(width: 28)

                        Text(musicMuted ? lm.t("settings.music.unmute") : lm.t("settings.music.mute"))
                            .font(.app(.body))
                            .foregroundStyle(SettingsTheme.primaryText)

                        Spacer()

                        settingsToggle(isOn: musicMuted)
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

    private func settingsToggle(isOn: Bool) -> some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(SettingsTheme.controlFill)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(SettingsTheme.panelBorder.opacity(0.7), lineWidth: 1)
            )
            .frame(width: 48, height: 28)
            .overlay(
                Circle()
                    .fill(isOn ? SettingsTheme.selectionFill : SettingsTheme.panelFill)
                    .overlay(
                        Circle()
                            .stroke(SettingsTheme.panelBorder.opacity(0.5), lineWidth: 1)
                    )
                    .frame(width: 22, height: 22)
                    .offset(x: isOn ? 10 : -10)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
            )
    }

    // MARK: - Progress section

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lm.t("settings.saved_data"))

            VStack(alignment: .leading, spacing: 0) {
                Button {
                    AppSettings.hapticImpact(.medium)
                    showResetProgressConfirmation = true
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "trash.fill")
                            .font(.app(size: 20, weight: .semibold))
                            .foregroundStyle(Color.red)
                            .frame(width: 28)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(lm.t("settings.reset_progress"))
                                .font(.app(.body))
                                .foregroundStyle(Color.red)

                            Text(lm.t("settings.reset_progress.description"))
                                .font(.app(.caption))
                                .foregroundStyle(SettingsTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.app(size: 14, weight: .bold))
                            .foregroundStyle(SettingsTheme.secondaryText.opacity(0.65))
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lm.t("settings.reset_progress"))
                .accessibilityHint(lm.t("settings.reset_progress.description"))
            }
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(SettingsTheme.panelFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(SettingsTheme.panelBorder, lineWidth: 1.5)
                    )
            )
            .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
        }
    }

    // MARK: - App section

    private var appSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lm.t("settings.app"))

            settingsCard {
                settingsActionRow(
                    icon: "figure",
                    title: lm.t("settings.accessibility"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.accessibility)
                }

                settingsDivider()

                settingsActionRow(
                    icon: "speaker.wave.2.fill",
                    title: lm.t("settings.sound"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.sound)
                }

                settingsDivider()

                settingsActionRow(
                    icon: "globe",
                    title: lm.t("settings.change_language"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.changeLanguage)
                }

                settingsDivider()

                settingsActionRow(
                    icon: "app.badge",
                    title: lm.t("settings.app_icon"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.appIcon)
                }

                settingsDivider()

                settingsActionRow(
                    icon: "rectangle.stack.badge.play",
                    title: lm.t("settings.show_onboarding_again"),
                    detail: nil,
                    showsDisclosure: false
                ) {
                    AppSettings.hapticImpact(.light)
                    hasSeenOnboarding = false
                    closeSettings()
                }

                settingsDivider()

                settingsActionRow(
                    icon: "externaldrive.fill",
                    title: lm.t("settings.saved_data"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.savedData)
                }
            }
        }
    }

    // MARK: - Support section

    private var supportSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(lm.t("settings.support"))

            settingsCard {
                settingsActionRow(
                    icon: "sparkles",
                    title: lm.t("settings.whats_new"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.whatsNew)
                }

                settingsDivider()

                settingsActionRow(
                    icon: "envelope.fill",
                    title: lm.t("settings.contact_me"),
                    detail: nil,
                    showsDisclosure: false
                ) {
                    openURL(supportMailURL)
                }

                settingsDivider()

                settingsActionRow(
                    icon: "heart.fill",
                    title: lm.t("settings.rate_app"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.rateApp)
                }

                settingsDivider()

                settingsActionRow(
                    icon: "info.circle.fill",
                    title: lm.t("settings.about"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.about)
                }

                settingsDivider()

                settingsActionRow(
                    icon: "hand.raised.fill",
                    title: lm.t("settings.privacy_policy"),
                    detail: nil,
                    showsDisclosure: true
                ) {
                    openDetail(.privacyPolicy)
                }
            }
        }
    }

    private func settingsDetailView(_ detail: SettingsDetail) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                if detail == .about {
                    aboutDetailContent
                } else {
                    detailHeaderCard(detail)

                    switch detail {
                    case .accessibility:
                        accessibilityDetailCard
                    case .sound:
                        soundDetailCard
                    case .changeLanguage:
                        languageDetailCard
                    case .savedData:
                        savedDataDetailCard
                    default:
                        EmptyView()
                    }
                }
            }
            .padding(.horizontal, inFrameMode ? 8 : 28)
            .padding(.bottom, inFrameMode ? 8 : 32)
        }
    }

    private func detailHeaderCard(_ detail: SettingsDetail) -> some View {
        settingsCard {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: detail.icon)
                    .font(.app(size: 30, weight: .bold))
                    .foregroundStyle(SettingsTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(detail.title(using: lm))
                    .font(.app(.title2))
                    .foregroundStyle(SettingsTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail.message(using: lm))
                    .font(.app(.body))
                    .foregroundStyle(SettingsTheme.secondaryText)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
        }
    }

    private var accessibilityDetailCard: some View {
        settingsCard {
            Button {
                AppSettings.hapticImpact(.light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    dyslexiaFontEnabled.toggle()
                }
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "textformat")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundStyle(SettingsTheme.secondaryText)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lm.t("settings.dyslexia_font"))
                            .font(.app(.body))
                            .foregroundStyle(SettingsTheme.primaryText)

                        Text(lm.t("settings.dyslexia_font.description"))
                            .font(.app(.caption))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    settingsToggle(isOn: dyslexiaFontEnabled)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var soundDetailCard: some View {
        settingsCard {
            VStack(spacing: 0) {
                HStack(spacing: 14) {
                    Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundStyle(SettingsTheme.secondaryText)
                        .frame(width: 28)

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
                .padding(.horizontal, 18)
                .padding(.vertical, 16)

                settingsDivider()

                Button {
                    AppSettings.hapticImpact(.light)
                    musicMuted.toggle()
                    BackgroundMusicPlayer.shared.setMuted(musicMuted)
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.app(size: 20, weight: .semibold))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .frame(width: 28)

                        Text(musicMuted ? lm.t("settings.music.unmute") : lm.t("settings.music.mute"))
                            .font(.app(.body))
                            .foregroundStyle(SettingsTheme.primaryText)

                        Spacer()

                        settingsToggle(isOn: musicMuted)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var languageDetailCard: some View {
        settingsCard {
            VStack(spacing: 0) {
                ForEach(Array(LanguageManager.supported.enumerated()), id: \.element.code) { index, lang in
                    languageRow(lang: lang, isLast: index == LanguageManager.supported.count - 1)
                }
            }
        }
    }

    private var savedDataDetailCard: some View {
        settingsCard {
            Button {
                AppSettings.hapticImpact(.medium)
                showResetProgressConfirmation = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "trash.fill")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundStyle(Color.red)
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lm.t("settings.reset_progress"))
                            .font(.app(.body))
                            .foregroundStyle(Color.red)

                        Text(lm.t("settings.reset_progress.description"))
                            .font(.app(.caption))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutDetailContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            settingsCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text(lm.t("settings.about.message"))
                        .font(.app(.body))
                        .foregroundStyle(SettingsTheme.secondaryText)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)

                    SettingsTheme.divider
                        .frame(height: 1)

                    HStack(spacing: 10) {
                        Image(systemName: "number.circle.fill")
                            .font(.app(size: 20, weight: .bold))
                            .foregroundStyle(SettingsTheme.secondaryText)

                        Text("\(lm.t("settings.version")) \(appVersionText)")
                            .font(.app(.body))
                            .foregroundStyle(SettingsTheme.primaryText)
                    }
                }
                .padding(18)
            }

            sectionHeader(lm.t("info.developers"))

            VStack(spacing: 14) {
                ForEach(developers) { developer in
                    developerProfileCard(developer)
                }
            }
        }
    }

    private func developerProfileCard(_ developer: DeveloperProfile) -> some View {
        settingsCard {
            HStack(spacing: 16) {
                developerAvatar

                VStack(alignment: .leading, spacing: 8) {
                    Text(developer.name)
                        .font(.app(.body))
                        .foregroundStyle(SettingsTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        developerLinkButton(title: "LinkedIn", icon: "link", urlString: developer.linkedInURL)
                        developerLinkButton(title: "Instagram", icon: "camera.fill", urlString: developer.instagramURL)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }

    private var developerAvatar: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.78, green: 0.78, blue: 0.78))

            VStack(spacing: 0) {
                Circle()
                    .fill(.white)
                    .frame(width: 42, height: 42)

                Circle()
                    .fill(.white)
                    .frame(width: 76, height: 76)
                    .offset(y: -5)
            }
            .offset(y: 11)
        }
        .frame(width: 86, height: 86)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(SettingsTheme.panelBorder.opacity(0.65), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.16), radius: 4, y: 2)
        .accessibilityHidden(true)
    }

    private func developerLinkButton(title: String, icon: String, urlString: String) -> some View {
        Button {
            guard let url = URL(string: urlString), !urlString.isEmpty else { return }
            openURL(url)
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.app(size: 13, weight: .bold))

                Text(title)
                    .font(.app(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(SettingsTheme.primaryText)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(SettingsTheme.controlFill)
            )
            .overlay(
                Capsule()
                    .stroke(SettingsTheme.panelBorder.opacity(0.75), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(urlString.isEmpty)
        .opacity(urlString.isEmpty ? 0.48 : 1)
        .accessibilityLabel(title)
    }

    @ViewBuilder
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(SettingsTheme.panelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(SettingsTheme.panelBorder, lineWidth: 1.5)
                )
        )
        .shadow(color: .black.opacity(0.08), radius: 6, y: 3)
    }

    private func settingsDivider() -> some View {
        SettingsTheme.divider
            .frame(height: 1)
            .padding(.leading, 56)
    }

    private func settingsActionRow(
        icon: String,
        title: String,
        detail: String?,
        showsDisclosure: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AppSettings.hapticImpact(.light)
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.app(size: 20, weight: .semibold))
                    .foregroundStyle(SettingsTheme.secondaryText)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.app(.body))
                        .foregroundStyle(SettingsTheme.primaryText)

                    if let detail {
                        Text(detail)
                            .font(.app(.caption))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                if showsDisclosure {
                    Image(systemName: "chevron.right")
                        .font(.app(size: 14, weight: .bold))
                        .foregroundStyle(SettingsTheme.secondaryText.opacity(0.65))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }

    private func resetProgress() {
        UserDefaults.standard.removeObject(forKey: "completedRedHoodLevels")
        UserDefaults.standard.removeObject(forKey: "currentBaseID")
        AppSettings.hapticSuccess()
    }

    private func openDetail(_ detail: SettingsDetail) {
        withAnimation(.easeInOut(duration: 0.22)) {
            selectedDetail = detail
        }
    }

    private func cycleLanguage() {
        guard let currentIndex = LanguageManager.supported.firstIndex(where: { $0.code == lm.currentLanguage }) else {
            lm.currentLanguage = LanguageManager.supported.first?.code ?? "en"
            return
        }

        let nextIndex = LanguageManager.supported.index(after: currentIndex)
        let wrappedIndex = nextIndex == LanguageManager.supported.endIndex ? LanguageManager.supported.startIndex : nextIndex

        withAnimation(.easeInOut(duration: 0.2)) {
            lm.currentLanguage = LanguageManager.supported[wrappedIndex].code
        }
    }

    private var supportMailURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = "mguida2604@gmail.com"
        components.queryItems = [
            URLQueryItem(name: "subject", value: lm.t("info.support_email_subject"))
        ]

        return components.url ?? URL(string: "mailto:mguida2604@gmail.com")!
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var developers: [DeveloperProfile] {
        [
            DeveloperProfile(name: "Calisto Ciro", linkedInURL: "", instagramURL: ""),
            DeveloperProfile(name: "Chiappetta Giulia", linkedInURL: "", instagramURL: ""),
            DeveloperProfile(name: "De Marco Francesca", linkedInURL: "", instagramURL: ""),
            DeveloperProfile(name: "Guida Marcello", linkedInURL: "", instagramURL: ""),
            DeveloperProfile(name: "Karameta Albi", linkedInURL: "", instagramURL: ""),
            DeveloperProfile(name: "Toshpulatov Bobur", linkedInURL: "", instagramURL: ""),
            DeveloperProfile(name: "Torcicollo Adolfo", linkedInURL: "", instagramURL: "")
        ]
    }
}

private struct DeveloperProfile: Identifiable {
    let id = UUID()
    let name: String
    let linkedInURL: String
    let instagramURL: String
}

private enum SettingsDetail: Identifiable {
    case accessibility
    case sound
    case appIcon
    case changeLanguage
    case savedData
    case whatsNew
    case rateApp
    case about
    case privacyPolicy

    var id: String {
        switch self {
        case .accessibility: return "accessibility"
        case .sound: return "sound"
        case .appIcon: return "appIcon"
        case .changeLanguage: return "changeLanguage"
        case .savedData: return "savedData"
        case .whatsNew: return "whatsNew"
        case .rateApp: return "rateApp"
        case .about: return "about"
        case .privacyPolicy: return "privacyPolicy"
        }
    }

    var icon: String {
        switch self {
        case .accessibility: return "figure"
        case .sound: return "speaker.wave.2.fill"
        case .appIcon: return "app.badge"
        case .changeLanguage: return "globe"
        case .savedData: return "externaldrive.fill"
        case .whatsNew: return "sparkles"
        case .rateApp: return "heart.fill"
        case .about: return "info.circle.fill"
        case .privacyPolicy: return "hand.raised.fill"
        }
    }

    func title(using lm: LanguageManager) -> String {
        switch self {
        case .accessibility: return lm.t("settings.accessibility")
        case .sound: return lm.t("settings.sound")
        case .appIcon: return lm.t("settings.app_icon")
        case .changeLanguage: return lm.t("settings.change_language")
        case .savedData: return lm.t("settings.saved_data")
        case .whatsNew: return lm.t("settings.whats_new")
        case .rateApp: return lm.t("settings.rate_app")
        case .about: return lm.t("settings.about")
        case .privacyPolicy: return lm.t("settings.privacy_policy")
        }
    }

    func message(using lm: LanguageManager) -> String {
        switch self {
        case .accessibility:
            return lm.t("settings.accessibility.message")
        case .sound:
            return lm.t("settings.sound.message")
        case .appIcon:
            return lm.t("settings.app_icon.message")
        case .changeLanguage:
            return lm.t("settings.change_language.message")
        case .savedData:
            return lm.t("settings.reset_progress.confirm.message")
        case .whatsNew:
            return lm.t("settings.whats_new.message")
        case .rateApp:
            return lm.t("settings.rate_app.message")
        case .about:
            return lm.t("settings.about.message")
        case .privacyPolicy:
            return lm.t("settings.privacy_policy.message")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager())
}
