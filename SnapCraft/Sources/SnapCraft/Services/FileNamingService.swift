import Foundation

@MainActor
final class FileNamingService {
    var pattern: String = "SnapCraft_{date}_{time}"
    var dateFormat: String = "yyyy-MM-dd"
    var timeFormat: String = "HH-mm-ss"

    func generateFilename(type: CaptureType, format: String) -> String {
        let now = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        let dateStr = dateFormatter.string(from: now)

        dateFormatter.dateFormat = timeFormat
        let timeStr = dateFormatter.string(from: now)

        let name = pattern
            .replacingOccurrences(of: "{date}", with: dateStr)
            .replacingOccurrences(of: "{time}", with: timeStr)
            .replacingOccurrences(of: "{type}", with: type.rawValue.lowercased())
            .replacingOccurrences(of: "{n}", with: "\(sequenceNumber())")

        return "\(name).\(format)"
    }

    func fullPath(directory: String, type: CaptureType, format: String) -> String {
        let filename = generateFilename(type: type, format: format)
        return (directory as NSString).appendingPathComponent(filename)
    }

    private var sequence = 0

    private func sequenceNumber() -> Int {
        sequence += 1
        return sequence
    }

    func ensureDirectory(_ path: String) {
        let fm = FileManager.default
        if !fm.fileExists(atPath: path) {
            try? fm.createDirectory(atPath: path, withIntermediateDirectories: true)
        }
    }
}
