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

            Divider()

            statusSection

            Divider()

            Button("Quit Wallmove") {
                NSApp.terminate(nil)
            }
        }
        .padding(10)
        .frame(minWidth: 240)
    }

    @ViewBuilder
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Status", systemImage: "circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .labelStyle(TitleOnlyLabelStyle())

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

            screenSaverStatus

            HStack(spacing: 6) {
                Image(systemName: "lock.square")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.lockScreenSummaryTitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
    }

    @ViewBuilder
    private var screenSaverStatus: some View {
        switch viewModel.screenSaverMode {
        case .off:
            HStack(spacing: 6) {
                Image(systemName: "moon.zzz")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Screen saver: Off")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .mirrorDesktop:
            HStack(spacing: 6) {
                Image(systemName: "rectangle.on.rectangle")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text("Screen saver: Same as desktop")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .separate:
            if let ssWallpaper = viewModel.screenSaverWallpaper {
                HStack(spacing: 6) {
                    Image(systemName: "moon.stars")
                        .font(.caption)
                        .foregroundStyle(.blue)
                    Text("Screen saver: \(ssWallpaper.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
