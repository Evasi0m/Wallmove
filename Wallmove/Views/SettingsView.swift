import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: WallmoveViewModel

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerView

                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 18),
                            GridItem(.flexible(), spacing: 18)
                        ],
                        spacing: 18
                    ) {
                        playbackCard
                        desktopCard
                        storageCard
                        aboutCard
                    }
                }
                .frame(maxWidth: DashboardWindowMetrics.contentWidth, alignment: .leading)
                .padding(.horizontal, DashboardWindowMetrics.horizontalPadding)
                .padding(.top, DashboardWindowMetrics.topInset)
                .padding(.bottom, DashboardWindowMetrics.bottomInset)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Settings")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white)

            Text("Tune how Wallmove behaves on login, local storage, and the live desktop wallpaper engine.")
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var playbackCard: some View {
        settingsPanel(
            title: "Playback",
            subtitle: "Launch behavior and startup status."
        ) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Launch at Login")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.white)

                    Text(viewModel.launchAtLoginDescription.isEmpty ? "Control whether Wallmove opens automatically after login." : viewModel.launchAtLoginDescription)
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { viewModel.launchAtLoginEnabled },
                    set: { viewModel.setLaunchAtLoginEnabled($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
            }
        }
    }

    private var desktopCard: some View {
        settingsPanel(
            title: "Desktop Wallpaper",
            subtitle: "Wallmove now focuses only on the live desktop wallpaper experience."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                infoLine("Active Wallpaper", value: viewModel.activeWallpaper?.displayName ?? "Not applied")
                infoLine("Imported Clips", value: "\(viewModel.wallpapers.count)")

                Text("Choose or change your live wallpaper from Home or Library. Settings here stay focused on system behavior and storage.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var storageCard: some View {
        settingsPanel(
            title: "Storage",
            subtitle: "Everything imported into Wallmove is copied into local app storage."
        ) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Imported Cache")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)

                        Text(viewModel.wallpapers.isEmpty ? "Empty" : viewModel.cacheSize)
                            .font(.system(size: 13))
                            .foregroundStyle(Color.white.opacity(0.62))
                    }

                    Spacer()

                    Button("Clear Cache") {
                        viewModel.clearCache()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(viewModel.wallpapers.isEmpty)
                    .handCursor()
                }

                Text("Deleting the original imported file will not break the wallpaper because Wallmove plays the copy stored in Application Support.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var aboutCard: some View {
        settingsPanel(
            title: "About Wallmove",
            subtitle: "Current app details and quick workflow notes."
        ) {
            VStack(alignment: .leading, spacing: 12) {
                infoLine("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                infoLine("Desktop", value: viewModel.activeWallpaper?.displayName ?? "Not applied")
                infoLine("Imported", value: "\(viewModel.wallpapers.count) wallpaper\(viewModel.wallpapers.count == 1 ? "" : "s")")
            }
        }
    }

    private func settingsPanel<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.62))
                    .fixedSize(horizontal: false, vertical: true)
            }

            content()
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .glassCard(cornerRadius: 30)
    }

    private func infoLine(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.58))
            Spacer()
            Text(value)
                .font(.system(size: 13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
    }
}
