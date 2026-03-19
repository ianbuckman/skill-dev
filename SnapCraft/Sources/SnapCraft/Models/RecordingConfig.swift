import Foundation

struct RecordingConfig: Codable {
    var mode: RecordingMode = .video
    var fps: Int = 30
    var quality: VideoQuality = .high
    var resolution: Resolution = .native
    var captureSystemAudio = true
    var captureMicrophone = false
    var showMouseClicks = false
    var showKeystrokes = false
    var showCamera = false
    var hideDesktopIcons = false
    var enableDND = true
    var showCursor = true

    // Mouse click highlight
    var clickColor: CodableColor = CodableColor(nsColor: .systemYellow)
    var clickSize: CGFloat = 30
    var clickStyle: ClickStyle = .filled
    var clickAnimation = true

    // Keystroke display
    var keystrokePosition: KeystrokePosition = .bottomCenter
    var keystrokeSize: KeystrokeSize = .medium
    var keystrokeTheme: KeystrokeTheme = .dark
    var showAllKeys = true

    // Camera
    var cameraShape: CameraShape = .circle
    var cameraPosition: CameraPosition = .bottomRight
    var cameraSize: CGFloat = 150
}

enum VideoQuality: String, CaseIterable, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum Resolution: String, CaseIterable, Codable {
    case native = "Native"
    case hd720 = "720p"
    case hd1080 = "1080p"
}

enum ClickStyle: String, CaseIterable, Codable {
    case filled = "Filled"
    case outline = "Outline"
}

enum KeystrokePosition: String, CaseIterable, Codable {
    case topCenter = "Top Center"
    case bottomCenter = "Bottom Center"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
}

enum KeystrokeSize: String, CaseIterable, Codable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
}

enum KeystrokeTheme: String, CaseIterable, Codable {
    case light = "Light"
    case dark = "Dark"
}

enum CameraShape: String, CaseIterable, Codable {
    case circle = "Circle"
    case rectangle = "Rectangle"
    case roundedRect = "Rounded Rectangle"
}

enum CameraPosition: String, CaseIterable, Codable {
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
}
