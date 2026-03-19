import AppKit
import SwiftUI

@MainActor
final class AreaSelectionOverlay: NSObject {
    private var overlayWindow: NSWindow?
    private var selectionView: AreaSelectionView?
    private var completion: ((CGRect?) -> Void)?

    func show(completion: @escaping (CGRect?) -> Void) {
        self.completion = completion

        guard let screen = NSScreen.main else {
            completion(nil)
            return
        }

        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.backgroundColor = NSColor.black.withAlphaComponent(0.15)
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = false
        window.acceptsMouseMovedEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let view = AreaSelectionView(frame: screen.frame)
        view.onSelectionComplete = { [weak self] rect in
            self?.hide()
            completion(rect)
        }
        view.onCancel = { [weak self] in
            self?.hide()
            completion(nil)
        }

        window.contentView = view
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(view)

        self.overlayWindow = window
        self.selectionView = view
    }

    func hide() {
        overlayWindow?.orderOut(nil)
        overlayWindow = nil
        selectionView = nil
    }
}

final class AreaSelectionView: NSView {
    var onSelectionComplete: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentPoint: NSPoint?
    private var isSelecting = false
    private var showCrosshair = true
    private var mousePosition: NSPoint = .zero

    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .mouseMoved, .mouseEnteredAndExited],
            owner: self,
            userInfo: nil
        ))
    }

    override func mouseMoved(with event: NSEvent) {
        mousePosition = convert(event.locationInWindow, from: nil)
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = convert(event.locationInWindow, from: nil)
        isSelecting = true
        showCrosshair = false
    }

    override func mouseDragged(with event: NSEvent) {
        currentPoint = convert(event.locationInWindow, from: nil)
        mousePosition = currentPoint!
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        guard isSelecting, let start = startPoint else { return }
        let end = convert(event.locationInWindow, from: nil)
        isSelecting = false

        let rect = CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )

        if rect.width > 5 && rect.height > 5 {
            onSelectionComplete?(rect)
        } else {
            showCrosshair = true
            needsDisplay = true
        }
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onCancel?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw semi-transparent overlay
        context.setFillColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        context.fill(bounds)

        if isSelecting, let start = startPoint, let current = currentPoint {
            // Draw selection area
            let selectionRect = CGRect(
                x: min(start.x, current.x),
                y: min(start.y, current.y),
                width: abs(current.x - start.x),
                height: abs(current.y - start.y)
            )

            // Clear the selection area
            context.clear(selectionRect)

            // Draw selection border
            context.setStrokeColor(NSColor.systemBlue.cgColor)
            context.setLineWidth(1.5)
            context.stroke(selectionRect)

            // Draw dimension label
            drawDimensions(context: context, rect: selectionRect)
        }

        if showCrosshair {
            drawCrosshair(context: context, at: mousePosition)
            drawMagnifier(context: context, at: mousePosition)
        }
    }

    private func drawCrosshair(context: CGContext, at point: NSPoint) {
        context.setStrokeColor(NSColor.systemBlue.withAlphaComponent(0.8).cgColor)
        context.setLineWidth(0.5)
        context.setLineDash(phase: 0, lengths: [4, 4])

        // Horizontal line
        context.move(to: CGPoint(x: 0, y: point.y))
        context.addLine(to: CGPoint(x: bounds.width, y: point.y))
        context.strokePath()

        // Vertical line
        context.move(to: CGPoint(x: point.x, y: 0))
        context.addLine(to: CGPoint(x: point.x, y: bounds.height))
        context.strokePath()

        context.setLineDash(phase: 0, lengths: [])
    }

    private func drawMagnifier(context: CGContext, at point: NSPoint) {
        let magnifierSize: CGFloat = 120
        let magnifierScale: CGFloat = 4.0
        let sourceSize = magnifierSize / magnifierScale

        let magnifierOrigin = CGPoint(
            x: point.x + 20,
            y: point.y + 20
        )

        // Background
        let magnifierRect = CGRect(origin: magnifierOrigin, size: CGSize(width: magnifierSize, height: magnifierSize))
        context.setFillColor(NSColor.windowBackgroundColor.cgColor)
        context.fillEllipse(in: magnifierRect)

        // Border
        context.setStrokeColor(NSColor.separatorColor.cgColor)
        context.setLineWidth(2)
        context.strokeEllipse(in: magnifierRect)

        // Coordinate text
        let coordStr = "\(Int(point.x)), \(Int(point.y))" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 10, weight: .medium),
            .foregroundColor: NSColor.labelColor
        ]
        let strSize = coordStr.size(withAttributes: attrs)
        coordStr.draw(
            at: CGPoint(
                x: magnifierOrigin.x + (magnifierSize - strSize.width) / 2,
                y: magnifierOrigin.y - strSize.height - 4
            ),
            withAttributes: attrs
        )
    }

    private func drawDimensions(context: CGContext, rect: CGRect) {
        let text = "\(Int(rect.width)) × \(Int(rect.height))" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            .foregroundColor: NSColor.white,
            .backgroundColor: NSColor.black.withAlphaComponent(0.7)
        ]
        let size = text.size(withAttributes: attrs)
        let textPoint = CGPoint(
            x: rect.midX - size.width / 2,
            y: rect.maxY + 8
        )

        let bgRect = CGRect(
            x: textPoint.x - 4,
            y: textPoint.y - 2,
            width: size.width + 8,
            height: size.height + 4
        )
        context.setFillColor(NSColor.black.withAlphaComponent(0.7).cgColor)
        let path = CGPath(roundedRect: bgRect, cornerWidth: 4, cornerHeight: 4, transform: nil)
        context.addPath(path)
        context.fillPath()

        text.draw(at: textPoint, withAttributes: attrs)
    }
}
