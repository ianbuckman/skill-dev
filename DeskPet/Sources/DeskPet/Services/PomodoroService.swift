import Foundation
import UserNotifications

@MainActor
final class PomodoroService {
    private var timer: Timer?
    private let petState: PetState
    private var elapsedSecondsInWork: Int = 0

    private let workDuration: TimeInterval = 1500   // 25 minutes
    private let breakDuration: TimeInterval = 300    // 5 minutes

    init(petState: PetState) {
        self.petState = petState
        requestNotificationPermission()
    }

    // MARK: - Public API

    func startPomodoro() {
        elapsedSecondsInWork = 0
        petState.isPomodoroPaused = false
        petState.pomodoroTimeRemaining = workDuration
        petState.pomodoroState = .working
        startTimer()
    }

    func pausePomodoro() {
        guard !petState.isPomodoroPaused else { return }
        petState.isPomodoroPaused = true
        stopTimer()
    }

    func resumePomodoro() {
        guard petState.isPomodoroPaused else { return }
        petState.isPomodoroPaused = false
        startTimer()
    }

    func resetPomodoro() {
        petState.isPomodoroPaused = false
        elapsedSecondsInWork = 0
        stopTimer()
        petState.pomodoroState = .idle
        petState.pomodoroTimeRemaining = 0
    }

    func skipPhase() {
        switch petState.pomodoroState {
        case .working:
            completeWorkPhase()
        case .breaking:
            completeBreakPhase()
        case .idle:
            break
        }
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        petState.pomodoroTimeRemaining -= 1

        if petState.pomodoroState == .working {
            elapsedSecondsInWork += 1
            if elapsedSecondsInWork.isMultiple(of: 60) {
                petState.todayFocusMinutes += 1
                petState.persistStats()
            }
        }

        if petState.pomodoroTimeRemaining <= 0 {
            switch petState.pomodoroState {
            case .working:
                completeWorkPhase()
            case .breaking:
                completeBreakPhase()
            case .idle:
                stopTimer()
            }
        }
    }

    // MARK: - Phase transitions

    private func completeWorkPhase() {
        stopTimer()
        petState.pomodoroSessionCount += 1
        petState.persistStats()
        petState.pomodoroState = .breaking
        petState.pomodoroTimeRemaining = breakDuration
        elapsedSecondsInWork = 0
        sendNotification(
            title: "DeskPet",
            body: "休息时间！去喝杯水吧 🐱"
        )
        startTimer()
    }

    private func completeBreakPhase() {
        stopTimer()
        petState.pomodoroState = .working
        petState.pomodoroTimeRemaining = workDuration
        elapsedSecondsInWork = 0
        sendNotification(
            title: "DeskPet",
            body: "休息结束！准备好继续工作了 🐱"
        )
        startTimer()
    }

    // MARK: - Notifications

    private var notificationsAvailable: Bool {
        Bundle.main.bundleIdentifier != nil
    }

    private func requestNotificationPermission() {
        guard notificationsAvailable else { return }
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendNotification(title: String, body: String) {
        guard notificationsAvailable else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
