import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsPlaceholder()
                .tabItem { Label("General", systemImage: "gear") }
            CaptureSettingsPlaceholder()
                .tabItem { Label("Capture", systemImage: "camera") }
            RecordingSettingsPlaceholder()
                .tabItem { Label("Recording", systemImage: "record.circle") }
            ShortcutsSettingsPlaceholder()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            AppearanceSettingsPlaceholder()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
        }
        .frame(width: 500, height: 400)
    }
}

private struct GeneralSettingsPlaceholder: View {
    var body: some View {
        Text("General Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct CaptureSettingsPlaceholder: View {
    var body: some View {
        Text("Capture Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct RecordingSettingsPlaceholder: View {
    var body: some View {
        Text("Recording Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ShortcutsSettingsPlaceholder: View {
    var body: some View {
        Text("Shortcuts Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct AppearanceSettingsPlaceholder: View {
    var body: some View {
        Text("Appearance Settings")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
