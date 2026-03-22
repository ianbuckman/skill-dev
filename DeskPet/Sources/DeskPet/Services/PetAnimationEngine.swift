import SwiftUI

@MainActor
final class PetAnimationEngine {

    // MARK: - Properties

    private var timer: Timer?
    private var petState: PetState
    private var targetPosition: CGPoint?
    private var currentAction: AnimationState = .idle
    private var actionTimer: TimeInterval = 0

    /// When true, the engine skips movement AI (used during drag).
    var isDragging: Bool = false

    /// Tick counter for passive mood changes (every 1500 ticks = ~5 minutes at 200ms).
    private var moodTickCounter: Int = 0
    private let moodChangeInterval: Int = 1500

    /// When non-nil, the engine is playing a one-shot reaction overlay.
    private var reactionRemainingTime: TimeInterval?

    /// The animation state that was active before a reaction was triggered.
    private var preReactionAction: AnimationState?

    private let tickInterval: TimeInterval = 0.2          // 200 ms
    private let moveSpeed: CGFloat = 2.5                  // pt per tick (2-3 range)
    private let actionDurationRange: ClosedRange<Double> = 2...5

    // MARK: - Init

    init(petState: PetState) {
        self.petState = petState
    }

    // MARK: - Public API

    func start() {
        stop()
        pickNewAction()
        timer = Timer.scheduledTimer(
            withTimeInterval: tickInterval,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.tick()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func triggerReaction(duration: TimeInterval = 1.0) {
        guard reactionRemainingTime == nil else { return }
        preReactionAction = currentAction
        currentAction = .reacting
        petState.animationState = .reacting
        petState.currentFrame = 0
        reactionRemainingTime = duration
    }

    // MARK: - Tick

    private func tick() {
        advanceFrame()
        updatePassiveMood()

        // Skip movement AI while dragging (frame cycling continues)
        if isDragging { return }

        // Handle reaction countdown
        if var remaining = reactionRemainingTime {
            remaining -= tickInterval
            if remaining <= 0 {
                reactionRemainingTime = nil
                if let previous = preReactionAction {
                    currentAction = previous
                    petState.animationState = previous
                    petState.currentFrame = 0
                    preReactionAction = nil
                }
            } else {
                reactionRemainingTime = remaining
            }
            return   // skip AI while reacting
        }

        // Decrement action timer
        actionTimer -= tickInterval
        if actionTimer <= 0 {
            pickNewAction()
        }

        // Movement
        if currentAction == .walking || currentAction == .running {
            moveTowardsTarget()
        }
    }

    // MARK: - Passive Mood

    private func updatePassiveMood() {
        moodTickCounter += 1
        guard moodTickCounter >= moodChangeInterval else { return }
        moodTickCounter = 0

        switch petState.pomodoroState {
        case .working:
            // Working for a while -> might get sleepy
            // elapsedSecondsInWork equivalent: pomodoroTimeRemaining tells us how far in
            let elapsedSeconds = 1500 - petState.pomodoroTimeRemaining
            if elapsedSeconds > 1200 { // > 20 minutes into work
                petState.mood = Bool.random() ? .sleepy : .normal
            } else {
                petState.mood = .normal
            }
        case .breaking:
            // On break -> likely happy
            petState.mood = Bool.random() ? .happy : .normal
        case .idle:
            // Idle -> drift between normal and sleepy
            petState.mood = Bool.random() ? .normal : .sleepy
        }
    }

    // MARK: - Frame Cycling

    private func advanceFrame() {
        let frameCount = SpriteData.frames(for: petState.animationState).count
        guard frameCount > 0 else { return }
        petState.currentFrame = (petState.currentFrame + 1) % frameCount
    }

    // MARK: - Movement AI

    private func moveTowardsTarget() {
        if targetPosition == nil {
            targetPosition = randomScreenPoint()
        }
        guard let target = targetPosition else { return }

        let dx = target.x - petState.petPosition.x
        let dy = target.y - petState.petPosition.y
        let distance = sqrt(dx * dx + dy * dy)

        let speed: CGFloat = currentAction == .running ? moveSpeed * 1.6 : moveSpeed

        if distance < speed {
            // Arrived at target
            petState.petPosition = target
            targetPosition = nil
            pickNewAction()
            return
        }

        let ratio = speed / distance
        petState.petPosition.x += dx * ratio
        petState.petPosition.y += dy * ratio

        // Face the direction of movement
        petState.facingRight = dx > 0

        clampToScreen()
    }

    // MARK: - Action Selection

    private func pickNewAction() {
        let candidates = allowedActions()
        let weights = candidates.map { weight(for: $0) }
        currentAction = weightedRandom(candidates, weights: weights)
        petState.animationState = currentAction
        petState.currentFrame = 0

        actionTimer = Double.random(in: actionDurationRange)

        if currentAction == .walking || currentAction == .running {
            targetPosition = randomScreenPoint()
        } else {
            targetPosition = nil
        }
    }

    /// Returns the set of animation states allowed under the current pomodoro mode.
    private func allowedActions() -> [AnimationState] {
        switch petState.pomodoroState {
        case .working:
            // Quiet mode: only calm states
            return [.idle, .sitting, .sleeping]
        case .breaking:
            // Active mode: lively states
            return [.running, .walking, .reacting]
        case .idle:
            // Normal: everything except reacting (reacting is triggered manually)
            return [.idle, .walking, .sitting, .sleeping, .running]
        }
    }

    /// Returns a relative weight for the given state, influenced by mood.
    private func weight(for state: AnimationState) -> Double {
        let base: Double
        switch state {
        case .idle:     base = 3
        case .walking:  base = 3
        case .sitting:  base = 2
        case .sleeping: base = 2
        case .running:  base = 2
        case .reacting: base = 1
        }

        var w = base
        switch petState.mood {
        case .happy:
            if state == .running || state == .reacting { w *= 2.0 }
            if state == .sleeping { w *= 0.3 }
        case .sleepy:
            if state == .sleeping || state == .sitting { w *= 2.5 }
            if state == .running { w *= 0.2 }
        case .normal:
            break
        }
        return w
    }

    // MARK: - Helpers

    private func weightedRandom(_ items: [AnimationState], weights: [Double]) -> AnimationState {
        let total = weights.reduce(0, +)
        guard total > 0, !items.isEmpty else { return .idle }
        var r = Double.random(in: 0..<total)
        for (index, w) in weights.enumerated() {
            r -= w
            if r <= 0 {
                return items[index]
            }
        }
        return items[items.count - 1]
    }

    private func screenBounds() -> CGRect {
        NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
    }

    private func randomScreenPoint() -> CGPoint {
        let bounds = screenBounds()
        let margin: CGFloat = 32   // keep a small margin from edges
        let x = CGFloat.random(in: (bounds.minX + margin)...(bounds.maxX - margin))
        let y = CGFloat.random(in: (bounds.minY + margin)...(bounds.maxY - margin))
        return CGPoint(x: x, y: y)
    }

    private func clampToScreen() {
        let bounds = screenBounds()
        let margin: CGFloat = 16
        let minX = bounds.minX + margin
        let maxX = bounds.maxX - margin
        let minY = bounds.minY + margin
        let maxY = bounds.maxY - margin

        if petState.petPosition.x < minX {
            petState.petPosition.x = minX
            petState.facingRight = true
            targetPosition = nil
        } else if petState.petPosition.x > maxX {
            petState.petPosition.x = maxX
            petState.facingRight = false
            targetPosition = nil
        }

        if petState.petPosition.y < minY {
            petState.petPosition.y = minY
            targetPosition = nil
        } else if petState.petPosition.y > maxY {
            petState.petPosition.y = maxY
            targetPosition = nil
        }
    }
}
