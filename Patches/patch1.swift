
struct OrganicBlobMask: View {
    var body: some View {
        OrganicBlobShape()
            .fill(Color.black)
    }
}

struct OrganicBlobShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.5, y: 0))
        path.addCurve(to: CGPoint(x: w, y: h * 0.4),
                      control1: CGPoint(x: w * 0.9, y: 0),
                      control2: CGPoint(x: w * 1.1, y: h * 0.1))
        path.addCurve(to: CGPoint(x: w * 0.6, y: h),
                      control1: CGPoint(x: w * 0.9, y: h * 0.8),
                      control2: CGPoint(x: w * 0.8, y: h * 1.05))
        path.addCurve(to: CGPoint(x: 0, y: h * 0.6),
                      control1: CGPoint(x: w * 0.3, y: h * 0.95),
                      control2: CGPoint(x: -w * 0.1, y: h * 0.8))
        path.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                      control1: CGPoint(x: w * 0.1, y: h * 0.3),
                      control2: CGPoint(x: w * 0.1, y: 0))
        
        return path
    }
}
