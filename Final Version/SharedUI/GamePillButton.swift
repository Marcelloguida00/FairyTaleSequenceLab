import SwiftUI

private enum GameButtonStyle {
    static let glossTop = Color(hex: "#FDE549")
    static let glossMid = Color(hex: "#FCDB00")
    static let glossBottom = Color(hex: "#FCDB00")
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
                    .stroke(Color(hex: "#430303"), lineWidth: 2)
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
                    .stroke(Color(hex: "#430303"), lineWidth: 2)
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
