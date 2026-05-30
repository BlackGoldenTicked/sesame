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
    case theme, themeSunset, themeAurora, themePeach, themeOcean, themeMono
    case textSize, small, medium, large
    case gridDensity, cellSize, compact, loose
    case hiddenApps, hiddenCount, filter, manageHiddenApps
    case groups, manageGroups, newGroup, edit, delete, ungrouped, noGroups, createGroupHint
    case appName, tagline, version, versionNumber, copyrightLine1, copyrightLine2, website, visitWebsite, sendFeedback, acknowledgements
    case copyright
    case font, fontFamily, systemDefault, preview, applicationFont, fontFootnote
    case menuShowApp, menuShowApplications, menuReload, menuSettings, menuQuit
    case menuTriggerCorner, cornerOff, cornerTopLeft, cornerTopRight, cornerBottomLeft, cornerBottomRight
    case ctxHide, ctxUninstall
    case confirmHideTitle, confirmHideBody, confirmUninstallTitle, confirmUninstallBody
    case actionHide, actionMoveToTrash, actionCancel, okButton, uninstallFailedTitle

    func string(_ lang: AppLanguage) -> String {
        switch lang {
        case .english: return Self.english[self] ?? ""
        case .chinese: return Self.chinese[self] ?? ""
        }
    }

    private static let english: [L: String] = [
        .settings: "Sesame Settings",
        .general: "General",
        .hidden: "Hidden",
        .groupsTab: "Groups",
        .about: "About",
        .generalSubtitle: "Configure Sesame's behavior and appearance.",
        .hiddenSubtitle: "Choose which apps appear in the launcher.",
        .groupsSubtitle: "Organize apps into named groups.",
        .aboutSubtitle: "About Sesame",
        .startup: "Startup",
        .launchAtLogin: "Launch Sesame at login",
        .language: "Language",
        .hotkeySection: "Hotkey",
        .hotkey: "Open Hint Mode",
        .hotkeyHint: "Press this combination inside the launcher to enter Hint mode.",
        .recording: "Recording…",
        .pressKey: "Press a key combination",
        .clear: "Reset",
        .appearance: "Appearance",
        .theme: "Theme",
        .themeSunset: "Sunset",
        .themeAurora: "Aurora",
        .themePeach: "Peach",
        .themeOcean: "Ocean",
        .themeMono: "Mono",
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
        .appName: "Sesame",
        .tagline: "Tiny grains. Open everything.",
        .version: "Version",
        .versionNumber: "1.0.0",
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
        .fontFootnote: "Affects the app buttons in the launcher and group editor.",
        .menuShowApp: "Show Sesame",
        .menuShowApplications: "Show Applications",
        .menuReload: "Reload Applications",
        .menuSettings: "Settings…",
        .menuQuit: "Quit Sesame",
        .menuTriggerCorner: "Trigger Corner",
        .cornerOff: "Off",
        .cornerTopLeft: "Top Left",
        .cornerTopRight: "Top Right",
        .cornerBottomLeft: "Bottom Left",
        .cornerBottomRight: "Bottom Right",
        .ctxHide: "Hide from Launcher",
        .ctxUninstall: "Move to Trash…",
        .confirmHideTitle: "Hide \u{201C}%@\u{201D}?",
        .confirmHideBody: "It will be removed from the launcher. You can restore it anytime from Settings \u{25B8} Hidden.",
        .confirmUninstallTitle: "Move \u{201C}%@\u{201D} to the Trash?",
        .confirmUninstallBody: "The application will be moved to the Trash. You can restore it from the Trash until you empty it.",
        .actionHide: "Hide",
        .actionMoveToTrash: "Move to Trash",
        .actionCancel: "Cancel",
        .okButton: "OK",
        .uninstallFailedTitle: "Couldn\u{2019}t move \u{201C}%@\u{201D} to the Trash"
    ]

    private static let chinese: [L: String] = [
        .settings: "Sesame 设置",
        .general: "通用",
        .hidden: "隐藏",
        .groupsTab: "分组",
        .about: "关于",
        .generalSubtitle: "配置 Sesame 的基本行为与外观。",
        .hiddenSubtitle: "选择启动器中显示的应用。",
        .groupsSubtitle: "把应用归类到命名分组中。",
        .aboutSubtitle: "关于 Sesame",
        .startup: "启动",
        .launchAtLogin: "登录时启动 Sesame",
        .language: "语言",
        .hotkeySection: "快捷键",
        .hotkey: "打开 Hint 模式",
        .hotkeyHint: "在启动器中按下该组合键进入 Hint 模式。",
        .recording: "正在录制…",
        .pressKey: "按下一个快捷键",
        .clear: "重置",
        .appearance: "外观",
        .theme: "主题配色",
        .themeSunset: "日落",
        .themeAurora: "极光",
        .themePeach: "蜜桃",
        .themeOcean: "海洋",
        .themeMono: "极简",
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
        .appName: "Sesame",
        .tagline: "颗粒虽小，处处可入。",
        .version: "版本",
        .versionNumber: "1.0.0",
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
        .fontFootnote: "影响启动器与分组编辑器中的应用按钮。",
        .menuShowApp: "显示 Sesame",
        .menuShowApplications: "显示应用",
        .menuReload: "重新扫描应用",
        .menuSettings: "设置…",
        .menuQuit: "退出 Sesame",
        .menuTriggerCorner: "触发热区",
        .cornerOff: "关闭",
        .cornerTopLeft: "左上角",
        .cornerTopRight: "右上角",
        .cornerBottomLeft: "左下角",
        .cornerBottomRight: "右下角",
        .ctxHide: "从启动器隐藏",
        .ctxUninstall: "移到废纸篓…",
        .confirmHideTitle: "隐藏「%@」？",
        .confirmHideBody: "它将从启动器中移除。你可以随时在「设置 \u{25B8} 隐藏」中恢复。",
        .confirmUninstallTitle: "将「%@」移到废纸篓？",
        .confirmUninstallBody: "该应用将被移到废纸篓。在清空废纸篓之前，你都可以恢复它。",
        .actionHide: "隐藏",
        .actionMoveToTrash: "移到废纸篓",
        .actionCancel: "取消",
        .okButton: "好",
        .uninstallFailedTitle: "无法将「%@」移到废纸篓"
    ]
}
