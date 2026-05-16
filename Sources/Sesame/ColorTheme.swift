import SwiftUI

enum ColorTheme: String, CaseIterable, Codable, Identifiable {
    case sunset
    case aurora
    case peach
    case ocean
    case mono

    var id: String { rawValue }

    var localizationKey: L {
        switch self {
        case .sunset: return .themeSunset
        case .aurora: return .themeAurora
        case .peach: return .themePeach
        case .ocean: return .themeOcean
        case .mono: return .themeMono
        }
    }

    // MARK: - Toolbar gradient (used by mode toggle + settings button)

    var toolbarGradientColors: [Color] {
        switch self {
        case .sunset:
            return [
                Color(red: 1.00, green: 0.62, blue: 0.42),
                Color(red: 1.00, green: 0.55, blue: 0.62),
                Color(red: 0.78, green: 0.65, blue: 0.96),
                Color(red: 0.45, green: 0.55, blue: 1.00)
            ]
        case .aurora:
            return [
                Color(red: 0.20, green: 0.95, blue: 0.65),
                Color(red: 0.25, green: 0.80, blue: 0.95),
                Color(red: 0.45, green: 0.50, blue: 1.00),
                Color(red: 0.70, green: 0.40, blue: 1.00)
            ]
        case .peach:
            return [
                Color(red: 1.00, green: 0.90, blue: 0.72),
                Color(red: 1.00, green: 0.74, blue: 0.55),
                Color(red: 1.00, green: 0.58, blue: 0.52),
                Color(red: 0.95, green: 0.45, blue: 0.60)
            ]
        case .ocean:
            return [
                Color(red: 0.32, green: 0.82, blue: 1.00),
                Color(red: 0.20, green: 0.58, blue: 0.95),
                Color(red: 0.18, green: 0.40, blue: 0.85),
                Color(red: 0.30, green: 0.28, blue: 0.78)
            ]
        case .mono:
            return [
                Color(white: 0.92),
                Color(white: 0.74),
                Color(white: 0.55),
                Color(white: 0.38)
            ]
        }
    }

    var toolbarGradient: LinearGradient {
        LinearGradient(
            colors: toolbarGradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Search pill color blobs (upper-right, lower-center, left-down)

    var pillBlobColors: [Color] {
        switch self {
        case .sunset:
            return [
                Color(red: 0.30, green: 0.55, blue: 1.00),
                Color(red: 1.00, green: 0.50, blue: 0.45),
                Color(red: 0.75, green: 0.50, blue: 1.00)
            ]
        case .aurora:
            return [
                Color(red: 0.25, green: 0.95, blue: 0.65),
                Color(red: 0.45, green: 0.55, blue: 1.00),
                Color(red: 0.70, green: 0.40, blue: 1.00)
            ]
        case .peach:
            return [
                Color(red: 1.00, green: 0.60, blue: 0.42),
                Color(red: 1.00, green: 0.50, blue: 0.55),
                Color(red: 0.98, green: 0.82, blue: 0.55)
            ]
        case .ocean:
            return [
                Color(red: 0.30, green: 0.78, blue: 1.00),
                Color(red: 0.18, green: 0.50, blue: 0.92),
                Color(red: 0.40, green: 0.42, blue: 0.96)
            ]
        case .mono:
            return [
                Color(white: 0.92),
                Color(white: 0.60),
                Color(white: 0.78)
            ]
        }
    }

    // MARK: - Ambient background tints (cool, warm, accent)

    var ambientColors: [Color] {
        switch self {
        case .sunset:
            return [
                Color(red: 0.25, green: 0.45, blue: 0.95),
                Color(red: 1.00, green: 0.45, blue: 0.55),
                Color(red: 0.65, green: 0.45, blue: 1.00)
            ]
        case .aurora:
            return [
                Color(red: 0.20, green: 0.90, blue: 0.62),
                Color(red: 0.40, green: 0.55, blue: 1.00),
                Color(red: 0.70, green: 0.40, blue: 1.00)
            ]
        case .peach:
            return [
                Color(red: 1.00, green: 0.55, blue: 0.40),
                Color(red: 0.95, green: 0.70, blue: 0.45),
                Color(red: 1.00, green: 0.48, blue: 0.62)
            ]
        case .ocean:
            return [
                Color(red: 0.25, green: 0.55, blue: 0.95),
                Color(red: 0.20, green: 0.75, blue: 0.95),
                Color(red: 0.30, green: 0.38, blue: 0.85)
            ]
        case .mono:
            return [
                Color(white: 0.55),
                Color(white: 0.62),
                Color(white: 0.50)
            ]
        }
    }
}
