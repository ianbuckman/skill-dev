import AVFoundation
import ScreenCaptureKit

@MainActor
final class ScreenRecordingService: NSObject {
    private var stream: SCStream?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var isRecording = false
    private var startTime: CMTime?
    private var outputURL: URL?
    private var streamOutput: RecordingStreamOutput?

    var onRecordingStarted: (() -> Void)?
    var onRecordingStopped: ((URL) -> Void)?
    var onError: ((Error) -> Void)?

    func startRecording(
        area: CGRect? = nil,
        windowID: CGWindowID? = nil,
        config: RecordingConfig,
        outputDirectory: String
    ) async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        let filter: SCContentFilter
        if let windowID = windowID,
           let window = content.windows.first(where: { $0.windowID == windowID }) {
            filter = SCContentFilter(desktopIndependentWindow: window)
        } else if let display = content.displays.first {
            filter = SCContentFilter(display: display, excludingWindows: [])
        } else {
            throw RecordingError.noDisplay
        }

        let streamConfig = SCStreamConfiguration()
        streamConfig.showsCursor = config.showCursor

        // Set resolution
        if let screen = NSScreen.main {
            let scale: CGFloat = 2
            if let area = area {
                streamConfig.width = Int(area.width * scale)
                streamConfig.height = Int(area.height * scale)
                streamConfig.sourceRect = area
            } else {
                streamConfig.width = Int(screen.frame.width * scale)
                streamConfig.height = Int(screen.frame.height * scale)
            }
        }

        // Set FPS
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(config.fps))

        // Audio
        if config.captureSystemAudio {
            streamConfig.capturesAudio = true
            streamConfig.channelCount = 2
            streamConfig.sampleRate = 48000
        }

        // Setup asset writer
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "SnapCraft_\(formatter.string(from: Date())).mp4"
        let url = URL(fileURLWithPath: outputDirectory).appendingPathComponent(filename)
        self.outputURL = url

        let writer = try AVAssetWriter(url: url, fileType: .mp4)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: streamConfig.width,
            AVVideoHeightKey: streamConfig.height,
            AVVideoCompressionPropertiesKey: [
                AVVideoAverageBitRateKey: qualityBitrate(config.quality, width: streamConfig.width, height: streamConfig.height),
                AVVideoExpectedSourceFrameRateKey: config.fps
            ]
        ]

        let vInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        vInput.expectsMediaDataInRealTime = true
        writer.add(vInput)
        self.videoInput = vInput

        if config.captureSystemAudio || config.captureMicrophone {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 48000,
                AVNumberOfChannelsKey: config.captureSystemAudio ? 2 : 1,
                AVEncoderBitRateKey: 128000
            ]
            let aInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            aInput.expectsMediaDataInRealTime = true
            writer.add(aInput)
            self.audioInput = aInput
        }

        self.assetWriter = writer

        // Start stream
        let output = RecordingStreamOutput()
        output.onVideoSample = { [weak self] sampleBuffer in
            self?.handleVideoSample(sampleBuffer)
        }
        output.onAudioSample = { [weak self] sampleBuffer in
            self?.handleAudioSample(sampleBuffer)
        }
        self.streamOutput = output

        let scStream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
        try scStream.addStreamOutput(output, type: .screen, sampleHandlerQueue: .global(qos: .userInitiated))
        if config.captureSystemAudio {
            try scStream.addStreamOutput(output, type: .audio, sampleHandlerQueue: .global(qos: .userInitiated))
        }

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        self.startTime = nil

        try await scStream.startCapture()
        self.stream = scStream
        self.isRecording = true
        onRecordingStarted?()
    }

    func stopRecording() async {
        guard isRecording else { return }
        isRecording = false

        do {
            try await stream?.stopCapture()
        } catch {
            print("Error stopping capture: \(error)")
        }
        stream = nil
        streamOutput = nil

        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        await assetWriter?.finishWriting()

        if let url = outputURL {
            onRecordingStopped?(url)
        }

        assetWriter = nil
        videoInput = nil
        audioInput = nil
        startTime = nil
    }

    private nonisolated func handleVideoSample(_ sampleBuffer: CMSampleBuffer) {
        guard sampleBuffer.isValid else { return }
        Task { @MainActor in
            guard isRecording, let videoInput = videoInput, videoInput.isReadyForMoreMediaData else { return }

            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if startTime == nil {
                startTime = timestamp
            }

            let adjustedBuffer = adjustTimestamp(sampleBuffer, offset: startTime!)
            if let adjusted = adjustedBuffer {
                videoInput.append(adjusted)
            }
        }
    }

    private nonisolated func handleAudioSample(_ sampleBuffer: CMSampleBuffer) {
        guard sampleBuffer.isValid else { return }
        Task { @MainActor in
            guard isRecording, let audioInput = audioInput, audioInput.isReadyForMoreMediaData else { return }
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            if let start = startTime {
                let adjusted = adjustTimestamp(sampleBuffer, offset: start)
                if let adj = adjusted {
                    audioInput.append(adj)
                }
            }
        }
    }

    private nonisolated func adjustTimestamp(_ buffer: CMSampleBuffer, offset: CMTime) -> CMSampleBuffer? {
        let pts = CMSampleBufferGetPresentationTimeStamp(buffer)
        let adjusted = CMTimeSubtract(pts, offset)
        if adjusted.seconds < 0 { return nil }

        var timingInfo = CMSampleTimingInfo(
            duration: CMSampleBufferGetDuration(buffer),
            presentationTimeStamp: adjusted,
            decodeTimeStamp: .invalid
        )

        var newBuffer: CMSampleBuffer?
        CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: buffer,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleBufferOut: &newBuffer
        )
        return newBuffer
    }

    private func qualityBitrate(_ quality: VideoQuality, width: Int, height: Int) -> Int {
        let pixels = width * height
        switch quality {
        case .low: return pixels * 2
        case .medium: return pixels * 4
        case .high: return pixels * 8
        }
    }
}

enum RecordingError: Error, LocalizedError {
    case noDisplay
    case writerFailed
    case alreadyRecording

    var errorDescription: String? {
        switch self {
        case .noDisplay: return "No display found"
        case .writerFailed: return "Failed to create video writer"
        case .alreadyRecording: return "Already recording"
        }
    }
}

final class RecordingStreamOutput: NSObject, SCStreamOutput, @unchecked Sendable {
    var onVideoSample: ((CMSampleBuffer) -> Void)?
    var onAudioSample: ((CMSampleBuffer) -> Void)?

    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of type: SCStreamOutputType) {
        switch type {
        case .screen:
            onVideoSample?(sampleBuffer)
        case .audio:
            onAudioSample?(sampleBuffer)
        @unknown default:
            break
        }
    }
}
