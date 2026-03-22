import Foundation

actor StorageService {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private var debounceTask: Task<Void, Never>?

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = appSupport.appendingPathComponent("ClipVault", isDirectory: true)
        self.fileURL = directory.appendingPathComponent("history.json")

        let enc = JSONEncoder()
        enc.outputFormatting = .prettyPrinted
        enc.dateEncodingStrategy = .iso8601
        self.encoder = enc

        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    func save(_ items: [ClipboardItem]) {
        debounceTask?.cancel()
        let currentItems = items
        debounceTask = Task {
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            writeToFile(currentItems)
        }
    }

    func load() -> [ClipboardItem] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: fileURL.path) else {
            return []
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let items = try decoder.decode([ClipboardItem].self, from: data)
            return items
        } catch {
            return []
        }
    }

    private func writeToFile(_ items: [ClipboardItem]) {
        do {
            let directory = fileURL.deletingLastPathComponent()
            let fm = FileManager.default
            if !fm.fileExists(atPath: directory.path) {
                try fm.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            let data = try encoder.encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Write failure is non-fatal; silently ignored.
        }
    }
}
