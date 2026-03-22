import SwiftUI

extension EnvironmentValues {
    @Entry var pomodoroService: PomodoroService? = nil
}

// MARK: - PomodoroPopoverView

struct PomodoroPopoverView: View {
    @Environment(PetState.self) private var petState
    @Environment(\.pomodoroService) private var pomodoroService

    var body: some View {
        VStack(spacing: 12) {
            headerSection
            Divider()
            pomodoroStatusSection
            pomodoroControlSection
            Divider()
            todayStatsSection
            Divider()
            petControlSection
            Divider()
            quitSection
        }
        .padding()
        .frame(width: 240)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "cat.fill")
                .font(.title2)
            Text("DeskPet")
                .font(.headline)
        }
    }

    // MARK: - Pomodoro Status

    private var pomodoroStatusSection: some View {
        VStack(spacing: 8) {
            statusLabel
            timeDisplay
            progressRing
        }
    }

    private var statusLabel: some View {
        Group {
            switch petState.pomodoroState {
            case .working:
                Text("工作中 🔴")
                    .foregroundStyle(.red)
            case .breaking:
                Text("休息中 🟢")
                    .foregroundStyle(.green)
            case .idle:
                Text("空闲")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline.weight(.medium))
    }

    private var timeDisplay: some View {
        Text(formattedTime(petState.pomodoroTimeRemaining))
            .font(.system(size: 36, weight: .light, design: .monospaced))
            .contentTransition(.numericText())
    }

    private var progressRing: some View {
        let totalDuration: TimeInterval = petState.pomodoroState == .working ? 1500 : 300
        let progress: Double = petState.pomodoroState == .idle
            ? 0
            : 1.0 - (petState.pomodoroTimeRemaining / totalDuration)

        return ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
            Circle()
                .trim(from: 0, to: max(0, min(progress, 1)))
                .stroke(
                    petState.pomodoroState == .working ? Color.red : Color.green,
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 50, height: 50)
    }

    // MARK: - Pomodoro Controls

    private var pomodoroControlSection: some View {
        Group {
            switch petState.pomodoroState {
            case .idle:
                Button {
                    pomodoroService?.startPomodoro()
                } label: {
                    Label("开始专注", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .tint(.red)
            case .working, .breaking:
                HStack(spacing: 8) {
                    if petState.isPomodoroPaused {
                        Button {
                            pomodoroService?.resumePomodoro()
                        } label: {
                            Label("继续", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    } else {
                        Button {
                            pomodoroService?.pausePomodoro()
                        } label: {
                            Label("暂停", systemImage: "pause.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    Button {
                        pomodoroService?.skipPhase()
                    } label: {
                        Label("跳过", systemImage: "forward.fill")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        pomodoroService?.resetPomodoro()
                    } label: {
                        Label("重置", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                }
                .controlSize(.small)
            }
        }
    }

    // MARK: - Today Stats

    private var todayStatsSection: some View {
        VStack(spacing: 4) {
            Text("今日统计")
                .font(.subheadline.weight(.medium))
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack {
                Label("\(petState.pomodoroSessionCount) 个周期", systemImage: "checkmark.circle")
                Spacer()
                Label("\(petState.todayFocusMinutes) 分钟", systemImage: "clock")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    // MARK: - Pet Control

    private var petControlSection: some View {
        @Bindable var state = petState
        return Toggle(isOn: $state.isPetVisible) {
            Label("显示宠物", systemImage: "eye")
        }
        .toggleStyle(.switch)
        .controlSize(.small)
    }

    // MARK: - Quit

    private var quitSection: some View {
        Button {
            NSApplication.shared.terminate(nil)
        } label: {
            Text("退出 DeskPet")
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .keyboardShortcut("q")
    }

    // MARK: - Helpers

    private func formattedTime(_ interval: TimeInterval) -> String {
        let total = max(Int(interval), 0)
        let minutes = total / 60
        let seconds = total % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
