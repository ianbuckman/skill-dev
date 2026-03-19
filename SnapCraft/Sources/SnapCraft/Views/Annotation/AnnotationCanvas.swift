import AppKit
import CoreImage

final class AnnotationCanvas: NSView {
    var backgroundImage: NSImage? { didSet { needsDisplay = true } }
    var items: [AnnotationItem] = [] { didSet { needsDisplay = true } }
    var currentTool: AnnotationTool = .arrow
    var currentColor: NSColor = .systemRed
    var currentLineWidth: CGFloat = 2
    var currentFontSize: CGFloat = 16
    var currentArrowStyle: ArrowStyle = .straight
    var counterValue: Int = 1
    var onItemsChanged: (([AnnotationItem]) -> Void)?

    private var isDrawing = false
    private var drawingItem: AnnotationItem?
    private var selectedItemIndex: Int?
    private var dragOffset: CGPoint = .zero

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Draw background image
        if let image = backgroundImage {
            image.draw(in: bounds)
        }

        // Draw all annotation items
        for (index, item) in items.enumerated() {
            drawItem(item, in: context, isSelected: index == selectedItemIndex)
        }

        // Draw current drawing item
        if let item = drawingItem {
            drawItem(item, in: context, isSelected: false)
        }
    }

    private func drawItem(_ item: AnnotationItem, in context: CGContext, isSelected: Bool) {
        let color = item.color.nsColor
        context.setStrokeColor(color.cgColor)
        context.setFillColor(color.cgColor)
        context.setLineWidth(item.lineWidth)
        context.setLineCap(.round)
        context.setLineJoin(.round)

        switch item.tool {
        case .arrow:
            drawArrow(item, in: context)
        case .rectangle:
            let rect = CGRect(
                x: min(item.startPoint.x, item.endPoint.x),
                y: min(item.startPoint.y, item.endPoint.y),
                width: abs(item.endPoint.x - item.startPoint.x),
                height: abs(item.endPoint.y - item.startPoint.y)
            )
            context.stroke(rect)
        case .filledRectangle:
            let rect = CGRect(
                x: min(item.startPoint.x, item.endPoint.x),
                y: min(item.startPoint.y, item.endPoint.y),
                width: abs(item.endPoint.x - item.startPoint.x),
                height: abs(item.endPoint.y - item.startPoint.y)
            )
            context.setFillColor(color.withAlphaComponent(0.3).cgColor)
            context.fill(rect)
            context.stroke(rect)
        case .ellipse:
            let rect = CGRect(
                x: min(item.startPoint.x, item.endPoint.x),
                y: min(item.startPoint.y, item.endPoint.y),
                width: abs(item.endPoint.x - item.startPoint.x),
                height: abs(item.endPoint.y - item.startPoint.y)
            )
            context.strokeEllipse(in: rect)
        case .line:
            context.move(to: item.startPoint)
            context.addLine(to: item.endPoint)
            context.strokePath()
        case .pencil:
            guard item.points.count >= 2 else { return }
            context.move(to: item.points[0])
            for point in item.points.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        case .highlight:
            guard item.points.count >= 2 else { return }
            context.setStrokeColor(color.withAlphaComponent(0.4).cgColor)
            context.setLineWidth(item.lineWidth * 5)
            context.move(to: item.points[0])
            for point in item.points.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        case .text:
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: item.fontName, size: item.fontSize) ?? NSFont.systemFont(ofSize: item.fontSize),
                .foregroundColor: color
            ]
            (item.text as NSString).draw(at: item.startPoint, withAttributes: attrs)
        case .blur:
            drawBlurEffect(item, in: context)
        case .pixelate:
            drawPixelateEffect(item, in: context)
        case .spotlight:
            drawSpotlight(item, in: context)
        case .counter:
            drawCounter(item, in: context)
        case .crop:
            break // Handled separately
        }

        if isSelected {
            drawSelectionHandles(for: item, in: context)
        }
    }

    private func drawArrow(_ item: AnnotationItem, in context: CGContext) {
        let start = item.startPoint
        let end = item.endPoint

        // Line
        context.move(to: start)
        if item.arrowStyle == .curved {
            let controlPoint = CGPoint(
                x: (start.x + end.x) / 2 + (end.y - start.y) * 0.3,
                y: (start.y + end.y) / 2 - (end.x - start.x) * 0.3
            )
            context.addQuadCurve(to: end, control: controlPoint)
        } else {
            context.addLine(to: end)
        }
        context.strokePath()

        // Arrowhead
        let angle = atan2(end.y - start.y, end.x - start.x)
        let arrowLength: CGFloat = 15
        let arrowAngle: CGFloat = .pi / 6

        let p1 = CGPoint(
            x: end.x - arrowLength * cos(angle - arrowAngle),
            y: end.y - arrowLength * sin(angle - arrowAngle)
        )
        let p2 = CGPoint(
            x: end.x - arrowLength * cos(angle + arrowAngle),
            y: end.y - arrowLength * sin(angle + arrowAngle)
        )

        context.move(to: end)
        context.addLine(to: p1)
        context.move(to: end)
        context.addLine(to: p2)
        context.strokePath()

        if item.arrowStyle == .doubleEnded {
            let rAngle = angle + .pi
            let rp1 = CGPoint(x: start.x - arrowLength * cos(rAngle - arrowAngle), y: start.y - arrowLength * sin(rAngle - arrowAngle))
            let rp2 = CGPoint(x: start.x - arrowLength * cos(rAngle + arrowAngle), y: start.y - arrowLength * sin(rAngle + arrowAngle))
            context.move(to: start)
            context.addLine(to: rp1)
            context.move(to: start)
            context.addLine(to: rp2)
            context.strokePath()
        }
    }

    private func drawBlurEffect(_ item: AnnotationItem, in context: CGContext) {
        let rect = item.boundingRect
        guard rect.width > 0, rect.height > 0,
              let bgImage = backgroundImage,
              let tiffData = bgImage.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else { return }

        let filter = CIFilter(name: "CIGaussianBlur")!
        filter.setValue(ciImage.cropped(to: rect), forKey: kCIInputImageKey)
        filter.setValue(10.0, forKey: kCIInputRadiusKey)

        if let output = filter.outputImage {
            let ciContext = CIContext()
            if let cgImage = ciContext.createCGImage(output, from: rect) {
                context.draw(cgImage, in: rect)
            }
        }
    }

    private func drawPixelateEffect(_ item: AnnotationItem, in context: CGContext) {
        let rect = item.boundingRect
        guard rect.width > 0, rect.height > 0,
              let bgImage = backgroundImage,
              let tiffData = bgImage.tiffRepresentation,
              let ciImage = CIImage(data: tiffData) else { return }

        let filter = CIFilter(name: "CIPixellate")!
        filter.setValue(ciImage.cropped(to: rect), forKey: kCIInputImageKey)
        filter.setValue(8.0, forKey: kCIInputScaleKey)

        if let output = filter.outputImage {
            let ciContext = CIContext()
            if let cgImage = ciContext.createCGImage(output, from: rect) {
                context.draw(cgImage, in: rect)
            }
        }
    }

    private func drawSpotlight(_ item: AnnotationItem, in context: CGContext) {
        let rect = item.boundingRect
        // Darken everything except the spotlight area
        context.saveGState()
        context.setFillColor(NSColor.black.withAlphaComponent(0.5).cgColor)

        let path = CGMutablePath()
        path.addRect(bounds)
        path.addEllipse(in: rect)

        context.addPath(path)
        context.fillPath(using: .evenOdd)
        context.restoreGState()
    }

    private func drawCounter(_ item: AnnotationItem, in context: CGContext) {
        let center = item.startPoint
        let radius: CGFloat = 14

        // Circle
        let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
        context.fillEllipse(in: circleRect)

        // Number
        let numStr = "\(item.counterNumber)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 14, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let size = numStr.size(withAttributes: attrs)
        numStr.draw(
            at: CGPoint(x: center.x - size.width / 2, y: center.y - size.height / 2),
            withAttributes: attrs
        )
    }

    private func drawSelectionHandles(for item: AnnotationItem, in context: CGContext) {
        let rect = item.boundingRect
        context.setStrokeColor(NSColor.systemBlue.cgColor)
        context.setLineWidth(1)
        context.setLineDash(phase: 0, lengths: [4, 4])
        context.stroke(rect.insetBy(dx: -4, dy: -4))
        context.setLineDash(phase: 0, lengths: [])

        let handleSize: CGFloat = 6
        let handles = [
            CGPoint(x: rect.minX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY),
            CGPoint(x: rect.minX, y: rect.maxY),
            CGPoint(x: rect.maxX, y: rect.maxY)
        ]
        context.setFillColor(NSColor.white.cgColor)
        for handle in handles {
            let r = CGRect(x: handle.x - handleSize/2, y: handle.y - handleSize/2, width: handleSize, height: handleSize)
            context.fillEllipse(in: r)
            context.strokeEllipse(in: r)
        }
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        // Check if clicking on existing item
        if let index = items.lastIndex(where: { $0.boundingRect.insetBy(dx: -10, dy: -10).contains(point) }) {
            selectedItemIndex = index
            dragOffset = CGPoint(x: point.x - items[index].startPoint.x, y: point.y - items[index].startPoint.y)
            needsDisplay = true
            return
        }

        selectedItemIndex = nil
        isDrawing = true

        if currentTool == .counter {
            let item = AnnotationItem(tool: .counter, startPoint: point, color: CodableColor(nsColor: currentColor), counterNumber: counterValue)
            items.append(item)
            counterValue += 1
            isDrawing = false
            onItemsChanged?(items)
        } else if currentTool == .text {
            let item = AnnotationItem(tool: .text, startPoint: point, color: CodableColor(nsColor: currentColor), text: "Text", fontSize: currentFontSize)
            items.append(item)
            isDrawing = false
            onItemsChanged?(items)
        } else {
            drawingItem = AnnotationItem(
                tool: currentTool,
                startPoint: point,
                color: CodableColor(nsColor: currentColor),
                lineWidth: currentLineWidth,
                arrowStyle: currentArrowStyle
            )
            if currentTool == .pencil || currentTool == .highlight {
                drawingItem?.points = [point]
            }
        }
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)

        if let index = selectedItemIndex {
            let dx = point.x - dragOffset.x - items[index].startPoint.x
            let dy = point.y - dragOffset.y - items[index].startPoint.y
            items[index].startPoint.x += dx
            items[index].startPoint.y += dy
            items[index].endPoint.x += dx
            items[index].endPoint.y += dy
            items[index].points = items[index].points.map { CGPoint(x: $0.x + dx, y: $0.y + dy) }
            dragOffset = CGPoint(x: point.x - items[index].startPoint.x, y: point.y - items[index].startPoint.y)
            needsDisplay = true
            return
        }

        guard isDrawing else { return }

        if currentTool == .pencil || currentTool == .highlight {
            drawingItem?.points.append(point)
        } else {
            drawingItem?.endPoint = point
        }
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if isDrawing, var item = drawingItem {
            let point = convert(event.locationInWindow, from: nil)
            if currentTool == .pencil || currentTool == .highlight {
                item.points.append(point)
            } else {
                item.endPoint = point
            }

            if item.boundingRect.width > 2 || item.boundingRect.height > 2 || !item.points.isEmpty {
                items.append(item)
                onItemsChanged?(items)
            }
        }
        isDrawing = false
        drawingItem = nil
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 51, let index = selectedItemIndex { // Delete
            items.remove(at: index)
            selectedItemIndex = nil
            onItemsChanged?(items)
            needsDisplay = true
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "z" {
            if event.modifierFlags.contains(.shift) {
                redo()
            } else {
                undo()
            }
        }
    }

    // MARK: - Undo/Redo

    private var undoStack: [[AnnotationItem]] = []
    private var redoStack: [[AnnotationItem]] = []

    func saveUndoState() {
        undoStack.append(items)
        redoStack.removeAll()
    }

    func undo() {
        guard !undoStack.isEmpty else { return }
        redoStack.append(items)
        items = undoStack.removeLast()
        onItemsChanged?(items)
        needsDisplay = true
    }

    func redo() {
        guard !redoStack.isEmpty else { return }
        undoStack.append(items)
        items = redoStack.removeLast()
        onItemsChanged?(items)
        needsDisplay = true
    }

    // MARK: - Export

    func exportImage() -> NSImage? {
        let imageRep = bitmapImageRepForCachingDisplay(in: bounds)
        if let rep = imageRep {
            cacheDisplay(in: bounds, to: rep)
            let image = NSImage(size: bounds.size)
            image.addRepresentation(rep)
            return image
        }
        return nil
    }
}
