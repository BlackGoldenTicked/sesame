import AppKit
import Combine
import Foundation

struct DisplayGroup: Identifiable {
    let id: String
    let title: String
    let applications: [MacApplication]
    let isLetterIndex: Bool
}

enum HintInputResult {
    case consumed
    case launched(MacApplication)
    case cancelled
}

final class LauncherModel: ObservableObject {
    @Published var applications: [MacApplication] = []
    @Published var searchText = ""
    @Published var focusRequest = 0

    @Published var hintMode: Bool = false
    @Published var hintBuffer: String = ""
    @Published private(set) var hintCodes: [String: String] = [:]

    @Published private(set) var visibleApplications: [MacApplication] = []
    @Published private(set) var filteredApplications: [MacApplication] = []
    @Published private(set) var displayGroups: [DisplayGroup] = []

    let settings: AppSettings

    private let scanQueue = DispatchQueue(label: "sesame.scan", qos: .userInitiated)
    private var watchSources: [DispatchSourceFileSystemObject] = []
    private var watchedFileDescriptors: [Int32] = []
    private var pendingReload: DispatchWorkItem?

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        bindDerivedState()
    }

    deinit {
        stopWatching()
    }

    private func bindDerivedState() {
        // visibleApplications = applications − hiddenAppPaths
        Publishers.CombineLatest($applications, settings.$hiddenAppPaths)
            .map { apps, hidden -> [MacApplication] in
                guard !hidden.isEmpty else { return apps }
                return apps.filter { !hidden.contains($0.url.path) }
            }
            .removeDuplicates()
            .assign(to: &$visibleApplications)

        // filteredApplications = visibleApplications filtered by searchText
        Publishers.CombineLatest($visibleApplications, $searchText)
            .map { apps, raw -> [MacApplication] in
                let query = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !query.isEmpty else { return apps }
                return apps.filter { $0.name.localizedCaseInsensitiveContains(query) }
            }
            .removeDuplicates()
            .assign(to: &$filteredApplications)

        // displayGroups recomputes only when its real inputs change.
        Publishers.CombineLatest3(
            $filteredApplications,
            settings.$sortMode.removeDuplicates(),
            settings.$customGroups.removeDuplicates()
        )
        .map { [weak self] apps, mode, customs -> [DisplayGroup] in
            guard let self else { return [] }
            switch mode {
            case .alphabetical:
                return self.alphabeticalGroups(from: apps)
            case .customGroups:
                return self.customGroupSections(from: apps, customGroups: customs)
            }
        }
        .assign(to: &$displayGroups)
    }

    private func alphabeticalGroups(from apps: [MacApplication]) -> [DisplayGroup] {
        let grouped = Dictionary(grouping: apps) { application in
            groupTitle(for: application.name)
        }

        return grouped
            .map { title, applications -> DisplayGroup in
                let sorted = applications.sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
                return DisplayGroup(
                    id: "letter-\(title)",
                    title: title,
                    applications: sorted,
                    isLetterIndex: true
                )
            }
            .sorted { left, right in
                if left.title == "#" { return false }
                if right.title == "#" { return true }
                return left.title.localizedStandardCompare(right.title) == .orderedAscending
            }
    }

    private func customGroupSections(from apps: [MacApplication], customGroups: [CustomGroup]) -> [DisplayGroup] {
        let appsByPath = Dictionary(uniqueKeysWithValues: apps.map { ($0.url.path, $0) })
        var assignedPaths: Set<String> = []
        var groups: [DisplayGroup] = []

        for group in customGroups {
            let members = group.appPaths.compactMap { appsByPath[$0] }
            if members.isEmpty { continue }
            assignedPaths.formUnion(members.map { $0.url.path })
            groups.append(
                DisplayGroup(
                    id: "custom-\(group.id.uuidString)",
                    title: group.name,
                    applications: members,
                    isLetterIndex: false
                )
            )
        }

        let unassigned = apps.filter { !assignedPaths.contains($0.url.path) }
        if !unassigned.isEmpty {
            let sorted = unassigned.sorted {
                $0.name.localizedStandardCompare($1.name) == .orderedAscending
            }
            groups.append(
                DisplayGroup(
                    id: "custom-unassigned",
                    title: "Ungrouped",
                    applications: sorted,
                    isLetterIndex: false
                )
            )
        }

        return groups
    }

    func reload() {
        applications = ApplicationScanner.scan()
    }

    func reloadAsync() {
        scanQueue.async { [weak self] in
            let scanned = ApplicationScanner.scan()
            DispatchQueue.main.async {
                guard let self = self else { return }
                if scanned != self.applications {
                    AppIconCache.shared.retain(paths: Set(scanned.map { $0.url.path }))
                    self.applications = scanned
                }
            }
        }
    }

    func startWatching() {
        stopWatching()

        let roots = ApplicationScanner.applicationRoots()
        for url in roots {
            let fd = Darwin.open(url.path, O_EVTONLY)
            guard fd >= 0 else { continue }
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .delete, .rename, .extend, .link],
                queue: scanQueue
            )
            source.setEventHandler { [weak self] in
                self?.scheduleDebouncedReload()
            }
            source.setCancelHandler {
                Darwin.close(fd)
            }
            source.resume()
            watchSources.append(source)
            watchedFileDescriptors.append(fd)
        }
    }

    func stopWatching() {
        pendingReload?.cancel()
        pendingReload = nil
        for source in watchSources {
            source.cancel()
        }
        watchSources.removeAll()
        watchedFileDescriptors.removeAll()
    }

    private func scheduleDebouncedReload() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.pendingReload?.cancel()
            let work = DispatchWorkItem { [weak self] in
                self?.reloadAsync()
            }
            self.pendingReload = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: work)
        }
    }

    func requestSearchFocus() {
        focusRequest += 1
    }

    // MARK: - Hint Mode

    func enterHintMode() {
        regenerateHints()
        hintBuffer = ""
        hintMode = true
    }

    func exitHintMode() {
        hintMode = false
        hintBuffer = ""
    }

    func handleHintInput(_ character: Character) -> HintInputResult {
        let key = String(character).lowercased()
        let next = hintBuffer + key

        let matches = hintCodes.filter { $0.value.hasPrefix(next) }
        if matches.isEmpty {
            exitHintMode()
            return .cancelled
        }

        if matches.count == 1, let pair = matches.first, pair.value == next {
            let path = pair.key
            if let app = visibleApplications.first(where: { $0.url.path == path }) {
                exitHintMode()
                return .launched(app)
            }
            exitHintMode()
            return .cancelled
        }

        hintBuffer = next
        return .consumed
    }

    private func regenerateHints() {
        let orderedPaths: [String] = displayGroups.flatMap { group in
            group.applications.map { $0.url.path }
        }
        hintCodes = HintCoordinator.generateCodes(for: orderedPaths)
    }

    // MARK: - App Management

    /// Hides the app from the launcher after the user confirms. The hidden set
    /// drives `visibleApplications`, so the grid updates automatically; the app
    /// can be restored from Settings ▸ Hidden.
    func hide(_ application: MacApplication) {
        AppActions.confirmHide(application, language: settings.language) { [weak self] confirmed in
            guard confirmed, let self else { return }
            self.settings.setHidden(true, for: application)
        }
    }

    /// Moves the app bundle to the Trash after the user confirms. System apps
    /// are not removable and are guarded against here as well as in the UI.
    func uninstall(_ application: MacApplication) {
        guard AppActions.isRemovable(application) else { return }
        AppActions.confirmUninstall(application, language: settings.language) { [weak self] confirmed in
            guard confirmed, let self else { return }
            do {
                try AppActions.moveToTrash(application)
                self.reloadAsync()
            } catch {
                AppActions.presentError(error, for: application, language: self.settings.language)
            }
        }
    }

    func open(_ application: MacApplication, completion: @escaping () -> Void = {}) {
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: application.url, configuration: configuration) { _, _ in
            DispatchQueue.main.async(execute: completion)
        }
    }

    private func groupTitle(for name: String) -> String {
        guard let firstScalar = name.unicodeScalars.first else {
            return "#"
        }

        let character = Character(firstScalar)
        let title = String(character).uppercased()
        let letters = CharacterSet.letters
        return letters.contains(firstScalar) ? title : "#"
    }
}
