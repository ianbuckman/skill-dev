import AppKit
import ScreenCaptureKit

@MainActor
final class ScreenCaptureService {

    // MARK: - Fullscreen Capture

    func captureFullscreen(display: CGDirectDisplayID? = nil) async throws -> CGImage {
        let displayID = display ?? CGMainDisplayID()
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let scDisplay = content.displays.first(where: { $0.displayID == displayID }) else {
            throw CaptureError.displayNotFound
        }

        let filter = SCContentFilter(display: scDisplay, excludingWindows: [])
        let config = SCStreamConfiguration()
        config.width = scDisplay.width
        config.height = scDisplay.height
        config.captureResolution = .best
        config.showsCursor = UserDefaults.standard.bool(forKey: "showCursorInCapture")

        return try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
    }

    // MARK: - Area Capture

    func captureArea(rect: CGRect, display: CGDirectDisplayID? = nil) async throws -> CGImage {
        let fullImage = try await captureFullscreen(display: display)
        let scale = CGFloat(fullImage.width) / NSScreen.main!.frame.width

        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.width * scale,
            height: rect.height * scale
        )

        guard let cropped = fullImage.cropping(to: scaledRect) else {
            throw CaptureError.cropFailed
        }
        return cropped
    }

    // MARK: - Window Capture

    func captureWindow(windowID: CGWindowID, background: WindowBackground = .none) async throws -> CGImage {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let window = content.windows.first(where: { $0.windowID == windowID }) else {
            throw CaptureError.windowNotFound
        }

        let filter = SCContentFilter(desktopIndependentWindow: window)
        let config = SCStreamConfiguration()
        config.width = Int(window.frame.width) * 2
        config.height = Int(window.frame.height) * 2
        config.showsCursor = false
        config.captureResolution = .best

        let isOpaque: Bool
        if case .transparent = background {
            isOpaque = false
        } else {
            isOpaque = true
        }
        config.shouldBeOpaque = isOpaque

        let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)

        switch background {
        case .none, .transparent:
            return image
        case .solidColor(let color):
            return addBackground(to: image, color: color)
        case .wallpaper:
            return image // Desktop background is included by default
        }
    }

    // MARK: - List Windows

    func listWindows() async throws -> [(id: CGWindowID, title: String, appName: String, frame: CGRect)] {
        let content = try await SCShareableContent.excludingDesktopWindows(true, onScreenWindowsOnly: true)
        return content.windows.compactMap { window in
            guard let app = window.owningApplication,
                  !app.bundleIdentifier.hasPrefix("com.apple.WindowManager"),
                  window.frame.width > 50, window.frame.height > 50 else {
                return nil
            }
            return (
                id: window.windowID,
                title: window.title ?? app.applicationName,
                appName: app.applicationName,
                frame: window.frame
            )
        }
    }

    // MARK: - Helpers

    private func addBackground(to image: CGImage, color: NSColor) -> CGImage {
        let padding: CGFloat = 40
        let width = CGFloat(image.width) + padding * 2
        let height = CGFloat(image.height) + padding * 2

        let context = CGContext(
            data: nil,
            width: Int(width),
            height: Int(height),
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )!

        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw shadow
        context.setShadow(offset: CGSize(width: 0, height: -10), blur: 30, color: NSColor.black.withAlphaComponent(0.3).cgColor)
        context.draw(image, in: CGRect(x: padding, y: padding, width: CGFloat(image.width), height: CGFloat(image.height)))

        return context.makeImage()!
    }

    // MARK: - Save

    func saveImage(_ image: CGImage, format: ImageFormat, to directory: String, namingPattern: String? = nil) throws -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        let filename = namingPattern ?? "SnapCraft_\(timestamp)"
        let ext = format == .png ? "png" : "jpg"
        let path = (directory as NSString).appendingPathComponent("\(filename).\(ext)")

        let url = URL(fileURLWithPath: path)
        let rep = NSBitmapImageRep(cgImage: image)

        let data: Data?
        switch format {
        case .png:
            data = rep.representation(using: .png, properties: [:])
        case .jpg:
            data = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.9])
        }

        guard let imageData = data else {
            throw CaptureError.saveFailed
        }

        try imageData.write(to: url)
        return path
    }
}

enum WindowBackground {
    case none
    case transparent
    case solidColor(NSColor)
    case wallpaper
}

enum CaptureError: Error, LocalizedError {
    case displayNotFound
    case windowNotFound
    case cropFailed
    case saveFailed
    case permissionDenied
    case scrollCaptureTimeout

    var errorDescription: String? {
        switch self {
        case .displayNotFound: return "Display not found"
        case .windowNotFound: return "Window not found"
        case .cropFailed: return "Failed to crop image"
        case .saveFailed: return "Failed to save image"
        case .permissionDenied: return "Screen capture permission denied"
        case .scrollCaptureTimeout: return "Scrolling capture timed out"
        }
    }
}
