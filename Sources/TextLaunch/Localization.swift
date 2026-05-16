import Foundation

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case english = "en"
    case chinese = "zh"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .english: return "English"
        case .chinese: return "中文"
        }
    }
}

enum L {
    case settings, general, hidden, groupsTab, about
    case generalSubtitle, hiddenSubtitle, groupsSubtitle, aboutSubtitle
    case startup, launchAtLogin
    case language
    case hotkeySection, hotkey, hotkeyHint, recording, pressKey, clear
    case appearance
    case textSize, small, medium, large
    case gridDensity, cellSize, compact, loose
    case hiddenApps, hiddenCount, filter, manageHiddenApps
    case groups, manageGroups, newGroup, edit, delete, ungrouped, noGroups, createGroupHint
    case appName, tagline, version, versionNumber, copyrightLine1, copyrightLine2, website, visitWebsite, sendFeedback, acknowledgements
    case copyright
    case font, fontFamily, systemDefault, preview, applicationFont, fontFootnote

    func string(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return Self.english[self] ?? ""
        case .chinese: return Self.chinese[self] ?? ""
        }
    }

    private static let english: [L: String] = [
        .settings: "TextLaunch Settings",
        .general: "General",
        .hidden: "Hidden",
        .groupsTab: "Groups",
        .about: "About",
        .generalSubtitle: "Configure TextLaunch's behavior and appearance.",
        .hiddenSubtitle: "Choose which apps appear in the launcher.",
        .groupsSubtitle: "Organize apps into named groups.",
        .aboutSubtitle: "About TextLaunch",
        .startup: "Startup",
        .launchAtLogin: "Launch TextLaunch at login",
        .language: "Language",
        .hotkeySection: "Hotkey",
        .hotkey: "Open Hint Mode",
        .hotkeyHint: "Press this combination inside the launcher to enter Hint mode.",
        .recording: "Recording…",
        .pressKey: "Press a key combination",
        .clear: "Reset",
        .appearance: "Appearance",
        .textSize: "Text Size",
        .small: "S",
        .medium: "M",
        .large: "L",
        .gridDensity: "Grid Density",
        .cellSize: "Background cell size",
        .compact: "Compact",
        .loose: "Loose",
        .hiddenApps: "Hidden Apps",
        .hiddenCount: "hidden",
        .filter: "Filter applications",
        .manageHiddenApps: "Choose which apps appear in the launcher.",
        .groups: "Custom Groups",
        .manageGroups: "Organize apps into named groups.",
        .newGroup: "New Group…",
        .edit: "Edit",
        .delete: "Delete",
        .ungrouped: "Ungrouped",
        .noGroups: "No custom groups yet.",
        .createGroupHint: "Create a group to organize your apps.",
        .appName: "TextLaunch",
        .tagline: "A keyboard-first launcher for macOS.",
        .version: "Version",
        .versionNumber: "0.0.1",
        .copyrightLine1: "© Chaordex Technologies Ltd.",
        .copyrightLine2: "2024–2026. All rights reserved.",
        .copyright: "© Chaordex Technologies Ltd. 2024–2026. All rights reserved.",
        .website: "Website",
        .visitWebsite: "Visit Website",
        .sendFeedback: "Send Feedback",
        .acknowledgements: "Acknowledgements",
        .font: "Font",
        .fontFamily: "Family",
        .systemDefault: "System Default",
        .preview: "Preview",
        .applicationFont: "Application Font",
        .fontFootnote: "Affects the app buttons in the launcher and group editor."
    ]

    private static let chinese: [L: String] = [
        .settings: "TextLaunch 设置",
        .general: "通用",
        .hidden: "隐藏",
        .groupsTab: "分组",
        .about: "关于",
        .generalSubtitle: "配置 TextLaunch 的基本行为与外观。",
        .hiddenSubtitle: "选择启动器中显示的应用。",
        .groupsSubtitle: "把应用归类到命名分组中。",
        .aboutSubtitle: "关于 TextLaunch",
        .startup: "启动",
        .launchAtLogin: "登录时启动 TextLaunch",
        .language: "语言",
        .hotkeySection: "快捷键",
        .hotkey: "打开 Hint 模式",
        .hotkeyHint: "在启动器中按下该组合键进入 Hint 模式。",
        .recording: "正在录制…",
        .pressKey: "按下一个快捷键",
        .clear: "重置",
        .appearance: "外观",
        .textSize: "文字大小",
        .small: "小",
        .medium: "中",
        .large: "大",
        .gridDensity: "网格密度",
        .cellSize: "背景网格尺寸",
        .compact: "紧凑",
        .loose: "宽松",
        .hiddenApps: "隐藏的应用",
        .hiddenCount: "已隐藏",
        .filter: "筛选应用",
        .manageHiddenApps: "选择启动器中显示的应用。",
        .groups: "自定义分组",
        .manageGroups: "把应用归类到命名分组中。",
        .newGroup: "新建分组…",
        .edit: "编辑",
        .delete: "删除",
        .ungrouped: "未分组",
        .noGroups: "还没有自定义分组。",
        .createGroupHint: "创建一个分组来管理你的应用。",
        .appName: "TextLaunch",
        .tagline: "为 macOS 打造的键盘优先启动器。",
        .version: "版本",
        .versionNumber: "0.0.1",
        .copyrightLine1: "© Chaordex Technologies Ltd.",
        .copyrightLine2: "2024–2026 版权所有。",
        .copyright: "© Chaordex Technologies Ltd. 2024–2026 版权所有。",
        .website: "官网",
        .visitWebsite: "访问官网",
        .sendFeedback: "意见反馈",
        .acknowledgements: "致谢",
        .font: "字体",
        .fontFamily: "字体族",
        .systemDefault: "系统默认",
        .preview: "预览",
        .applicationFont: "应用字体",
        .fontFootnote: "影响启动器与分组编辑器中的应用按钮。"
    ]
}
