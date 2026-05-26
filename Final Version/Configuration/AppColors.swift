import SwiftUI
import UIKit

// Adaptive semantic colors — si adattano automaticamente a Light / Dark Mode
// senza dover leggere @Environment in ogni vista.
extension Color {

    // dark: #081423  light: #F2F8FD
    static let appBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.031, green: 0.078, blue: 0.137, alpha: 1)
            : UIColor(red: 0.949, green: 0.973, blue: 0.992, alpha: 1)
    })

    // dark: #0C1E32  light: #E4F1FB
    static let appPanelBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.047, green: 0.118, blue: 0.196, alpha: 1)
            : UIColor(red: 0.894, green: 0.945, blue: 0.984, alpha: 1)
    })

    // dark: #122841  light: #D2E7F8
    static let appGridBackground = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.071, green: 0.157, blue: 0.255, alpha: 1)
            : UIColor(red: 0.824, green: 0.906, blue: 0.973, alpha: 1)
    })

    // dark: #C8E4F8  light: #0E263E
    static let appPrimaryText = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.784, green: 0.894, blue: 0.973, alpha: 1)
            : UIColor(red: 0.055, green: 0.149, blue: 0.243, alpha: 1)
    })

    // dark: #64A0D2  light: #3A6A96
    static let appSecondaryText = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.392, green: 0.627, blue: 0.824, alpha: 1)
            : UIColor(red: 0.227, green: 0.416, blue: 0.588, alpha: 1)
    })

    // dark: #289BD7  light: #1A8CC7  — blu mappa
    static let appAccent = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.157, green: 0.608, blue: 0.843, alpha: 1)
            : UIColor(red: 0.102, green: 0.549, blue: 0.780, alpha: 1)
    })

    // dark: #235078  light: #64AFE1  — bordo blu
    static let appBorder = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.137, green: 0.314, blue: 0.471, alpha: 1)
            : UIColor(red: 0.392, green: 0.686, blue: 0.882, alpha: 1)
    })

    // dark: #0C1E32  light: #F2F8FD
    static let appCardBack = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.047, green: 0.118, blue: 0.196, alpha: 1)
            : UIColor(red: 0.949, green: 0.973, blue: 0.992, alpha: 1)
    })

    // dark: #122841  light: #F5FCFF
    static let appSpeechBubble = Color(UIColor {
        $0.userInterfaceStyle == .dark
            ? UIColor(red: 0.071, green: 0.157, blue: 0.255, alpha: 1)
            : UIColor(red: 0.961, green: 0.988, blue: 1.000, alpha: 1)
    })
}
