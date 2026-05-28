import CoreGraphics
import SwiftUI

/// Calcolo dimensioni mappa coerente tra menu e gioco (fit vs fill).
enum MapLayout {
    /// Rapporto dell'asset `mappa` (3344×1882).
    static let worldMapAspectRatio: CGFloat = 3344.0 / 1882.0

    /// Rapporto dell'asset `redhoodislefinal` (2509×1882).
    static let redHoodMapAspectRatio: CGFloat = 2509.0 / 1882.0

    enum ContentMode {
        /// Mostra tutta la mappa (possibili bande laterali/sopra-sotto).
        case fit
        /// Riempie lo schermo (possibile crop ai bordi).
        case fill
    }

    static func mapSize(
        in container: CGSize,
        aspectRatio: CGFloat,
        contentMode: ContentMode,
        minimumVisibleAspectRatio: CGFloat? = nil
    ) -> CGSize {
        guard container.width > 0, container.height > 0 else { return .zero }

        let containerAspect = container.width / container.height

        switch contentMode {
        case .fit:
            if containerAspect > aspectRatio {
                let height = container.height
                return CGSize(width: height * aspectRatio, height: height)
            }
            let width = container.width
            return CGSize(width: width, height: width / aspectRatio)

        case .fill:
            if let minimumVisibleAspectRatio,
               containerAspect < minimumVisibleAspectRatio {
                let height = container.width / minimumVisibleAspectRatio
                return CGSize(width: height * aspectRatio, height: height)
            }

            if containerAspect > aspectRatio {
                let width = container.width
                return CGSize(width: width, height: width / aspectRatio)
            }
            let height = container.height
            return CGSize(width: height * aspectRatio, height: height)
        }
    }
}

/// Immagine mappa ridimensionata senza deformare (crop se necessario, mai stretch).
struct MapBackgroundImage: View {
    let name: String
    let mapSize: CGSize

    var body: some View {
        Image(name)
            .resizable()
            .interpolation(.high)
            .aspectRatio(contentMode: .fill)
            .frame(width: mapSize.width, height: mapSize.height)
            .clipped()
            .accessibilityHidden(true)
    }
}
