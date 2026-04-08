import SwiftUI

struct MenuBarView: View {
    @ObservedObject var viewModel: WallmoveViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button("Open Dashboard") {
                DashboardLauncher.openDashboard?()
            }

            Divider()

            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLoginEnabled($0) }
                )
            )

            if let active = viewModel.activeWallpaper {
                Text("Desktop: \(active.displayName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Quit Wallmove") {
                NSApp.terminate(nil)
            }
        }
        .padding(10)
        .frame(minWidth: 220)
    }
}
