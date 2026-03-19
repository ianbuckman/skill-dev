import Foundation

@MainActor
final class DesktopIconService {
    private var wasHidden = false

    func hideDesktopIcons() {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["write", "com.apple.finder", "CreateDesktop", "-bool", "false"]
        try? task.run()
        task.waitUntilExit()

        restartFinder()
        wasHidden = true
    }

    func showDesktopIcons() {
        let task = Process()
        task.launchPath = "/usr/bin/defaults"
        task.arguments = ["write", "com.apple.finder", "CreateDesktop", "-bool", "true"]
        try? task.run()
        task.waitUntilExit()

        restartFinder()
        wasHidden = false
    }

    func toggleDesktopIcons() {
        if wasHidden {
            showDesktopIcons()
        } else {
            hideDesktopIcons()
        }
    }

    var isHidden: Bool { wasHidden }

    private func restartFinder() {
        let task = Process()
        task.launchPath = "/usr/bin/killall"
        task.arguments = ["Finder"]
        try? task.run()
        task.waitUntilExit()
    }
}
