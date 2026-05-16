import Foundation

enum HintCoordinator {
    private static let letters: [Character] = Array("asdfghjklqwertyuiopzxcvbnm")

    static func generateCodes(for paths: [String]) -> [String: String] {
        guard !paths.isEmpty else { return [:] }
        var codes: [String: String] = [:]
        let count = paths.count

        if count <= letters.count {
            for (index, path) in paths.enumerated() {
                codes[path] = String(letters[index])
            }
            return codes
        }

        var index = 0
        outer: for first in letters {
            for second in letters {
                if index >= count { break outer }
                codes[paths[index]] = "\(first)\(second)"
                index += 1
            }
        }
        return codes
    }
}
