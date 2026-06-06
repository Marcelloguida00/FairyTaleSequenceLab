
private struct OpenBookBackground: View {
    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            let pw = w / 2
            
            ZStack {
                // Leather Cover
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color(red: 0.25, green: 0.12, blue: 0.08), Color(red: 0.15, green: 0.06, blue: 0.04)]),
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ))
                    .frame(width: w + 40, height: h + 40)
                    .shadow(color: .black.opacity(0.8), radius: 20, x: 0, y: 15)
                
                // Left Page Stack
                ForEach(1...6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(red: 0.85, green: 0.8, blue: 0.65))
                        .frame(width: pw, height: h)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                        )
                        .offset(x: -pw / 2 - CGFloat(i * 2), y: CGFloat(i * 2))
                }
                
                // Right Page Stack
                ForEach(1...6, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(red: 0.85, green: 0.8, blue: 0.65))
                        .frame(width: pw, height: h)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                        )
                        .offset(x: pw / 2 + CGFloat(i * 2), y: CGFloat(i * 2))
                }
                
                // Spine center shadow for depth
                Rectangle()
                    .fill(LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8), .clear]), startPoint: .leading, endPoint: .trailing))
                    .frame(width: 30, height: h + 40)
                    .offset(y: 5)
            }
            .position(x: w / 2, y: h / 2)
        }
    }
}
