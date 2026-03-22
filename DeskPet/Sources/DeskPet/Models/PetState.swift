import SwiftUI

enum AnimationState: String, Sendable {
    case idle, walking, sitting, sleeping, running, reacting
}

enum PetMood: String, Sendable {
    case happy, normal, sleepy
}

enum PomodoroState: String, Sendable {
    case idle, working, breaking
}

@Observable
@MainActor
final class PetState {
    var petPosition: CGPoint = CGPoint(x: 400, y: 300)
    var animationState: AnimationState = .idle
    var facingRight: Bool = true
    var mood: PetMood = .normal
    var pomodoroState: PomodoroState = .idle
    var pomodoroTimeRemaining: TimeInterval = 0
    var pomodoroSessionCount: Int = 0
    var isPomodoroPaused: Bool = false
    var isPetVisible: Bool = true
    var todayFocusMinutes: Int = 0
    var currentFrame: Int = 0
    var isSpinning: Bool = false

    // MARK: - UserDefaults Keys

    private static let focusMinutesKey = "todayFocusMinutes"
    private static let sessionCountKey = "pomodoroSessionCount"
    private static let lastDateKey = "lastFocusDate"

    // MARK: - Init

    init() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = UserDefaults.standard.object(forKey: Self.lastDateKey) as? Date ?? .distantPast
        if Calendar.current.isDate(today, inSameDayAs: lastDate) {
            todayFocusMinutes = UserDefaults.standard.integer(forKey: Self.focusMinutesKey)
            pomodoroSessionCount = UserDefaults.standard.integer(forKey: Self.sessionCountKey)
        } else {
            todayFocusMinutes = 0
            pomodoroSessionCount = 0
            UserDefaults.standard.set(today, forKey: Self.lastDateKey)
        }
    }

    // MARK: - Persistence

    func persistStats() {
        UserDefaults.standard.set(todayFocusMinutes, forKey: Self.focusMinutesKey)
        UserDefaults.standard.set(pomodoroSessionCount, forKey: Self.sessionCountKey)
        let today = Calendar.current.startOfDay(for: Date())
        UserDefaults.standard.set(today, forKey: Self.lastDateKey)
    }
}
