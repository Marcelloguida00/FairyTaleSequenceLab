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
    static let menuPanelFill = Color(red: 0.98, green: 0.95, blue: 0.86)
    static let menuRowText = Color(red: 0.18, green: 0.10, blue: 0.08)
}

private enum SettingsRoute: Equatable {
    case main
    case advanced
    case detail(SettingsDetail)
}

struct SettingsView: View {
    @EnvironmentObject var lm: LanguageManager
    @Environment(AppFontSettings.self) private var fontSettings
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var onClose: (() -> Void)? = nil
    var inFrameMode: Bool = false
    var onAdvancedSettingsRequested: (() -> Void)? = nil
    @Binding var advancedSettingsUnlocked: Bool

    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("musicVolume") private var musicVolume: Double = 0.32
    @AppStorage("musicMuted")  private var musicMuted:  Bool   = false
    @AppStorage("musicTheme") private var musicTheme: String = BackgroundMusicTheme.gardenGate.rawValue
    @AppStorage("dyslexiaFontEnabled") private var dyslexiaFontEnabled = false
    @State private var showResetProgressConfirmation = false
    @State private var route: SettingsRoute = .main
    @State private var returnRoute: SettingsRoute = .main
    @State private var showInternalAdvancedMathGate = false
    @State private var internalAdvancedMathProblem = MathAdditionProblem.randomSimple()

    init(
        onClose: (() -> Void)? = nil,
        inFrameMode: Bool = false,
        onAdvancedSettingsRequested: (() -> Void)? = nil,
        advancedSettingsUnlocked: Binding<Bool> = .constant(false)
    ) {
        self.onClose = onClose
        self.inFrameMode = inFrameMode
        self.onAdvancedSettingsRequested = onAdvancedSettingsRequested
        self._advancedSettingsUnlocked = advancedSettingsUnlocked
    }

    private var usesFrameLayout: Bool {
        inFrameMode
    }

    private var usesExpandedMainRows: Bool {
        inFrameMode && route == .main
    }

