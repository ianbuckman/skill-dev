import SwiftUI

struct MenuBarView: View {
    @Environment(AppState.self) private var appState
    @State private var coordinator: CaptureCoordinator?

    var body: some View {
        VStack(spacing: 0) {
            CaptureModesSection(coordinator: coordinator)
            Divider()
            RecordingModesSection(coordinator: coordinator, isRecording: appState.isRecording)
            Divider()
            QuickActionsSection(coordinator: coordinator)
            Divider()
            FooterSection()
        }
        .frame(width: 260)
        .task {
            if coordinator == nil {
                let coord = CaptureCoordinator(appState: appState)
                coord.registerDefaultHotkeys()
                coordinator = coord
            }
        }
    }
}

private struct CaptureModesSection: View {
    let coordinator: CaptureCoordinator?

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
                    coordinator?.performCapture(mode: mode)
                }
            }
        }
        .padding(.bottom, 4)
    }
}

private struct RecordingModesSection: View {
    let coordinator: CaptureCoordinator?
    let isRecording: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Recording")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.top, 4)

            if isRecording {
                MenuBarButton(
                    title: "Stop Recording",
                    systemImage: "stop.circle.fill",
                    shortcut: ""
                ) {
                    coordinator?.stopRecording()
                }
                .foregroundStyle(.red)
            } else {
                ForEach(RecordingMode.allCases) { mode in
                    MenuBarButton(
                        title: mode.displayName,
                        systemImage: mode.systemImage,
                        shortcut: mode.shortcutHint
                    ) {
                        coordinator?.startRecording(mode: mode)
                    }
                }
            }
        }
        .padding(.bottom, 4)
    }
}

private struct QuickActionsSection: View {
    let coordinator: CaptureCoordinator?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            MenuBarButton(
                title: "Toggle Desktop Icons",
                systemImage: "desktopcomputer",
                shortcut: ""
            ) {
                coordinator?.desktopIconService.toggleDesktopIcons()
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
