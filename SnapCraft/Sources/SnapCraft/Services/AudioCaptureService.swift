import AVFoundation

@MainActor
final class AudioCaptureService {
    private var captureSession: AVCaptureSession?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var onAudioBuffer: ((CMSampleBuffer) -> Void)?

    func startMicrophoneCapture(onBuffer: @escaping (CMSampleBuffer) -> Void) throws {
        self.onAudioBuffer = onBuffer

        let session = AVCaptureSession()
        session.beginConfiguration()

        guard let device = AVCaptureDevice.default(for: .audio) else {
            throw AudioError.noMicrophone
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else {
            throw AudioError.cannotAddInput
        }
        session.addInput(input)

        let output = AVCaptureAudioDataOutput()
        let delegate = AudioOutputDelegate()
        delegate.onSampleBuffer = onBuffer
        output.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "com.snapcraft.audio"))

        guard session.canAddOutput(output) else {
            throw AudioError.cannotAddOutput
        }
        session.addOutput(output)

        session.commitConfiguration()
        session.startRunning()

        self.captureSession = session
        self.audioOutput = output
    }

    func stopMicrophoneCapture() {
        captureSession?.stopRunning()
        captureSession = nil
        audioOutput = nil
        onAudioBuffer = nil
    }

    static func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }
}

private final class AudioOutputDelegate: NSObject, AVCaptureAudioDataOutputSampleBufferDelegate, @unchecked Sendable {
    var onSampleBuffer: ((CMSampleBuffer) -> Void)?

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        onSampleBuffer?(sampleBuffer)
    }
}

enum AudioError: Error, LocalizedError {
    case noMicrophone
    case cannotAddInput
    case cannotAddOutput

    var errorDescription: String? {
        switch self {
        case .noMicrophone: return "No microphone found"
        case .cannotAddInput: return "Cannot add audio input"
        case .cannotAddOutput: return "Cannot add audio output"
        }
    }
}
