import AppKit

@MainActor
final class TimerCountdownOverlay {
    private var window: NSWindow?
    private var countdownView: CountdownView?

    func show(seconds: Int, completion: @escaping () -> Void) {
        guard let screen = NSScreen.main else {
            completion()
            return
        }

        let size = CGSize(width: 120, height: 120)
        let origin = CGPoint(
            x: screen.frame.midX - size.width / 2,
            y: screen.frame.midY - size.height / 2
        )

        let window = NSWindow(
            contentRect: CGRect(origin: origin, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.level = .screenSaver
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.ignoresMouseEvents = true

        let view = CountdownView(frame: CGRect(origin: .zero, size: size))
        view.remainingSeconds = seconds
        window.contentView = view
        window.makeKeyAndOrderFront(nil)

        self.window = window
        self.countdownView = view

        startCountdown(from: seconds, completion: completion)
    }

    private func startCountdown(from seconds: Int, completion: @escaping () -> Void) {
        var remaining = seconds

        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            remaining -= 1
            Task { @MainActor in
                if remaining <= 0 {
                    timer.invalidate()
                    self?.hide()
                    completion()
                } else {
                    self?.countdownView?.remainingSeconds = remaining
                    self?.countdownView?.needsDisplay = true
                }
            }
        }
    }

    func hide() {
        window?.orderOut(nil)
        window = nil
        countdownView = nil
    }
}

final class CountdownView: NSView {
    var remainingSeconds: Int = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Background circle
        let circleRect = bounds.insetBy(dx: 10, dy: 10)
        context.setFillColor(NSColor.black.withAlphaComponent(0.7).cgColor)
        context.fillEllipse(in: circleRect)

        // Number
        let text = "\(remainingSeconds)" as NSString
        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 48, weight: .bold),
            .foregroundColor: NSColor.white
        ]
        let size = text.size(withAttributes: attrs)
        text.draw(
            at: CGPoint(
                x: bounds.midX - size.width / 2,
                y: bounds.midY - size.height / 2
            ),
            withAttributes: attrs
        )
    }
}
