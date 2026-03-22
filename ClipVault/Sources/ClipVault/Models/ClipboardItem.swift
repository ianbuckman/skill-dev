import Foundation

struct ClipboardItem: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    var isPinned: Bool
    let content: ClipboardContent

    init(id: UUID = UUID(), content: ClipboardContent, isPinned: Bool = false, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isPinned = isPinned
        self.timestamp = timestamp
    }
}

enum ClipboardContent: Codable {
    case text(String)
    case image(Data)
}
