import SwiftUI

/// Sfondo mappa principale (stesso asset e fitting di `ContentView` sulla world map).
struct WorldMapBackgroundView: View {
    private static let mapAspectRatio: CGFloat = 1448.0 / 1086.0

    var body: some View {
        GeometryReader { proxy in
            let mapSize = fittedMapSize(in: proxy.size)

            ZStack {
                Color(red: 0.10, green: 0.55, blue: 0.78)
                    .ignoresSafeArea()

                Image("mappa")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: mapSize.width, height: mapSize.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                    .accessibilityHidden(true)
            }
        }
        .ignoresSafeArea()
    }

    private func fittedMapSize(in container: CGSize) -> CGSize {
        let containerAspectRatio = container.width / container.height

        if containerAspectRatio > Self.mapAspectRatio {
            let height = container.height
            return CGSize(width: height * Self.mapAspectRatio, height: height)
        }

        let width = container.width
        return CGSize(width: width, height: width / Self.mapAspectRatio)
    }
}
