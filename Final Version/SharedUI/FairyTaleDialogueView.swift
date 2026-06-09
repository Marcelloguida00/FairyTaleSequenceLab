import SwiftUI

/// Two-character dialogue: active speaker bright, inactive dimmed; frame switches by speaker.
struct FairyTaleDialogueView: View {
    let lines: [DialogueLine]
    /// Se impostato (es. `0` intro isola), influenza i ritratti inattivi.
    var waypointID: Int? = nil
    let onComplete: () -> Void

    @State private var lineIndex = 0
    @State private var dialogueChunkIndex = 0
    @State private var isDialogueTextFullyShown = false
    @Environment(LanguageManager.self) private var lm

    private static let frameAspectRatio: CGFloat = DialogueFrameMetrics.frameAspectRatio
    /// Frame altezza ≈ personaggi × questo fattore (leggermente più alto).
    private static let frameHeightOverPortrait: CGFloat = 1.12
    private static let portraitHeightLandscapeRatio: CGFloat = 0.54
    private static let portraitHeightPortraitRatio: CGFloat = 0.27
    private static let portraitMaxHeight: CGFloat = 330

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
            let portraitHeight = min(
                geometry.size.height * (isLandscape ? Self.portraitHeightLandscapeRatio : Self.portraitHeightPortraitRatio),
                Self.portraitMaxHeight
            )
            let sideWidth = min(geometry.size.width * (isLandscape ? 0.20 : 0.26), 240)
            let centerMaxWidth = max(
                180,
                geometry.size.width - (sideWidth * 2) - (horizontalPadding * 2) - (columnSpacing * 2)
            )
            let frameHeight = portraitHeight * Self.frameHeightOverPortrait
            let frameMaxWidth = min(centerMaxWidth, frameHeight * Self.frameAspectRatio)

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
            .contentShape(Rectangle())
            .onTapGesture { handleDialogueTap(dialogueFrameWidth: frameMaxWidth) }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .contain)
        .onChange(of: lineIndex) { _, _ in
            dialogueChunkIndex = 0
            isDialogueTextFullyShown = false
        }
        .onChange(of: dialogueChunkIndex) { _, _ in
            isDialogueTextFullyShown = false
        }
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
        return DialoguePortraitAssets.imageName(
            role: columnRole,
            speaking: isActive,
            line: line,
            waypointID: waypointID
        )
    }

    private func rolesMatch(_ active: DialogueSpeakerRole, _ column: DialogueSpeakerRole) -> Bool {
        switch (active, column) {
        case (.lumi, .lumi), (.redRidingHood, .redRidingHood):
            return true
        default:
            return false
        }
    }

    private func dialogueChunks(for text: String, frameWidth: CGFloat) -> [String] {
        let fontSize = DialogueFrameMetrics.scaledFontSize(
            DialogueFrameMetrics.dialogueFontSize,
            frameWidth: frameWidth
        )
        let textAreaWidth = frameWidth * DialogueFrameMetrics.dialogueTextBoxWidthRatio
        let horizontalInset = DialogueFrameMetrics.scaled(
            DialogueFrameMetrics.bodyPaddingHorizontal,
            frameWidth: frameWidth
        )
        let maxTextWidth = max(1, textAreaWidth - (horizontalInset * 2))
        return DialogueTextPaginator.chunks(
            text: text,
            fontSize: fontSize,
            maxWidth: maxTextWidth,
            maxLines: DialogueFrameMetrics.dialogueLineLimit
        )
    }

    private func displayedDialogueText(fullText: String, frameWidth: CGFloat) -> String {
        let chunks = dialogueChunks(for: fullText, frameWidth: frameWidth)
        guard !chunks.isEmpty else { return fullText }
        let index = min(dialogueChunkIndex, chunks.count - 1)
        let chunk = chunks[index]
        if index < chunks.count - 1 {
            return chunk + "…"
        }
        return chunk
    }

    @ViewBuilder
    private func dialoguePanel(maxWidth: CGFloat) -> some View {
        let role = activeRole
        let fullText = currentLine?.text ?? ""
        let displayText = displayedDialogueText(fullText: fullText, frameWidth: maxWidth)

        DialogueFramePanel(
            frameImageName: dialogueFrameImageName,
            nameOnTrailing: namePlateOnTrailing,
            speakerName: currentLine?.speaker ?? role.displayName,
            dialogueText: displayText,
            isDialogueTextFullyShown: $isDialogueTextFullyShown
        )
        .frame(maxWidth: maxWidth)
        .frame(maxHeight: maxWidth / Self.frameAspectRatio)
        .aspectRatio(Self.frameAspectRatio, contentMode: .fit)
        .animation(.easeInOut(duration: 0.2), value: lineIndex)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(role.displayName). \(fullText)")
    }

    private func handleDialogueTap(dialogueFrameWidth: CGFloat) {
        guard !lines.isEmpty else { return }
        AppSettings.hapticImpact(.light)

        if !isDialogueTextFullyShown {
            isDialogueTextFullyShown = true
            return
        }

        advanceDialogue(dialogueFrameWidth: dialogueFrameWidth)
    }

    private func advanceDialogue(dialogueFrameWidth: CGFloat) {
        let fullText = currentLine?.text ?? ""
        let chunks = dialogueChunks(for: fullText, frameWidth: dialogueFrameWidth)

        if dialogueChunkIndex < chunks.count - 1 {
            withAnimation(.easeInOut(duration: 0.15)) {
                dialogueChunkIndex += 1
            }
            return
        }

        dialogueChunkIndex = 0
        if lineIndex < lines.count - 1 {
            withAnimation(.easeInOut(duration: 0.2)) {
                lineIndex += 1
            }
        } else {
            onComplete()
        }
    }

}

