import SwiftUI

/// Horizontal narrator caption frame (`frame_dialogo_narratore`, 1024×199).
enum NarratorFrameMetrics {
    static let frameImageName = "frame_dialogo_narratore"

    static let designFrameWidth: CGFloat = 1024
    static let designFrameHeight: CGFloat = 199
    static var frameAspectRatio: CGFloat { designFrameWidth / designFrameHeight }

    static let dialogueTextBoxWidth: CGFloat = 880
    static let dialogueTextBoxHeight: CGFloat = 132
    static var dialogueTextBoxWidthRatio: CGFloat { dialogueTextBoxWidth / designFrameWidth }
    static var dialogueTextBoxHeightRatio: CGFloat { dialogueTextBoxHeight / designFrameHeight }

    static let bodyPaddingHorizontal: CGFloat = 72
    static var bodyPaddingVertical: CGFloat {
        (designFrameHeight - dialogueTextBoxHeight) * 0.5
    }
    static let dialogueLineLimit = 3
    static let dialogueFontSize: CGFloat = 28

    static func scaled(_ designValue: CGFloat, frameWidth: CGFloat) -> CGFloat {
        designValue * (frameWidth / designFrameWidth)
    }

    static func scaledFontSize(_ designSize: CGFloat, frameWidth: CGFloat) -> CGFloat {
        scaled(designSize, frameWidth: frameWidth)
    }

    static func dialogueTextRect(in size: CGSize) -> CGRect {
        let width = size.width * dialogueTextBoxWidthRatio
        let height = size.height * dialogueTextBoxHeightRatio
        let originX = (size.width - width) * 0.5
        let originY = (size.height - height) * 0.5
        return CGRect(x: originX, y: originY, width: width, height: height)
    }
}

/// Una riga di sottotitolo; l'id è l'indice assoluto della riga nel testo completo,
/// così SwiftUI anima inserimenti/rimozioni quando la finestra scorre.
struct NarratorSubtitleLine: Identifiable, Equatable {
    let id: Int
    let text: String
}

struct NarratorFramePanel: View {
    let visibleLines: [NarratorSubtitleLine]

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let dialogueRect = NarratorFrameMetrics.dialogueTextRect(in: size)
            let dialogueFontSize = NarratorFrameMetrics.scaledFontSize(
                NarratorFrameMetrics.dialogueFontSize,
                frameWidth: size.width
            )
            let dialogueHorizontalInset = NarratorFrameMetrics.scaled(
                NarratorFrameMetrics.bodyPaddingHorizontal,
                frameWidth: size.width
            )
            let rowHeight = dialogueRect.height / CGFloat(NarratorFrameMetrics.dialogueLineLimit)

            ZStack {
                Image(NarratorFrameMetrics.frameImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .accessibilityHidden(true)

                VStack(spacing: 0) {
                    ForEach(visibleLines) { line in
                        Text(line.text)
                            .font(.app(size: dialogueFontSize, weight: .medium))
                            .foregroundColor(Color(red: 0.20, green: 0.09, blue: 0.05))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .frame(height: rowHeight)
                            .transition(.asymmetric(
                                insertion: .move(edge: .bottom).combined(with: .opacity),
                                removal: .move(edge: .top).combined(with: .opacity)
                            ))
                    }
                }
                .accessibilityHidden(true)
                .padding(.horizontal, dialogueHorizontalInset)
                .frame(width: dialogueRect.width, height: dialogueRect.height, alignment: .center)
                .clipped()
                .position(x: dialogueRect.midX, y: dialogueRect.midY)
            }
        }
        .aspectRatio(NarratorFrameMetrics.frameAspectRatio, contentMode: .fit)
    }
}

#Preview("Narrator frame") {
    NarratorFramePanel(
        visibleLines: [
            NarratorSubtitleLine(id: 0, text: "I am your guide in this magical world!"),
            NarratorSubtitleLine(id: 1, text: "Once, all the fairy tales lived here"),
            NarratorSubtitleLine(id: 2, text: "in peace and harmony...")
        ]
    )
    .frame(width: 720)
    .padding()
    .background(Color.gray.opacity(0.35))
}
