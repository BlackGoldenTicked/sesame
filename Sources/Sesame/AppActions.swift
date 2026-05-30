import AppKit
import Foundation

/// Destructive / management actions performed on a launcher app, each gated
/// behind a confirmation dialog. Kept apart from the views so the confirmation
/// and filesystem logic stays small, testable, and reusable.
///
/// Confirmations are shown as a sheet attached to the launcher window. The
/// launcher runs at `.screenSaver` window level and covers the full screen, so
/// a free-standing `NSAlert` (modal panel) is rendered behind it and never
/// becomes visible. A sheet is always layered above its host window.
enum AppActions {
    /// Apps living under `/System/` are managed by macOS and protected by SIP;
    /// they can never be moved to the Trash, so uninstall is hidden for them.
    static func isRemovable(_ application: MacApplication) -> Bool {
        !application.url.path.hasPrefix("/System/")
    }

    /// Asks the user to confirm hiding the app, then calls `completion(true)`
    /// only if confirmed.
    static func confirmHide(
        _ application: MacApplication,
        language: AppLanguage,
        completion: @escaping (Bool) -> Void
    ) {
        confirm(
            title: String(format: L.confirmHideTitle.string(language), application.name),
            body: L.confirmHideBody.string(language),
            confirmTitle: L.actionHide.string(language),
            destructive: false,
            language: language,
            completion: completion
        )
    }

    /// Asks the user to confirm moving the app to the Trash, then calls
    /// `completion(true)` only if confirmed.
    static func confirmUninstall(
        _ application: MacApplication,
        language: AppLanguage,
        completion: @escaping (Bool) -> Void
    ) {
        confirm(
            title: String(format: L.confirmUninstallTitle.string(language), application.name),
            body: L.confirmUninstallBody.string(language),
            confirmTitle: L.actionMoveToTrash.string(language),
            destructive: true,
            language: language,
            completion: completion
        )
    }

    /// Moves the application bundle to the Trash. Throws on failure (for
    /// example, insufficient permissions) so the caller can surface the error.
    static func moveToTrash(_ application: MacApplication) throws {
        try FileManager.default.trashItem(at: application.url, resultingItemURL: nil)
    }

    /// Presents a non-fatal error explaining why an uninstall could not finish.
    static func presentError(_ error: Error, for application: MacApplication, language: AppLanguage) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = String(format: L.uninstallFailedTitle.string(language), application.name)
        alert.informativeText = error.localizedDescription
        alert.addButton(withTitle: L.okButton.string(language))
        present(alert, completion: nil)
    }

    private static func confirm(
        title: String,
        body: String,
        confirmTitle: String,
        destructive: Bool,
        language: AppLanguage,
        completion: @escaping (Bool) -> Void
    ) {
        let alert = NSAlert()
        alert.alertStyle = destructive ? .critical : .warning
        alert.messageText = title
        alert.informativeText = body
        let confirmButton = alert.addButton(withTitle: confirmTitle)
        alert.addButton(withTitle: L.actionCancel.string(language))
        if #available(macOS 11.0, *) {
            confirmButton.hasDestructiveAction = destructive
        }
        present(alert) { response in
            completion(response == .alertFirstButtonReturn)
        }
    }

    /// Shows the alert as a sheet on the launcher window when available, falling
    /// back to a standalone modal otherwise. `completion` always runs on the
    /// main thread.
    private static func present(_ alert: NSAlert, completion: ((NSApplication.ModalResponse) -> Void)?) {
        if let host = launcherWindow() {
            alert.beginSheetModal(for: host) { response in
                completion?(response)
            }
        } else {
            completion?(alert.runModal())
        }
    }

    private static func launcherWindow() -> NSWindow? {
        NSApp.windows.first { $0.isVisible && $0.level == .screenSaver }
    }
}
