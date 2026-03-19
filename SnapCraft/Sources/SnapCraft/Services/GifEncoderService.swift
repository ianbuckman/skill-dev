import AVFoundation
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class GifEncoderService {
    private var frames: [CGImage] = []
    private var frameDuration: Double = 1.0 / 15.0 // 15 FPS default
    private var isCapturing = false
    private var captureTimer: Timer?

    var maxFrames = 600 // 40 seconds at 15 FPS
    var gifFPS: Int = 15 {
        didSet { frameDuration = 1.0 / Double(gifFPS) }
    }

    func addFrame(_ image: CGImage) {
        guard frames.count < maxFrames else { return }
        frames.append(image)
    }

    func encodeToGIF(outputPath: String, width: Int? = nil, height: Int? = nil) throws -> URL {
        guard !frames.isEmpty else {
            throw GifError.noFrames
        }

        let url = URL(fileURLWithPath: outputPath)
        guard let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.gif.identifier as CFString,
            frames.count,
            nil
        ) else {
            throw GifError.createFailed
        }

        // GIF properties
        let gifProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: 0 // infinite loop
            ]
        ]
        CGImageDestinationSetProperties(destination, gifProperties as CFDictionary)

        // Frame properties
        let frameProperties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFDelayTime as String: frameDuration,
                kCGImagePropertyGIFUnclampedDelayTime as String: frameDuration
            ]
        ]

        for frame in frames {
            let processedFrame: CGImage
            if let w = width, let h = height {
                processedFrame = resizeImage(frame, to: CGSize(width: w, height: h)) ?? frame
            } else {
                processedFrame = frame
            }
            CGImageDestinationAddImage(destination, processedFrame, frameProperties as CFDictionary)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw GifError.finalizeFailed
        }

        return url
    }

    func encodeVideoToGIF(videoURL: URL, outputPath: String, fps: Int = 15) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        let duration = try await asset.load(.duration)
        let totalSeconds = duration.seconds
        let frameCount = Int(totalSeconds * Double(fps))
        let frameDur = 1.0 / Double(fps)

        frames.removeAll()
        self.frameDuration = frameDur

        for i in 0..<frameCount {
            let time = CMTime(seconds: Double(i) * frameDur, preferredTimescale: 600)
            let (image, _) = try await generator.image(at: time)
            frames.append(image)
        }

        return try encodeToGIF(outputPath: outputPath)
    }

    func reset() {
        frames.removeAll()
    }

    private func resizeImage(_ image: CGImage, to size: CGSize) -> CGImage? {
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: image.bitsPerComponent,
            bytesPerRow: 0,
            space: image.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: image.bitmapInfo.rawValue
        )
        context?.interpolationQuality = .high
        context?.draw(image, in: CGRect(origin: .zero, size: size))
        return context?.makeImage()
    }
}

enum GifError: Error, LocalizedError {
    case noFrames
    case createFailed
    case finalizeFailed

    var errorDescription: String? {
        switch self {
        case .noFrames: return "No frames to encode"
        case .createFailed: return "Failed to create GIF destination"
        case .finalizeFailed: return "Failed to finalize GIF"
        }
    }
}
