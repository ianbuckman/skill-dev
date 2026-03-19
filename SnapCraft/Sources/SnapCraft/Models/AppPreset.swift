import Foundation

struct AppPreset: Identifiable, Codable {
    let id: UUID
    var name: String
    var captureMode: CaptureMode
    var imageFormat: ImageFormat
    var saveDirectory: String
    var recordingConfig: RecordingConfig

    init(
        name: String,
        captureMode: CaptureMode = .area,
        imageFormat: ImageFormat = .png,
        saveDirectory: String = NSHomeDirectory() + "/Desktop",
        recordingConfig: RecordingConfig = RecordingConfig()
    ) {
        self.id = UUID()
        self.name = name
        self.captureMode = captureMode
        self.imageFormat = imageFormat
        self.saveDirectory = saveDirectory
        self.recordingConfig = recordingConfig
    }
}

// Make enums used in AppPreset Codable-conforming where needed
extension CaptureMode: Codable {}
extension ImageFormat: Codable {}
extension RecordingMode: Codable {}