    var body: some View {
        ZStack {
            if !inFrameMode {
                SettingsTheme.background.ignoresSafeArea()
            }

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, usesFrameLayout ? 0 : (inFrameMode ? 8 : 28))
                    .padding(.top, usesFrameLayout ? 0 : (inFrameMode ? 6 : 24))

                Group {
                    switch route {
                    case .main:
                        mainSettingsSection
                            .padding(.horizontal, usesFrameLayout ? 0 : (inFrameMode ? 8 : 28))
                            .padding(.bottom, usesFrameLayout ? 0 : (inFrameMode ? 8 : 32))
                            .frame(maxHeight: usesExpandedMainRows ? .infinity : nil)
                            .transition(.move(edge: .leading).combined(with: .opacity))

                    case .advanced:
                        ScrollView(.vertical, showsIndicators: false) {
                            advancedSettingsSection
                                .padding(.horizontal, usesFrameLayout ? 0 : 28)
                                .padding(.bottom, usesFrameLayout ? 0 : 32)
                        }
                        .frame(maxHeight: usesFrameLayout ? .infinity : nil)
                        .transition(.move(edge: .trailing).combined(with: .opacity))

                    case .detail(let selectedDetail):
                        settingsDetailView(selectedDetail)
                            .frame(maxHeight: usesFrameLayout ? .infinity : nil)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .id(lm.currentLanguage)
                .animation(.easeInOut(duration: 0.22), value: route)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if !inFrameMode && showInternalAdvancedMathGate {
                AdvancedSettingsMathGate(
                    problem: internalAdvancedMathProblem,
                    onSuccess: openAdvancedSettings,
                    onCancel: { showInternalAdvancedMathGate = false }
                )
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .onChange(of: advancedSettingsUnlocked) { _, unlocked in
            guard unlocked else { return }
            advancedSettingsUnlocked = false
            openAdvancedSettings()
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

    private var headerCircleSize: CGFloat {
        usesFrameLayout ? 52 : 40
    }

    private var headerTitleSize: CGFloat {
        usesFrameLayout ? 34 : 22
    }

    private var header: some View {
        HStack(spacing: 0) {
            GameCircleBackButton(size: headerCircleSize) {
                AppSettings.hapticImpact(.light)
                handleBackButton()
            }
            .accessibilityLabel(lm.t("button.back"))

            Text(headerTitle)
                .font(.app(size: headerTitleSize, weight: .bold))
                .foregroundStyle(SettingsTheme.menuRowText)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            Color.clear
                .frame(width: headerCircleSize, height: headerCircleSize)
                .accessibilityHidden(true)
        }
        .padding(.bottom, usesFrameLayout ? 18 : (inFrameMode ? 16 : 24))
    }

    private var headerTitle: String {
        switch route {
        case .main:
            return lm.t("settings.title")
        case .advanced:
            return lm.t("settings.advanced_settings")
        case .detail(let detail):
            return detail.title(using: lm)
        }
    }

    private func navigateBack() {
        withAnimation(.easeInOut(duration: 0.22)) {
            switch route {
            case .detail:
                route = returnRoute
            case .advanced:
                route = .main
            case .main:
                break
            }
        }
    }

    private func handleBackButton() {
        if route == .main {
            dismissSettings()
        } else {
            navigateBack()
        }
    }

    private func dismissSettings() {
        if let onClose {
            onClose()
        } else {
            dismiss()
        }
    }

    private func closeSettings() {
        dismissSettings()
    }

    // MARK: - Section header

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            sectionLine
            Text(title)
                .font(.app(size: usesFrameLayout ? 14 : 12, weight: .semibold))
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
    private func languageRow(lang: LanguageManager.Language, isLast: Bool, expanded: Bool = false) -> some View {
        let isSelected = lm.currentLanguage == lang.code

        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                lm.currentLanguage = lang.code
            }
            AppSettings.hapticImpact(.light)
        } label: {
            HStack(spacing: expanded ? 18 : 14) {
                Text(lang.flag)
                    .font(.app(size: expanded ? 34 : 28))

                Text(lang.nativeName)
                    .font(.app(size: expanded ? 22 : 17, weight: expanded ? .semibold : .regular))
                    .foregroundStyle(expanded ? SettingsTheme.menuRowText : SettingsTheme.primaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.app(size: expanded ? 26 : 20, weight: .semibold))
                        .foregroundStyle(SettingsTheme.menuRowText)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, expanded ? 24 : 16)
            .padding(.vertical, expanded ? 18 : 12)
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
                .frame(height: expanded ? 1.5 : 1)
                .padding(.leading, expanded ? 68 : 56)
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
                        fontSettings.dyslexiaFontEnabled.toggle()
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

                        settingsToggle(isOn: fontSettings.dyslexiaFontEnabled)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(lm.t("settings.dyslexia_font"))
                .accessibilityHint(lm.t("settings.dyslexia_font.description"))
                .accessibilityAddTraits(fontSettings.dyslexiaFontEnabled ? [.isSelected] : [])
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

                SettingsTheme.divider
                    .frame(height: 1)
                    .padding(.leading, 56)

                VStack(spacing: 0) {
                    ForEach(Array(BackgroundMusicTheme.allCases.enumerated()), id: \.element.id) { index, theme in
                        musicThemeRow(theme, isLast: index == BackgroundMusicTheme.allCases.count - 1)
                    }
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

    private func settingsToggle(isOn: Bool, expanded: Bool = false) -> some View {
        let trackWidth = expanded ? 58.0 : 48.0
        let trackHeight = expanded ? 34.0 : 28.0
        let knobSize = expanded ? 26.0 : 22.0
        let knobOffset = expanded ? 12.0 : 10.0

        return RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
            .fill(SettingsTheme.controlFill)
            .overlay(
                RoundedRectangle(cornerRadius: trackHeight / 2, style: .continuous)
                    .stroke(SettingsTheme.panelBorder.opacity(0.7), lineWidth: 1)
            )
            .frame(width: trackWidth, height: trackHeight)
            .overlay(
                Circle()
                    .fill(isOn ? SettingsTheme.selectionFill : SettingsTheme.panelFill)
                    .overlay(
                        Circle()
                            .stroke(SettingsTheme.panelBorder.opacity(0.5), lineWidth: 1)
                    )
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: isOn ? knobOffset : -knobOffset)
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

    // MARK: - Main settings (child-friendly)

    private var mainSettingsSection: some View {
        settingsCard(largeStyle: usesFrameLayout, fillAvailableHeight: usesExpandedMainRows) {
            settingsActionRow(
                icon: "speaker.wave.2.fill",
                title: lm.t("settings.sound"),
                detail: nil,
                showsDisclosure: true,
                largeStyle: usesFrameLayout,
                fillHeight: usesExpandedMainRows
            ) {
                openDetail(.sound, returningTo: .main)
            }

            settingsDivider(largeStyle: usesFrameLayout)

            settingsActionRow(
                icon: "app.badge",
                title: lm.t("settings.app_icon"),
                detail: nil,
                showsDisclosure: true,
                largeStyle: usesFrameLayout,
                fillHeight: usesExpandedMainRows
            ) {
                openDetail(.appIcon, returningTo: .main)
            }

            settingsDivider(largeStyle: usesFrameLayout)

            settingsActionRow(
                icon: "rectangle.stack.badge.play",
                title: lm.t("settings.show_onboarding_again"),
                detail: nil,
                showsDisclosure: false,
                largeStyle: usesFrameLayout,
                fillHeight: usesExpandedMainRows
            ) {
                AppSettings.hapticImpact(.light)
                hasSeenOnboarding = false
                closeSettings()
            }

            settingsDivider(largeStyle: usesFrameLayout)

            settingsActionRow(
                icon: "figure.and.child.holdinghands",
                title: lm.t("settings.advanced_settings"),
                detail: nil,
                showsDisclosure: true,
                largeStyle: usesFrameLayout,
                fillHeight: usesExpandedMainRows
            ) {
                requestAdvancedSettingsAccess()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: usesExpandedMainRows ? .infinity : nil)
    }

    // MARK: - Advanced settings (parent / support)

    private var advancedSettingsSection: some View {
        VStack(spacing: usesFrameLayout ? 24 : 18) {
            settingsCard(largeStyle: usesFrameLayout) {
                settingsActionRow(
                    icon: "figure",
                    title: lm.t("settings.accessibility"),
                    detail: nil,
                    showsDisclosure: true,
                    largeStyle: usesFrameLayout
                ) {
                    openDetail(.accessibility, returningTo: .advanced)
                }

                settingsDivider(largeStyle: usesFrameLayout)

                settingsActionRow(
                    icon: "globe",
                    title: lm.t("settings.change_language"),
                    detail: nil,
                    showsDisclosure: true,
                    largeStyle: usesFrameLayout
                ) {
                    openDetail(.changeLanguage, returningTo: .advanced)
                }

                settingsDivider(largeStyle: usesFrameLayout)

                settingsActionRow(
                    icon: "externaldrive.fill",
                    title: lm.t("settings.saved_data"),
                    detail: nil,
                    showsDisclosure: true,
                    largeStyle: usesFrameLayout
                ) {
                    openDetail(.savedData, returningTo: .advanced)
                }
            }

            settingsCard(largeStyle: usesFrameLayout) {
                settingsActionRow(
                    icon: "sparkles",
                    title: lm.t("settings.whats_new"),
                    detail: nil,
                    showsDisclosure: true,
                    largeStyle: usesFrameLayout
                ) {
                    openDetail(.whatsNew, returningTo: .advanced)
                }

                settingsDivider(largeStyle: usesFrameLayout)

                settingsActionRow(
                    icon: "envelope.fill",
                    title: lm.t("settings.contact_me"),
                    detail: nil,
                    showsDisclosure: false,
                    largeStyle: usesFrameLayout
                ) {
                    openURL(supportMailURL)
                }

                settingsDivider(largeStyle: usesFrameLayout)

                settingsActionRow(
                    icon: "heart.fill",
                    title: lm.t("settings.rate_app"),
                    detail: nil,
                    showsDisclosure: true,
                    largeStyle: usesFrameLayout
                ) {
                    openDetail(.rateApp, returningTo: .advanced)
                }

                settingsDivider(largeStyle: usesFrameLayout)

                settingsActionRow(
                    icon: "info.circle.fill",
                    title: lm.t("settings.about"),
                    detail: nil,
                    showsDisclosure: true,
                    largeStyle: usesFrameLayout
                ) {
                    openDetail(.about, returningTo: .advanced)
                }

                settingsDivider(largeStyle: usesFrameLayout)

                settingsActionRow(
                    icon: "hand.raised.fill",
                    title: lm.t("settings.privacy_policy"),
                    detail: nil,
                    showsDisclosure: true,
                    largeStyle: usesFrameLayout
                ) {
                    openDetail(.privacyPolicy, returningTo: .advanced)
                }
            }
        }
    }

    // MARK: - Legacy sections (kept for reference, unused in navigation)

    private func settingsDetailView(_ detail: SettingsDetail) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: usesFrameLayout ? 24 : 18) {
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
            .padding(.horizontal, usesFrameLayout ? 0 : (inFrameMode ? 0 : 28))
            .padding(.bottom, usesFrameLayout ? 0 : (inFrameMode ? 0 : 32))
        }
    }

    private func detailHeaderCard(_ detail: SettingsDetail) -> some View {
        settingsCard(largeStyle: usesFrameLayout) {
            VStack(alignment: .leading, spacing: usesFrameLayout ? 20 : 16) {
                Image(systemName: detail.icon)
                    .font(.app(size: usesFrameLayout ? 38 : 30, weight: .bold))
                    .foregroundStyle(SettingsTheme.menuRowText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(detail.title(using: lm))
                    .font(.app(size: usesFrameLayout ? 28 : 22, weight: .bold))
                    .foregroundStyle(SettingsTheme.menuRowText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(detail.message(using: lm))
                    .font(.app(size: usesFrameLayout ? 20 : 17, weight: .regular))
                    .foregroundStyle(SettingsTheme.secondaryText)
                    .lineSpacing(usesFrameLayout ? 6 : 5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(usesFrameLayout ? 24 : 18)
        }
    }

    private var accessibilityDetailCard: some View {
        settingsCard(largeStyle: usesFrameLayout) {
            Button {
                AppSettings.hapticImpact(.light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    fontSettings.dyslexiaFontEnabled.toggle()
                }
            } label: {
                HStack(spacing: usesFrameLayout ? 18 : 14) {
                    Image(systemName: "textformat")
                        .font(.app(size: usesFrameLayout ? 28 : 20, weight: .bold))
                        .foregroundStyle(SettingsTheme.menuRowText)
                        .frame(width: usesFrameLayout ? 36 : 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lm.t("settings.dyslexia_font"))
                            .font(.app(size: usesFrameLayout ? 22 : 17, weight: usesFrameLayout ? .semibold : .regular))
                            .foregroundStyle(usesFrameLayout ? SettingsTheme.menuRowText : SettingsTheme.primaryText)

                        Text(lm.t("settings.dyslexia_font.description"))
                            .font(.app(size: usesFrameLayout ? 16 : 12, weight: .regular))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    settingsToggle(isOn: fontSettings.dyslexiaFontEnabled, expanded: usesFrameLayout)
                }
                .padding(.horizontal, usesFrameLayout ? 24 : 18)
                .padding(.vertical, usesFrameLayout ? 20 : 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var soundDetailCard: some View {
        settingsCard(largeStyle: usesFrameLayout) {
            VStack(spacing: 0) {
                HStack(spacing: usesFrameLayout ? 18 : 14) {
                    Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.app(size: usesFrameLayout ? 28 : 20, weight: .bold))
                        .foregroundStyle(SettingsTheme.menuRowText)
                        .frame(width: usesFrameLayout ? 36 : 28)
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
                    .tint(SettingsTheme.menuRowText)
                    .disabled(musicMuted)
                    .opacity(musicMuted ? 0.45 : 1)
                    .animation(.easeInOut(duration: 0.2), value: musicMuted)
                }
                .padding(.horizontal, usesFrameLayout ? 24 : 18)
                .padding(.vertical, usesFrameLayout ? 20 : 16)

                settingsDivider(largeStyle: usesFrameLayout)

                Button {
                    AppSettings.hapticImpact(.light)
                    musicMuted.toggle()
                    BackgroundMusicPlayer.shared.setMuted(musicMuted)
                } label: {
                    HStack(spacing: usesFrameLayout ? 18 : 14) {
                        Image(systemName: musicMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.app(size: usesFrameLayout ? 28 : 20, weight: .bold))
                            .foregroundStyle(SettingsTheme.menuRowText)
                            .frame(width: usesFrameLayout ? 36 : 28)

                        Text(musicMuted ? lm.t("settings.music.unmute") : lm.t("settings.music.mute"))
                            .font(.app(size: usesFrameLayout ? 22 : 17, weight: usesFrameLayout ? .semibold : .regular))
                            .foregroundStyle(usesFrameLayout ? SettingsTheme.menuRowText : SettingsTheme.primaryText)

                        Spacer()

                        settingsToggle(isOn: musicMuted, expanded: usesFrameLayout)
                    }
                    .padding(.horizontal, usesFrameLayout ? 24 : 18)
                    .padding(.vertical, usesFrameLayout ? 20 : 16)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                settingsDivider()

                VStack(spacing: 0) {
                    ForEach(Array(BackgroundMusicTheme.allCases.enumerated()), id: \.element.id) { index, theme in
                        musicThemeRow(theme, isLast: index == BackgroundMusicTheme.allCases.count - 1)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func musicThemeRow(_ theme: BackgroundMusicTheme, isLast: Bool) -> some View {
        let isSelected = musicTheme == theme.rawValue

        Button {
            AppSettings.hapticImpact(.light)
            BackgroundMusicPlayer.shared.setTheme(theme)
            withAnimation(.easeInOut(duration: 0.2)) {
                musicTheme = theme.rawValue
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "music.note")
                    .font(.app(size: 20, weight: .semibold))
                    .foregroundStyle(SettingsTheme.secondaryText)
                    .frame(width: 28)

                Text(lm.t(theme.localizedNameKey))
                    .font(.app(.body))
                    .foregroundStyle(SettingsTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.app(size: 20, weight: .semibold))
                        .foregroundStyle(SettingsTheme.secondaryText)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(isSelected ? SettingsTheme.selectionFill : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(lm.t(theme.localizedNameKey))
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])

        if !isLast {
            settingsDivider()
        }
    }

    private var languageDetailCard: some View {
        settingsCard(largeStyle: usesFrameLayout) {
            VStack(spacing: 0) {
                ForEach(Array(LanguageManager.supported.enumerated()), id: \.element.code) { index, lang in
                    languageRow(
                        lang: lang,
                        isLast: index == LanguageManager.supported.count - 1,
                        expanded: usesFrameLayout
                    )
                }
            }
        }
    }

    private var savedDataDetailCard: some View {
        settingsCard(largeStyle: usesFrameLayout) {
            Button {
                AppSettings.hapticImpact(.medium)
                showResetProgressConfirmation = true
            } label: {
                HStack(spacing: usesFrameLayout ? 18 : 14) {
                    Image(systemName: "trash.fill")
                        .font(.app(size: usesFrameLayout ? 28 : 20, weight: .bold))
                        .foregroundStyle(Color.red)
                        .frame(width: usesFrameLayout ? 36 : 28)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(lm.t("settings.reset_progress"))
                            .font(.app(size: usesFrameLayout ? 22 : 17, weight: usesFrameLayout ? .semibold : .regular))
                            .foregroundStyle(Color.red)

                        Text(lm.t("settings.reset_progress.description"))
                            .font(.app(size: usesFrameLayout ? 16 : 12, weight: .regular))
                            .foregroundStyle(SettingsTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()
                }
                .padding(.horizontal, usesFrameLayout ? 24 : 18)
                .padding(.vertical, usesFrameLayout ? 20 : 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }

    private var aboutDetailContent: some View {
        VStack(alignment: .leading, spacing: usesFrameLayout ? 24 : 18) {
            settingsCard(largeStyle: usesFrameLayout) {
                VStack(alignment: .leading, spacing: usesFrameLayout ? 18 : 14) {
                    Text(lm.t("settings.about.message"))
                        .font(.app(size: usesFrameLayout ? 20 : 17, weight: .regular))
                        .foregroundStyle(SettingsTheme.secondaryText)
                        .lineSpacing(usesFrameLayout ? 6 : 5)
                        .fixedSize(horizontal: false, vertical: true)

                    SettingsTheme.divider
                        .frame(height: usesFrameLayout ? 1.5 : 1)

                    HStack(spacing: usesFrameLayout ? 14 : 10) {
                        Image(systemName: "number.circle.fill")
                            .font(.app(size: usesFrameLayout ? 26 : 20, weight: .bold))
                            .foregroundStyle(SettingsTheme.menuRowText)

                        Text("\(lm.t("settings.version")) \(appVersionText)")
                            .font(.app(size: usesFrameLayout ? 22 : 17, weight: usesFrameLayout ? .semibold : .regular))
                            .foregroundStyle(SettingsTheme.menuRowText)
                    }
                }
                .padding(usesFrameLayout ? 24 : 18)
            }

            sectionHeader(lm.t("info.developers"))

            VStack(spacing: usesFrameLayout ? 18 : 14) {
                ForEach(developers) { developer in
                    developerProfileCard(developer)
                }
            }
        }
    }

    private func developerProfileCard(_ developer: DeveloperProfile) -> some View {
        settingsCard(largeStyle: usesFrameLayout) {
            HStack(spacing: usesFrameLayout ? 20 : 16) {
                developerAvatar

                VStack(alignment: .leading, spacing: usesFrameLayout ? 10 : 8) {
                    Text(developer.name)
                        .font(.app(size: usesFrameLayout ? 22 : 17, weight: usesFrameLayout ? .semibold : .regular))
                        .foregroundStyle(SettingsTheme.menuRowText)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: usesFrameLayout ? 14 : 12) {
                        developerLinkButton(title: "LinkedIn", icon: "link", urlString: developer.linkedInURL)
                        developerLinkButton(title: "Instagram", icon: "camera.fill", urlString: developer.instagramURL)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(usesFrameLayout ? 20 : 16)
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
                    .font(.app(size: usesFrameLayout ? 15 : 13, weight: .bold))

                Text(title)
                    .font(.app(size: usesFrameLayout ? 15 : 13, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(SettingsTheme.menuRowText)
            .padding(.horizontal, usesFrameLayout ? 14 : 10)
            .padding(.vertical, usesFrameLayout ? 9 : 7)
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
    private func settingsCard<Content: View>(
        largeStyle: Bool = false,
        fillAvailableHeight: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .frame(maxWidth: .infinity, maxHeight: fillAvailableHeight ? .infinity : nil, alignment: .top)
        .background(
            RoundedRectangle(cornerRadius: largeStyle ? 24 : 18, style: .continuous)
                .fill(SettingsTheme.menuPanelFill)
                .overlay(
                    RoundedRectangle(cornerRadius: largeStyle ? 24 : 18, style: .continuous)
                        .stroke(SettingsTheme.panelBorder, lineWidth: largeStyle ? 2.5 : 2)
                )
        )
        .shadow(color: .black.opacity(largeStyle ? 0.08 : 0.06), radius: largeStyle ? 6 : 4, y: 2)
    }

    private func settingsDivider(largeStyle: Bool = false) -> some View {
        SettingsTheme.divider
            .frame(height: largeStyle ? 1.5 : 1)
            .padding(.leading, largeStyle ? 68 : 56)
    }

    private func settingsActionRow(
        icon: String,
        title: String,
        detail: String?,
        showsDisclosure: Bool,
        largeStyle: Bool = false,
        fillHeight: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AppSettings.hapticImpact(.light)
            action()
        } label: {
            HStack(spacing: largeStyle ? 18 : 14) {
                Image(systemName: icon)
                    .font(.app(size: largeStyle ? 28 : 20, weight: .bold))
                    .foregroundStyle(largeStyle ? SettingsTheme.menuRowText : SettingsTheme.secondaryText)
                    .frame(width: largeStyle ? 36 : 28)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.app(size: largeStyle ? 22 : 17, weight: largeStyle ? .semibold : .regular))
                        .foregroundStyle(largeStyle ? SettingsTheme.menuRowText : SettingsTheme.primaryText)
                        .lineLimit(largeStyle ? 2 : 1)
                        .minimumScaleFactor(largeStyle ? 0.82 : 1)
                        .multilineTextAlignment(.leading)

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
                        .font(.app(size: largeStyle ? 18 : 14, weight: .bold))
                        .foregroundStyle(
                            largeStyle
                                ? SettingsTheme.menuRowText.opacity(0.72)
                                : SettingsTheme.secondaryText.opacity(0.65)
                        )
                }
            }
            .padding(.horizontal, largeStyle ? 24 : 18)
            .padding(.vertical, fillHeight ? 0 : (largeStyle ? 18 : 16))
            .frame(maxWidth: .infinity, maxHeight: fillHeight ? .infinity : nil, alignment: .leading)
            .frame(minHeight: fillHeight ? 64 : nil)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .frame(maxHeight: fillHeight ? .infinity : nil)
        .accessibilityLabel(title)
    }

    private func resetProgress() {
        UserDefaults.standard.removeObject(forKey: "completedRedHoodLevels")
        UserDefaults.standard.removeObject(forKey: "currentBaseID")
        UserDefaults.standard.removeObject(forKey: "unlockedWorldBaseIDs")
        AppSettings.hapticSuccess()
    }

    private func requestAdvancedSettingsAccess() {
        AppSettings.hapticImpact(.light)

        if let onAdvancedSettingsRequested {
            onAdvancedSettingsRequested()
            return
        }

        internalAdvancedMathProblem = MathAdditionProblem.randomSimple()
        withAnimation(.easeInOut(duration: 0.2)) {
            showInternalAdvancedMathGate = true
        }
    }

    private func openAdvancedSettings() {
        showInternalAdvancedMathGate = false
        withAnimation(.easeInOut(duration: 0.22)) {
            route = .advanced
        }
    }

    private func openDetail(_ detail: SettingsDetail, returningTo: SettingsRoute) {
        returnRoute = returningTo
        withAnimation(.easeInOut(duration: 0.22)) {
            route = .detail(detail)
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

private enum SettingsDetail: Identifiable, Equatable {
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
