import SwiftUI
import UIKit

// Adaptive semantic colors — si adattano automaticamente a Light / Dark Mode
// senza dover leggere @Environment in ogni vista.
extension Color {

    // dark: #2C1A0E  light: #F5E8D0
    static let appBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.173, green: 0.102, blue: 0.055, alpha: 1)
            : UIColor(red: 0.961, green: 0.910, blue: 0.816, alpha: 1)
    })

    // dark: #3D2010  light: #EDD8B0
    static let appPanelBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.125, blue: 0.063, alpha: 1)
            : UIColor(red: 0.929, green: 0.847, blue: 0.690, alpha: 1)
    })

    // dark: #4A2D18  light: #E0C898
    static let appGridBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.290, green: 0.176, blue: 0.094, alpha: 1)
            : UIColor(red: 0.878, green: 0.784, blue: 0.596, alpha: 1)
    })

    // dark: #F5E6C8  light: #2C1A0E
    static let appPrimaryText = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.961, green: 0.902, blue: 0.784, alpha: 1)
            : UIColor(red: 0.173, green: 0.102, blue: 0.055, alpha: 1)
    })

    // dark: #C8A464  light: #7A4828
    static let appSecondaryText = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.784, green: 0.643, blue: 0.392, alpha: 1)
            : UIColor(red: 0.478, green: 0.282, blue: 0.157, alpha: 1)
    })

    // dark: #D94F44  light: #C0392B  — rosso Cappuccetto
    static let appAccent = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.851, green: 0.310, blue: 0.267, alpha: 1)
            : UIColor(red: 0.753, green: 0.224, blue: 0.169, alpha: 1)
    })

    // dark: #8B6914  light: #A07820  — oro antico
    static let appBorder = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.545, green: 0.412, blue: 0.078, alpha: 1)
            : UIColor(red: 0.627, green: 0.471, blue: 0.125, alpha: 1)
    })

    // dark: #3D2010  light: #F5E8D0
    static let appCardBack = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.239, green: 0.125, blue: 0.063, alpha: 1)
            : UIColor(red: 0.961, green: 0.910, blue: 0.816, alpha: 1)
    })

    // dark: #4A2D18  light: #FFF0DC
    static let appSpeechBubble = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.290, green: 0.176, blue: 0.094, alpha: 1)
            : UIColor(red: 1.000, green: 0.941, blue: 0.863, alpha: 1)
    })
}
