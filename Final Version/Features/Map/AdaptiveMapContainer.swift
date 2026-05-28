import SwiftUI

/// Contenitore che adatta un contenuto (es. mappa 16:9) a qualsiasi schermo
/// mantenendo le proporzioni dell'immagine.
///
/// - `.fit`  → l'immagine resta intera, bande sullo sfondo se serve
/// - `.fill` → riempie lo schermo, possibile crop ai bordi
struct AdaptiveMapContainer<Background: View, Content: View>: View {
    let aspectRatio: CGFloat
    let contentMode: MapLayout.ContentMode
    let minimumVisibleAspectRatio: CGFloat?
    let background: Background
    @ViewBuilder let content: (_ mapSize: CGSize) -> Content

    init(
        aspectRatio: CGFloat,
        contentMode: MapLayout.ContentMode = .fit,
        minimumVisibleAspectRatio: CGFloat? = nil,
        @ViewBuilder background: () -> Background,
        @ViewBuilder content: @escaping (_ mapSize: CGSize) -> Content
    ) {
        self.aspectRatio = aspectRatio
        self.contentMode = contentMode
        self.minimumVisibleAspectRatio = minimumVisibleAspectRatio
        self.background = background()
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            let mapSize = MapLayout.mapSize(
                in: proxy.size,
                aspectRatio: aspectRatio,
                contentMode: contentMode,
                minimumVisibleAspectRatio: minimumVisibleAspectRatio
            )

            ZStack {
                background
                    .ignoresSafeArea()

                content(mapSize)
                    .frame(width: mapSize.width, height: mapSize.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .clipped()
        }
        .ignoresSafeArea()
    }
}

extension AdaptiveMapContainer where Background == Color {
    init(
        aspectRatio: CGFloat,
        contentMode: MapLayout.ContentMode = .fit,
        minimumVisibleAspectRatio: CGFloat? = nil,
        letterboxColor: Color = Color(red: 0.10, green: 0.55, blue: 0.78),
        @ViewBuilder content: @escaping (_ mapSize: CGSize) -> Content
    ) {
        self.init(
            aspectRatio: aspectRatio,
            contentMode: contentMode,
            minimumVisibleAspectRatio: minimumVisibleAspectRatio,
            background: { letterboxColor },
            content: content
        )
    }
}
