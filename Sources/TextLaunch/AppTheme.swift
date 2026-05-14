import AppKit
import SwiftUI

enum AppTheme {
    static let canvas = Color(hex: 0xEEF1EE)
    static let panel = Color(hex: 0xF8F9F7)
    static let surface = Color(hex: 0xFCFCF9)
    static let elevated = Color(hex: 0xD9DED8)
    static let primary = Color(hex: 0x4F5F68)
    static let primaryActive = Color(hex: 0x3F4C54)
    static let body = Color(hex: 0x273036)
    static let muted = Color(hex: 0x7A8589)
    static let mutedStrong = Color(hex: 0x5F6B70)
    static let onPrimary = Color(hex: 0xF8F9F7)
    static let accent = Color(hex: 0xC58A2E)
}

extension Color {
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

extension NSColor {
    convenience init(hex: UInt32) {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
