import SwiftUI

private let menuPanelAspectRatio: CGFloat = 600.0 / 1072.0

struct MainMenuSceneView: View {
    @Binding var cloudEnterProgress: CGFloat
    @Binding var cloudExitProgress: CGFloat

    var body: some View {
        ZStack {
            WorldMapBackgroundView()
                .accessibilityHidden(true)

            CloudTransitionOverlay(
                enterProgress: cloudEnterProgress,
                exitProgress: cloudExitProgress
            )
            .allowsHitTesting(false)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Pannello sopra le nuvole (dissolvenza + Play)

struct MainMenuPanelLayer: View {
    let isTransitioning: Bool
    let resetID: Int
    var deferPanelReveal: Bool = false
    let onPlay: () -> Void

    @State private var panelOpacity: Double = 0
    @State private var panelScale: CGFloat = 1.04
    @State private var isPanelDissolving = false
    @State private var didRevealPanel = false
    @State private var showSettings = false
    @State private var isSettingsTransitionActive = false
    @State private var showsSettingsCloudOverlay = false
    @State private var settingsCloudEnterProgress: CGFloat = 0
    @State private var settingsCloudExitProgress: CGFloat = 0
    @State private var showAdvancedMathGate = false
    @State private var advancedMathProblem = MathAdditionProblem.randomSimple()
    @State private var advancedSettingsUnlocked = false
    @Environment(LanguageManager.self) var lm
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let panelFadeDuration: TimeInterval = 0.30
    private static let settingsFadeDuration: TimeInterval = 0.30

    private var settingsFadeAnimation: Animation {
        reduceMotion
            ? .linear(duration: 0.01)
            : .easeInOut(duration: Self.settingsFadeDuration)
    }

    private var cloudEnterDuration: TimeInterval {
        reduceMotion ? 0.01 : CloudTransitionAnimator.enterDuration
    }

    private var cloudExitDuration: TimeInterval {
        reduceMotion ? 0.01 : CloudTransitionAnimator.exitDuration
    }

    private var isInteractionBlocked: Bool {
        isTransitioning || isPanelDissolving || isSettingsTransitionActive || showSettings
    }

    var body: some View {
        MenuPanelView(
            isDisabled: isInteractionBlocked,
            onPlay: startGame,
            onSettings: { Task { await openSettings() } }
        )
        .opacity(panelOpacity)
        .scaleEffect(panelScale)
        .allowsHitTesting(panelOpacity > 0.5 && !isInteractionBlocked)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .id(resetID)
        .overlay {
            if showsSettingsCloudOverlay {
                CloudTransitionOverlay(
                    enterProgress: settingsCloudEnterProgress,
                    exitProgress: settingsCloudExitProgress
                )
                .allowsHitTesting(false)
                .zIndex(50)
            }

            if showSettings {
                SettingsFrameOverlay(
                    onClose: { Task { await closeSettings() } },
                    onAdvancedSettingsRequested: {
                        advancedMathProblem = MathAdditionProblem.randomSimple()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAdvancedMathGate = true
                        }
                    },
                    advancedSettingsUnlocked: $advancedSettingsUnlocked
                )
                .environment(lm)
                .transition(.opacity)
                .zIndex(100)
                .allowsHitTesting(!showAdvancedMathGate)
            }

            if showAdvancedMathGate {
                AdvancedSettingsMathGate(
                    problem: advancedMathProblem,
                    onSuccess: {
                        showAdvancedMathGate = false
                        advancedSettingsUnlocked = true
                    },
                    onCancel: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            showAdvancedMathGate = false
                        }
                    }
                )
                .environment(lm)
                .transition(.opacity)
                .zIndex(200)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            if !deferPanelReveal {
                tryRevealPanel()
            }
        }
        .onChange(of: deferPanelReveal) { _, shouldDefer in
            if !shouldDefer {
                tryRevealPanel()
            }
        }
        .onChange(of: resetID) { _, _ in
            if !deferPanelReveal {
                revealPanel()
            }
        }
    }

    @MainActor
    private func openSettings() async {
        guard !isSettingsTransitionActive, !isTransitioning, !showSettings else { return }

        isSettingsTransitionActive = true
        AppSettings.hapticImpact(.light)

        showsSettingsCloudOverlay = true
        settingsCloudExitProgress = 0
        settingsCloudEnterProgress = 0

        withAnimation(.easeInOut(duration: cloudEnterDuration)) {
            settingsCloudEnterProgress = 1
        }

        try? await Task.sleep(nanoseconds: UInt64(cloudEnterDuration * 1_000_000_000))

        withAnimation(settingsFadeAnimation) {
            showSettings = true
        }

        if !reduceMotion {
            try? await Task.sleep(nanoseconds: UInt64(Self.settingsFadeDuration * 1_000_000_000))
        }

        isSettingsTransitionActive = false
    }

    @MainActor
    private func closeSettings() async {
        guard showSettings, !isSettingsTransitionActive else { return }

        isSettingsTransitionActive = true
        AppSettings.hapticImpact(.light)

        withAnimation(settingsFadeAnimation) {
            showSettings = false
            showAdvancedMathGate = false
        }

        try? await Task.sleep(nanoseconds: UInt64(Self.settingsFadeDuration * 1_000_000_000))

        withAnimation(.easeInOut(duration: cloudExitDuration)) {
            settingsCloudExitProgress = 1
        }

        try? await Task.sleep(nanoseconds: UInt64(cloudExitDuration * 1_000_000_000))

        settingsCloudEnterProgress = 0
        settingsCloudExitProgress = 0
        showsSettingsCloudOverlay = false
        isSettingsTransitionActive = false
    }

    private func tryRevealPanel() {
        guard !didRevealPanel else { return }
        didRevealPanel = true
        revealPanel()
    }

    private func revealPanel() {
        isPanelDissolving = false

        if reduceMotion {
            panelOpacity = 1
            panelScale = 1
            return
        }

        panelOpacity = 0
        panelScale = 1.04

        withAnimation(.easeOut(duration: Self.panelFadeDuration)) {
            panelOpacity = 1
            panelScale = 1
        }
    }

    private func startGame() {
        guard !isTransitioning, !isPanelDissolving else { return }
        isPanelDissolving = true
        AppSettings.hapticImpact(.medium)

        if reduceMotion {
            panelOpacity = 0
            panelScale = 1
            onPlay()
            return
        }

        withAnimation(.easeOut(duration: Self.panelFadeDuration)) {
            panelOpacity = 0
            panelScale = 1.04
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Self.panelFadeDuration * 1_000_000_000))
            onPlay()
        }
    }
}

