import SwiftUI

@MainActor
enum DashboardLauncher {
    static var openDashboard: (() -> Void)?
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
