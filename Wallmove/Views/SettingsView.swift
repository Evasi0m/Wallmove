import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: WallmoveViewModel

    var body: some View {
        ZStack {
            Color.wmBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    appHeader
                    preferencesCard
                    storageCard
                }
                .frame(maxWidth: 480)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 36)
            }
        }
    }

    // MARK: - App Header

    private var appHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color.wmSurface)
                    .frame(width: 80, height: 80)
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(.white)
            }

            Text("Wallmove")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)

            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                Text("Version \(version)")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.wmTextSecondary)
            }
        }
    }

    // MARK: - Preferences Card

    private var preferencesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Preferences")

            rowDivider

            // Launch at Login
            settingsRow(
                leading: {
                    Text("Launch at Login")
                        .foregroundStyle(.white)
                        .font(.system(size: 14))
                },
                trailing: {
                    Toggle("", isOn: Binding(
                        get: { viewModel.launchAtLoginEnabled },
                        set: { viewModel.setLaunchAtLoginEnabled($0) }
                    ))
                    .labelsHidden()
                }
            )

            if !viewModel.launchAtLoginDescription.isEmpty {
                Text(viewModel.launchAtLoginDescription)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.wmTextSecondary)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }

            rowDivider

            // Screen Saver Mode
            settingsRow(
                leading: {
                    Text("Screen Saver")
                        .foregroundStyle(.white)
                        .font(.system(size: 14))
                },
                trailing: {
                    Picker("", selection: $viewModel.selectedScreenSaverMode) {
                        ForEach(WallpaperLibrary.ScreenSaverMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
            )

            if viewModel.selectedScreenSaverMode == .separate {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Screen Saver Wallpaper")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.wmTextSecondary)

                    Picker("", selection: Binding(
                        get: { viewModel.selectedScreenSaverWallpaperID },
                        set: { viewModel.selectedScreenSaverWallpaperID = $0 }
                    )) {
                        ForEach(viewModel.wallpapers) { w in
                            Text(w.displayName).tag(Optional(w.id))
                        }
                    }
                    .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }

            if viewModel.selectedScreenSaverMode != viewModel.screenSaverMode
                || viewModel.selectedScreenSaverWallpaperID != viewModel.screenSaverWallpaperID {
                HStack {
                    Spacer()
                    Button("Apply Screen Saver Settings") {
                        viewModel.applyScreenSaverSettings()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .background(Color.wmSurface, in: RoundedRectangle(cornerRadius: 14))
        .frame(maxWidth: 480)
        .padding(.horizontal, 20)
    }

    // MARK: - Storage Card

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Storage")

            rowDivider

            settingsRow(
                leading: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Imported Cache")
                            .foregroundStyle(.white)
                            .font(.system(size: 14))
                        Text(viewModel.wallpapers.isEmpty ? "Empty" : viewModel.cacheSize)
                            .foregroundStyle(Color.wmTextSecondary)
                            .font(.system(size: 12))
                    }
                },
                trailing: {
                    Button {
                        viewModel.clearCache()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.wallpapers.isEmpty)
                    .help("Clear all imported videos")
                }
            )

            Text("Videos are copied into ~/Library/Application Support/Wallmove/. Deleting the originals will not break the app.")
                .font(.system(size: 11))
                .foregroundStyle(Color.wmTextSecondary)
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
        }
        .background(Color.wmSurface, in: RoundedRectangle(cornerRadius: 14))
        .frame(maxWidth: 480)
        .padding(.horizontal, 20)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.wmTextSecondary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
    }

    private var rowDivider: some View {
        Rectangle()
            .fill(Color.wmBorder)
            .frame(height: 1)
            .padding(.leading, 16)
    }

    private func settingsRow<L: View, T: View>(
        @ViewBuilder leading: () -> L,
        @ViewBuilder trailing: () -> T
    ) -> some View {
        HStack {
            leading()
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}
