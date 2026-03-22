import SwiftUI

@MainActor
final class InteractionManager {

    // MARK: - Properties

    private let petState: PetState
    private let animationEngine: PetAnimationEngine
    private var lastDragTranslation: CGSize = .zero
    private var moodResetTask: Task<Void, Never>?
    private var spinResetTask: Task<Void, Never>?

    // MARK: - Init

    init(petState: PetState, animationEngine: PetAnimationEngine) {
        self.petState = petState
        self.animationEngine = animationEngine
    }

    // MARK: - Tap

    func handleTap() {
        animationEngine.triggerReaction()
        setMoodTemporarily(.happy, duration: 5.0)
    }

    // MARK: - Double Tap

    func handleDoubleTap() {
        animationEngine.triggerReaction(duration: 2.0)
        setMoodTemporarily(.happy, duration: 5.0)
        triggerSpin()
    }

    // MARK: - Drag

    func handleDragChanged(translation: CGSize) {
        animationEngine.isDragging = true

        let deltaX = translation.width - lastDragTranslation.width
        let deltaY = translation.height - lastDragTranslation.height

        petState.petPosition.x += deltaX
        // macOS y-axis points upward, SwiftUI drag translation y-axis points downward
        petState.petPosition.y -= deltaY

        lastDragTranslation = translation
    }

    func handleDragEnded() {
        animationEngine.isDragging = false
        lastDragTranslation = .zero
    }

    // MARK: - Private

    private func setMoodTemporarily(_ mood: PetMood, duration: TimeInterval) {
        moodResetTask?.cancel()
        petState.mood = mood
        moodResetTask = Task {
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            petState.mood = .normal
        }
    }

    private func triggerSpin() {
        spinResetTask?.cancel()
        petState.isSpinning = true
        spinResetTask = Task {
            try? await Task.sleep(for: .seconds(2.0))
            guard !Task.isCancelled else { return }
            petState.isSpinning = false
        }
    }
}
