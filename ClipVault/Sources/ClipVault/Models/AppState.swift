import AppKit
import Foundation

@MainActor
@Observable
final class AppState {
    var items: [ClipboardItem] = []
    var searchText: String = ""
    var maxHistoryCount: Int = 500
    var recordImages: Bool = true
    var skipNextChange: Bool = false

    private let storageService = StorageService()

    var filteredItems: [ClipboardItem] {
        let pinned: [ClipboardItem]
        let unpinned: [ClipboardItem]

        if searchText.isEmpty {
            pinned = items.filter { $0.isPinned }
            unpinned = items.filter { !$0.isPinned }
        } else {
            let query = searchText.lowercased()
            pinned = items.filter { item in
                item.isPinned && matchesSearch(item, query: query)
            }
            unpinned = items.filter { item in
                !item.isPinned && matchesSearch(item, query: query)
            }
        }
        return pinned + unpinned
    }

    private func matchesSearch(_ item: ClipboardItem, query: String) -> Bool {
        guard let text = item.textContent else { return false }
        return text.localizedCaseInsensitiveContains(query)
    }

    // MARK: - Persistence

    func loadHistory() async {
        let loaded = await storageService.load()
        items = loaded
    }

    private func persistItems() {
        let snapshot = items
        Task {
            await storageService.save(snapshot)
        }
    }

    // MARK: - Mutations

    func add(_ item: ClipboardItem) {
        items.insert(item, at: 0)

        // Enforce maxHistoryCount by removing oldest non-pinned items
        while items.count > maxHistoryCount {
            if let lastNonPinnedIndex = items.lastIndex(where: { !$0.isPinned }) {
                items.remove(at: lastNonPinnedIndex)
            } else {
                // All items are pinned — stop removing
                break
            }
        }

        persistItems()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        persistItems()
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        persistItems()
    }

    func clearAll() {
        items.removeAll { !$0.isPinned }
        persistItems()
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.content {
        case .text(let string):
            pasteboard.setString(string, forType: .string)
        case .image(let data):
            pasteboard.setData(data, forType: .png)
        }

        skipNextChange = true
    }
}
