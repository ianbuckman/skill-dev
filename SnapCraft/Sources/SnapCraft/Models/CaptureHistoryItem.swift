import Foundation

struct CaptureHistoryItem: Identifiable, Codable {
    let id: UUID
    let type: CaptureType
    let filePath: String
    let thumbnailPath: String?
    let timestamp: Date
    let fileSize: Int64

    init(type: CaptureType, filePath: String, thumbnailPath: String? = nil, fileSize: Int64 = 0) {
        self.id = UUID()
        self.type = type
        self.filePath = filePath
        self.thumbnailPath = thumbnailPath
        self.timestamp = Date()
        self.fileSize = fileSize
    }
}

enum CaptureType: String, CaseIterable, Codable, Identifiable {
    case screenshot = "Screenshot"
    case recording = "Recording"
    case gif = "GIF"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .screenshot: return "camera.fill"
        case .recording: return "video.fill"
        case .gif: return "film"
        }
    }
}
