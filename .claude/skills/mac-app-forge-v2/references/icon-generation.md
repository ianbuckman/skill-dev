# 图标生成指南

在没有设计师和外部工具的情况下，生成一个可用的 macOS App 图标。

## 方案 1: Swift 脚本生成（推荐）

用 Swift 脚本生成一个简单但好看的图标：带背景色 + SF Symbol 或文字。

保存为 `scripts/generate_icon.swift`，然后 `swift scripts/generate_icon.swift` 执行。

```swift
import Cocoa

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)

image.lockFocus()

// 背景 - 圆角矩形 + 渐变
let rect = NSRect(origin: .zero, size: size)
let cornerRadius: CGFloat = 220 // macOS 图标标准圆角
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 20, dy: 20),
                         xRadius: cornerRadius, yRadius: cornerRadius)

// 渐变色 - 根据 app 性质选择
let gradient = NSGradient(
    starting: NSColor(red: 0.2, green: 0.5, blue: 1.0, alpha: 1.0),
    ending: NSColor(red: 0.1, green: 0.3, blue: 0.8, alpha: 1.0)
)!
gradient.draw(in: path, angle: -45)

// 文字/符号 - 居中
let text = "🔧" // 替换为合适的 emoji 或字母
let font = NSFont.systemFont(ofSize: 500, weight: .bold)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white
]
let textSize = (text as NSString).size(withAttributes: attrs)
let textPoint = NSPoint(
    x: (size.width - textSize.width) / 2,
    y: (size.height - textSize.height) / 2
)
(text as NSString).draw(at: textPoint, withAttributes: attrs)

image.unlockFocus()

// 保存为 PNG
guard let tiffData = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiffData),
      let pngData = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Failed to generate PNG")
}

let outputPath = "assets/AppIcon.png"
try! pngData.write(to: URL(fileURLWithPath: outputPath))
print("✅ Icon saved to \(outputPath)")
```

## 方案 2: sips 命令行（最简单）

如果已经有一个 1024x1024 PNG，直接用 macOS 自带的 `sips` 工具：

```bash
# 确保是 1024x1024
sips -z 1024 1024 input.png --out assets/AppIcon.png
```

## PNG → icns 转换

macOS .app bundle 需要 .icns 格式。转换方法：

```bash
#!/bin/bash
set -e

INPUT_PNG="assets/AppIcon.png"
ICONSET_DIR="assets/AppIcon.iconset"
OUTPUT_ICNS="assets/AppIcon.icns"

mkdir -p "${ICONSET_DIR}"

# 生成各尺寸
sips -z 16 16     "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_16x16.png"
sips -z 32 32     "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_16x16@2x.png"
sips -z 32 32     "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_32x32.png"
sips -z 64 64     "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_32x32@2x.png"
sips -z 128 128   "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_128x128.png"
sips -z 256 256   "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_128x128@2x.png"
sips -z 256 256   "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_256x256.png"
sips -z 512 512   "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_256x256@2x.png"
sips -z 512 512   "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_512x512.png"
sips -z 1024 1024 "${INPUT_PNG}" --out "${ICONSET_DIR}/icon_512x512@2x.png"

# 转换为 icns
iconutil -c icns "${ICONSET_DIR}" -o "${OUTPUT_ICNS}"

# 清理
rm -rf "${ICONSET_DIR}"

echo "✅ ${OUTPUT_ICNS} 生成完成"
```

## 图标配色建议

根据 App 类型选择基础色：

| App 类型 | 推荐配色 | 示例 Emoji/符号 |
|---------|---------|---------------|
| 开发工具 | 蓝紫渐变 | 🔧 ⚙️ `</>` |
| 生产力工具 | 绿色/青色 | ✅ 📋 📊 |
| 媒体/内容 | 橙红渐变 | 🎵 📷 🎬 |
| 通信/社交 | 蓝色 | 💬 📨 |
| 安全/隐私 | 深色 | 🔒 🛡️ |
| 财务/数据 | 金色/绿色 | 💰 📈 |
| 系统工具 | 灰色/银色 | ⚡ 🖥️ |

## 注意事项

1. macOS 图标标准: 1024x1024px，PNG 格式
2. 圆角由系统自动裁切，但预留圆角空间看起来更好
3. 不需要做阴影，系统会自动加
4. Electron 项目直接用 PNG，electron-builder 会自动转换
5. Swift 项目需要转为 .icns 并放入 Resources 目录
