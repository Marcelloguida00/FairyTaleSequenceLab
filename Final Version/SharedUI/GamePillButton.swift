import SwiftUI

enum GameButtonAppearance {
    static let glossTop = Color(hex: "#FDE549")
    static let glossMid = Color(hex: "#FCDB00")
    static let glossBottom = Color(hex: "#FCDB00")
    static let border = Color(hex: "#430303")
    static let label = Color(hex: "#262521")

    /// Gloss strip on pill buttons (shorter = larger horizontal inset).
    static let pillHighlightHorizontalInset: CGFloat = 13
    static let pillHighlightTopInset: CGFloat = 2
    static let pillHighlightHeight: CGFloat = 22

    /// Gloss strip on circle buttons (smaller inset = wider highlight).
    static let circleHighlightHorizontalInset: CGFloat = 1
    static let circleHighlightTopInset: CGFloat = 2
    static let circleHighlightHeight: CGFloat = 26

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
    @Environment(\.differentiate) private var differentiate

    var body: some View {
        ZStack {
            Capsule()
                .fill(GameButtonStyle.glossGradient)
                .overlay(alignment: .top) {
                    Capsule()
                        .fill(GameButtonStyle.highlightGradient)
                        .padding(.horizontal, GameButtonAppearance.pillHighlightHorizontalInset)
                        .padding(.top, GameButtonAppearance.pillHighlightTopInset)
                        .frame(height: GameButtonAppearance.pillHighlightHeight)
                }
                .overlay {
                    Capsule()
                        .stroke(GameButtonAppearance.border, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.28), radius: 5, y: 3)

            if differentiate {
                Capsule()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                GameButtonAppearance.border.opacity(0.15),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
        }
    }
}

/// Glossy yellow circle used for icon buttons (back, etc.).
struct GameCircleButtonBackground: View {
    @Environment(\.differentiate) private var differentiate

    var body: some View {
        ZStack {
            Circle()
                .fill(GameButtonStyle.glossGradient)
                .overlay(alignment: .top) {
                    Circle()
                        .fill(GameButtonStyle.highlightGradient)
                        .padding(.horizontal, GameButtonAppearance.circleHighlightHorizontalInset)
                        .padding(.top, GameButtonAppearance.circleHighlightTopInset)
                        .frame(height: GameButtonAppearance.circleHighlightHeight)
                }
                .overlay {
                    Circle()
                        .stroke(GameButtonAppearance.border, lineWidth: 2)
                }
                .shadow(color: .black.opacity(0.28), radius: 5, y: 3)

            if differentiate {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                GameButtonAppearance.border.opacity(0.2),
                                .clear
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
            }
        }
    }
}

struct GamePillLabel: View {
    let title: String
    var fontSize: CGFloat = 15
    var horizontalPadding: CGFloat = 22
    var verticalPadding: CGFloat = 10
    var minWidth: CGFloat? = nil
    var minHeight: CGFloat? = nil
    var boundsSize: CGSize? = nil
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil

    private var labelColor: Color {
        GameButtonStyle.label
    }

    private var labelContent: some View {
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
    }

    var body: some View {
        Group {
            if let boundsSize {
                labelContent
                    .frame(width: boundsSize.width)
                    .frame(minHeight: boundsSize.height, alignment: .center)
            } else {
                labelContent
                    .frame(
                        minWidth: minWidth,
                        minHeight: minHeight ?? GameButtonMetrics.pillMinHeight
                    )
            }
        }
        .background(GamePillButtonBackground())
    }
}

/// Plain button with HIG minimum touch target — prefer over raw `Button` + `.plain`.
struct GamePlainButton<Label: View>: View {
    let action: () -> Void
    @ViewBuilder let label: () -> Label

    init(action: @escaping () -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
    }

    var body: some View {
        Button(action: action, label: label)
            .buttonStyle(.plain)
            .gameMinimumTouchTarget()
    }
}

/// Secondary capsule (skip, play again, cancel text actions).
struct GameCapsuleButton: View {
    let title: String
    var systemImage: String? = nil
    var fontSize: CGFloat = GameButtonMetrics.pillFontSize - 1
    var foregroundColor: Color = GameButtonAppearance.label.opacity(0.72)
    var fillColor: Color = Color.white.opacity(0.88)
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.app(size: fontSize * 0.88, weight: .semibold))
                }
                Text(title)
                    .font(.app(size: fontSize, weight: .semibold))
            }
            .foregroundStyle(foregroundColor)
            .padding(.horizontal, GameButtonMetrics.pillHorizontalPadding - 6)
            .padding(.vertical, GameButtonMetrics.pillVerticalPadding - 1)
            .background(Capsule().fill(fillColor))
        }
        .buttonStyle(.plain)
        .gameMinimumTouchTarget()
    }
}

