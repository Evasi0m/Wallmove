import AppKit
import SwiftUI

struct WindowConfigurationView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView(frame: .zero)
        DispatchQueue.main.async {
            configureWindowIfNeeded(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configureWindowIfNeeded(for: nsView)
        }
    }

    private func configureWindowIfNeeded(for view: NSView) {
        guard let window = view.window else { return }

        let size = DashboardWindowMetrics.defaultSize
        window.setContentSize(size)

        // Fixed size — no resizing
        window.minSize = size
        window.maxSize = size
        window.styleMask.remove(.resizable)

        // Full-dark, edge-to-edge content
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        window.isOpaque = true

        // Remove the hairline separator under the titlebar area
        window.titlebarSeparatorStyle = .none

        // Disable fullscreen and zoom
        window.collectionBehavior.remove(.fullScreenPrimary)
        window.collectionBehavior.remove(.fullScreenAuxiliary)
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }
}
