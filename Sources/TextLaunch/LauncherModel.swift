import AppKit
import Combine
import Foundation

struct DisplayGroup: Identifiable {
    let id: String
    let title: String
    let applications: [MacApplication]
    let isLetterIndex: Bool
}

final class LauncherModel: ObservableObject {
    @Published var applications: [MacApplication] = []
    @Published var searchText = ""
    @Published var focusRequest = 0

    let settings: AppSettings

    private var cancellables: Set<AnyCancellable> = []
    private let scanQueue = DispatchQueue(label: "textlaunch.scan", qos: .userInitiated)
    private var watchSources: [DispatchSourceFileSystemObject] = []
    private var watchedFileDescriptors: [Int32] = []
    private var pendingReload: DispatchWorkItem?

    init(settings: AppSettings = AppSettings()) {
        self.settings = settings
        settings.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }

    deinit {
        stopWatching()
    }

    var visibleApplications: [MacApplication] {
        applications.filter { !settings.hiddenAppPaths.contains($0.url.path) }
    }

    var filteredApplications: [MacApplication] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = visibleApplications
        guard !query.isEmpty else {
            return base
        }

        return base.filter { application in
            application.name.localizedCaseInsensitiveContains(query)
        }
    }

    var displayGroups: [DisplayGroup] {
        switch settings.sortMode {
        case .alphabetical:
            return alphabeticalGroups(from: filteredApplications)
        case .customGroups:
            return customGroupSections(from: filteredApplications)
        }
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

    private func customGroupSections(from apps: [MacApplication]) -> [DisplayGroup] {
        let appsByPath = Dictionary(uniqueKeysWithValues: apps.map { ($0.url.path, $0) })
        var assignedPaths: Set<String> = []
        var groups: [DisplayGroup] = []

        for group in settings.customGroups {
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
