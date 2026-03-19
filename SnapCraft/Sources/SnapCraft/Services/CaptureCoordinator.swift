import AppKit

@MainActor
final class CaptureCoordinator {
    let appState: AppState
    let captureService = ScreenCaptureService()
    let scrollCaptureService = ScrollCaptureService()
    let recordingService = ScreenRecordingService()
    let gifEncoder = GifEncoderService()
    let ocrService = OCRService()
    let historyService = HistoryService()
    let fileNamingService = FileNamingService()
    let desktopIconService = DesktopIconService()
    let presetService = PresetService()

    let areaSelector = AreaSelectionOverlay()
    let windowPicker = WindowPickerOverlay()
    let freezeOverlay = FreezeOverlay()
    let timerOverlay = TimerCountdownOverlay()
    let allInOneController = AllInOneOverlayController()
    let quickAccessController = QuickAccessOverlayController()
    let pinController = PinWindowController()
    let annotationController = AnnotationWindowController()

    init(appState: AppState) {
        self.appState = appState
        setupQuickAccessCallbacks()
    }

    // MARK: - Capture Actions

    func performCapture(mode: CaptureMode) {
        switch mode {
        case .area:
            captureArea()
        case .window:
            captureWindow()
        case .fullscreen:
            captureFullscreen()
        case .scrolling:
            captureScrolling()
        case .timed:
            captureTimed()
        case .freeze:
            captureFreeze()
        case .allInOne:
            showAllInOne()
        case .ocr:
            performOCR()
        }
    }

    func startRecording(mode: RecordingMode) {
        switch mode {
        case .video:
            startVideoRecording()
        case .gif:
            startGifRecording()
        }
    }

    func stopRecording() {
        Task {
            await recordingService.stopRecording()
            appState.isRecording = false
        }
    }

    // MARK: - Screenshot Modes

    private func captureArea() {
        areaSelector.show { [weak self] rect in
            guard let self, let rect else { return }
            Task {
                do {
                    let image = try await self.captureService.captureArea(rect: rect)
                    self.handleCapturedImage(image, type: .screenshot)
                } catch {
                    print("Area capture failed: \(error)")
                }
            }
        }
    }

    private func captureWindow() {
        windowPicker.show { [weak self] windowID in
            guard let self, let windowID else { return }
            Task {
                do {
                    let image = try await self.captureService.captureWindow(windowID: windowID)
                    self.handleCapturedImage(image, type: .screenshot)
                } catch {
                    print("Window capture failed: \(error)")
                }
            }
        }
    }

    private func captureFullscreen() {
        Task {
            do {
                let image = try await captureService.captureFullscreen()
                handleCapturedImage(image, type: .screenshot)
            } catch {
                print("Fullscreen capture failed: \(error)")
            }
        }
    }

    private func captureScrolling() {
        areaSelector.show { [weak self] rect in
            guard let self, let rect else { return }
            Task {
                do {
                    let image = try await self.scrollCaptureService.captureScrolling(rect: rect)
                    self.handleCapturedImage(image, type: .screenshot)
                } catch {
                    print("Scrolling capture failed: \(error)")
                }
            }
        }
    }

    private func captureTimed() {
        let delay = UserDefaults.standard.integer(forKey: "timerDelay")
        let seconds = delay > 0 ? delay : 3

        timerOverlay.show(seconds: seconds) { [weak self] in
            self?.captureFullscreen()
        }
    }

    private func captureFreeze() {
        freezeOverlay.freeze { [weak self] rect in
            guard let self, let rect else { return }
            Task {
                do {
                    let image = try await self.captureService.captureArea(rect: rect)
                    self.handleCapturedImage(image, type: .screenshot)
                } catch {
                    print("Freeze capture failed: \(error)")
                }
            }
        }
    }

    private func showAllInOne() {
        allInOneController.show(
            onModeSelected: { [weak self] mode in
                self?.performCapture(mode: mode)
            },
            onRecordingSelected: { [weak self] mode in
                self?.startRecording(mode: mode)
            }
        )
    }

    private func performOCR() {
        areaSelector.show { [weak self] rect in
            guard let self, let rect else { return }
            Task {
                do {
                    let image = try await self.captureService.captureArea(rect: rect)
                    let text = try await self.ocrService.recognizeAndCopy(from: image)
                    if text.isEmpty {
                        print("No text recognized")
                    }
                } catch {
                    print("OCR failed: \(error)")
                }
            }
        }
    }

    // MARK: - Recording

    private func startVideoRecording() {
        appState.isRecording = true
        let config = appState.recordingConfig
        let saveDir = UserDefaults.standard.string(forKey: "saveDirectory") ?? NSHomeDirectory() + "/Desktop"

        if config.hideDesktopIcons {
            desktopIconService.hideDesktopIcons()
        }

        recordingService.onRecordingStopped = { [weak self] url in
            guard let self else { return }
            if config.hideDesktopIcons {
                self.desktopIconService.showDesktopIcons()
            }
            self.handleRecordedVideo(url: url)
        }

        Task {
            do {
                try await recordingService.startRecording(config: config, outputDirectory: saveDir)
            } catch {
                print("Recording failed: \(error)")
                appState.isRecording = false
            }
        }
    }

