import AVFoundation
import SwiftUI

enum DashboardWindowMetrics {
    static let defaultSize = CGSize(width: 922, height: 677)
    static let minimumSize = CGSize(width: 820, height: 560)
    static let maximumSize = CGSize(width: 922, height: 677)
    static let sidebarWidth: CGFloat = 346
}

struct DashboardView: View {
    @ObservedObject var viewModel: WallmoveViewModel

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: DashboardWindowMetrics.sidebarWidth)

            Divider()

            previewPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("Wallmove Error", isPresented: errorIsPresented, actions: {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }

    private var wallpaperSelection: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedWallpaperID },
            set: { viewModel.selectWallpaper(id: $0) }
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    @ViewBuilder
    private var previewPanel: some View {
        if let wallpaper = viewModel.selectedWallpaper {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(wallpaper.displayName)
                            .font(.system(size: 26, weight: .semibold, design: .rounded))

                        Text("Choose how this clip behaves on the desktop and in screen saver mode.")
                            .foregroundStyle(.secondary)
                    }

                    previewSurface

                    HStack(spacing: 12) {
                        Button("Apply to Desktop") {
                            viewModel.applySelectedWallpaper()
                        }
                        .buttonStyle(.borderedProminent)

                        Button("Delete") {
                            viewModel.deleteSelectedWallpaper()
                        }
                        .buttonStyle(.bordered)
                    }

                    settingsCard

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Storage")
                            .font(.headline)

                        Text("Imported videos are copied into `~/Library/Application Support/Wallmove/Wallpapers/`, so deleting the original file will not break Wallmove.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Button("Clear Imported Cache") {
                            viewModel.clearCache()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(18)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
                .padding(.horizontal, 22)
                .padding(.vertical, 18)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "Select a Wallpaper",
                systemImage: "play.rectangle",
                description: Text("Choose a video from the sidebar to preview it and apply it to the desktop.")
            )
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Wallmove")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("Minimal live wallpapers for your desktop and screen saver.")
                    .foregroundStyle(.secondary)

                Button("Import Videos", systemImage: "plus") {
                    viewModel.importWallpapers()
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            List(selection: wallpaperSelection) {
                if viewModel.wallpapers.isEmpty {
                    ContentUnavailableView(
                        "No Wallpapers Yet",
                        systemImage: "film.stack",
                        description: Text("Import a `.mp4` or `.mov` file to start building your local wallpaper library.")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.wallpapers) { wallpaper in
                        WallpaperRowView(
                            wallpaper: wallpaper,
                            isActive: wallpaper.id == viewModel.activeWallpaperID,
                            isScreenSaver: wallpaper.id == viewModel.screenSaverWallpaperID && viewModel.screenSaverMode == .separate
                        )
                        .tag(wallpaper.id)
                    }
                }
            }
            .listStyle(.sidebar)
        }
        .frame(maxHeight: .infinity)
    }

    private var previewSurface: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let targetWidth = max(width, 320)
            let targetHeight = min(max(targetWidth * 9 / 16, 220), 330)

            LoopingVideoView(
                playerController: viewModel.previewController,
                videoGravity: .resizeAspectFill
            )
            .frame(width: targetWidth, height: targetHeight)
            .background(
                LinearGradient(
                    colors: [.black.opacity(0.95), .black.opacity(0.78)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 24)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: 330)
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Playback")
                    .font(.headline)

                Toggle(
                    "Launch Wallmove at Login",
                    isOn: Binding(
                        get: { viewModel.launchAtLoginEnabled },
                        set: { viewModel.setLaunchAtLoginEnabled($0) }
                    )
                )

                Text(viewModel.launchAtLoginDescription)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Screen Saver")
                    .font(.headline)

                Picker("Screen Saver", selection: $viewModel.selectedScreenSaverMode) {
                    ForEach(WallpaperLibrary.ScreenSaverMode.allCases) { mode in
                        Text(mode.title).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                if viewModel.selectedScreenSaverMode == .separate {
                    Picker("Wallpaper", selection: Binding(
                        get: { viewModel.selectedScreenSaverWallpaperID },
                        set: { viewModel.selectedScreenSaverWallpaperID = $0 }
                    )) {
                        ForEach(viewModel.wallpapers) { wallpaper in
                            Text(wallpaper.displayName).tag(Optional(wallpaper.id))
                        }
                    }
                }

                Button("Apply Screen Saver Settings") {
                    viewModel.applyScreenSaverSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(18)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    DashboardView(viewModel: WallmoveViewModel())
}
