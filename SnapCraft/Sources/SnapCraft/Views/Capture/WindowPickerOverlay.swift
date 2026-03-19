import AppKit
import SwiftUI

@MainActor
final class WindowPickerOverlay: NSObject {
    private var overlayWindow: NSWindow?
    private var completion: ((CGWindowID?) -> Void)?
    private var highlightWindow: NSWindow?
    private var captureService = ScreenCaptureService()

    func show(completion: @escaping (CGWindowID?) -> Void) {
        self.completion = completion

        Task {
            do {
                let windows = try await captureService.listWindows()
                showPicker(windows: windows)
            } catch {
                completion(nil)
            }
        }
    }

    private func showPicker(windows: [(id: CGWindowID, title: String, appName: String, frame: CGRect)]) {
        guard let screen = NSScreen.main else {
            completion?(nil)
            return
        }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = NSColor.black.withAlphaComponent(0.01)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = WindowPickerView(frame: screen.frame)
        view.windows = windows
        view.onWindowSelected = { [weak self] windowID in
            self?.hide()
            self?.completion?(windowID)
        }
        view.onCancel = { [weak self] in
            self?.hide()
            self?.completion?(nil)
        }
        view.onHighlight = { [weak self] frame in
            self?.showHighlight(frame: frame)
        }

        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)
        overlayWindow = window
    }

    private func showHighlight(frame: CGRect?) {
        if let frame = frame {
            if highlightWindow == nil {
                let hw = NSWindow(
                    contentRect: .zero,
                    styleMask: .borderless,
                    backing: .buffered,
                    defer: false
                )
                hw.level = .screenSaver - 1
                hw.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.15)
                hw.isOpaque = false
                hw.hasShadow = false
                hw.ignoresMouseEvents = true
                highlightWindow = hw
            }
            // Convert from screen coordinates (top-left origin) to NSWindow coordinates (bottom-left origin)
            if let screen = NSScreen.main {
                let flippedY = screen.frame.height - frame.origin.y - frame.height
                highlightWindow?.setFrame(
                    CGRect(x: frame.origin.x, y: flippedY, width: frame.width, height: frame.height),
                    display: true
                )
            }
            highlightWindow?.orderFront(nil)
        } else {
            highlightWindow?.orderOut(nil)
        }
    }

    func hide() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        highlightWindow?.orderOut(nil)
        highlightWindow = nil
    }
}

final class WindowPickerView: NSView {
    var windows: [(id: CGWindowID, title: String, appName: String, frame: CGRect)] = []
    var onWindowSelected: ((CGWindowID) -> Void)?
    var onCancel: (() -> Void)?
    var onHighlight: ((CGRect?) -> Void)?

    private var hoveredWindowID: CGWindowID?

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        // Find window under cursor (screen coordinates: flip Y)
        if let screen = NSScreen.main {
            let screenPoint = CGPoint(x: point.x, y: screen.frame.height - point.y)
            if let win = windows.first(where: { $0.frame.contains(screenPoint) }) {
                if hoveredWindowID != win.id {
                    hoveredWindowID = win.id
                    onHighlight?(win.frame)
                }
            } else {
                hoveredWindowID = nil
                onHighlight?(nil)
            }
        }
    }

    override func mouseDown(with event: NSEvent) {
        if let windowID = hoveredWindowID {
            onWindowSelected?(windowID)
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        // Minimal draw — the highlight window handles visual feedback
    }
}
