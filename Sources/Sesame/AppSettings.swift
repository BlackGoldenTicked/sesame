import AppKit
import Combine
import Foundation
import SwiftUI

enum SortMode: String, Codable, CaseIterable, Identifiable {
    case alphabetical
    case customGroups

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alphabetical:
            return "Alphabetical"
        case .customGroups:
            return "Custom Groups"
        }
    }
}

enum TextSize: String, Codable, CaseIterable, Identifiable {
    case small
    case medium
    case large

    var id: String { rawValue }

    var fontSize: Double {
        switch self {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        }
    }

    var displayLabel: String {
        switch self {
        case .small: return "S"
        case .medium: return "M"
        case .large: return "L"
        }
    }
}

struct TileMetrics {
    let iconSize: CGFloat
    let tileWidth: CGFloat
    let textWidth: CGFloat
    let spacing: CGFloat
    let rowSpacing: CGFloat
    let textVerticalSpacing: CGFloat

    static func from(fontSize: Double) -> TileMetrics {
        let size = CGFloat(fontSize)
        // Icon scales with font: 12 → 48, 14 → 56, 16 → 64
        let icon = (size * 4).rounded()
        // Tile width = icon + room for 2-line label, scaled by font
        let tile = (icon + size * 3.2 + 24).rounded()
        // Text width slightly narrower than tile to give breathing room
        let textWidth = tile - 4
        // Spacing between tiles scales lightly with font
        let spacing = (size + 4).rounded()
        return TileMetrics(
            iconSize: icon,
            tileWidth: tile,
            textWidth: textWidth,
            spacing: spacing,
            rowSpacing: spacing + 6,
            textVerticalSpacing: max(4, (size * 0.45).rounded())
        )
    }
}

struct Hotkey: Codable, Equatable {
    var modifiers: UInt
    var keyCode: UInt16

    static let `default` = Hotkey(
        modifiers: NSEvent.ModifierFlags.command.rawValue,
        keyCode: 40 // K
    )

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifiers)
    }

    func matches(_ event: NSEvent) -> Bool {
        let relevant: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        let pressed = event.modifierFlags.intersection(relevant)
        let stored = modifierFlags.intersection(relevant)
        return pressed == stored && event.keyCode == keyCode
    }

    var displayString: String {
        var parts: [String] = []
        let flags = modifierFlags
        if flags.contains(.control) { parts.append("⌃") }
        if flags.contains(.option) { parts.append("⌥") }
        if flags.contains(.shift) { parts.append("⇧") }
        if flags.contains(.command) { parts.append("⌘") }
        parts.append(Self.keyName(for: keyCode))
        return parts.joined()
    }

    private static func keyName(for keyCode: UInt16) -> String {
        if let mapped = keyMap[keyCode] { return mapped }
        return "·"
    }

    private static let keyMap: [UInt16: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
        8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
        16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩",
        37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
        44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥", 49: "Space",
        50: "`", 51: "⌫", 53: "⎋",
        123: "←", 124: "→", 125: "↓", 126: "↑"
    ]
}

struct CustomGroup: Codable, Identifiable, Hashable {
    var id: UUID
    var name: String
    var appPaths: [String]

    init(id: UUID = UUID(), name: String, appPaths: [String] = []) {
        self.id = id
        self.name = name
        self.appPaths = appPaths
    }
}

final class AppSettings: ObservableObject {
    static let systemFontName = "__system__"

    @Published var fontName: String = AppSettings.systemFontName { didSet { save() } }
    @Published var textSize: TextSize = .medium { didSet { save() } }
    @Published var hiddenAppPaths: Set<String> = [] { didSet { save() } }
    @Published var sortMode: SortMode = .alphabetical { didSet { save() } }
    @Published var customGroups: [CustomGroup] = [] { didSet { save() } }
    @Published var language: AppLanguage = AppSettings.systemPreferredLanguage() {
        didSet {
            save()
            if oldValue != language {
                NotificationCenter.default.post(name: AppSettings.languageDidChange, object: self)
            }
        }
    }

    static let languageDidChange = Notification.Name("AppSettings.languageDidChange")
    @Published var launchAtLogin: Bool = false {
        didSet {
            if oldValue != launchAtLogin {
                LaunchAtLoginManager.setEnabled(launchAtLogin)
            }
            save()
        }
    }
    @Published var hintHotkey: Hotkey = .default { didSet { save() } }
    @Published var gridCellSize: Double = 114 { didSet { save() } }
    @Published var colorTheme: ColorTheme = .sunset { didSet { save() } }

