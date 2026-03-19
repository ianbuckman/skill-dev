import AppKit
import SwiftUI

@MainActor
final class AnnotationWindowController {
    private var window: NSWindow?
    private var canvas: AnnotationCanvas?

    func show(image: NSImage, onSave: @escaping (NSImage) -> Void) {
        let imageSize = image.size
        let screenFrame = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1200, height: 800)
        let maxWidth = min(imageSize.width + 40, screenFrame.width * 0.9)
        let maxHeight = min(imageSize.height + 80, screenFrame.height * 0.9)

        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: maxWidth, height: maxHeight),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "SnapCraft — Annotate"
        window.center()
        window.isReleasedWhenClosed = false

        let canvas = AnnotationCanvas(frame: CGRect(origin: .zero, size: imageSize))
        canvas.backgroundImage = image

        let scrollView = NSScrollView()
        scrollView.documentView = canvas
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.allowsMagnification = true
        scrollView.minMagnification = 0.25
        scrollView.maxMagnification = 4.0

        let toolbarHosting = NSHostingView(rootView: AnnotationToolbarWrapper(canvas: canvas, onSave: { [weak self, weak canvas] in
            guard let canvas = canvas, let exported = canvas.exportImage() else { return }
            onSave(exported)
            self?.close()
        }))
        toolbarHosting.translatesAutoresizingMaskIntoConstraints = false

        let containerView = NSView()
        containerView.addSubview(toolbarHosting)
        containerView.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            toolbarHosting.topAnchor.constraint(equalTo: containerView.topAnchor),
            toolbarHosting.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            toolbarHosting.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            toolbarHosting.heightAnchor.constraint(equalToConstant: 44),

            scrollView.topAnchor.constraint(equalTo: toolbarHosting.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        window.contentView = containerView
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        self.window = window
        self.canvas = canvas
    }

    func close() {
        window?.close()
        window = nil
        canvas = nil
    }
}

struct AnnotationToolbarWrapper: View {
    let canvas: AnnotationCanvas
    let onSave: () -> Void

    @State private var selectedTool: AnnotationTool = .arrow
    @State private var selectedColor: Color = .red
    @State private var lineWidth: CGFloat = 2
    @State private var fontSize: CGFloat = 16
    @State private var arrowStyle: ArrowStyle = .straight

    var body: some View {
        AnnotationToolbar(
            selectedTool: $selectedTool,
            selectedColor: $selectedColor,
            lineWidth: $lineWidth,
            fontSize: $fontSize,
            arrowStyle: $arrowStyle,
            onUndo: { canvas.undo() },
            onRedo: { canvas.redo() },
            onSave: onSave,
            onCopy: {
                if let image = canvas.exportImage() {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([image])
                }
            }
        )
        .onChange(of: selectedTool) { _, newValue in canvas.currentTool = newValue }
        .onChange(of: selectedColor) { _, newValue in canvas.currentColor = NSColor(newValue) }
        .onChange(of: lineWidth) { _, newValue in canvas.currentLineWidth = newValue }
        .onChange(of: fontSize) { _, newValue in canvas.currentFontSize = newValue }
        .onChange(of: arrowStyle) { _, newValue in canvas.currentArrowStyle = newValue }
    }
}
