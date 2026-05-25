import SwiftUI

struct ParchmentView<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            Color.appBackground

            // Scroll-edge shadow at top
            LinearGradient(
                colors: [
                    Color.appBorder.opacity(0.45),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 10)

            content()
        }
        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: -4)
    }
}
