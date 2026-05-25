import SwiftUI
import UIKit

// Adaptive semantic colors — si adattano automaticamente a Light / Dark Mode
// senza dover leggere @Environment in ogni vista.
extension Color {

    static let appBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.13, green: 0.10, blue: 0.07, alpha: 1)
            : UIColor(red: 0.961, green: 0.945, blue: 0.922, alpha: 1)
    })

    static let appPanelBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.13, blue: 0.09, alpha: 1)
            : UIColor(red: 0.94, green: 0.92, blue: 0.88, alpha: 1)
    })

    static let appGridBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.21, green: 0.17, blue: 0.12, alpha: 1)
            : UIColor(red: 0.87, green: 0.85, blue: 0.81, alpha: 1)
    })

    static let appPrimaryText = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.94, green: 0.89, blue: 0.81, alpha: 1)
            : UIColor(red: 0.20, green: 0.13, blue: 0.07, alpha: 1)
    })

    static let appSecondaryText = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.78, green: 0.65, blue: 0.48, alpha: 1)
            : UIColor(red: 0.55, green: 0.42, blue: 0.27, alpha: 1)
    })

    static let appAccent = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.92, green: 0.62, blue: 0.28, alpha: 1)
            : UIColor(red: 0.77, green: 0.47, blue: 0.17, alpha: 1)
    })

    static let appBorder = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.52, green: 0.40, blue: 0.24, alpha: 1)
            : UIColor(red: 0.83, green: 0.71, blue: 0.45, alpha: 1)
    })

    static let appCardBack = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.19, green: 0.15, blue: 0.10, alpha: 1)
            : UIColor(red: 0.961, green: 0.945, blue: 0.922, alpha: 1)
    })

    static let appSpeechBubble = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.17, blue: 0.12, alpha: 1)
            : UIColor(red: 1.0, green: 0.985, blue: 0.94, alpha: 1)
    })
}
