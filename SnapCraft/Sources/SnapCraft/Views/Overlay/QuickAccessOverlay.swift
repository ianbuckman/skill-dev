import AppKit
import SwiftUI

@MainActor
final class QuickAccessOverlayController {
    private var window: NSPanel?
    private var autoCloseTimer: Timer?
    private var hostingView: NSHostingView<QuickAccessOverlayView>?

    var onAnnotate: ((NSImage) -> Void)?
    var onPin: ((NSImage) -> Void)?
    var onClose: (() -> Void)?

    func show(image: NSImage, filePath: String?) {
        hide()

        guard let screen = NSScreen.main else { return }

        let panelWidth: CGFloat = 300
        let panelHeight: CGFloat = 200
        let margin: CGFloat = 16

        let origin = CGPoint(
            x: screen.visibleFrame.maxX - panelWidth - margin,
            y: screen.visibleFrame.minY + margin
        )

        let panel = NSPanel(
            contentRect: CGRect(origin: origin, size: CGSize(width: panelWidth, height: panelHeight)),
            styleMask: [.titled, .closable, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.title = ""
        panel.titlebarAppearsTransparent = true

        let view = QuickAccessOverlayView(
            image: image,
            filePath: filePath,
            onCopy: { [weak self] in
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.writeObjects([image])
                self?.flashCopied()
            },
            onAnnotate: { [weak self] in
                self?.hide()
                self?.onAnnotate?(image)
            },
            onPin: { [weak self] in
                self?.hide()
                self?.onPin?(image)
            },
            onClose: { [weak self] in
                self?.hide()
                self?.onClose?()
            }
        )

        let hosting = NSHostingView(rootView: view)
        panel.contentView = hosting

        panel.orderFrontRegardless()

        self.window = panel
        self.hostingView = hosting

        // Auto-close after configurable duration
        let duration = UserDefaults.standard.double(forKey: "quickAccessAutoClose")
        if duration > 0 {
            autoCloseTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.hide()
                }
            }
        }
    }

    func hide() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
        window?.orderOut(nil)
        window = nil
        hostingView = nil
    }

    private func flashCopied() {
        // Brief visual feedback could be added here
    }
}

struct QuickAccessOverlayView: View {
    let image: NSImage
    let filePath: String?
    let onCopy: () -> Void
    let onAnnotate: () -> Void
    let onPin: () -> Void
    let onClose: () -> Void

    @State private var showCopied = false

    var body: some View {
        VStack(spacing: 8) {
            ImagePreview()
            ActionButtons()
            FileInfo()
        }
        .padding(12)
        .frame(width: 280)
    }

    @ViewBuilder
    private func ImagePreview() -> some View {
        Image(nsImage: image)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxHeight: 100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 2)
            .onDrag {
                NSItemProvider(object: image)
            }
    }

    @ViewBuilder
    private func ActionButtons() -> some View {
        HStack(spacing: 8) {
            OverlayButton(title: showCopied ? "Copied!" : "Copy", systemImage: "doc.on.doc") {
                onCopy()
                showCopied = true
                Task {
                    try? await Task.sleep(for: .seconds(1))
                    showCopied = false
                }
            }

            OverlayButton(title: "Annotate", systemImage: "pencil.tip") {
                onAnnotate()
            }

            OverlayButton(title: "Pin", systemImage: "pin") {
                onPin()
            }

            OverlayButton(title: "Close", systemImage: "xmark") {
                onClose()
            }
        }
    }

    @ViewBuilder
    private func FileInfo() -> some View {
        if let path = filePath {
            Text(URL(fileURLWithPath: path).lastPathComponent)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct OverlayButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: systemImage)
                    .font(.system(size: 14))
                Text(title)
                    .font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}
