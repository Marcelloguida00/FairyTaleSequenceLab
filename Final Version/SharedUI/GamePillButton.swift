import SwiftUI

enum GameButtonAppearance {
    static let glossTop = Color(hex: "#FDE549")
    static let glossMid = Color(hex: "#FCDB00")
    static let glossBottom = Color(hex: "#FCDB00")
    static let border = Color(hex: "#430303")
    static let label = Color(red: 0.29, green: 0.12, blue: 0.08)

    static var glossGradient: LinearGradient {
        LinearGradient(
            colors: [glossTop, glossMid, glossBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var highlightGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.72),
                Color.white.opacity(0.08),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

private typealias GameButtonStyle = GameButtonAppearance

/// Glossy yellow capsule button used across the app.
struct GamePillButtonBackground: View {
    var body: some View {
        Capsule()
            .fill(GameButtonStyle.glossGradient)
            .overlay(alignment: .top) {
                Capsule()
                    .fill(GameButtonStyle.highlightGradient)
                    .padding(.horizontal, 10)
                    .padding(.top, 5)
                    .frame(height: 18)
            }
            .overlay {
                Capsule()
                    .stroke(GameButtonAppearance.border, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.28), radius: 5, y: 3)
    }
}

/// Glossy yellow circle used for icon buttons (back, etc.).
struct GameCircleButtonBackground: View {
    var body: some View {
        Circle()
            .fill(GameButtonStyle.glossGradient)
            .overlay(alignment: .top) {
                Circle()
                    .fill(GameButtonStyle.highlightGradient)
                    .padding(.horizontal, 8)
                    .padding(.top, 4)
                    .frame(height: 22)
            }
            .overlay {
                Circle()
                    .stroke(GameButtonAppearance.border, lineWidth: 2)
            }
            .shadow(color: .black.opacity(0.28), radius: 5, y: 3)
    }
}

struct GamePillLabel: View {
    let title: String
    var fontSize: CGFloat = 15
    var horizontalPadding: CGFloat = 22
    var verticalPadding: CGFloat = 10
    var minWidth: CGFloat? = nil
    var minHeight: CGFloat? = nil
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil

    private var labelColor: Color {
        GameButtonStyle.label
    }

    var body: some View {
        HStack(spacing: 8) {
            if let leadingIcon {
                Image(systemName: leadingIcon)
                    .font(.app(size: fontSize * 0.92, weight: .black))
            }

            Text(title.uppercased())
                .font(.app(size: fontSize, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            if let trailingIcon {
                Image(systemName: trailingIcon)
                    .font(.app(size: fontSize * 0.92, weight: .black))
            }
        }
        .foregroundStyle(labelColor)
        .shadow(color: .black.opacity(0.16), radius: 0, x: 0, y: 1)
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, verticalPadding)
        .frame(minWidth: minWidth, minHeight: minHeight)
        .background(GamePillButtonBackground())
    }
}

struct GamePillButton: View {
    let title: String
    var fontSize: CGFloat = 15
    var horizontalPadding: CGFloat = 22
    var verticalPadding: CGFloat = 10
    var minWidth: CGFloat? = nil
    var minHeight: CGFloat? = nil
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            GamePillLabel(
                title: title,
                fontSize: fontSize,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                minWidth: minWidth,
                minHeight: minHeight,
                leadingIcon: leadingIcon,
                trailingIcon: trailingIcon
            )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

struct GameCircleButton: View {
    let systemImage: String
    var size: CGFloat = 52
    var iconSize: CGFloat? = nil
    var iconWeight: Font.Weight = .black
    var isDisabled: Bool = false
    let action: () -> Void

    private var resolvedIconSize: CGFloat {
        iconSize ?? size * 0.36
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.app(size: resolvedIconSize, weight: iconWeight))
                .foregroundStyle(GameButtonStyle.label)
                .shadow(color: .black.opacity(0.14), radius: 0, x: 0, y: 1)
                .frame(width: size, height: size)
                .background(GameCircleButtonBackground())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

struct GameCircleBackButton: View {
    var size: CGFloat = 52
    let action: () -> Void

    var body: some View {
        GameCircleButton(
            systemImage: "chevron.left",
            size: size,
            iconSize: size * 0.34,
            iconWeight: .black,
            action: action
        )
    }
}

struct GameCircleSettingsButton: View {
    var size: CGFloat = 52
    let action: () -> Void

    var body: some View {
        GameCircleButton(
            systemImage: "gearshape.fill",
            size: size,
            iconSize: size * 0.38,
            iconWeight: .black,
            action: action
        )
    }
}

/// Downward map marker above the avatar — matches the glossy yellow back button.
struct GameMapLocationMarker: View {
    var width: CGFloat
    var height: CGFloat
    var cornerRadius: CGFloat? = nil

    private var resolvedCornerRadius: CGFloat {
        cornerRadius ?? min(width, height) * 0.22
    }

    var body: some View {
        GameMapLocationMarkerShape(cornerRadius: resolvedCornerRadius)
            .fill(GameButtonAppearance.glossGradient)
            .overlay(alignment: .top) {
                GameMapLocationMarkerShape(cornerRadius: resolvedCornerRadius)
                    .fill(GameButtonAppearance.highlightGradient)
                    .padding(.horizontal, width * 0.12)
                    .padding(.top, height * 0.08)
                    .frame(height: height * 0.42)
            }
            .overlay {
                GameMapLocationMarkerShape(cornerRadius: resolvedCornerRadius)
                    .stroke(GameButtonAppearance.border, lineWidth: max(1.5, width * 0.07))
            }
            .frame(width: width, height: height)
            .shadow(color: .black.opacity(0.28), radius: 3, x: 0, y: 2)
    }
}

struct GameMapLocationMarkerShape: Shape {
    var cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let points = [
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY)
        ]
        return roundedPolygonPath(
            points: points,
            radius: min(cornerRadius, rect.width * 0.24, rect.height * 0.18)
        )
    }

    private func roundedPolygonPath(points: [CGPoint], radius: CGFloat) -> Path {
        guard points.count >= 3, radius > 0 else {
            var path = Path()
            path.addLines(points)
            path.closeSubpath()
            return path
        }

        var path = Path()
        let count = points.count

        for index in 0..<count {
            let current = points[index]
            let previous = points[(index - 1 + count) % count]
            let next = points[(index + 1) % count]

            let toPrevious = vector(from: current, to: previous)
            let toNext = vector(from: current, to: next)

            let previousDistance = distance(from: current, to: previous)
            let nextDistance = distance(from: current, to: next)
            let inset = min(radius, previousDistance * 0.45, nextDistance * 0.45)

            let start = CGPoint(
                x: current.x + toPrevious.x * inset,
                y: current.y + toPrevious.y * inset
            )
            let end = CGPoint(
                x: current.x + toNext.x * inset,
                y: current.y + toNext.y * inset
            )

            if index == 0 {
                path.move(to: start)
            } else {
                path.addLine(to: start)
            }
            path.addQuadCurve(to: end, control: current)
        }

        path.closeSubpath()
        return path
    }

    private func vector(from origin: CGPoint, to destination: CGPoint) -> CGPoint {
        let dx = destination.x - origin.x
        let dy = destination.y - origin.y
        let length = max(sqrt(dx * dx + dy * dy), 0.001)
        return CGPoint(x: dx / length, y: dy / length)
    }

    private func distance(from a: CGPoint, to b: CGPoint) -> CGFloat {
        sqrt(pow(b.x - a.x, 2) + pow(b.y - a.y, 2))
    }
}

#Preview("Circle back (Settings)") {
    ZStack {
        Color(red: 0.98, green: 0.95, blue: 0.86)
        GameCircleBackButton(size: 52) {}
    }
    .frame(width: 200, height: 120)
}

#Preview("Circle button") {
    ZStack {
        Color(red: 0.98, green: 0.95, blue: 0.86)
        GameCircleButton(systemImage: "chevron.left", size: 52) {}
    }
    .frame(width: 200, height: 120)
}

#Preview("Pill button (DONE / PLAY)") {
    ZStack {
        Color(red: 0.98, green: 0.95, blue: 0.86)
        GamePillButton(title: "DONE", fontSize: 18, horizontalPadding: 34, verticalPadding: 12) {}
    }
    .frame(width: 260, height: 120)
}
