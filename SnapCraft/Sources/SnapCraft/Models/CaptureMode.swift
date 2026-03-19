import Foundation

enum CaptureMode: String, CaseIterable, Identifiable {
    case area = "Area"
    case window = "Window"
    case fullscreen = "Fullscreen"
    case scrolling = "Scrolling"
    case timed = "Timed"
    case freeze = "Freeze"
    case allInOne = "All-In-One"
    case ocr = "OCR"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .area: return "Area Capture"
        case .window: return "Window Capture"
        case .fullscreen: return "Fullscreen Capture"
        case .scrolling: return "Scrolling Capture"
        case .timed: return "Timed Capture"
        case .freeze: return "Freeze Screen"
        case .allInOne: return "All-In-One"
        case .ocr: return "OCR Text"
        }
    }

    var shortcutHint: String {
        switch self {
        case .area: return "⌘⇧4"
        case .window: return "⌘⇧5"
        case .fullscreen: return "⌘⇧3"
        case .scrolling: return "⌘⇧6"
        case .timed: return "⌘⇧T"
        case .freeze: return "⌘⇧F"
        case .allInOne: return "⌘⇧0"
        case .ocr: return "⌘⇧9"
        }
    }

    var systemImage: String {
        switch self {
        case .area: return "rectangle.dashed"
        case .window: return "macwindow"
        case .fullscreen: return "rectangle.inset.filled"
        case .scrolling: return "arrow.up.and.down.text.horizontal"
        case .timed: return "timer"
        case .freeze: return "snowflake"
        case .allInOne: return "square.grid.2x2"
        case .ocr: return "text.viewfinder"
        }
    }
}

enum RecordingMode: String, CaseIterable, Identifiable {
    case video = "Video"
    case gif = "GIF"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .video: return "Screen Recording"
        case .gif: return "GIF Recording"
        }
    }

    var shortcutHint: String {
        switch self {
        case .video: return "⌘⇧7"
        case .gif: return "⌘⇧8"
        }
    }

    var systemImage: String {
        switch self {
        case .video: return "record.circle"
        case .gif: return "film"
        }
    }
}
