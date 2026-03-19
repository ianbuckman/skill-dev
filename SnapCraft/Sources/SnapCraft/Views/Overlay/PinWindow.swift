import AppKit
import SwiftUI

@MainActor
final class PinWindowController {
    private var pinWindows: [UUID: NSPanel] = [:]

    func pin(image: NSImage, id: UUID = UUID()) {
        let imageSize = image.size
        let maxDimension: CGFloat = 400
        let scale = min(maxDimension / imageSize.width, maxDimension / imageSize.height, 1.0)
        let windowSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )

        let panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = PinView(frame: CGRect(origin: .zero, size: windowSize))
        view.image = image
        view.pinID = id
        view.onClose = { [weak self] in
            self?.unpin(id: id)
        }
        view.onToggleLock = { [weak self] locked in
            self?.pinWindows[id]?.ignoresMouseEvents = locked
        }
        view.onOpacityChange = { [weak self] opacity in
            self?.pinWindows[id]?.alphaValue = opacity
        }

        panel.contentView = view
        panel.center()
        panel.orderFrontRegardless()

        pinWindows[id] = panel
    }

    func unpin(id: UUID) {
        pinWindows[id]?.orderOut(nil)
        pinWindows.removeValue(forKey: id)
    }

    func unpinAll() {
        for (_, panel) in pinWindows {
            panel.orderOut(nil)
        }
        pinWindows.removeAll()
    }
}

final class PinView: NSView {
    var image: NSImage?
    var pinID: UUID?
    var isLocked = false
    var onClose: (() -> Void)?
    var onToggleLock: ((Bool) -> Void)?
    var onOpacityChange: ((CGFloat) -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        guard let image = image else { return }

        // Draw rounded corners
        let path = NSBezierPath(roundedRect: bounds, xRadius: 8, yRadius: 8)
        path.addClip()

        image.draw(in: bounds)

        // Draw border
        NSColor.separatorColor.setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    override func rightMouseDown(with event: NSEvent) {
        let menu = NSMenu()

        let lockItem = NSMenuItem(
            title: isLocked ? "Unlock" : "Lock (Click-through)",
            action: #selector(toggleLock),
            keyEquivalent: ""
        )
        lockItem.target = self
        menu.addItem(lockItem)

        menu.addItem(.separator())

        let opacityMenu = NSMenu()
        for opacity in stride(from: 1.0, through: 0.2, by: -0.2) {
            let item = NSMenuItem(
                title: "\(Int(opacity * 100))%",
                action: #selector(setOpacity(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = Int(opacity * 100)
            opacityMenu.addItem(item)
        }
        let opacityItem = NSMenuItem(title: "Opacity", action: nil, keyEquivalent: "")
        opacityItem.submenu = opacityMenu
        menu.addItem(opacityItem)

        menu.addItem(.separator())

        let closeItem = NSMenuItem(title: "Close", action: #selector(closePinned), keyEquivalent: "w")
        closeItem.target = self
        menu.addItem(closeItem)

        NSMenu.popUpContextMenu(menu, with: event, for: self)
    }

    override func keyDown(with event: NSEvent) {
        let moveAmount: CGFloat = event.modifierFlags.contains(.shift) ? 10 : 1
        guard let window = window else { return }
        var frame = window.frame

        switch event.keyCode {
        case 123: frame.origin.x -= moveAmount // Left
        case 124: frame.origin.x += moveAmount // Right
        case 125: frame.origin.y -= moveAmount // Down
        case 126: frame.origin.y += moveAmount // Up
        case 53: closePinned() // Escape
        default: super.keyDown(with: event)
        }

        window.setFrame(frame, display: true)
    }

    @objc private func toggleLock() {
        isLocked.toggle()
        onToggleLock?(isLocked)
    }

    @objc private func setOpacity(_ sender: NSMenuItem) {
        let opacity = CGFloat(sender.tag) / 100.0
        onOpacityChange?(opacity)
    }

    @objc private func closePinned() {
        onClose?()
    }
}
