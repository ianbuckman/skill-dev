import AppKit
import ScreenCaptureKit

@MainActor
final class ScrollCaptureService {
    private let captureService = ScreenCaptureService()
    private let scrollDelay: TimeInterval = 0.3
    private let maxScrollAttempts = 50
    private let overlapPixels: CGFloat = 50

    func captureScrolling(rect: CGRect) async throws -> CGImage {
        var images: [CGImage] = []
        var previousHash: Int = 0

        for _ in 0..<maxScrollAttempts {
            // Capture current visible area
            let image = try await captureService.captureArea(rect: rect)
            let currentHash = imageHash(image)

            // Check if we've reached the end (same content as before)
            if currentHash == previousHash && !images.isEmpty {
                break
            }

            images.append(image)
            previousHash = currentHash

            // Scroll down
            let scrollPoint = CGPoint(x: rect.midX, y: rect.midY)
            simulateScroll(at: scrollPoint, deltaY: -Int32(rect.height - overlapPixels))

            // Wait for content to settle
            try await Task.sleep(for: .milliseconds(Int(scrollDelay * 1000)))
        }

        guard !images.isEmpty else {
            throw CaptureError.scrollCaptureTimeout
        }

        if images.count == 1 {
            return images[0]
        }

        return stitchImages(images)
    }

    private func simulateScroll(at point: CGPoint, deltaY: Int32) {
        if let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: deltaY,
            wheel2: 0,
            wheel3: 0
        ) {
            event.location = point
            event.post(tap: .cghidEventTap)
        }
    }

    private func stitchImages(_ images: [CGImage]) -> CGImage {
        guard let first = images.first else { fatalError("No images to stitch") }

        let width = first.width
        // Calculate total height accounting for overlap
        let overlapPx = Int(overlapPixels * 2) // Retina
        let totalHeight = first.height + (images.count - 1) * (first.height - overlapPx)

        let context = CGContext(
            data: nil,
            width: width,
            height: totalHeight,
            bitsPerComponent: first.bitsPerComponent,
            bytesPerRow: 0,
            space: first.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: first.bitmapInfo.rawValue
        )!

        var yOffset = totalHeight - first.height
        for (index, image) in images.enumerated() {
            let drawRect = CGRect(x: 0, y: yOffset, width: width, height: image.height)
            context.draw(image, in: drawRect)
            if index < images.count - 1 {
                yOffset -= (image.height - overlapPx)
            }
        }

        return context.makeImage()!
    }

    private func imageHash(_ image: CGImage) -> Int {
        // Simple hash based on a sample of pixels
        guard let data = image.dataProvider?.data,
              let bytes = CFDataGetBytePtr(data) else { return 0 }

        let length = CFDataGetLength(data)
        var hash = 0
        let step = max(1, length / 100)
        for i in stride(from: 0, to: length, by: step) {
            hash = hash &+ Int(bytes[i]) &* 31
        }
        return hash
    }
}
