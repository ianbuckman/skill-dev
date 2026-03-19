import AppKit

@MainActor
final class FreezeOverlay {
    private var frozenWindow: NSWindow?
    private var frozenImage: CGImage?
    private var areaSelector: AreaSelectionOverlay?

    func freeze(completion: @escaping (CGRect?) -> Void) {
        Task {
            do {
                // Capture current screen
                let captureService = ScreenCaptureService()
                let image = try await captureService.captureFullscreen()
                self.frozenImage = image

                guard let screen = NSScreen.main else {
                    completion(nil)
                    return
                }

                // Create a window covering the entire screen with the frozen image
                let window = NSWindow(
                    contentRect: screen.frame,
                    styleMask: .borderless,
                    backing: .buffered,
                    defer: false
                )
                window.level = .screenSaver
                window.isOpaque = true
                window.backgroundColor = .black
                window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

                let imageView = NSImageView(frame: screen.frame)
                imageView.image = NSImage(cgImage: image, size: screen.frame.size)
                imageView.imageScaling = .scaleAxesIndependently
                window.contentView = imageView
                window.makeKeyAndOrderFront(nil)

                self.frozenWindow = window

                // Now show area selector on top
                let selector = AreaSelectionOverlay()
                selector.show { [weak self] rect in
                    self?.unfreeze()
                    completion(rect)
                }
                self.areaSelector = selector

            } catch {
                completion(nil)
            }
        }
    }

    func unfreeze() {
        areaSelector?.hide()
        areaSelector = nil
        frozenWindow?.orderOut(nil)
        frozenWindow = nil
        frozenImage = nil
    }
}
