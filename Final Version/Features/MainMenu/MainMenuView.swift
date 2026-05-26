import SwiftUI

private let menuPanelAspectRatio: CGFloat = 600.0 / 1072.0

struct MainMenuSceneView: View {
    @Binding var cloudEnterProgress: CGFloat
    @Binding var cloudExitProgress: CGFloat

    var body: some View {
        ZStack {
            WorldMapBackgroundView()

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
    let onPlay: () -> Void

    @State private var panelOpacity: Double = 0
    @State private var panelScale: CGFloat = 1.04
    @State private var isPanelDissolving = false
    @State private var didRevealPanel = false
    @State private var showSettings = false
    @EnvironmentObject var lm: LanguageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let panelFadeDuration: TimeInterval = 0.30

    var body: some View {
        ZStack {
            MenuPanelView(
                isDisabled: isTransitioning || isPanelDissolving,
                onPlay: startGame,
                onSettings: { showSettings = true }
            )
        }
        .opacity(panelOpacity)
        .scaleEffect(panelScale)
        .allowsHitTesting(panelOpacity > 0.5 && !isTransitioning && !isPanelDissolving)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .id(resetID)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(lm)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            tryRevealPanel()
        }
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

// MARK: - Pannello centrale (cornice + titolo + Play)

private struct MenuPanelView: View {
    let isDisabled: Bool
    let onPlay: () -> Void
    let onSettings: () -> Void

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

                VStack(spacing: panelSize.height * 0.04) {
                    MenuTitleView(panelWidth: panelSize.width)

                    Spacer(minLength: panelSize.height * 0.02)

                    MenuPlayButton(
                        width: panelSize.width * 0.62,
                        isDisabled: isDisabled,
                        action: onPlay
                    )

                    MenuSettingsButton(
                        width: panelSize.width * 0.62,
                        isDisabled: isDisabled,
                        action: onSettings
                    )

                    Spacer(minLength: panelSize.height * 0.06)
                }
                .padding(.horizontal, panelSize.width * 0.14)
                .padding(.top, panelSize.height * 0.14)
                .padding(.bottom, panelSize.height * 0.12)
                .frame(width: panelSize.width, height: panelSize.height)
            }
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

    @EnvironmentObject private var lm: LanguageManager

    private let gold = Color(red: 0.90, green: 0.72, blue: 0.22)

    var body: some View {
        Button(action: action) {
            Text(lm.t("button.settings"))
                .font(.system(size: width * 0.14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, width * 0.07)
                .frame(width: width, height: width * 0.38)
                .background(
                    RoundedRectangle(cornerRadius: width * 0.14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.38, green: 0.24, blue: 0.08),
                                    Color(red: 0.22, green: 0.13, blue: 0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.88, blue: 0.45),
                                    gold
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(4, width * 0.04)
                        )
                )
                .shadow(color: .black.opacity(0.30), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
        .accessibilityLabel(lm.t("a11y.settings_button"))
    }
}

// MARK: - Titolo "World of Fables"

private struct MenuTitleView: View {
    let panelWidth: CGFloat

    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 1.0, green: 0.92, blue: 0.35),
                Color(red: 0.98, green: 0.62, blue: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        VStack(spacing: panelWidth * 0.012) {
            titleLine("World", size: panelWidth * 0.13)
            ofRow
            titleLine("Fables", size: panelWidth * 0.13)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("World of Fables")
    }

    private var ofRow: some View {
        HStack(spacing: panelWidth * 0.03) {
            goldFlourish
            Text("of")
                .font(.system(size: panelWidth * 0.055, weight: .bold, design: .serif))
                .foregroundStyle(titleGradient)
                .shadow(color: outlineColor, radius: 0, x: 1, y: 1)
                .shadow(color: outlineColor, radius: 0, x: -1, y: -1)
            goldFlourish
        }
    }

    private var goldFlourish: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.75, green: 0.52, blue: 0.10),
                        Color(red: 0.95, green: 0.78, blue: 0.28)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: panelWidth * 0.10, height: max(2, panelWidth * 0.008))
    }

    private var outlineColor: Color {
        Color(red: 0.35, green: 0.20, blue: 0.06)
    }

    @ViewBuilder
    private func titleLine(_ text: String, size: CGFloat) -> some View {
        ZStack {
            Text(text)
                .font(.system(size: size, weight: .black, design: .serif))
                .foregroundStyle(outlineColor)
                .offset(x: 1.5, y: 1.5)

            Text(text)
                .font(.system(size: size, weight: .black, design: .serif))
                .foregroundStyle(titleGradient)
        }
    }
}

// MARK: - Bottone Play

private struct MenuPlayButton: View {
    let width: CGFloat
    let isDisabled: Bool
    let action: () -> Void

    @EnvironmentObject private var lm: LanguageManager

    private let gold = Color(red: 0.90, green: 0.72, blue: 0.22)
    private let green = Color(red: 0.18, green: 0.52, blue: 0.28)

    var body: some View {
        Button(action: action) {
            Text(lm.t("button.play"))
                .font(.system(size: width * 0.14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .tracking(1.2)
                .frame(width: width, height: width * 0.38)
                .background(
                    RoundedRectangle(cornerRadius: width * 0.14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.22, green: 0.58, blue: 0.32),
                                    green
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: width * 0.14, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(red: 1.0, green: 0.88, blue: 0.45),
                                    gold
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(4, width * 0.04)
                        )
                )
                .shadow(color: .black.opacity(0.30), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
        .accessibilityLabel(lm.t("a11y.play_button"))
        .accessibilityHint(lm.t("a11y.play_hint"))
    }
}
