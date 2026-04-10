import AppKit
import Combine
import CoreGraphics

@MainActor
final class PlaybackSuspensionMonitor: ObservableObject {
    @Published private(set) var shouldSuspendDesktopPlayback = false

    private var workspaceObservers: [Any] = []
    private var isDisplaySleeping = false

    init() {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers = [
            workspaceCenter.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.evaluatePlaybackState()
                }
            },
            workspaceCenter.addObserver(forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.evaluatePlaybackState()
                }
            },
            workspaceCenter.addObserver(forName: NSWorkspace.screensDidSleepNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.isDisplaySleeping = true
                    self.evaluatePlaybackState()
                }
            },
            workspaceCenter.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
                guard let self else { return }
                Task { @MainActor in
                    self.isDisplaySleeping = false
                    self.evaluatePlaybackState()
                }
            }
        ]

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScreenConfigurationChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        evaluatePlaybackState()
    }

    deinit {
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach { workspaceCenter.removeObserver($0) }
        NotificationCenter.default.removeObserver(self)
    }

    @objc
    private func handleScreenConfigurationChange() {
        evaluatePlaybackState()
    }

    private func evaluatePlaybackState() {
        shouldSuspendDesktopPlayback = isDisplaySleeping || frontmostApplicationOccupiesFullScreen()
    }

    private func frontmostApplicationOccupiesFullScreen() -> Bool {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            return false
        }

        let onScreenOptions: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let rawWindowInfo = CGWindowListCopyWindowInfo(onScreenOptions, kCGNullWindowID) as? [[String: Any]] else {
            return false
        }

        let screens = NSScreen.screens.map(\.frame)
        return rawWindowInfo.contains { info in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == application.processIdentifier else {
                return false
            }

            guard let layer = info[kCGWindowLayer as String] as? Int,
                  layer == 0 else {
                return false
            }

            if let alpha = info[kCGWindowAlpha as String] as? Double, alpha <= 0.01 {
                return false
            }

            guard let boundsDictionary = info[kCGWindowBounds as String] as? NSDictionary,
                  let bounds = CGRect(dictionaryRepresentation: boundsDictionary) else {
                return false
            }

            return screens.contains { screenFrame in
                abs(bounds.origin.x - screenFrame.origin.x) < 4 &&
                abs(bounds.origin.y - screenFrame.origin.y) < 4 &&
                abs(bounds.size.width - screenFrame.size.width) < 4 &&
                abs(bounds.size.height - screenFrame.size.height) < 4
            }
        }
    }
}
