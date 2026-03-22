import SwiftUI

@main
struct ClipVaultApp: App {
    @State private var appState = AppState()
    @State private var monitor: ClipboardMonitor?

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
                }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
