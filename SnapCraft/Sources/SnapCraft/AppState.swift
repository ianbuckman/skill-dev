import SwiftUI
import ScreenCaptureKit

@Observable
@MainActor
final class AppState {
    // MARK: - Capture State
    var currentCaptureMode: CaptureMode = .area
    var isCapturing = false
    var lastCapturedImage: NSImage?
    var lastCapturedFilePath: String?

    // MARK: - Recording State
    var isRecording = false
    var recordingDuration: TimeInterval = 0
    var recordingConfig = RecordingConfig()

    // MARK: - Overlay State
    var showQuickAccess = false
    var pinnedWindows: [PinnedImage] = []

    // MARK: - Settings (persisted via @AppStorage in SettingsView)
    var saveDirectory: String = NSHomeDirectory() + "/Desktop"
    var imageFormat: ImageFormat = .png
    var showCrosshair = true
    var showMagnifier = true

    // MARK: - History
    var captureHistory: [CaptureHistoryItem] = []
}

struct PinnedImage: Identifiable {
    let id = UUID()
    let image: NSImage
    var position: CGPoint
    var size: CGSize
    var opacity: Double = 1.0
    var isLocked = false
}

enum ImageFormat: String, CaseIterable {
    case png = "PNG"
    case jpg = "JPG"
}
