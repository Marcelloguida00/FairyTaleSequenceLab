import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

/// Touch targets and chrome sizes aligned with Apple HIG (44 pt minimum; roomier on iPad).
enum GameButtonMetrics {
    /// Minimum interactive target on all platforms (Human Interface Guidelines).
    static let minimumTouchTarget: CGFloat = 44

    static var isPad: Bool {
        #if canImport(UIKit)
        UIDevice.current.userInterfaceIdiom == .pad
        #else
        false
        #endif
    }

    /// Map / sequencing / AR chrome circles (back, settings) — visibly larger on iPad.
    static var chromeCircleSize: CGFloat { isPad ? 80 : 56 }

    /// Standard circle icon buttons.
    static var standardCircleSize: CGFloat { isPad ? 56 : 48 }

    /// Storybook control on the map.
    static var bookButtonSize: CGFloat { isPad ? 112 : 88 }

    static var pillMinHeight: CGFloat { isPad ? 48 : 44 }
    static var pillFontSize: CGFloat { isPad ? 17 : 15 }
    static var pillHorizontalPadding: CGFloat { isPad ? 26 : 22 }
    static var pillVerticalPadding: CGFloat { isPad ? 12 : 10 }

    /// Large CTA on the map (play / start event).
    static var primaryPillWidth: CGFloat { isPad ? 260 : 220 }
    static var primaryPillHeight: CGFloat { isPad ? 72 : 60 }
    static var primaryPillFontSize: CGFloat { isPad ? 28 : 24 }
    static var primaryPillHorizontalPadding: CGFloat { isPad ? 56 : 44 }
    static var primaryPillVerticalPadding: CGFloat { isPad ? 18 : 14 }

    /// When both `minWidth` and `minHeight` are set (or `fixedSize`), the glossy pill must fill that rect.
    static func pillBoundsSize(
        minWidth: CGFloat?,
        minHeight: CGFloat?,
        fixedSize: CGSize? = nil
    ) -> CGSize? {
        if let fixedSize { return fixedSize }
        if let minWidth, let minHeight {
            return CGSize(width: minWidth, height: minHeight)
        }
        return nil
    }

    /// List / settings rows (same minimum as pill buttons).
    static var settingsRowMinHeight: CGFloat { pillMinHeight }

    static func pillMinHeight(atLeast proposed: CGFloat) -> CGFloat {
        max(proposed, pillMinHeight)
    }

    static func rowMinHeight(fillHeight: Bool) -> CGFloat {
        fillHeight ? 64 : settingsRowMinHeight
    }
}

extension View {
    /// Ensures the tappable region is at least the HIG minimum (44×44 pt).
    func gameMinimumTouchTarget(
        minWidth: CGFloat = GameButtonMetrics.minimumTouchTarget,
        minHeight: CGFloat = GameButtonMetrics.minimumTouchTarget
    ) -> some View {
        frame(minWidth: minWidth, minHeight: minHeight)
            .contentShape(Rectangle())
    }

    /// Settings / info list rows: minimum row height + rectangular hit area.
    func gameSettingsRowTouchTarget(fillHeight: Bool = false) -> some View {
        frame(minHeight: GameButtonMetrics.rowMinHeight(fillHeight: fillHeight))
            .contentShape(Rectangle())
    }
}
