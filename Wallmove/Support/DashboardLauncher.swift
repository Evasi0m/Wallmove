import SwiftUI

@MainActor
enum DashboardLauncher {
    static var openDashboard: (() -> Void)?

    static func showDashboard() {
        if let dashboardWindow = NSApp.windows.first(where: {
            $0.identifier?.rawValue == SceneID.dashboard
        }) {
            if dashboardWindow.isMiniaturized {
                dashboardWindow.deminiaturize(nil)
            }
            dashboardWindow.orderFrontRegardless()
            dashboardWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        openDashboard?()
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
