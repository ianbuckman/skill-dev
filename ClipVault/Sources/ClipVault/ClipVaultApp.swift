import SwiftUI

@main
struct ClipVaultApp: App {
    @State private var appState = AppState()
    @State private var monitor: ClipboardMonitor?
    @State private var hotkeyService: HotkeyService?

    var body: some Scene {
        MenuBarExtra("ClipVault", systemImage: "doc.on.clipboard") {
            ContentView()
                .environment(appState)
                .task {
                    guard monitor == nil else { return }
                    await appState.loadHistory()

                    let m = ClipboardMonitor(appState: appState)
                    m.start()
                    monitor = m

                    let hk = HotkeyService()
                    hk.onToggle = {
                        // Activate the app to trigger the MenuBarExtra popover
                        NSApp.activate(ignoringOtherApps: true)
                    }
                    hk.start()
                    hotkeyService = hk
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
