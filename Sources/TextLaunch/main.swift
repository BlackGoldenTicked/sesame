import AppKit
import SwiftUI

enum HotCorner: String, CaseIterable {
    case topLeft
    case topRight
    case bottomLeft
    case bottomRight
    case off

    static let defaultsKey = "HotCorner"

    var title: String {
        switch self {
        case .off:
            return "Off"
        case .topLeft:
            return "Top Left"
        case .topRight:
            return "Top Right"
        case .bottomLeft:
            return "Bottom Left"
        case .bottomRight:
            return "Bottom Right"
        }
    }

    static var saved: HotCorner {
        guard
            let rawValue = UserDefaults.standard.string(forKey: defaultsKey),
            let corner = HotCorner(rawValue: rawValue)
        else {
            return .topLeft
        }

        return corner
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: HotCorner.defaultsKey)
    }
}

final class LauncherWindow: NSWindow {
    var onEscape: (() -> Void)?
    var keyInterceptor: ((NSEvent) -> Bool)?

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        true
    }

    override func sendEvent(_ event: NSEvent) {
        if event.type == .keyDown, keyInterceptor?(event) == true {
            return
        }
        super.sendEvent(event)
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            onEscape?()
            return
        }

        super.keyDown(with: event)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = AppSettings()
    private lazy var model = LauncherModel(settings: settings)
    private var window: LauncherWindow?
    private var settingsWindow: NSWindow?
    private var groupEditorWindow: NSWindow?
    private var statusItem: NSStatusItem?
    private var hotCorner = HotCorner.saved
    private var hotCornerMenuItems: [NSMenuItem] = []
    private var hotCornerTimer: Timer?
    private var hotCornerEnteredAt: Date?
    private var hotCornerIsArmed = true
    private var launcherSuspended = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        applyAppIcon()
        configureMenu()
        configureStatusItem()
        model.reload()
        model.startWatching()
        showLauncher()
        installHotCornerMonitor()
    }

    private func applyAppIcon() {
        guard
            let url = Bundle.module.url(forResource: "logo", withExtension: "png"),
            let image = NSImage(contentsOf: url)
        else {
            return
        }
        NSApp.applicationIconImage = image
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showLauncher()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotCornerTimer?.invalidate()
    }

    @objc private func showLauncherFromMenu() {
        showLauncher()
    }

    @objc private func reloadApplications() {
        model.reload()
    }

    @objc private func openSettingsFromMenu() {
        openSettings()
    }

    @objc private func setHotCorner(_ sender: NSMenuItem) {
        guard
            let rawValue = sender.representedObject as? String,
            let corner = HotCorner(rawValue: rawValue)
        else {
            return
        }

        hotCorner = corner
        hotCorner.save()
        resetHotCornerState()
        updateHotCornerMenuItems()
    }

    private func showLauncher() {
        let isNewWindow = window == nil
        let launcherWindow = window ?? makeWindow()
        window = launcherWindow

        launcherWindow.setFrame(NSScreen.main?.frame ?? launcherWindow.frame, display: true)
        launcherWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        model.reloadAsync()
        if !isNewWindow {
            DispatchQueue.main.async { [model] in
                model.requestSearchFocus()
            }
        }
    }

    private func hideLauncher() {
        window?.orderOut(nil)
        resetHotCornerState()
    }

    private func suspendLauncher() {
        guard let window = window, window.isVisible else { return }
        launcherSuspended = true
        window.orderOut(nil)
    }

    private func resumeLauncherIfNeeded() {
        guard launcherSuspended else { return }
        launcherSuspended = false
        if settingsWindow == nil, groupEditorWindow == nil {
            showLauncher()
        }
    }

    private func makeWindow() -> LauncherWindow {
        let screenFrame = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let window = LauncherWindow(
            contentRect: screenFrame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        window.title = "TextLaunch"
        window.level = .screenSaver
        window.animationBehavior = .none
        window.isReleasedWhenClosed = false
        window.isOpaque = true
        window.backgroundColor = NSColor(red: 0.07, green: 0.07, blue: 0.085, alpha: 1)
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        window.onEscape = { [weak self] in
            self?.hideLauncher()
        }

        let root = LauncherView(
            model: model,
            close: { [weak self] in
                self?.hideLauncher()
            },
            openSettings: { [weak self] in
                self?.openSettings()
            },
            openCustomGroupEditor: { [weak self] group in
                self?.openCustomGroupEditor(editing: group)
            }
        )

        window.contentView = NSHostingView(rootView: root)
        window.keyInterceptor = { [weak self] event in
            self?.handleLauncherKey(event) ?? false
        }

        return window
    }

    private func handleLauncherKey(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags
        let chars = event.charactersIgnoringModifiers ?? ""
        let lower = chars.lowercased()
        let plain = !flags.contains(.command)
            && !flags.contains(.option)
            && !flags.contains(.control)

        // Ctrl+A → select all in the focused text field
        if flags.contains(.control), lower == "a", !model.hintMode {
            NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
            return true
        }

        if model.hintMode {
            // Esc exits hint mode
            if event.keyCode == 53 {
                model.exitHintMode()
                return true
            }
            // Plain letter input goes to hint matcher
            if plain, let scalar = lower.unicodeScalars.first,
               CharacterSet.lowercaseLetters.contains(scalar) {
                let result = model.handleHintInput(Character(scalar))
                if case let .launched(app) = result {
                    hideLauncher()
                    model.open(app)
                }
                return true
            }
            // Swallow other unmodified keystrokes so they don't leak to the field
            return plain
        }

        // Enter hint mode via configured hotkey
        if settings.hintHotkey.matches(event) {
            model.enterHintMode()
            return true
        }

        return false
    }

    private func openSettings() {
        if let existing = settingsWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        suspendLauncher()

        let view = SettingsView(
            settings: settings,
            model: model,
            onClose: { [weak self] in
                self?.closeSettings()
            },
            onEditGroup: { [weak self] group in
                self?.openCustomGroupEditor(editing: group)
            }
        )

        let host = NSHostingController(rootView: view)
        if #available(macOS 13.0, *) {
            host.sizingOptions = [.preferredContentSize]
        }
        let window = NSWindow(contentViewController: host)
        window.title = settings.t(.settings)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = SettingsWindowDelegate.shared
        SettingsWindowDelegate.shared.onClose = { [weak self] in
            self?.settingsWindow = nil
            self?.resumeLauncherIfNeeded()
        }

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closeSettings() {
        settingsWindow?.close()
        settingsWindow = nil
    }

    private func openCustomGroupEditor(editing group: CustomGroup?) {
        if let existing = groupEditorWindow {
            existing.close()
            groupEditorWindow = nil
        }

        suspendLauncher()

        let view = CustomGroupEditorView(
            settings: settings,
            model: model,
            initialGroup: group,
            onSave: { [weak self] updated in
                self?.settings.upsertGroup(updated)
                self?.settings.sortMode = .customGroups
                self?.closeGroupEditor()
            },
            onCancel: { [weak self] in
                self?.closeGroupEditor()
            }
        )

        let host = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: host)
        window.title = group == nil ? "New Custom Group" : "Edit Custom Group"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 960, height: 680))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = GroupEditorWindowDelegate.shared
        GroupEditorWindowDelegate.shared.onClose = { [weak self] in
            self?.groupEditorWindow = nil
            self?.resumeLauncherIfNeeded()
        }

        groupEditorWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func closeGroupEditor() {
        groupEditorWindow?.close()
        groupEditorWindow = nil
    }

    private func installHotCornerMonitor() {
        let timer = Timer(timeInterval: 0.12, repeats: true) { [weak self] _ in
            self?.pollHotCorner()
        }

        RunLoop.main.add(timer, forMode: .common)
        hotCornerTimer = timer
    }

    private func pollHotCorner() {
        guard hotCorner != .off, window?.isVisible != true else {
            resetHotCornerState()
            return
        }

        if mouseIsInHotCorner(NSEvent.mouseLocation) {
            if hotCornerEnteredAt == nil {
                hotCornerEnteredAt = Date()
            }

            if hotCornerIsArmed, let enteredAt = hotCornerEnteredAt, Date().timeIntervalSince(enteredAt) >= 0.24 {
                hotCornerIsArmed = false
                showLauncher()
            }
        } else {
            resetHotCornerState()
        }
    }

    private func mouseIsInHotCorner(_ point: NSPoint) -> Bool {
        let triggerSize: CGFloat = 18

        return NSScreen.screens.contains { screen in
            let frame = screen.frame

            switch hotCorner {
            case .off:
                return false
            case .topLeft:
                return point.x >= frame.minX &&
                    point.x <= frame.minX + triggerSize &&
                    point.y <= frame.maxY &&
                    point.y >= frame.maxY - triggerSize
            case .topRight:
                return point.x <= frame.maxX &&
                    point.x >= frame.maxX - triggerSize &&
                    point.y <= frame.maxY &&
                    point.y >= frame.maxY - triggerSize
            case .bottomLeft:
                return point.x >= frame.minX &&
                    point.x <= frame.minX + triggerSize &&
                    point.y >= frame.minY &&
                    point.y <= frame.minY + triggerSize
            case .bottomRight:
                return point.x <= frame.maxX &&
                    point.x >= frame.maxX - triggerSize &&
                    point.y >= frame.minY &&
                    point.y <= frame.minY + triggerSize
            }
        }
    }

    private func resetHotCornerState() {
        hotCornerEnteredAt = nil
        hotCornerIsArmed = true
    }

    private func configureMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "TextLaunch")

        let showItem = NSMenuItem(
            title: "Show TextLaunch",
            action: #selector(showLauncherFromMenu),
            keyEquivalent: "l"
        )
        showItem.target = self
        appMenu.addItem(showItem)

        let reloadItem = NSMenuItem(
            title: "Reload Applications",
            action: #selector(reloadApplications),
            keyEquivalent: "r"
        )
        reloadItem.target = self
        appMenu.addItem(reloadItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ","
        )
        settingsItem.target = self
        appMenu.addItem(settingsItem)

        appMenu.addItem(makeHotCornerMenuItem())
        appMenu.addItem(.separator())
        appMenu.addItem(
            NSMenuItem(
                title: "Quit TextLaunch",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q"
            )
        )

        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        NSApp.mainMenu = mainMenu
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            if
                let iconURL = Bundle.module.url(forResource: "menubar", withExtension: "png"),
                let image = NSImage(contentsOf: iconURL)
            {
                let target = NSSize(width: 18, height: 18)
                let scaled = NSImage(size: target)
                scaled.lockFocus()
                NSGraphicsContext.current?.imageInterpolation = .high
                image.draw(in: NSRect(origin: .zero, size: target))
                scaled.unlockFocus()
                scaled.isTemplate = true
                button.image = scaled
            } else {
                button.title = "TextLaunch"
            }
            button.target = self
            button.action = #selector(showLauncherFromMenu)
        }

        let menu = NSMenu(title: "TextLaunch")
        let showItem = NSMenuItem(
            title: "Show Applications",
            action: #selector(showLauncherFromMenu),
            keyEquivalent: ""
        )
        showItem.target = self
        menu.addItem(showItem)

        let reloadItem = NSMenuItem(
            title: "Reload Applications",
            action: #selector(reloadApplications),
            keyEquivalent: ""
        )
        reloadItem.target = self
        menu.addItem(reloadItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettingsFromMenu),
            keyEquivalent: ""
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(makeHotCornerMenuItem())
        menu.addItem(.separator())
        menu.addItem(
            NSMenuItem(
                title: "Quit TextLaunch",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: ""
            )
        )

        item.menu = menu
        statusItem = item
    }

    private func makeHotCornerMenuItem() -> NSMenuItem {
        let parentItem = NSMenuItem(title: "Trigger Corner", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Trigger Corner")

        for corner in HotCorner.allCases {
            if corner == .off {
                submenu.addItem(.separator())
            }

            let item = NSMenuItem(
                title: corner.title,
                action: #selector(setHotCorner(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = corner.rawValue
            submenu.addItem(item)
            hotCornerMenuItems.append(item)
        }

        parentItem.submenu = submenu
        updateHotCornerMenuItems()
        return parentItem
    }

    private func updateHotCornerMenuItems() {
        for item in hotCornerMenuItems {
            item.state = (item.representedObject as? String) == hotCorner.rawValue ? .on : .off
        }
    }
}

final class SettingsWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = SettingsWindowDelegate()
    var onClose: (() -> Void)?

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}

final class GroupEditorWindowDelegate: NSObject, NSWindowDelegate {
    static let shared = GroupEditorWindowDelegate()
    var onClose: (() -> Void)?

    func windowWillClose(_ notification: Notification) {
        onClose?()
    }
}

let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.run()
