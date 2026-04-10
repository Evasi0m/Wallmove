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
        }

        func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
            sender.frameRect(forContentRect: CGRect(origin: .zero, size: DashboardWindowMetrics.defaultSize)).size
        }

        func windowShouldZoom(_ window: NSWindow, toFrame newFrame: NSRect) -> Bool {
            false
        }
    }
}
