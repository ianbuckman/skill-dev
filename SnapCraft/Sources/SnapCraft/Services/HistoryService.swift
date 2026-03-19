import Foundation
import AppKit

@MainActor
final class HistoryService {
    private let historyFileURL: URL
    private let thumbnailDirectory: URL
    private let maxAge: TimeInterval = 30 * 24 * 60 * 60 // 1 month

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("SnapCraft")
        historyFileURL = appDir.appendingPathComponent("history.json")
        thumbnailDirectory = appDir.appendingPathComponent("thumbnails")

        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(at: thumbnailDirectory, withIntermediateDirectories: true)
    }

    func loadHistory() -> [CaptureHistoryItem] {
        guard let data = try? Data(contentsOf: historyFileURL),
              var items = try? JSONDecoder().decode([CaptureHistoryItem].self, from: data) else {
            return []
        }

        // Remove expired items
        let cutoff = Date().addingTimeInterval(-maxAge)
        items = items.filter { $0.timestamp > cutoff }
        saveHistory(items)

        return items
    }

    func addItem(_ item: CaptureHistoryItem) {
        var items = loadHistory()
        items.insert(item, at: 0)
        saveHistory(items)
    }

    func removeItem(id: UUID) {
        var items = loadHistory()
        if let index = items.firstIndex(where: { $0.id == id }) {
            let item = items[index]
            // Remove thumbnail
            if let thumbnailPath = item.thumbnailPath {
                try? FileManager.default.removeItem(atPath: thumbnailPath)
            }
            items.remove(at: index)
            saveHistory(items)
        }
    }

    func clearHistory() {
        saveHistory([])
        try? FileManager.default.removeItem(at: thumbnailDirectory)
        try? FileManager.default.createDirectory(at: thumbnailDirectory, withIntermediateDirectories: true)
    }

    func generateThumbnail(for image: NSImage, itemID: UUID) -> String? {
        let thumbnailSize = CGSize(width: 200, height: 200)
        let thumbnail = NSImage(size: thumbnailSize)
        thumbnail.lockFocus()
        image.draw(
            in: CGRect(origin: .zero, size: thumbnailSize),
            from: CGRect(origin: .zero, size: image.size),
            operation: .copy,
            fraction: 1.0
        )
        thumbnail.unlockFocus()

        let path = thumbnailDirectory.appendingPathComponent("\(itemID.uuidString).png")
        guard let tiffData = thumbnail.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiffData),
              let pngData = rep.representation(using: .png, properties: [:]) else {
            return nil
        }

        try? pngData.write(to: path)
        return path.path
    }

    func filterHistory(by type: CaptureType?) -> [CaptureHistoryItem] {
        let items = loadHistory()
        guard let type = type else { return items }
        return items.filter { $0.type == type }
    }

    private func saveHistory(_ items: [CaptureHistoryItem]) {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: historyFileURL)
    }
}
