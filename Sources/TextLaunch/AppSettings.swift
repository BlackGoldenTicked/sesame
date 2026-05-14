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
    @Published var fontSize: Double = 13 { didSet { save() } }
    @Published var hiddenAppPaths: Set<String> = [] { didSet { save() } }
    @Published var sortMode: SortMode = .alphabetical { didSet { save() } }
    @Published var customGroups: [CustomGroup] = [] { didSet { save() } }

    private static let defaultsKey = "TextLaunchSettings.v1"
    private var suppressSave = false

    init() {
        load()
    }

    private struct Persisted: Codable {
        var fontName: String
        var fontSize: Double
        var hiddenAppPaths: [String]
        var sortMode: SortMode
        var customGroups: [CustomGroup]
    }

    private func load() {
        guard
            let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
            let parsed = try? JSONDecoder().decode(Persisted.self, from: data)
        else {
            return
        }

        suppressSave = true
        fontName = parsed.fontName
        fontSize = parsed.fontSize
        hiddenAppPaths = Set(parsed.hiddenAppPaths)
        sortMode = parsed.sortMode
        customGroups = parsed.customGroups
        suppressSave = false
    }

    private func save() {
        guard !suppressSave else { return }
        let persisted = Persisted(
            fontName: fontName,
            fontSize: fontSize,
            hiddenAppPaths: Array(hiddenAppPaths),
            sortMode: sortMode,
            customGroups: customGroups
        )

        if let data = try? JSONEncoder().encode(persisted) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }

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
}

enum InstalledFontCatalog {
    static func familyNames() -> [String] {
        NSFontManager.shared.availableFontFamilies.sorted { lhs, rhs in
            lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
        }
    }
}
