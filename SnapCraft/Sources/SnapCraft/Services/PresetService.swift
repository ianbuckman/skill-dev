import Foundation

@MainActor
final class PresetService {
    private let presetsFileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("SnapCraft")
        presetsFileURL = appDir.appendingPathComponent("presets.json")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
    }

    func loadPresets() -> [AppPreset] {
        guard let data = try? Data(contentsOf: presetsFileURL),
              let presets = try? JSONDecoder().decode([AppPreset].self, from: data) else {
            return []
        }
        return presets
    }

    func savePreset(_ preset: AppPreset) {
        var presets = loadPresets()
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = preset
        } else {
            presets.append(preset)
        }
        savePresets(presets)
    }

    func deletePreset(id: UUID) {
        var presets = loadPresets()
        presets.removeAll { $0.id == id }
        savePresets(presets)
    }

    private func savePresets(_ presets: [AppPreset]) {
        guard let data = try? JSONEncoder().encode(presets) else { return }
        try? data.write(to: presetsFileURL)
    }
}
