import SwiftUI

struct TestView: View {
    var body: some View {
        ZStack {
            Color.white
            
            Color.clear.overlay(
                Color.red
                    .mask {
                        GeometryReader { maskGeom in
                            Circle().fill(Color.black)
                        }
                    }
            )
        }
        .frame(width: 200, height: 200)
    }
}
