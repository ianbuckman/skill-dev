import Cocoa

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// 背景 - 圆角矩形 + 温暖橙色渐变（匹配像素猫配色）
let rect = NSRect(origin: .zero, size: size)
let cornerRadius: CGFloat = 220
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 20, dy: 20),
                         xRadius: cornerRadius, yRadius: cornerRadius)

let gradient = NSGradient(
    starting: NSColor(red: 1.0, green: 0.65, blue: 0.3, alpha: 1.0),
    ending: NSColor(red: 0.95, green: 0.45, blue: 0.2, alpha: 1.0)
)!
gradient.draw(in: path, angle: -45)

// 猫咪 emoji 居中
let text = "🐱"
let font = NSFont.systemFont(ofSize: 500, weight: .bold)
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

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to generate PNG")
}

let outputPath = "assets/AppIcon.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("✅ Icon saved to \(outputPath)")
