import SwiftUI

enum SettingsFrameLayout {
    static let aspectRatio: CGFloat = 997.0 / 1024.0
    static let contentInset: CGFloat = 100
}

struct SettingsFrameOverlay: View {
    let onClose: () -> Void
    let onAdvancedSettingsRequested: () -> Void
    @Binding var advancedSettingsUnlocked: Bool
    var onShowTutorialAgain: (() -> Void)? = nil

    var body: some View {
        GeometryReader { proxy in
            let frameSize = fittedSettingsFrameSize(in: proxy.size)

            ZStack {
                Image("framesettings")
                    .renderingMode(.original)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: frameSize.width, height: frameSize.height)
                    .shadow(color: .black.opacity(0.36), radius: 16, y: 10)
                    .accessibilityHidden(true)

                SettingsView(
                    onClose: onClose,
                    inFrameMode: true,
                    onAdvancedSettingsRequested: onAdvancedSettingsRequested,
                    advancedSettingsUnlocked: $advancedSettingsUnlocked,
                    onShowTutorialAgain: onShowTutorialAgain
                )
                .padding(SettingsFrameLayout.contentInset)
                .frame(width: frameSize.width, height: frameSize.height)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard)
    }

    private func fittedSettingsFrameSize(in container: CGSize) -> CGSize {
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
