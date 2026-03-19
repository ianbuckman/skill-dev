import SwiftUI

struct BackgroundToolView: View {
    let originalImage: NSImage
    var onExport: (NSImage) -> Void

    @State private var selectedBackground: BackgroundPreset = .gradient1
    @State private var padding: CGFloat = 40
    @State private var cornerRadius: CGFloat = 12
    @State private var aspectRatio: AspectRatioPreset = .original
    @State private var alignment: ImageAlignment = .center
    @State private var autoBalance = true

    var body: some View {
        HSplitView {
            PreviewPane()
            ControlsPane()
        }
        .frame(minWidth: 800, minHeight: 500)
    }

    @ViewBuilder
    private func PreviewPane() -> some View {
        VStack {
            Spacer()
            ComposedImageView(
                image: originalImage,
                background: selectedBackground,
                padding: padding,
                cornerRadius: cornerRadius
            )
            .frame(maxWidth: 500, maxHeight: 400)
            .shadow(radius: 8)
            Spacer()
        }
        .frame(minWidth: 500)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    @ViewBuilder
    private func ControlsPane() -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                BackgroundSection()
                Divider()
                LayoutSection()
                Divider()
                ExportSection()
            }
            .padding()
        }
        .frame(width: 260)
    }

    @ViewBuilder
    private func BackgroundSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Background")
                .font(.headline)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 8) {
                ForEach(BackgroundPreset.allCases) { preset in
                    Button {
                        selectedBackground = preset
                    } label: {
                        preset.preview
                            .frame(width: 50, height: 35)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(selectedBackground == preset ? Color.accentColor : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    @ViewBuilder
    private func LayoutSection() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Layout")
                .font(.headline)

            LabeledContent("Padding") {
                Slider(value: $padding, in: 0...120, step: 4)
            }

            LabeledContent("Corner Radius") {
                Slider(value: $cornerRadius, in: 0...32, step: 2)
            }

            Toggle("Auto Balance", isOn: $autoBalance)

            Picker("Aspect Ratio", selection: $aspectRatio) {
                ForEach(AspectRatioPreset.allCases) { ratio in
                    Text(ratio.displayName).tag(ratio)
                }
            }
        }
    }

    @ViewBuilder
    private func ExportSection() -> some View {
        VStack(spacing: 8) {
            Button("Export") {
                if let composed = composeImage() {
                    onExport(composed)
                }
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button("Copy to Clipboard") {
                if let composed = composeImage() {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.writeObjects([composed])
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private func composeImage() -> NSImage? {
        let imgSize = originalImage.size
        let totalWidth = imgSize.width + padding * 2
        let totalHeight = imgSize.height + padding * 2

        let result = NSImage(size: CGSize(width: totalWidth, height: totalHeight))
        result.lockFocus()

        // Draw background
        let bgRect = CGRect(origin: .zero, size: CGSize(width: totalWidth, height: totalHeight))
        selectedBackground.drawBackground(in: bgRect)

        // Draw image with corner radius
        let imageRect = CGRect(x: padding, y: padding, width: imgSize.width, height: imgSize.height)
        let path = NSBezierPath(roundedRect: imageRect, xRadius: cornerRadius, yRadius: cornerRadius)
        path.addClip()

        // Shadow
        let shadow = NSShadow()
        shadow.shadowOffset = CGSize(width: 0, height: -4)
        shadow.shadowBlurRadius = 20
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
        shadow.set()

        originalImage.draw(in: imageRect)

        result.unlockFocus()
        return result
    }
}

struct ComposedImageView: View {
    let image: NSImage
    let background: BackgroundPreset
    let padding: CGFloat
    let cornerRadius: CGFloat

    var body: some View {
        ZStack {
            background.preview
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .shadow(radius: 8)
                .padding(padding)
        }
        .aspectRatio(contentMode: .fit)
    }
}

enum BackgroundPreset: String, CaseIterable, Identifiable {
    case gradient1 = "Ocean"
    case gradient2 = "Sunset"
    case gradient3 = "Forest"
    case gradient4 = "Lavender"
    case gradient5 = "Rose"
    case gradient6 = "Midnight"
    case gradient7 = "Sky"
    case gradient8 = "Peach"
    case gradient9 = "Mint"
    case gradient10 = "Slate"
    case solidWhite = "White"
    case solidBlack = "Black"

    var id: String { rawValue }

    var colors: [Color] {
        switch self {
        case .gradient1: return [Color(red: 0.1, green: 0.4, blue: 0.8), Color(red: 0.2, green: 0.7, blue: 0.9)]
        case .gradient2: return [Color(red: 0.9, green: 0.4, blue: 0.2), Color(red: 0.95, green: 0.7, blue: 0.3)]
        case .gradient3: return [Color(red: 0.1, green: 0.6, blue: 0.3), Color(red: 0.3, green: 0.8, blue: 0.5)]
        case .gradient4: return [Color(red: 0.5, green: 0.3, blue: 0.8), Color(red: 0.7, green: 0.5, blue: 0.9)]
        case .gradient5: return [Color(red: 0.9, green: 0.3, blue: 0.5), Color(red: 0.95, green: 0.6, blue: 0.7)]
        case .gradient6: return [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.2, green: 0.2, blue: 0.5)]
        case .gradient7: return [Color(red: 0.4, green: 0.6, blue: 0.9), Color(red: 0.6, green: 0.8, blue: 1.0)]
        case .gradient8: return [Color(red: 1.0, green: 0.7, blue: 0.5), Color(red: 1.0, green: 0.85, blue: 0.7)]
        case .gradient9: return [Color(red: 0.3, green: 0.8, blue: 0.7), Color(red: 0.5, green: 0.9, blue: 0.8)]
        case .gradient10: return [Color(red: 0.4, green: 0.45, blue: 0.5), Color(red: 0.6, green: 0.65, blue: 0.7)]
        case .solidWhite: return [.white, .white]
        case .solidBlack: return [.black, .black]
        }
    }

    var preview: some View {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    func drawBackground(in rect: CGRect) {
        let nsColors = colors.map { NSColor($0) }
        if nsColors.count >= 2 {
            if let gradient = NSGradient(colors: nsColors) {
                gradient.draw(in: rect, angle: 135)
            }
        }
    }
}

enum AspectRatioPreset: String, CaseIterable, Identifiable {
    case original = "Original"
    case square = "1:1"
    case ratio16x9 = "16:9"
    case ratio4x3 = "4:3"
    case twitter = "Twitter"
    case instagram = "Instagram"

    var id: String { rawValue }
    var displayName: String { rawValue }
}

enum ImageAlignment: String, CaseIterable {
    case center = "Center"
    case topLeft = "Top Left"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomRight = "Bottom Right"
}
