import AppKit
import CoreGraphics

@MainActor
final class DesktopWallpaperWindowController {
    private(set) var screen: NSScreen
    private let playerView = PlayerLayerView(frame: .zero)
    private let playerController = LoopingVideoPlayerController()
    private let window: DesktopWallpaperWindow

    init(screen: NSScreen) {
        self.screen = screen
        self.window = DesktopWallpaperWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )

        configureWindow()
        playerController.attach(to: playerView)
    }

    func updateScreen(_ newScreen: NSScreen) {
        screen = newScreen
        window.setFrame(newScreen.frame, display: true)
        window.setFrameOrigin(newScreen.frame.origin)
    }

    func showVideo(at url: URL?) {
        playerController.loadVideo(url: url)
        if url == nil {
            window.orderOut(nil)
        } else {
            window.orderBack(nil)
        }
    }

    func setPaused(_ paused: Bool) {
        playerController.setPaused(paused)
    }

    private func configureWindow() {
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]

        let desktopIconLevel = Int(CGWindowLevelForKey(.desktopIconWindow))
        window.level = NSWindow.Level(rawValue: desktopIconLevel - 1)

        playerView.frame = window.contentView?.bounds ?? .zero
        playerView.autoresizingMask = [.width, .height]
        window.contentView = playerView
        window.orderOut(nil)
    }
}

final class DesktopWallpaperWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
