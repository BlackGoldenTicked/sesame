import AppKit

final class AppIconCache {
    static let shared = AppIconCache()

    private var cache: [String: NSImage] = [:]

    private init() {}

    func icon(for url: URL) -> NSImage {
        let key = url.path
        if let cached = cache[key] {
            return cached
        }
        let image = NSWorkspace.shared.icon(forFile: key)
        image.size = NSSize(width: 64, height: 64)
        cache[key] = image
        return image
    }

    func retain(paths keep: Set<String>) {
        cache = cache.filter { keep.contains($0.key) }
    }
}