// MARK: - Dialogue frame (name plate + body text)

private enum DialogueFrameMetrics {
    // MARK: - Arte (frame 1357×570, area dialogo 1297×254)

    static let designFrameWidth: CGFloat = 1357
    static let designFrameHeight: CGFloat = 570
    static var frameAspectRatio: CGFloat { designFrameWidth / designFrameHeight }

    static let dialogueTextBoxWidth: CGFloat = 1297
    static let dialogueTextBoxHeight: CGFloat = 254
    static var dialogueTextBoxWidthRatio: CGFloat { dialogueTextBoxWidth / designFrameWidth }
    static var dialogueTextBoxHeightRatio: CGFloat { dialogueTextBoxHeight / designFrameHeight }
    /// Margine superiore frame → area dialogo (design px).
    static let bodyPaddingVertical: CGFloat = 208
    static let bodyPaddingHorizontal: CGFloat = 120

    static let dialogueLineLimit = 3

    // MARK: - Tipografia (modifica qui — Preview «Frame dialogo · font»)

    static let speakerNameFontSize: CGFloat = 42
    static let dialogueFontSize: CGFloat = 48
    /// Centro nome speaker da bordo sinistro frame (design px).
    static let speakerNameCenterXLumi: CGFloat = 380
    static let speakerNameCenterXNonLumi: CGFloat = 980
    /// Distanza bordo superiore frame → inizio area nome (design px), entrambi i personaggi.
    static let speakerNameOffsetFromTop: CGFloat = 22

    static func scaled(_ designValue: CGFloat, frameWidth: CGFloat) -> CGFloat {
        designValue * (frameWidth / designFrameWidth)
    }

    static func scaledFontSize(_ designSize: CGFloat, frameWidth: CGFloat) -> CGFloat {
        scaled(designSize, frameWidth: frameWidth)
    }

    /// Rettangolo area dialogo (1297×254) con stesse proporzioni del frame.
    static func dialogueTextRect(in size: CGSize, centerX: CGFloat) -> CGRect {
        let width = size.width * dialogueTextBoxWidthRatio
        let height = size.height * dialogueTextBoxHeightRatio
        let originX = centerX - width * 0.5
        let originY = size.height * (bodyPaddingVertical / designFrameHeight)
        return CGRect(x: originX, y: originY, width: width, height: height)
    }

    static func speakerNameCenterX(in size: CGSize, isNonLumiSpeaker: Bool) -> CGFloat {
        let designX = isNonLumiSpeaker ? speakerNameCenterXNonLumi : speakerNameCenterXLumi
        return size.width * (designX / designFrameWidth)
    }

    static func speakerNameCenterY(in size: CGSize) -> CGFloat {
        let topInset = size.height * (speakerNameOffsetFromTop / designFrameHeight)
        let plateHeight = size.height * namePlateHeightRatio
        return topInset + plateHeight * 0.5
    }

    static let namePlateWidthRatio: CGFloat = 0.28
    static let namePlateHeightRatio: CGFloat = 0.24
}

private struct DialogueFramePanel: View {
    let frameImageName: String
    let nameOnTrailing: Bool
    let speakerName: String
    let dialogueText: String
    @Binding var isDialogueTextFullyShown: Bool

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let nameWidth = size.width * DialogueFrameMetrics.namePlateWidthRatio
            let nameHeight = size.height * DialogueFrameMetrics.namePlateHeightRatio
            let nameCenterX = DialogueFrameMetrics.speakerNameCenterX(
                in: size,
                isNonLumiSpeaker: nameOnTrailing
            )
            let nameCenterY = DialogueFrameMetrics.speakerNameCenterY(in: size)
            let speakerFontSize = DialogueFrameMetrics.scaledFontSize(
                DialogueFrameMetrics.speakerNameFontSize,
                frameWidth: size.width
            )
            let dialogueFontSize = DialogueFrameMetrics.scaledFontSize(
                DialogueFrameMetrics.dialogueFontSize,
                frameWidth: size.width
            )
            let dialogueRect = DialogueFrameMetrics.dialogueTextRect(
                in: size,
                centerX: size.width * 0.5
            )
            let dialogueHorizontalInset = DialogueFrameMetrics.scaled(
                DialogueFrameMetrics.bodyPaddingHorizontal,
                frameWidth: size.width
            )

