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

        window.setContentSize(DashboardWindowMetrics.defaultSize)
        window.minSize = DashboardWindowMetrics.minimumSize
        window.maxSize = DashboardWindowMetrics.maximumSize

        // Full-dark, edge-to-edge look
        window.styleMask.insert(.fullSizeContentView)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0.11, green: 0.11, blue: 0.11, alpha: 1.0)
        window.isOpaque = true

        // Disable fullscreen and zoom
        window.collectionBehavior.remove(.fullScreenPrimary)
        window.collectionBehavior.remove(.fullScreenAuxiliary)
        window.standardWindowButton(.zoomButton)?.isEnabled = false
        window.standardWindowButton(.zoomButton)?.isHidden = true
    }
}