    private func startGifRecording() {
        // Use video recording internally, then convert to GIF
        appState.isRecording = true
        appState.recordingConfig.mode = .gif
        let saveDir = UserDefaults.standard.string(forKey: "saveDirectory") ?? NSHomeDirectory() + "/Desktop"

        recordingService.onRecordingStopped = { [weak self] url in
            guard let self else { return }
            Task {
                let gifPath = self.fileNamingService.fullPath(directory: saveDir, type: .gif, format: "gif")
                do {
                    let gifURL = try await self.gifEncoder.encodeVideoToGIF(videoURL: url, outputPath: gifPath)
                    try? FileManager.default.removeItem(at: url) // Remove temp MP4
                    self.handleRecordedGIF(url: gifURL)
                } catch {
                    print("GIF encoding failed: \(error)")
                }
            }
        }

        Task {
            do {
                var config = appState.recordingConfig
                config.fps = 15 // Lower FPS for GIF
                try await recordingService.startRecording(config: config, outputDirectory: NSTemporaryDirectory())
            } catch {
                print("GIF recording failed: \(error)")
                appState.isRecording = false
            }
        }
    }

    // MARK: - Handle Results

    private func handleCapturedImage(_ cgImage: CGImage, type: CaptureType) {
        let nsImage = NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        appState.lastCapturedImage = nsImage

        // Auto-copy to clipboard
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([nsImage])

        // Save to file
        let saveDir = UserDefaults.standard.string(forKey: "saveDirectory") ?? NSHomeDirectory() + "/Desktop"
        let format: ImageFormat = UserDefaults.standard.string(forKey: "imageFormat") == "JPG" ? .jpg : .png

        do {
            let path = try captureService.saveImage(cgImage, format: format, to: saveDir)
            appState.lastCapturedFilePath = path

            // Add to history
            let thumbnailPath = historyService.generateThumbnail(for: nsImage, itemID: UUID())
            let fileSize = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int64) ?? 0
            let historyItem = CaptureHistoryItem(type: type, filePath: path, thumbnailPath: thumbnailPath, fileSize: fileSize)
            historyService.addItem(historyItem)

            // Show quick access
            quickAccessController.show(image: nsImage, filePath: path)
        } catch {
            print("Failed to save: \(error)")
        }
    }

    private func handleRecordedVideo(url: URL) {
        appState.isRecording = false
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        let historyItem = CaptureHistoryItem(type: .recording, filePath: url.path, fileSize: fileSize)
        historyService.addItem(historyItem)

        // Show thumbnail from first frame
        if let thumbnail = generateVideoThumbnail(url: url) {
            quickAccessController.show(image: thumbnail, filePath: url.path)
        }
    }

    private func handleRecordedGIF(url: URL) {
        appState.isRecording = false
        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        let historyItem = CaptureHistoryItem(type: .gif, filePath: url.path, fileSize: fileSize)
        historyService.addItem(historyItem)
    }

    private func generateVideoThumbnail(url: URL) -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return NSImage(cgImage: cgImage, size: CGSize(width: cgImage.width / 2, height: cgImage.height / 2))
        } catch {
            return nil
        }
    }

    // MARK: - Quick Access Callbacks

    private func setupQuickAccessCallbacks() {
        quickAccessController.onAnnotate = { [weak self] image in
            self?.annotationController.show(image: image) { annotatedImage in
                // Save annotated image
                let pb = NSPasteboard.general
                pb.clearContents()
                pb.writeObjects([annotatedImage])
            }
        }

        quickAccessController.onPin = { [weak self] image in
            self?.pinController.pin(image: image)
        }
    }

    // MARK: - Hotkey Registration

    func registerDefaultHotkeys() {
        let hotkeyService = HotkeyService.shared
        let mods = CarbonModifier.command | CarbonModifier.shift

        hotkeyService.register(keyCode: CarbonKeyCode.key3, modifiers: mods) { [weak self] in
            self?.performCapture(mode: .fullscreen)
        }
        hotkeyService.register(keyCode: CarbonKeyCode.key4, modifiers: mods) { [weak self] in
            self?.performCapture(mode: .area)
        }
        hotkeyService.register(keyCode: CarbonKeyCode.key5, modifiers: mods) { [weak self] in
            self?.performCapture(mode: .window)
        }
        hotkeyService.register(keyCode: CarbonKeyCode.key6, modifiers: mods) { [weak self] in
            self?.performCapture(mode: .scrolling)
        }
        hotkeyService.register(keyCode: CarbonKeyCode.key7, modifiers: mods) { [weak self] in
            self?.startRecording(mode: .video)
        }
        hotkeyService.register(keyCode: CarbonKeyCode.key8, modifiers: mods) { [weak self] in
            self?.startRecording(mode: .gif)
        }
        hotkeyService.register(keyCode: CarbonKeyCode.key9, modifiers: mods) { [weak self] in
            self?.performCapture(mode: .ocr)
        }
        hotkeyService.register(keyCode: CarbonKeyCode.key0, modifiers: mods) { [weak self] in
            self?.performCapture(mode: .allInOne)
        }
    }
}

import AVFoundation
