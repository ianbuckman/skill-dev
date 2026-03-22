import AppKit
import Foundation

@MainActor
final class ClipboardMonitor {
    private let appState: AppState
    private var lastChangeCount: Int

    init(appState: AppState) {
        self.appState = appState
        self.lastChangeCount = NSPasteboard.general.changeCount
    }

    private var pollTask: Task<Void, Never>?

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(500))
                self?.checkClipboard()
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        let currentChangeCount = pasteboard.changeCount

        guard currentChangeCount != lastChangeCount else { return }
        lastChangeCount = currentChangeCount

        // If the app itself just wrote to the pasteboard, skip this change.
        if appState.skipNextChange {
            appState.skipNextChange = false
            return
        }

        // Try text first.
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            // Avoid duplicate: skip if the most recent item has the same text.
            if case .text(let lastText) = appState.items.first?.content, lastText == text {
                return
            }
            let item = ClipboardItem(content: .text(text))
            appState.add(item)
            return
        }

        // Try image (only if recording images is enabled).
        guard appState.recordImages else { return }

        if let imageData = pasteboard.data(forType: .png) ?? pasteboard.data(forType: .tiff),
           !imageData.isEmpty {
            // Avoid duplicate: skip if the most recent item has identical image data.
            if case .image(let lastData) = appState.items.first?.content, lastData == imageData {
                return
            }
            let item = ClipboardItem(content: .image(imageData))
            appState.add(item)
        }
    }
}
