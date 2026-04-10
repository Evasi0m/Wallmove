import AppKit
import SwiftUI

struct WindowConfigurationView: NSViewRepresentable {
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            context.coordinator.configureWindowIfNeeded(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            context.coordinator.configureWindowIfNeeded(for: nsView)
        }
    }

    final class Coordinator: NSObject, NSWindowDelegate {
        private weak var window: NSWindow?
        private var hasPresentedInitialWindow = false

        func configureWindowIfNeeded(for view: NSView) {
            guard let window = view.window else { return }

            self.window = window

            let size = DashboardWindowMetrics.defaultSize
            let fixedFrameSize = window.frameRect(forContentRect: CGRect(origin: .zero, size: size)).size

            window.identifier = NSUserInterfaceItemIdentifier(SceneID.dashboard)
            window.title = "Wallmove"
            window.delegate = self
            window.setContentSize(size)
            window.contentMinSize = size
            window.contentMaxSize = size
            window.minSize = fixedFrameSize
            window.maxSize = fixedFrameSize
            window.resizeIncrements = fixedFrameSize
            window.contentResizeIncrements = size
            window.aspectRatio = size
            window.styleMask.remove(.resizable)
            window.showsResizeIndicator = false

            // Keep the system title bar hidden and let content extend behind the traffic lights.
            window.toolbar = nil
            window.styleMask.insert(.fullSizeContentView)
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            window.backgroundColor = .clear
            window.isOpaque = false
            window.hasShadow = true
            window.isReleasedWhenClosed = false
            window.isRestorable = false
            window.tabbingMode = .disallowed

            if let themeFrame = window.contentView?.superview {
                themeFrame.wantsLayer = true
                themeFrame.layer?.backgroundColor = NSColor.clear.cgColor
            }

            // Remove the hairline separator under the titlebar area
            window.titlebarSeparatorStyle = .none

            // Disable fullscreen and zoom
            window.collectionBehavior.remove(.fullScreenPrimary)
            window.collectionBehavior.remove(.fullScreenAuxiliary)
            window.standardWindowButton(.zoomButton)?.isEnabled = false
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.standardWindowButton(.miniaturizeButton)?.isEnabled = true

            if window.frame.size != fixedFrameSize {
                var frame = window.frame
                frame.size = fixedFrameSize
                window.setFrame(frame, display: true)
            }

            centerWindowIfNeeded(window, fixedFrameSize: fixedFrameSize)

            if !hasPresentedInitialWindow {
                hasPresentedInitialWindow = true
                DashboardLauncher.showDashboard()
            }
        }

        func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
            sender.frameRect(forContentRect: CGRect(origin: .zero, size: DashboardWindowMetrics.defaultSize)).size
        }

        func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
            false
        }

        private func centerWindowIfNeeded(_ window: NSWindow, fixedFrameSize: NSSize) {
            guard let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }

            let visibleFrame = screen.visibleFrame.insetBy(dx: 20, dy: 20)
            let centeredOrigin = CGPoint(
                x: visibleFrame.midX - (fixedFrameSize.width / 2),
                y: visibleFrame.midY - (fixedFrameSize.height / 2)
            )

            var frame = window.frame
            let maxX = visibleFrame.maxX - fixedFrameSize.width
            let maxY = visibleFrame.maxY - fixedFrameSize.height

            let isOutOfBounds =
                frame.origin.x < visibleFrame.minX ||
                frame.origin.x > maxX ||
                frame.origin.y < visibleFrame.minY ||
                frame.origin.y > maxY

            if isOutOfBounds {
                frame.origin.x = centeredOrigin.x
                frame.origin.y = centeredOrigin.y
                window.setFrame(frame, display: true)
            }
        }
    }
}
