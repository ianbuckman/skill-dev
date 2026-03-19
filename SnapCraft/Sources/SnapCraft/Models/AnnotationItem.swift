import Foundation
import AppKit

enum AnnotationTool: String, CaseIterable, Identifiable, Codable {
    case arrow = "Arrow"
    case rectangle = "Rectangle"
    case filledRectangle = "Filled Rectangle"
    case ellipse = "Ellipse"
    case line = "Line"
    case pencil = "Pencil"
    case highlight = "Highlight"
    case text = "Text"
    case blur = "Blur"
    case pixelate = "Pixelate"
    case spotlight = "Spotlight"
    case counter = "Counter"
    case crop = "Crop"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .arrow: return "arrow.up.right"
        case .rectangle: return "rectangle"
        case .filledRectangle: return "rectangle.fill"
        case .ellipse: return "circle"
        case .line: return "line.diagonal"
        case .pencil: return "pencil"
        case .highlight: return "highlighter"
        case .text: return "textformat"
        case .blur: return "drop.halffull"
        case .pixelate: return "mosaic.fill"
        case .spotlight: return "flashlight.on.fill"
        case .counter: return "number.circle"
        case .crop: return "crop"
        }
    }
}

enum ArrowStyle: Int, CaseIterable, Codable {
    case straight = 0
    case curved = 1
    case doubleEnded = 2
    case thick = 3
}

struct AnnotationItem: Identifiable, Codable {
    let id: UUID
    var tool: AnnotationTool
    var startPoint: CGPoint
    var endPoint: CGPoint
    var points: [CGPoint] // For pencil/highlight
    var color: CodableColor
    var lineWidth: CGFloat
    var text: String
    var fontSize: CGFloat
    var fontName: String
    var arrowStyle: ArrowStyle
    var counterNumber: Int
    var isSelected: Bool

    init(
        tool: AnnotationTool,
        startPoint: CGPoint = .zero,
        endPoint: CGPoint = .zero,
        points: [CGPoint] = [],
        color: CodableColor = CodableColor(nsColor: .systemRed),
        lineWidth: CGFloat = 2,
        text: String = "",
        fontSize: CGFloat = 16,
        fontName: String = "Helvetica Neue",
        arrowStyle: ArrowStyle = .straight,
        counterNumber: Int = 1
    ) {
        self.id = UUID()
        self.tool = tool
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.points = points
        self.color = color
        self.lineWidth = lineWidth
        self.text = text
        self.fontSize = fontSize
        self.fontName = fontName
        self.arrowStyle = arrowStyle
        self.counterNumber = counterNumber
        self.isSelected = false
    }

    var boundingRect: CGRect {
        if !points.isEmpty {
            let xs = points.map(\.x)
            let ys = points.map(\.y)
            let minX = xs.min() ?? 0
            let minY = ys.min() ?? 0
            let maxX = xs.max() ?? 0
            let maxY = ys.max() ?? 0
            return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
        }
        return CGRect(
            x: min(startPoint.x, endPoint.x),
            y: min(startPoint.y, endPoint.y),
            width: abs(endPoint.x - startPoint.x),
            height: abs(endPoint.y - startPoint.y)
        )
    }
}

struct CodableColor: Codable {
    var red: CGFloat
    var green: CGFloat
    var blue: CGFloat
    var alpha: CGFloat

    init(nsColor: NSColor) {
        let c = nsColor.usingColorSpace(.sRGB) ?? nsColor
        self.red = c.redComponent
        self.green = c.greenComponent
        self.blue = c.blueComponent
        self.alpha = c.alphaComponent
    }

    var nsColor: NSColor {
        NSColor(srgbRed: red, green: green, blue: blue, alpha: alpha)
    }
}