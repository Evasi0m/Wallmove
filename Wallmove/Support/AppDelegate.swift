import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            DashboardLauncher.openDashboard?()
        } else {
            sender.activate(ignoringOtherApps: true)
            sender.windows.first(where: \.canBecomeMain)?.makeKeyAndOrderFront(nil)
        }

        return true
    }
}
