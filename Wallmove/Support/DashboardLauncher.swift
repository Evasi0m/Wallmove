import SwiftUI

@MainActor
enum DashboardLauncher {
    static var openDashboard: (() -> Void)?

    static func showDashboard() {
        if let dashboardWindow = findDashboardWindow() {
            present(dashboardWindow)
            return
        }

        openDashboard?()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            if let dashboardWindow = findDashboardWindow() {
                present(dashboardWindow)
            }
        }
    }

    private static func findDashboardWindow() -> NSWindow? {
        NSApp.windows.first { window in
            if window.identifier?.rawValue == SceneID.dashboard {
                return true
            }

            let isAppWindow = !window.styleMask.contains(.borderless)
            let titleMatches = window.title == "Wallmove"
            return isAppWindow && titleMatches
        }
    }

    private static func present(_ window: NSWindow) {
        NSApp.unhide(nil)

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        clampWindowToVisibleScreen(window)

        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private static func clampWindowToVisibleScreen(_ window: NSWindow) {
        guard let screen = window.screen ?? NSScreen.main ?? NSScreen.screens.first else { return }

        let visibleFrame = screen.visibleFrame.insetBy(dx: 20, dy: 20)
        var frame = window.frame

        let maxX = visibleFrame.maxX - frame.width
        let maxY = visibleFrame.maxY - frame.height

        if frame.origin.x < visibleFrame.minX || frame.origin.x > maxX ||
            frame.origin.y < visibleFrame.minY || frame.origin.y > maxY {
            frame.origin.x = visibleFrame.midX - (frame.width / 2)
            frame.origin.y = visibleFrame.midY - (frame.height / 2)
        } else {
            frame.origin.x = min(max(frame.origin.x, visibleFrame.minX), maxX)
            frame.origin.y = min(max(frame.origin.y, visibleFrame.minY), maxY)
        }

        window.setFrame(frame, display: true)
    }
}

struct DashboardLauncherBinder: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .onAppear {
                DashboardLauncher.openDashboard = {
                    openWindow(id: SceneID.dashboard)
                    NSApp.activate(ignoringOtherApps: true)
                }
            }
    }
}
