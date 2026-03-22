import SwiftUI

@main
struct DeskPetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            if let petState = appDelegate.petState,
               let pomodoroService = appDelegate.pomodoroService {
                PomodoroPopoverView()
                    .environment(petState)
                    .environment(\.pomodoroService, pomodoroService)
            } else {
                Text("Loading...")
            }
        } label: {
            Label("DeskPet", systemImage: "cat.fill")
        }
        .menuBarExtraStyle(.window)
    }
}

// MARK: - AppDelegate

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var petState: PetState?
    var pomodoroService: PomodoroService?
    private var animationEngine: PetAnimationEngine?
    private var windowController: PetWindowController?
    private var interactionManager: InteractionManager?
    private var positionTimer: Timer?
    private var lastPetVisible: Bool = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let state = PetState()
        let engine = PetAnimationEngine(petState: state)
        let interaction = InteractionManager(petState: state, animationEngine: engine)
        let controller = PetWindowController(petState: state, interactionManager: interaction)
        let pomodoro = PomodoroService(petState: state)

        self.petState = state
        self.animationEngine = engine
        self.interactionManager = interaction
        self.windowController = controller
        self.pomodoroService = pomodoro

        controller.setupWindow()
        controller.show()

        engine.start()

        // Sync window position at the same cadence as the animation engine (200ms).
        // Also checks isPetVisible changes to show/hide the pet window.
        positionTimer = Timer.scheduledTimer(
            withTimeInterval: 0.2,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.windowController?.updatePosition()

                if let petState = self.petState, petState.isPetVisible != self.lastPetVisible {
                    self.lastPetVisible = petState.isPetVisible
                    if petState.isPetVisible {
                        self.windowController?.show()
                    } else {
                        self.windowController?.hide()
                    }
                }
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        positionTimer?.invalidate()
        positionTimer = nil
        animationEngine?.stop()
    }

}