private struct InfoFrameOverlay: View {
    let onClose: () -> Void

    var body: some View {
        GeometryReader { proxy in
            let frameSize = fittedInfoFrameSize(in: proxy.size)

            ZStack {
                ZStack {
                    Image("framesettings")
                        .renderingMode(.original)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                        .frame(width: frameSize.width, height: frameSize.height)
                        .shadow(color: .black.opacity(0.36), radius: 16, y: 10)
                        .accessibilityHidden(true)

                    InfoView(onClose: onClose)
                        .frame(width: frameSize.width * 0.72, height: frameSize.height * 0.70)
                        .padding(.top, frameSize.height * 0.04)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func fittedInfoFrameSize(in container: CGSize) -> CGSize {
        let maxHeight = container.height * 0.90
        let maxWidth = container.width * 0.92
        var height = maxHeight
        var width = height * SettingsFrameLayout.aspectRatio

        if width > maxWidth {
            width = maxWidth
            height = width / SettingsFrameLayout.aspectRatio
        }

        return CGSize(width: width, height: height)
    }
}

private enum InfoTheme {
    static let panelFill = Color(red: 0.976, green: 0.957, blue: 0.890)
    static let panelBorder = Color(red: 0.722, green: 0.631, blue: 0.420)
    static let primaryText = Color(red: 0.290, green: 0.204, blue: 0.180)
    static let secondaryText = Color(red: 0.549, green: 0.451, blue: 0.333)
    static let controlFill = Color(red: 0.945, green: 0.918, blue: 0.827)
    static let divider = Color(red: 0.722, green: 0.631, blue: 0.420).opacity(0.35)
}

private struct InfoView: View {
    let onClose: () -> Void

    @Environment(LanguageManager.self) private var lm

    private let supportEmail = "mguida2604@gmail.com"
    private let developers = [
        "Calisto Ciro",
        "Chiappetta Giulia",
        "De Marco Francesca",
        "Guida Marcello",
        "Karameta Albi",
        "Toshpulatov Bobur",
        "Torcicollo Adolfo"
    ]

    private let collaborators = [
        "Razzino Alberto"
    ]

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 8)
                .padding(.top, 6)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    sectionHeader(lm.t("info.developers"))

                    VStack(spacing: 0) {
                        ForEach(Array(developers.enumerated()), id: \.offset) { index, developer in
                            developerRow(developer, isLast: index == developers.count - 1)
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(lm.t("info.developers"))
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(InfoTheme.panelFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(InfoTheme.panelBorder, lineWidth: 1.5)
                            )
                    )

                    if AppFeatureFlags.showsCollaboratorsInAbout {
                        sectionHeader(lm.t("info.collaborators"))

                        VStack(spacing: 0) {
                            ForEach(Array(collaborators.enumerated()), id: \.offset) { index, collaborator in
                                developerRow(collaborator, isLast: index == collaborators.count - 1)
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel(lm.t("info.collaborators"))
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(InfoTheme.panelFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(InfoTheme.panelBorder, lineWidth: 1.5)
                                )
                        )
                    }

                    sectionHeader(lm.t("info.contacts"))

                    VStack(spacing: 0) {
                        contactRow
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(InfoTheme.panelFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(InfoTheme.panelBorder, lineWidth: 1.5)
                            )
                    )


                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
        }
    }

    private var header: some View {
        HStack {
            HStack(spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .font(.app(.title2, weight: .bold))
                    .foregroundStyle(InfoTheme.secondaryText)
                    .accessibilityHidden(true)

                Text(lm.t("info.title"))
                    .font(.app(.title2))
                    .foregroundStyle(InfoTheme.primaryText)
                    .accessibilityAddTraits(.isHeader)
            }

            Spacer()

            GamePillButton(
                title: lm.t("button.done"),
                action: onClose
            )
            .accessibilityLabel(lm.t("a11y.info_close_button"))
        }
        .padding(.bottom, 16)
    }

    private func sectionHeader(_ title: String) -> some View {
        HStack(spacing: 10) {
            sectionLine
            Text(title)
                .font(.app(.caption))
                .textCase(.uppercase)
                .foregroundStyle(InfoTheme.secondaryText)
                .tracking(1.1)
                .accessibilityAddTraits(.isHeader)
            sectionLine
        }
        .padding(.horizontal, 4)
    }

    private var sectionLine: some View {
        Rectangle()
            .fill(InfoTheme.divider)
            .frame(height: 1)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private func developerRow(_ name: String, isLast: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "person.fill")
                .font(.app(.body, weight: .semibold))
                .foregroundStyle(InfoTheme.secondaryText)
                .frame(width: 28)
                .accessibilityHidden(true)

            Text(name)
                .font(.app(.body))
                .foregroundStyle(InfoTheme.primaryText)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)

        if !isLast {
            InfoTheme.divider
                .frame(height: 1)
                .padding(.leading, 56)
                .accessibilityHidden(true)
        }
    }

    private var contactRow: some View {
        Link(destination: supportMailURL) {
            HStack(spacing: 14) {
                Image(systemName: "envelope.fill")
                    .font(.app(.body, weight: .semibold))
                    .foregroundStyle(InfoTheme.secondaryText)
                    .frame(width: 28)
                    .accessibilityHidden(true)

                Text(supportEmail)
                    .font(.app(.body))
                    .foregroundStyle(InfoTheme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.app(.footnote, weight: .bold))
                    .foregroundStyle(InfoTheme.secondaryText.opacity(0.70))
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .gameSettingsRowTouchTarget()
        }
        .buttonStyle(.plain)
        .gameMinimumTouchTarget()
        .accessibilityLabel(lm.t("a11y.info_email_button"))
    }

    private var supportMailURL: URL {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: lm.t("info.support_email_subject"))
        ]

        return components.url ?? URL(string: "mailto:\(supportEmail)")!
    }
}

// MARK: - Pannello centrale (cornice + titolo + Play)

private struct MenuPanelView: View {
    let isDisabled: Bool
    let onPlay: () -> Void
    let onSettings: () -> Void

