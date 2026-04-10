import AppKit
import Combine

@MainActor
final class WallpaperEngine {
    private var desktopWindowControllers: [String: DesktopWallpaperWindowController] = [:]
    private let suspensionMonitor = PlaybackSuspensionMonitor()
    private var desktopSuspensionCancellable: AnyCancellable?
    private var currentWallpaperURL: URL?

    init() {
        rebuildWindows()

        desktopSuspensionCancellable = suspensionMonitor.$shouldSuspendDesktopPlayback
            .sink { [weak self] shouldSuspend in
                self?.desktopWindowControllers.values.forEach { $0.setPaused(shouldSuspend) }
            }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenConfigurationChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func configure(desktopURL: URL?) {
        currentWallpaperURL = desktopURL
        rebuildWindows()
        refreshDesktopPresentation()
    }

    func hideAll() {
        configure(desktopURL: nil)
    }

    @objc
    private func handleScreenConfigurationChange() {
        rebuildWindows()
        refreshDesktopPresentation()
    }

    private func rebuildWindows() {
        let screens = NSScreen.screens
        let keys = Set(screens.map(Self.screenKey))

        for screen in screens {
            let key = Self.screenKey(screen)
            if let controller = desktopWindowControllers[key] {
                controller.updateScreen(screen)
            } else {
                let controller = DesktopWallpaperWindowController(screen: screen)
                controller.showVideo(at: currentWallpaperURL)
                controller.setPaused(suspensionMonitor.shouldSuspendDesktopPlayback)
                desktopWindowControllers[key] = controller
            }
        }

        desktopWindowControllers.keys
            .filter { !keys.contains($0) }
            .forEach { key in
                desktopWindowControllers[key]?.showVideo(at: nil)
                desktopWindowControllers.removeValue(forKey: key)
            }
    }

    private func refreshDesktopPresentation() {
        desktopWindowControllers.values.forEach { controller in
            controller.showVideo(at: currentWallpaperURL)
            controller.setPaused(suspensionMonitor.shouldSuspendDesktopPlayback)
        }
    }

    private static func screenKey(_ screen: NSScreen) -> String {
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        if let number {
            return number.stringValue
        }

        return "\(screen.localizedName)-\(Int(screen.frame.origin.x))-\(Int(screen.frame.origin.y))-\(Int(screen.frame.width))x\(Int(screen.frame.height))"
    }
}
