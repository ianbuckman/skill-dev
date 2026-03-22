import Cocoa

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// Background - rounded rectangle with gradient
let rect = NSRect(origin: .zero, size: size)
let cornerRadius: CGFloat = 220
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 20, dy: 20),
                         xRadius: cornerRadius, yRadius: cornerRadius)

// Teal/cyan gradient for productivity tool
let gradient = NSGradient(
    starting: NSColor(red: 0.15, green: 0.75, blue: 0.85, alpha: 1.0),
    ending: NSColor(red: 0.10, green: 0.50, blue: 0.70, alpha: 1.0)
)!
gradient.draw(in: path, angle: -45)

// Clipboard icon using text
let text = "📋"
let font = NSFont.systemFont(ofSize: 450, weight: .bold)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white
]
let textSize = (text as NSString).size(withAttributes: attrs)
let textPoint = NSPoint(
    x: (size.width - textSize.width) / 2,
    y: (size.height - textSize.height) / 2 - 20
)
(text as NSString).draw(at: textPoint, withAttributes: attrs)

image.unlockFocus()

// Save as PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to generate PNG")
}

let outputPath = "assets/AppIcon.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("✅ Icon saved to \(outputPath)")