    @Environment(LanguageManager.self) private var lm

    var body: some View {
        GeometryReader { proxy in
            let panelSize = fittedPanelSize(in: proxy.size)

            ZStack {
                Image("bordomenu")
                    .renderingMode(.original)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: panelSize.width, height: panelSize.height)
                    .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
                    .accessibilityHidden(true)

                VStack(spacing: panelSize.height * 0.03) {
                    AppMenuTitleView(panelWidth: panelSize.width, style: .mainMenu)

                    Spacer(minLength: panelSize.height * 0.02)

                    MenuPlayButton(
                        width: panelSize.width * 0.72,
                        isDisabled: isDisabled,
                        action: onPlay
                    )

                    MenuSettingsButton(
                        width: panelSize.width * 0.72,
                        isDisabled: isDisabled,
                        action: onSettings
                    )

                    Spacer(minLength: panelSize.height * 0.06)
                }
                .padding(.horizontal, panelSize.width * 0.14)
                .padding(.top, panelSize.height * 0.14)
                .padding(.bottom, panelSize.height * 0.12)
                .frame(width: panelSize.width, height: panelSize.height)
                .clipped()
                .accessibilityElement(children: .contain)
                .accessibilityLabel(lm.t("a11y.main_menu"))
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func fittedPanelSize(in container: CGSize) -> CGSize {
        let maxHeight = container.height * 0.82
        let maxWidth = container.width * 0.42
        var height = maxHeight
        var width = height * menuPanelAspectRatio

        if width > maxWidth {
            width = maxWidth
            height = width / menuPanelAspectRatio
        }

        return CGSize(width: width, height: height)
    }
}

// MARK: - Bottone Settings

private struct MenuSettingsButton: View {
    let width: CGFloat
    let isDisabled: Bool
    let action: () -> Void

    @Environment(LanguageManager.self) private var lm

    var body: some View {
        GamePillButton(
            title: lm.t("button.settings"),
            fontSize: width * 0.105,
            horizontalPadding: width * 0.05,
            verticalPadding: width * 0.055,
            minWidth: width,
            minHeight: GameButtonMetrics.pillMinHeight(atLeast: width * 0.26),
            isDisabled: isDisabled,
            action: action
        )
        .accessibilityLabel(lm.t("a11y.settings_button"))
        .accessibilityHint(lm.t("a11y.settings_hint"))
    }
}

// MARK: - Bottone Info

private struct MenuInfoButton: View {
    let size: CGFloat
    let isDisabled: Bool
    let action: () -> Void

    @Environment(LanguageManager.self) private var lm

    private let gold = Color(red: 0.90, green: 0.72, blue: 0.22)

    var body: some View {
        Button(action: action) {
            Image(systemName: "info.circle.fill")
                .font(.app(size: size * 0.48, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.30, green: 0.48, blue: 0.82),
                                    Color(red: 0.14, green: 0.25, blue: 0.55)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.88, blue: 0.45),
                                    gold
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(3, size * 0.08)
                        )
                )
                .shadow(color: .black.opacity(0.30), radius: 7, y: 4)
        }
        .buttonStyle(.plain)
        .gameMinimumTouchTarget(
            minWidth: max(size, GameButtonMetrics.minimumTouchTarget),
            minHeight: max(size, GameButtonMetrics.minimumTouchTarget)
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
        .accessibilityLabel(lm.t("a11y.info_button"))
        .accessibilityHint(lm.t("a11y.info_hint"))
    }
}

// MARK: - Bottone Play

private struct MenuPlayButton: View {
    let width: CGFloat
    let isDisabled: Bool
    let action: () -> Void

    @Environment(LanguageManager.self) private var lm

    var body: some View {
        GamePillButton(
            title: lm.t("button.play"),
            fontSize: width * 0.115,
            horizontalPadding: width * 0.05,
            verticalPadding: width * 0.055,
            minWidth: width,
            minHeight: GameButtonMetrics.pillMinHeight(atLeast: width * 0.26),
            isDisabled: isDisabled,
            action: action
        )
        .accessibilityLabel(lm.t("a11y.play_button"))
        .accessibilityHint(lm.t("a11y.play_hint"))
    }
}
