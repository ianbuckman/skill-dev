import SwiftUI
import AVFoundation
import AVKit

struct VideoEditorView: View {
    let videoURL: URL
    var onExport: (URL) -> Void

    @State private var player: AVPlayer?
    @State private var duration: Double = 0
    @State private var currentTime: Double = 0
    @State private var trimStart: Double = 0
    @State private var trimEnd: Double = 0
    @State private var isPlaying = false
    @State private var volume: Float = 1.0
    @State private var isExporting = false

    var body: some View {
        VStack(spacing: 12) {
            PlayerView()
            TimelineView()
            ControlsView()
            ExportView()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
        .task {
            await loadVideo()
        }
    }

    @ViewBuilder
    private func PlayerView() -> some View {
        if let player = player {
            VideoPlayer(player: player)
                .frame(maxHeight: 300)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            ProgressView()
                .frame(height: 300)
        }
    }

    @ViewBuilder
    private func TimelineView() -> some View {
        VStack(spacing: 4) {
            // Trim range slider
            HStack {
                Text(formatTime(trimStart))
                    .font(.caption.monospacedDigit())
                Slider(value: $trimStart, in: 0...duration)
                    .onChange(of: trimStart) { _, newValue in
                        if newValue > trimEnd { trimEnd = newValue }
                        seekTo(newValue)
                    }
                Text("Start")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                Text(formatTime(trimEnd))
                    .font(.caption.monospacedDigit())
                Slider(value: $trimEnd, in: 0...duration)
                    .onChange(of: trimEnd) { _, newValue in
                        if newValue < trimStart { trimStart = newValue }
                        seekTo(newValue)
                    }
                Text("End")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Duration: \(formatTime(trimEnd - trimStart))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func ControlsView() -> some View {
        HStack(spacing: 16) {
            Button {
                togglePlayPause()
            } label: {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
            }
            .buttonStyle(.plain)

            HStack(spacing: 4) {
                Image(systemName: volume > 0 ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    .font(.caption)
                Slider(value: $volume, in: 0...1)
                    .frame(width: 80)
                    .onChange(of: volume) { _, newValue in
                        player?.volume = newValue
                    }
            }

            Spacer()

            Button("Reset Trim") {
                trimStart = 0
                trimEnd = duration
            }
        }
    }

    @ViewBuilder
    private func ExportView() -> some View {
        HStack {
            if isExporting {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Exporting...")
                    .font(.caption)
            }
            Spacer()
            Button("Export Trimmed Video") {
                Task { await exportTrimmed() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isExporting)
        }
    }

    private func loadVideo() async {
        let asset = AVURLAsset(url: videoURL)
        do {
            let dur = try await asset.load(.duration)
            duration = dur.seconds
            trimEnd = dur.seconds
            player = AVPlayer(url: videoURL)
        } catch {
            print("Failed to load video: \(error)")
        }
    }

    private func togglePlayPause() {
        guard let player = player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    private func seekTo(_ time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    private func exportTrimmed() async {
        isExporting = true
        defer { isExporting = false }

        let asset = AVURLAsset(url: videoURL)
        let startTime = CMTime(seconds: trimStart, preferredTimescale: 600)
        let endTime = CMTime(seconds: trimEnd, preferredTimescale: 600)
        let timeRange = CMTimeRange(start: startTime, end: endTime)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            return
        }

        let outputURL = videoURL.deletingLastPathComponent()
            .appendingPathComponent("trimmed_\(videoURL.lastPathComponent)")

        try? FileManager.default.removeItem(at: outputURL)

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.timeRange = timeRange

        await exportSession.export()

        if exportSession.status == .completed {
            onExport(outputURL)
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

struct RecordingControlBar: View {
    let isRecording: Bool
    let duration: TimeInterval
    let onStop: () -> Void
    let onPause: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(.red)
                .frame(width: 10, height: 10)
                .opacity(isRecording ? 1 : 0.3)

            Text(formatDuration(duration))
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(.white)

            Spacer()

            Button(action: onStop) {
                Image(systemName: "stop.fill")
                    .foregroundStyle(.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .environment(\.colorScheme, .dark)
        .clipShape(Capsule())
        .shadow(radius: 4)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
