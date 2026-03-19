import Cocoa

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let cornerRadius: CGFloat = 220
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 20, dy: 20),
                         xRadius: cornerRadius, yRadius: cornerRadius)

// Camera/media gradient — cyan to blue
let gradient = NSGradient(
    starting: NSColor(red: 0.15, green: 0.75, blue: 0.95, alpha: 1.0),
    ending: NSColor(red: 0.1, green: 0.4, blue: 0.85, alpha: 1.0)
)!
gradient.draw(in: path, angle: -45)

// Camera viewfinder symbol
let symbolText = "📷" as NSString
let symbolFont = NSFont.systemFont(ofSize: 420, weight: .regular)
let symbolAttrs: [NSAttributedString.Key: Any] = [
    .font: symbolFont,
    .foregroundColor: NSColor.white
]
let symbolSize = symbolText.size(withAttributes: symbolAttrs)
let symbolPoint = NSPoint(
    x: (size.width - symbolSize.width) / 2,
    y: (size.height - symbolSize.height) / 2 + 20
)
symbolText.draw(at: symbolPoint, withAttributes: symbolAttrs)

// "SC" text at bottom
let scText = "SC" as NSString
let scFont = NSFont.systemFont(ofSize: 140, weight: .heavy)
let scAttrs: [NSAttributedString.Key: Any] = [
    .font: scFont,
    .foregroundColor: NSColor.white.withAlphaComponent(0.4)
]
let scSize = scText.size(withAttributes: scAttrs)
let scPoint = NSPoint(
    x: (size.width - scSize.width) / 2,
    y: 100
)
scText.draw(at: scPoint, withAttributes: scAttrs)

image.unlockFocus()

guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to generate PNG")
}

let fm = FileManager.default
try! fm.createDirectory(atPath: "assets", withIntermediateDirectories: true)
try! pngData.write(to: URL(fileURLWithPath: "assets/AppIcon.png"))
print("✅ Icon saved to assets/AppIcon.png")
