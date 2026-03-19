import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(spacing: 0) {
            CaptureModesSection()
            Divider()
            RecordingModesSection()
            Divider()
            QuickActionsSection()
            Divider()
            FooterSection()
        }
        .frame(width: 260)
    }
}

private struct CaptureModesSection: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Screenshot")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(CaptureMode.allCases) { mode in
                MenuBarButton(
                    title: mode.displayName,
                    systemImage: mode.systemImage,
                    shortcut: mode.shortcutHint
                ) {
                    // TODO: Trigger capture
                }
            }
        }
        .padding(.bottom, 4)
    }
}

private struct RecordingModesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Recording")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 4)

            ForEach(RecordingMode.allCases) { mode in
                MenuBarButton(
                    title: mode.displayName,
                    systemImage: mode.systemImage,
                    shortcut: mode.shortcutHint
                ) {
                    // TODO: Trigger recording
                }
            }
        }
        .padding(.bottom, 4)
    }
}

private struct QuickActionsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            MenuBarButton(title: "History", systemImage: "clock.arrow.circlepath", shortcut: "") {
                // TODO: Open history
            }
            MenuBarButton(title: "Settings...", systemImage: "gear", shortcut: "⌘,") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct FooterSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            MenuBarButton(title: "Quit SnapCraft", systemImage: "power", shortcut: "⌘Q") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MenuBarButton: View {
    let title: String
    let systemImage: String
    let shortcut: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .frame(width: 16)
                Text(title)
                Spacer()
                if !shortcut.isEmpty {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
