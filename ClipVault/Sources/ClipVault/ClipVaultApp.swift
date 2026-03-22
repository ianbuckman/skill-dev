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
                        // Find the MenuBarExtra's status item button and simulate a click
                        if let button = NSApp.windows
                            .compactMap({ $0.value(forKey: "statusItem") as? NSStatusItem })
                            .first?.button {
                            button.performClick(nil)
                        }
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
