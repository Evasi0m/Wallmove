import SwiftUI

@main
struct WallmoveApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var viewModel = WallmoveViewModel()
    @State private var showsMenuBarExtra = true

    var body: some Scene {
        Window("Wallmove", id: SceneID.dashboard) {
            DashboardView(viewModel: viewModel)
                .frame(
                    width: DashboardWindowMetrics.defaultSize.width,
                    height: DashboardWindowMetrics.defaultSize.height
                )
                .overlay(alignment: .topLeading) {
                    DashboardLauncherBinder()
                }
                .background {
                    WindowConfigurationView()
                }
        }
        .defaultSize(
            width: DashboardWindowMetrics.defaultSize.width,
            height: DashboardWindowMetrics.defaultSize.height
        )
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra("Wallmove", systemImage: "play.rectangle.on.rectangle", isInserted: $showsMenuBarExtra) {
            MenuBarView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.menu)
    }
}

enum SceneID {
    static let dashboard = "dashboard"
}
