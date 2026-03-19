import SwiftUI

@main
struct SnapCraftApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra("SnapCraft", systemImage: "camera.viewfinder") {
            MenuBarView()
                .environment(appState)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    var coordinator: CaptureCoordinator?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Get app state from the SwiftUI app
        // Coordinator will be set up when menu bar view appears
    }
}
