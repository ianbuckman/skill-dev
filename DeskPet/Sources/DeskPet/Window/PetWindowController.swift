import AppKit
import SwiftUI

/// Manages the floating NSPanel that hosts the pet on the desktop.
@MainActor
final class PetWindowController {
    private var panel: NSPanel?
    private let petState: PetState
    private let interactionManager: InteractionManager?

    init(petState: PetState, interactionManager: InteractionManager? = nil) {
        self.petState = petState
        self.interactionManager = interactionManager
    }

    // MARK: - Public API

    /// Creates the NSPanel, configures its properties, and hosts PetCanvasView.
    func setupWindow() {
        let panelSize: CGFloat = 80

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelSize, height: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = false
        panel.hasShadow = false
        panel.acceptsMouseMovedEvents = true
        panel.isMovableByWindowBackground = false

        let contentView = PetCanvasView()
            .environment(petState)
            .environment(\.interactionManager, interactionManager)

        let hostingView = NSHostingView(rootView: contentView)
        panel.contentView = hostingView

        // Position the window at the pet's initial position
        let origin = NSPoint(
            x: petState.petPosition.x - panelSize / 2,
            y: petState.petPosition.y - panelSize / 2
        )
        panel.setFrameOrigin(origin)

        self.panel = panel
    }

    /// Updates the panel's screen position from `petState.petPosition`.
    func updatePosition() {
        guard let panel else { return }
        let panelSize = panel.frame.size
        let origin = NSPoint(
            x: petState.petPosition.x - panelSize.width / 2,
            y: petState.petPosition.y - panelSize.height / 2
        )
        panel.setFrameOrigin(origin)
    }

    /// Shows the panel on screen.
    func show() {
        panel?.orderFront(nil)
    }

    /// Hides the panel.
    func hide() {
        panel?.orderOut(nil)
    }
}
