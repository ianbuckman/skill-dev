import SwiftUI

/// Renders a `SpriteFrame` as a pixel grid using Canvas for high-performance drawing.
struct PixelGridView: View {
    let frame: SpriteFrame
    var pixelSize: CGFloat = 4
    var flipped: Bool = false

    var body: some View {
        let gridSize = CGFloat(SpriteFrame.size)
        let totalSize = gridSize * pixelSize

        Canvas { context, _ in
            for row in 0..<SpriteFrame.size {
                for col in 0..<SpriteFrame.size {
                    let pixel = frame.pixels[row][col]
                    guard pixel != .clear else { continue }

                    let drawCol = flipped ? (SpriteFrame.size - 1 - col) : col
                    let rect = CGRect(
                        x: CGFloat(drawCol) * pixelSize,
                        y: CGFloat(row) * pixelSize,
                        width: pixelSize,
                        height: pixelSize
                    )
                    context.fill(Path(rect), with: .color(pixel.color))
                }
            }
        }
        .frame(width: totalSize, height: totalSize)
    }
}