struct GamePillButton: View {
    let title: String
    var fontSize: CGFloat = GameButtonMetrics.pillFontSize
    var horizontalPadding: CGFloat = GameButtonMetrics.pillHorizontalPadding
    var verticalPadding: CGFloat = GameButtonMetrics.pillVerticalPadding
    var minWidth: CGFloat? = nil
    var minHeight: CGFloat? = nil
    /// When set, the glossy capsule stretches to this size (map/sequencing chrome).
    var fixedSize: CGSize? = nil
    var leadingIcon: String? = nil
    var trailingIcon: String? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    private var boundsSize: CGSize? {
        GameButtonMetrics.pillBoundsSize(
            minWidth: minWidth,
            minHeight: minHeight,
            fixedSize: fixedSize
        )
    }

    var body: some View {
        Button(action: action) {
            GamePillLabel(
                title: title,
                fontSize: fontSize,
                horizontalPadding: horizontalPadding,
                verticalPadding: verticalPadding,
                minWidth: minWidth,
                minHeight: minHeight,
                boundsSize: boundsSize,
                leadingIcon: leadingIcon,
                trailingIcon: trailingIcon
            )
        }
        .buttonStyle(.plain)
        .gameMinimumTouchTarget(
            minWidth: max(boundsSize?.width ?? 0, GameButtonMetrics.minimumTouchTarget),
            minHeight: max(boundsSize?.height ?? 0, GameButtonMetrics.minimumTouchTarget)
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

/// Large map / event CTA pill — fills primary bounds on iPad and iPhone.
struct GamePrimaryPillButton: View {
    let title: String
    var trailingIcon: String? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    private var primarySize: CGSize {
        CGSize(
            width: GameButtonMetrics.primaryPillWidth,
            height: GameButtonMetrics.primaryPillHeight
        )
    }

    var body: some View {
        GamePillButton(
            title: title,
            fontSize: GameButtonMetrics.primaryPillFontSize,
            horizontalPadding: GameButtonMetrics.primaryPillHorizontalPadding,
            verticalPadding: GameButtonMetrics.primaryPillVerticalPadding,
            minWidth: primarySize.width,
            minHeight: primarySize.height,
            trailingIcon: trailingIcon,
            isDisabled: isDisabled,
            action: action
        )
    }
}

struct GameCircleButton: View {
    let systemImage: String
    var size: CGFloat = GameButtonMetrics.standardCircleSize
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
        .gameMinimumTouchTarget(
            minWidth: max(size, GameButtonMetrics.minimumTouchTarget),
            minHeight: max(size, GameButtonMetrics.minimumTouchTarget)
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

struct GameCircleBackButton: View {
    var size: CGFloat = GameButtonMetrics.chromeCircleSize
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
    var size: CGFloat = GameButtonMetrics.chromeCircleSize
    let action: () -> Void

    var body: some View {
        GameCircleButton(
            systemImage: "gearshape.fill",
            size: size,
            iconSize: size * 0.28,
            iconWeight: .black,
            action: action
        )
    }
}

struct GameCircleTextButton: View {
    let title: String
    var size: CGFloat = GameButtonMetrics.standardCircleSize
    var fontSize: CGFloat? = nil
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.app(size: fontSize ?? size * 0.46, weight: .black))
                .foregroundStyle(GameButtonStyle.label)
                .shadow(color: .black.opacity(0.14), radius: 0, x: 0, y: 1)
                .frame(width: size, height: size)
                .background(GameCircleButtonBackground())
        }
        .buttonStyle(.plain)
        .gameMinimumTouchTarget(
            minWidth: max(size, GameButtonMetrics.minimumTouchTarget),
            minHeight: max(size, GameButtonMetrics.minimumTouchTarget)
        )
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.55 : 1)
    }
}

struct GameCircleCheckButton: View {
    var size: CGFloat = GameButtonMetrics.standardCircleSize
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        GameCircleButton(
            systemImage: "checkmark",
            size: size,
            iconSize: size * 0.34,
            iconWeight: .black,
            isDisabled: isDisabled,
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

// Canvas completo: `GameButtonTuningPreview.swift` → preview "Bottoni · tuning"