            ZStack {
                Image(frameImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .accessibilityHidden(true)

                // Small top frame — speaker name
                Text(speakerName)
                    .font(.app(size: speakerFontSize, weight: .semibold))
                    .foregroundColor(Color(red: 0.32, green: 0.12, blue: 0.07))
                    .textCase(.uppercase)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .multilineTextAlignment(.center)
                    .frame(width: nameWidth, height: nameHeight, alignment: .center)
                    .position(x: nameCenterX, y: nameCenterY)
                    .accessibilityHidden(true)

                // Area dialogo 1297×254; max 3 righe, effetto digitato (tap gestito dal parent)
                DialogueTypewriterText(
                    fullText: dialogueText,
                    font: .app(size: dialogueFontSize, weight: .medium),
                    color: Color(red: 0.20, green: 0.09, blue: 0.05),
                    lineLimit: DialogueFrameMetrics.dialogueLineLimit,
                    isFullyShown: $isDialogueTextFullyShown
                )
                .accessibilityHidden(true)
                .padding(.horizontal, dialogueHorizontalInset)
                .frame(width: dialogueRect.width, height: dialogueRect.height, alignment: .center)
                .position(x: dialogueRect.midX, y: dialogueRect.midY)
            }
        }
        .aspectRatio(DialogueFrameMetrics.frameAspectRatio, contentMode: .fit)
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

// MARK: - Previews

/// Apri **Frame dialogo · font** nel canvas: modifica `speakerNameFontSize` e `dialogueFontSize` in `DialogueFrameMetrics`, poi Resume.
#Preview("Frame dialogo · font") {
    DialogueFrameTypographyPreview()
}

#Preview("Dialogo completo") {
    FairyTaleDialogueView(
        lines: [
            DialogueLine(
                speaker: "Lumi",
                text: "Ciao! Prova a toccare lo schermo per avanzare."
            ),
            DialogueLine(
                speaker: "Cappuccetto Rosso",
                text: "Andiamo dalla nonna!"
            )
        ],
        onComplete: {}
    )
    .environment(LanguageManager())
}

#Preview("Dialogo completo · landscape", traits: .landscapeLeft) {
    FairyTaleDialogueView(
        lines: [
            DialogueLine(
                speaker: "Lumi",
                text: "La mappa è sottosopra… aiutami a rimettere in ordine la fiaba!"
            ),
            DialogueLine(
                speaker: "Cappuccetto Rosso",
                text: "Ci penso io!"
            )
        ],
        onComplete: {}
    )
    .environment(LanguageManager())
}

// MARK: - Preview canvas (solo frame + testo)

private struct DialogueFrameTypographyPreview: View {
    /// Larghezza simile al frame in gioco (cambia per provare iPad / iPhone).
    private let previewFrameWidth: CGFloat = 600

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Regola i font in DialogueFrameMetrics")
                        .font(.headline)
                    Label {
                        Text("speakerNameFontSize = \(Int(DialogueFrameMetrics.speakerNameFontSize))  ·  Semibold")
                    } icon: {
                        Image(systemName: "person.text.rectangle")
                    }
                    Label {
                        Text("dialogueFontSize = \(Int(DialogueFrameMetrics.dialogueFontSize))  ·  Medium")
                    } icon: {
                        Image(systemName: "text.bubble")
                    }
                    Text("Su dispositivo: punto ≈ \(Int(DialogueFrameMetrics.scaledFontSize(DialogueFrameMetrics.dialogueFontSize, frameWidth: previewFrameWidth))) pt a larghezza \(Int(previewFrameWidth))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                frameSample(
                    title: "Lumi — nome a sinistra",
                    frameImageName: "frame_dialogo_lumi",
                    nameOnTrailing: false,
                    speakerName: DialogueSpeakerRole.lumi.displayName,
                    dialogueText: "Testo di prova nel riquadro grande."
                )

                frameSample(
                    title: "Altri — nome a destra",
                    frameImageName: "frame_dialogo",
                    nameOnTrailing: true,
                    speakerName: DialogueSpeakerRole.redRidingHood.displayName,
                    dialogueText: "Prima parte del messaggio lungo che continua dopo il tocco con altre parole importanti per la storia."
                )
            }
            .padding(24)
        }
        .background(Color(red: 0.45, green: 0.55, blue: 0.48))
    }

    @ViewBuilder
    private func frameSample(
        title: String,
        frameImageName: String,
        nameOnTrailing: Bool,
        speakerName: String,
        dialogueText: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(.white)

            DialogueFramePanel(
                frameImageName: frameImageName,
                nameOnTrailing: nameOnTrailing,
                speakerName: speakerName,
                dialogueText: dialogueText,
                isDialogueTextFullyShown: .constant(false)
            )
            .frame(width: previewFrameWidth)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
}
