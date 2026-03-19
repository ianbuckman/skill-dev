import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gear") }
            CaptureSettingsView()
                .tabItem { Label("Capture", systemImage: "camera") }
            RecordingSettingsView()
                .tabItem { Label("Recording", systemImage: "record.circle") }
            ShortcutsSettingsView()
                .tabItem { Label("Shortcuts", systemImage: "keyboard") }
            AppearanceSettingsView()
                .tabItem { Label("Appearance", systemImage: "paintbrush") }
            PresetsSettingsView()
                .tabItem { Label("Presets", systemImage: "slider.horizontal.3") }
        }
        .frame(width: 520, height: 420)
    }
}

struct GeneralSettingsView: View {
    @AppStorage("saveDirectory") private var saveDirectory = NSHomeDirectory() + "/Desktop"
    @AppStorage("imageFormat") private var imageFormat = "PNG"
    @AppStorage("quickAccessAutoClose") private var autoCloseTime: Double = 5.0
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("namingPattern") private var namingPattern = "SnapCraft_{date}_{time}"

    var body: some View {
        Form {
            Section("Save Location") {
                HStack {
                    Text(saveDirectory)
                        .lineLimit(1)
                        .truncationMode(.head)
                    Spacer()
                    Button("Choose...") {
                        let panel = NSOpenPanel()
                        panel.canChooseFiles = false
                        panel.canChooseDirectories = true
                        if panel.runModal() == .OK, let url = panel.url {
                            saveDirectory = url.path
                        }
                    }
                }

                Picker("Default Format", selection: $imageFormat) {
                    Text("PNG").tag("PNG")
                    Text("JPG").tag("JPG")
                }

                TextField("Naming Pattern", text: $namingPattern)
                    .textFieldStyle(.roundedBorder)
                Text("Variables: {date}, {time}, {type}, {n}")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Quick Access Overlay") {
                HStack {
                    Text("Auto-close after")
                    Slider(value: $autoCloseTime, in: 0...30, step: 1)
                    Text("\(Int(autoCloseTime))s")
                        .frame(width: 30)
                }
                Text("Set to 0 to disable auto-close")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("System") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct CaptureSettingsView: View {
    @AppStorage("showCrosshair") private var showCrosshair = true
    @AppStorage("showMagnifier") private var showMagnifier = true
    @AppStorage("showCursorInCapture") private var showCursor = false
    @AppStorage("windowShadow") private var windowShadow = true
    @AppStorage("windowPadding") private var windowPadding: Double = 20
    @AppStorage("timerDelay") private var timerDelay = 3

    var body: some View {
        Form {
            Section("Area Capture") {
                Toggle("Show Crosshair", isOn: $showCrosshair)
                Toggle("Show Magnifier", isOn: $showMagnifier)
                Toggle("Include Cursor", isOn: $showCursor)
            }

            Section("Window Capture") {
                Toggle("Window Shadow", isOn: $windowShadow)
                HStack {
                    Text("Padding")
                    Slider(value: $windowPadding, in: 0...80, step: 4)
                    Text("\(Int(windowPadding))px")
                        .frame(width: 40)
                }
            }

            Section("Timer") {
                Picker("Delay", selection: $timerDelay) {
                    Text("3 seconds").tag(3)
                    Text("5 seconds").tag(5)
                    Text("10 seconds").tag(10)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct RecordingSettingsView: View {
    @AppStorage("recordingFPS") private var fps = 30
    @AppStorage("recordingQuality") private var quality = "High"
    @AppStorage("captureSystemAudio") private var systemAudio = true
    @AppStorage("captureMicrophone") private var microphone = false
    @AppStorage("showMouseClicks") private var mouseClicks = false
    @AppStorage("showKeystrokes") private var keystrokes = false
    @AppStorage("hideDesktopOnRecord") private var hideDesktop = false
    @AppStorage("enableDND") private var enableDND = true
    @AppStorage("gifFPS") private var gifFPS = 15

    var body: some View {
        Form {
            Section("Video") {
                Picker("FPS", selection: $fps) {
                    Text("24").tag(24)
                    Text("30").tag(30)
                    Text("60").tag(60)
                }
                Picker("Quality", selection: $quality) {
                    Text("Low").tag("Low")
                    Text("Medium").tag("Medium")
                    Text("High").tag("High")
                }
            }

            Section("Audio") {
                Toggle("System Audio", isOn: $systemAudio)
                Toggle("Microphone", isOn: $microphone)
            }

            Section("Visual") {
                Toggle("Highlight Mouse Clicks", isOn: $mouseClicks)
                Toggle("Show Keystrokes", isOn: $keystrokes)
                Toggle("Hide Desktop Icons", isOn: $hideDesktop)
                Toggle("Enable Do Not Disturb", isOn: $enableDND)
            }

            Section("GIF") {
                Picker("GIF FPS", selection: $gifFPS) {
                    Text("10").tag(10)
                    Text("15").tag(15)
                    Text("20").tag(20)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("Screenshot Shortcuts") {
                ShortcutRow(action: "Fullscreen Capture", shortcut: "⌘⇧3")
                ShortcutRow(action: "Area Capture", shortcut: "⌘⇧4")
                ShortcutRow(action: "Window Capture", shortcut: "⌘⇧5")
                ShortcutRow(action: "Scrolling Capture", shortcut: "⌘⇧6")
                ShortcutRow(action: "OCR Text", shortcut: "⌘⇧9")
                ShortcutRow(action: "All-In-One", shortcut: "⌘⇧0")
            }

            Section("Recording Shortcuts") {
                ShortcutRow(action: "Screen Recording", shortcut: "⌘⇧7")
                ShortcutRow(action: "GIF Recording", shortcut: "⌘⇧8")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct ShortcutRow: View {
    let action: String
    let shortcut: String

    var body: some View {
        HStack {
            Text(action)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}

struct AppearanceSettingsView: View {
    @AppStorage("colorScheme") private var colorScheme = "System"

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Appearance", selection: $colorScheme) {
                    Text("System").tag("System")
                    Text("Light").tag("Light")
                    Text("Dark").tag("Dark")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct PresetsSettingsView: View {
    @State private var presets: [AppPreset] = []
    @State private var presetService = PresetService()

    var body: some View {
        VStack {
            if presets.isEmpty {
                ContentUnavailableView(
                    "No Presets",
                    systemImage: "slider.horizontal.3",
                    description: Text("Create presets for quick capture configurations")
                )
            } else {
                List {
                    ForEach(presets) { preset in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preset.name)
                                    .font(.headline)
                                Text("\(preset.captureMode.displayName) · \(preset.imageFormat.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Delete", role: .destructive) {
                                presetService.deletePreset(id: preset.id)
                                loadPresets()
                            }
                        }
                    }
                }
            }

            Button("Add Preset") {
                let preset = AppPreset(name: "Preset \(presets.count + 1)")
                presetService.savePreset(preset)
                loadPresets()
            }
            .padding()
        }
        .task {
            loadPresets()
        }
    }

    private func loadPresets() {
        presets = presetService.loadPresets()
    }
}
