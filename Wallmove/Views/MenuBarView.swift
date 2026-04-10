import SwiftUI

struct MenuBarView: View {
    @Environment(\.openWindow) private var openWindow
    @ObservedObject var viewModel: WallmoveViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button("Open Dashboard") {
                openDashboardWindow()
            }
            .handCursor()

            Divider()

            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLoginEnabled($0) }
                )
            )

            Divider()

            statusSection

            Divider()

            Button("Quit Wallmove") {
                NSApp.terminate(nil)
            }
            .handCursor()
        }
        .padding(10)
        .frame(minWidth: 240)
        .onAppear {
            DashboardLauncher.openDashboard = {
                openWindow(id: SceneID.dashboard)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Status")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if let active = viewModel.activeWallpaper {
                HStack(spacing: 6) {
                    Image(systemName: "display")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(active.displayName)
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            } else {
                Text("No desktop wallpaper set")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(viewModel.wallpapers.count) wallpaper\(viewModel.wallpapers.count == 1 ? "" : "s") imported")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func openDashboardWindow() {
        DashboardLauncher.openDashboard = {
            openWindow(id: SceneID.dashboard)
            NSApp.activate(ignoringOtherApps: true)
        }
        DashboardLauncher.showDashboard()
    }
}
