import AppKit
import Combine

@MainActor
final class WallpaperEngine {
    private var desktopWindowControllers: [String: DesktopWallpaperWindowController] = [:]
    private var screenSaverWindowControllers: [String: DesktopWallpaperWindowController] = [:]
    private let suspensionMonitor = PlaybackSuspensionMonitor()
    private var desktopSuspensionCancellable: AnyCancellable?
    private var screenSaverStateCancellable: AnyCancellable?
    private var currentWallpaperURL: URL?
    private var currentScreenSaverURL: URL?

    init() {
        rebuildWindows()

        desktopSuspensionCancellable = suspensionMonitor.$shouldSuspendDesktopPlayback
            .sink { [weak self] shouldSuspend in
                self?.desktopWindowControllers.values.forEach { $0.setPaused(shouldSuspend) }
            }

        screenSaverStateCancellable = suspensionMonitor.$isScreenSaverRunning
            .sink { [weak self] isRunning in
                self?.updateScreenSaverPresentation(isRunning: isRunning)
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

    func configure(desktopURL: URL?, screenSaverURL: URL?) {
        currentWallpaperURL = desktopURL
        currentScreenSaverURL = screenSaverURL
        rebuildWindows()

        desktopWindowControllers.values.forEach { controller in
            controller.showVideo(at: desktopURL)
            controller.setPaused(suspensionMonitor.shouldSuspendDesktopPlayback)
        }

        updateScreenSaverPresentation(isRunning: suspensionMonitor.isScreenSaverRunning)
    }

    func hideAll() {
        configure(desktopURL: nil, screenSaverURL: nil)
    }

    private func updateScreenSaverPresentation(isRunning: Bool) {
        screenSaverWindowControllers.values.forEach { controller in
            controller.showVideo(at: isRunning ? currentScreenSaverURL : nil)
            controller.setPaused(!isRunning || currentScreenSaverURL == nil)
        }
    }

    @objc
    private func handleScreenConfigurationChange() {
        rebuildWindows()
        desktopWindowControllers.values.forEach { controller in
            controller.showVideo(at: currentWallpaperURL)
            controller.setPaused(suspensionMonitor.shouldSuspendDesktopPlayback)
        }
        updateScreenSaverPresentation(isRunning: suspensionMonitor.isScreenSaverRunning)
    }

    private func rebuildWindows() {
        let screens = NSScreen.screens
        let keys = Set(screens.map(Self.screenKey))

        for screen in screens {
            let key = Self.screenKey(screen)
            if let controller = desktopWindowControllers[key] {
                controller.updateScreen(screen)
            } else {
                let controller = DesktopWallpaperWindowController(screen: screen, placement: .desktop)
                controller.showVideo(at: currentWallpaperURL)
                controller.setPaused(suspensionMonitor.shouldSuspendDesktopPlayback)
                desktopWindowControllers[key] = controller
            }

            if let controller = screenSaverWindowControllers[key] {
                controller.updateScreen(screen)
            } else {
                let controller = DesktopWallpaperWindowController(screen: screen, placement: .screenSaver)
                controller.showVideo(at: nil)
                controller.setPaused(true)
                screenSaverWindowControllers[key] = controller
            }
        }

        desktopWindowControllers.keys
            .filter { !keys.contains($0) }
            .forEach { key in
                desktopWindowControllers.removeValue(forKey: key)
            }

        screenSaverWindowControllers.keys
            .filter { !keys.contains($0) }
            .forEach { key in
                screenSaverWindowControllers.removeValue(forKey: key)
            }
    }

    private static func screenKey(_ screen: NSScreen) -> String {
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return number?.stringValue ?? UUID().uuidString
    }
}
