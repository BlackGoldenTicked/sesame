import AppKit
import Foundation

struct MacApplication: Identifiable, Hashable {
    let id: URL
    let name: String
    let url: URL
}

struct ApplicationGroup: Identifiable {
    let id: String
    let title: String
    let applications: [MacApplication]
}

enum ApplicationScanner {
    static func applicationRoots() -> [URL] {
        let fileManager = FileManager.default
        let homeApplications = fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        return [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: "/System/Applications", isDirectory: true),
            homeApplications
        ].filter { fileManager.fileExists(atPath: $0.path) }
    }

    static func scan() -> [MacApplication] {
        let fileManager = FileManager.default
        let roots = applicationRoots()

        var seen = Set<URL>()
        var applications: [MacApplication] = []

        for root in roots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isApplicationKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator where url.pathExtension.lowercased() == "app" {
                let standardizedURL = url.standardizedFileURL
                guard seen.insert(standardizedURL).inserted else {
                    continue
                }

                applications.append(
                    MacApplication(
                        id: standardizedURL,
                        name: displayName(for: standardizedURL),
                        url: standardizedURL
                    )
                )
            }
        }

        return applications.sorted { left, right in
            let comparison = left.name.localizedStandardCompare(right.name)
            if comparison == .orderedSame {
                return left.url.path.localizedStandardCompare(right.url.path) == .orderedAscending
            }
            return comparison == .orderedAscending
        }
    }

    private static func displayName(for url: URL) -> String {
        if let bundle = Bundle(url: url) {
            let dictionaries = [bundle.localizedInfoDictionary, bundle.infoDictionary]
            for dictionary in dictionaries {
                if let displayName = dictionary?["CFBundleDisplayName"] as? String, !displayName.isEmpty {
                    return displayName
                }
                if let name = dictionary?["CFBundleName"] as? String, !name.isEmpty {
                    return name
                }
            }
        }

        return FileManager.default.displayName(atPath: url.path).replacingOccurrences(of: ".app", with: "")
    }
}
