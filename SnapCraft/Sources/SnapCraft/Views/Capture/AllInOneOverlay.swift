import AppKit
import SwiftUI

@MainActor
final class AllInOneOverlayController {
    private var window: NSPanel?

    func show(onModeSelected: @escaping (CaptureMode) -> Void, onRecordingSelected: @escaping (RecordingMode) -> Void) {
        guard let screen = NSScreen.main else { return }

        let panelSize = CGSize(width: 360, height: 220)
        let origin = CGPoint(
            x: screen.frame.midX - panelSize.width / 2,
            y: screen.frame.midY - panelSize.height / 2
        )

        let panel = NSPanel(
            contentRect: CGRect(origin: origin, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true

        let view = NSHostingView(rootView: AllInOneView(
            onModeSelected: { [weak self] mode in
                self?.hide()
                onModeSelected(mode)
            },
            onRecordingSelected: { [weak self] mode in
                self?.hide()
                onRecordingSelected(mode)
            },
            onCancel: { [weak self] in
                self?.hide()
            }
        ))
        panel.contentView = view
        panel.makeKeyAndOrderFront(nil)
        self.window = panel
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
    }
}

struct AllInOneView: View {
    let onModeSelected: (CaptureMode) -> Void
    let onRecordingSelected: (RecordingMode) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            Text("All-In-One")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                ForEach([CaptureMode.area, .window, .fullscreen, .scrolling], id: \.self) { mode in
                    ModeButton(title: mode.displayName, systemImage: mode.systemImage) {
                        onModeSelected(mode)
                    }
                }
            }

            HStack(spacing: 8) {
                ForEach([CaptureMode.timed, .freeze, .ocr], id: \.self) { mode in
                    ModeButton(title: mode.displayName, systemImage: mode.systemImage) {
                        onModeSelected(mode)
                    }
                }
            }

            Divider()
                .background(.white.opacity(0.3))

            HStack(spacing: 8) {
                ForEach(RecordingMode.allCases) { mode in
                    ModeButton(title: mode.displayName, systemImage: mode.systemImage) {
                        onRecordingSelected(mode)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onExitCommand { onCancel() }
    }
}

private struct ModeButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title2)
                Text(title)
                    .font(.caption2)
            }
            .frame(width: 70, height: 56)
            .background(.white.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
