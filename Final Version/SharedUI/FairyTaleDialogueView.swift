import SwiftUI

/// Two-character dialogue: active speaker bright, inactive dimmed; frame switches by speaker.
struct FairyTaleDialogueView: View {
    let lines: [DialogueLine]
    let continueButtonTitle: String
    var secondaryButtonTitle: String? = nil
    var onSecondary: (() -> Void)? = nil
    let onComplete: () -> Void

    @State private var lineIndex = 0

    private static let frameAspectRatio: CGFloat = 1024.0 / 382.0

    private var currentLine: DialogueLine? {
        guard lineIndex >= 0, lineIndex < lines.count else { return nil }
        return lines[lineIndex]
    }

    private var activeRole: DialogueSpeakerRole {
        DialogueSpeakerRole(speakerName: currentLine?.speaker ?? "")
    }

    /// Lumi → `frame_dialogo_lumi`, nome a sinistra. Altri → `frame_dialogo`, nome a destra.
    private var dialogueFrameImageName: String {
        switch activeRole {
        case .lumi:
            return "frame_dialogo_lumi"
        default:
            return "frame_dialogo"
        }
    }

    private var namePlateOnTrailing: Bool {
        switch activeRole {
        case .lumi:
            return false
        default:
            return true
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let horizontalPadding: CGFloat = isLandscape ? 20 : 12
            let columnSpacing: CGFloat = isLandscape ? 10 : 6
            let portraitHeight = min(geometry.size.height * (isLandscape ? 0.58 : 0.30), 360)
            let sideWidth = min(geometry.size.width * (isLandscape ? 0.20 : 0.26), 240)
            let centerMaxWidth = max(
                180,
                geometry.size.width - (sideWidth * 2) - (horizontalPadding * 2) - (columnSpacing * 2)
            )
            let frameMaxWidth = min(centerMaxWidth, isLandscape ? 640 : 420)

            ZStack {
                dialogueBackground
                    .ignoresSafeArea()

                HStack(alignment: .bottom, spacing: columnSpacing) {
                    characterColumn(
                        role: .lumi,
                        width: sideWidth,
                        height: portraitHeight
                    )

                    dialoguePanel(maxWidth: frameMaxWidth)
                        .layoutPriority(1)

                    characterColumn(
                        role: .redRidingHood,
                        width: sideWidth,
                        height: portraitHeight
                    )
                }
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .ignoresSafeArea(edges: .bottom)
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .onTapGesture { advance() }
        .accessibilityElement(children: .contain)
    }

    /// Light scrim so the Red Hood map stays visible behind the dialogue.
    private var dialogueBackground: some View {
        ZStack {
            Color.clear
            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color.black.opacity(0.22),
                    Color.black.opacity(0.32)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    @ViewBuilder
    private func characterColumn(role: DialogueSpeakerRole, width: CGFloat, height: CGFloat) -> some View {
        let isActive = rolesMatch(activeRole, role)
        let imageName = portraitImageName(for: role, isActive: isActive)

        DialogueCharacterPortrait(imageName: imageName)
        .frame(width: width, height: height, alignment: .bottom)
        .animation(.easeInOut(duration: 0.22), value: lineIndex)
    }

    private func portraitImageName(for columnRole: DialogueSpeakerRole, isActive: Bool) -> String {
        let line = currentLine ?? DialogueLine(speaker: "", text: "")
        if isActive {
            return DialoguePortraitAssets.imageName(role: columnRole, speaking: true, line: line)
        }
        return DialoguePortraitAssets.imageName(role: columnRole, speaking: false, line: line)
    }

    private func rolesMatch(_ active: DialogueSpeakerRole, _ column: DialogueSpeakerRole) -> Bool {
        switch (active, column) {
        case (.lumi, .lumi), (.redRidingHood, .redRidingHood):
            return true
        default:
            return false
        }
    }

    @ViewBuilder
    private func dialoguePanel(maxWidth: CGFloat) -> some View {
        let role = activeRole
        let text = currentLine?.text ?? ""
        let isLastLine = lineIndex >= lines.count - 1

        DialogueFramePanel(
            frameImageName: dialogueFrameImageName,
            nameOnTrailing: namePlateOnTrailing,
            speakerName: role.displayName,
            dialogueText: text,
            isLastLine: isLastLine,
            continueButtonTitle: continueButtonTitle,
            secondaryButtonTitle: secondaryButtonTitle,
            onSecondary: onSecondary,
            onComplete: onComplete
        )
        .frame(maxWidth: maxWidth)
        .frame(maxHeight: maxWidth / Self.frameAspectRatio)
        .aspectRatio(Self.frameAspectRatio, contentMode: .fit)
        .animation(.easeInOut(duration: 0.2), value: lineIndex)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(role.displayName). \(text)")
    }

    private func advance() {
        guard lineIndex < lines.count - 1 else { return }
        AppSettings.hapticImpact(.light)
        withAnimation(.easeInOut(duration: 0.2)) {
            lineIndex += 1
        }
    }
}

// MARK: - Dialogue frame (name plate + body text)

private struct DialogueFramePanel: View {
    let frameImageName: String
    let nameOnTrailing: Bool
    let speakerName: String
    let dialogueText: String
    let isLastLine: Bool
    let continueButtonTitle: String
    var secondaryButtonTitle: String?
    var onSecondary: (() -> Void)?
    let onComplete: () -> Void

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let nameWidth = size.width * 0.28
            let nameHeight = size.height * 0.24
            let bodyTop = size.height * 0.20
            let horizontalInset = size.width * 0.055

            ZStack {
                Image(frameImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .accessibilityHidden(true)

                // Small top frame — speaker name
                Text(speakerName)
                    .font(.app(.subheadline, weight: .bold))
                    .foregroundColor(Color(red: 0.32, green: 0.12, blue: 0.07))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .frame(width: nameWidth, height: nameHeight, alignment: .center)
                    .position(
                        x: nameOnTrailing
                            ? size.width - horizontalInset - nameWidth * 0.5
                            : horizontalInset + nameWidth * 0.5,
                        y: nameHeight * 0.52
                    )

                // Large frame — dialogue + controls
                VStack(alignment: .leading, spacing: size.height * 0.04) {
                    Text(dialogueText)
                        .font(.app(.title3, weight: .semibold))
                        .foregroundColor(Color(red: 0.20, green: 0.09, blue: 0.05))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(alignment: .center, spacing: 10) {
                        if !isLastLine {
                            Text("Tocca per continuare")
                                .font(.app(.caption))
                                .foregroundColor(Color(red: 0.35, green: 0.22, blue: 0.14).opacity(0.7))
                        }

                        Spacer(minLength: 0)

                        if isLastLine {
                            if let secondaryButtonTitle, let onSecondary {
                                Button(action: onSecondary) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.app(.caption))
                                        Text(secondaryButtonTitle)
                                            .font(.app(.caption))
                                            .fontWeight(.semibold)
                                    }
                                    .foregroundColor(Color(red: 0.35, green: 0.22, blue: 0.14))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color.white.opacity(0.5))
                                    )
                                }
                                .buttonStyle(.plain)
                            }

                            GamePillButton(
                                title: continueButtonTitle,
                                fontSize: 14,
                                horizontalPadding: 18,
                                verticalPadding: 10,
                                minWidth: 96,
                                minHeight: 44,
                                trailingIcon: "arrow.right",
                                action: onComplete
                            )
                        }
                    }
                }
                .padding(.horizontal, horizontalInset + 8)
                .padding(.bottom, size.height * 0.08)
                .frame(
                    width: size.width - horizontalInset * 2,
                    height: size.height - bodyTop - size.height * 0.06,
                    alignment: .topLeading
                )
                .position(
                    x: size.width * 0.5,
                    y: bodyTop + (size.height - bodyTop) * 0.5
                )
            }
        }
        .aspectRatio(1024.0 / 382.0, contentMode: .fit)
    }
}

private struct DialogueCharacterPortrait: View {
    let imageName: String

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .accessibilityHidden(true)
    }
}

#Preview("Dialogue Lumi") {
    FairyTaleDialogueView(
        lines: RedHoodDialogueLoader.introLines(waypoint: 0) ?? [],
        continueButtonTitle: "Inizia!",
        onComplete: {}
    )
    .environmentObject(LanguageManager())
}
