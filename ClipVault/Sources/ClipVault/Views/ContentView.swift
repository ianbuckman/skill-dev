import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ClipboardListView(appState: appState)
            .frame(width: 340, height: 480)
    }
}
