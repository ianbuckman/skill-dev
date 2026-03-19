import AVFoundation
import AppKit

@MainActor
final class CameraCaptureService: NSObject {
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var outputDelegate: CameraOutputDelegate?
    var latestFrame: CGImage?

    var shape: CameraShape = .circle
    var size: CGFloat = 150

    func startCapture() throws {
        let session = AVCaptureSession()
        session.sessionPreset = .medium

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
              ?? AVCaptureDevice.default(for: .video) else {
            throw CameraError.noCamera
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw CameraError.cannotAddInput
        }
        session.addInput(input)

        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        let delegate = CameraOutputDelegate()
        delegate.onFrame = { [weak self] image in
            Task { @MainActor in
                self?.latestFrame = image
            }
        }
        output.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "com.snapcraft.camera"))

        guard session.canAddOutput(output) else {
            throw CameraError.cannotAddOutput
        }
        session.addOutput(output)

        session.startRunning()

        self.captureSession = session
        self.videoOutput = output
        self.outputDelegate = delegate
    }

    func stopCapture() {
        captureSession?.stopRunning()
        captureSession = nil
        videoOutput = nil
        outputDelegate = nil
        latestFrame = nil
    }

    func compositeFrame(onto background: CGImage, position: CameraPosition) -> CGImage {
        guard let cameraFrame = latestFrame else { return background }

        let bgWidth = CGFloat(background.width)
        let bgHeight = CGFloat(background.height)
        let camSize = size * 2 // Retina

        let context = CGContext(
            data: nil,
            width: Int(bgWidth),
            height: Int(bgHeight),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )!

        // Draw background
        context.draw(background, in: CGRect(x: 0, y: 0, width: bgWidth, height: bgHeight))

        // Calculate position
        let margin: CGFloat = 20
        let camRect: CGRect
        switch position {
        case .topLeft:
            camRect = CGRect(x: margin, y: bgHeight - camSize - margin, width: camSize, height: camSize)
        case .topRight:
            camRect = CGRect(x: bgWidth - camSize - margin, y: bgHeight - camSize - margin, width: camSize, height: camSize)
        case .bottomLeft:
            camRect = CGRect(x: margin, y: margin, width: camSize, height: camSize)
        case .bottomRight:
            camRect = CGRect(x: bgWidth - camSize - margin, y: margin, width: camSize, height: camSize)
        }

        // Clip to shape
        switch shape {
        case .circle:
            context.addEllipse(in: camRect)
            context.clip()
        case .roundedRect:
            let path = CGPath(roundedRect: camRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
            context.addPath(path)
            context.clip()
        case .rectangle:
            break // No clipping needed
        }

        // Draw camera frame
        context.draw(cameraFrame, in: camRect)

        // Reset clip
        context.resetClip()

        // Draw border
        context.setStrokeColor(NSColor.white.cgColor)
        context.setLineWidth(3)
        switch shape {
        case .circle:
            context.strokeEllipse(in: camRect)
        case .roundedRect:
            let path = CGPath(roundedRect: camRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
            context.addPath(path)
            context.strokePath()
        case .rectangle:
            context.stroke(camRect)
        }

        return context.makeImage()!
    }

    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .video) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

private final class CameraOutputDelegate: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    var onFrame: ((CGImage) -> Void)?

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        onFrame?(cgImage)
    }
}

enum CameraError: Error, LocalizedError {
    case noCamera
    case cannotAddInput
    case cannotAddOutput

    var errorDescription: String? {
        switch self {
        case .noCamera: return "No camera found"
        case .cannotAddInput: return "Cannot add camera input"
        case .cannotAddOutput: return "Cannot add camera output"
        }
    }
}
