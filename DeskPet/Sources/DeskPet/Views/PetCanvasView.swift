import SwiftUI

extension EnvironmentValues {
    @Entry var interactionManager: InteractionManager? = nil
}

/// Pet rendering view that reads the current animation frame from PetState
/// and delegates pixel rendering to PixelGridView.
struct PetCanvasView: View {
    @Environment(PetState.self) private var petState
    @Environment(\.interactionManager) private var interactionManager

    @State private var spinAngle: Double = 0

    var body: some View {
        let frames = SpriteData.frames(for: petState.animationState)
        let frameIndex = min(petState.currentFrame, max(frames.count - 1, 0))

        Group {
            if !frames.isEmpty {
                PixelGridView(
                    frame: frames[frameIndex],
                    pixelSize: 5,
                    flipped: !petState.facingRight
                )
                .frame(width: 80, height: 80)
            } else {
                Color.clear
                    .frame(width: 80, height: 80)
            }
        }
            .rotationEffect(.degrees(spinAngle))
            .onChange(of: petState.isSpinning) { _, isSpinning in
                if isSpinning {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        spinAngle += 360
                    }
                } else {
                    // Reset angle without animation to avoid visual jump
                    spinAngle = 0
                }
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                interactionManager?.handleDoubleTap()
            }
            .onTapGesture(count: 1) {
                interactionManager?.handleTap()
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        interactionManager?.handleDragChanged(translation: value.translation)
                    }
                    .onEnded { _ in
                        interactionManager?.handleDragEnded()
                    }
            )
    }
}
