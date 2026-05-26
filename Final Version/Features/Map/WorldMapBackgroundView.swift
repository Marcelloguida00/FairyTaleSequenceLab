import SwiftUI

/// Sfondo mappa principale (stesso asset e fitting di `ContentView` sulla world map).
struct WorldMapBackgroundView: View {
    var body: some View {
        AdaptiveMapContainer(
            aspectRatio: MapLayout.worldMapAspectRatio,
            contentMode: .fill
        ) { mapSize in
            MapBackgroundImage(name: "mappa", mapSize: mapSize)
        }
    }
}