    private static let defaultsKey = "SesameSettings.v2"
    private static let legacyDefaultsKey = "SesameSettings.v1"
    private var suppressSave = false

    init() {
        load()
        suppressSave = true
        launchAtLogin = LaunchAtLoginManager.isEnabled
        suppressSave = false
    }

    private struct Persisted: Codable {
        var fontName: String
        var textSize: TextSize
        var hiddenAppPaths: [String]
        var sortMode: SortMode
        var customGroups: [CustomGroup]
        var language: AppLanguage
        var hintHotkey: Hotkey
        var gridCellSize: Double
        var colorTheme: ColorTheme?
    }

    private struct LegacyPersisted: Codable {
        var fontName: String
        var fontSize: Double
        var hiddenAppPaths: [String]
        var sortMode: SortMode
        var customGroups: [CustomGroup]
    }

    private func load() {
        let defaults = UserDefaults.standard

        if
            let data = defaults.data(forKey: Self.defaultsKey),
            let parsed = try? JSONDecoder().decode(Persisted.self, from: data)
        {
            suppressSave = true
            fontName = parsed.fontName
            textSize = parsed.textSize
            hiddenAppPaths = Set(parsed.hiddenAppPaths)
            sortMode = parsed.sortMode
            customGroups = parsed.customGroups
            language = parsed.language
            hintHotkey = parsed.hintHotkey
            gridCellSize = parsed.gridCellSize
            colorTheme = parsed.colorTheme ?? .sunset
            suppressSave = false
            return
        }

        if
            let data = defaults.data(forKey: Self.legacyDefaultsKey),
            let parsed = try? JSONDecoder().decode(LegacyPersisted.self, from: data)
        {
            suppressSave = true
            fontName = parsed.fontName
            textSize = Self.closestTextSize(to: parsed.fontSize)
            hiddenAppPaths = Set(parsed.hiddenAppPaths)
            sortMode = parsed.sortMode
            customGroups = parsed.customGroups
            suppressSave = false
        }
    }

    private static func closestTextSize(to value: Double) -> TextSize {
        TextSize.allCases.min(by: { abs($0.fontSize - value) < abs($1.fontSize - value) }) ?? .medium
    }

    private static func systemPreferredLanguage() -> AppLanguage {
        let identifier = Locale.current.identifier.lowercased()
        return identifier.hasPrefix("zh") ? .chinese : .english
    }

    private func save() {
        guard !suppressSave else { return }
        let persisted = Persisted(
            fontName: fontName,
            textSize: textSize,
            hiddenAppPaths: Array(hiddenAppPaths),
            sortMode: sortMode,
            customGroups: customGroups,
            language: language,
            hintHotkey: hintHotkey,
            gridCellSize: gridCellSize,
            colorTheme: colorTheme
        )

        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

    var fontSize: Double { textSize.fontSize }

    var tileMetrics: TileMetrics { TileMetrics.from(fontSize: fontSize) }

    var isUsingSystemFont: Bool {
        fontName == Self.systemFontName
    }

    func appFont(weight: Font.Weight = .semibold, sizeBoost: CGFloat = 0) -> Font {
        let size = fontSize + sizeBoost
        if isUsingSystemFont {
            return .system(size: size, weight: weight)
        }
        return .custom(fontName, size: size)
    }

    func sectionFont() -> Font {
        let size = fontSize + 1
        if isUsingSystemFont {
            return .system(size: size, weight: .heavy, design: .monospaced)
        }
        return .custom(fontName, size: size)
    }

    func setHidden(_ hidden: Bool, for application: MacApplication) {
        if hidden {
            hiddenAppPaths.insert(application.url.path)
        } else {
            hiddenAppPaths.remove(application.url.path)
        }
    }

    func isHidden(_ application: MacApplication) -> Bool {
        hiddenAppPaths.contains(application.url.path)
    }

    func upsertGroup(_ group: CustomGroup) {
        if let index = customGroups.firstIndex(where: { $0.id == group.id }) {
            customGroups[index] = group
        } else {
            customGroups.append(group)
        }
    }

    func removeGroup(id: UUID) {
        customGroups.removeAll { $0.id == id }
    }

    func t(_ key: L) -> String {
        key.string(language)
    }
}

enum InstalledFontCatalog {
    static func familyNames() -> [String] {
        NSFontManager.shared.availableFontFamilies.sorted { lhs, rhs in
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }
}
