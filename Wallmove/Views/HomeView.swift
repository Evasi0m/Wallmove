import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    let onOpenPreview: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.wallpapers.isEmpty {
                emptyState
            } else {
                heroContent
            }
        }
        .onAppear {
            selectInitialHero()
        }
    }

    // MARK: - Hero

    private var heroContent: some View {
        ZStack(alignment: .bottom) {
            // Full-window video
            LoopingVideoView(
                playerController: viewModel.previewController,
                videoGravity: .resizeAspectFill
            )
            .ignoresSafeArea()

            // Bottom gradient + info + strip
            VStack(alignment: .leading, spacing: 0) {
                // Fade gradient
                LinearGradient(
                    colors: [.clear, .black.opacity(0.55), .black.opacity(0.88)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)

                // Info + actions
                if let wp = viewModel.selectedWallpaper {
                    heroInfo(for: wp)
                }

                // Thumbnail strip
                thumbnailStrip
                    .padding(.top, 18)
                    .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Info Row

    private func heroInfo(for wp: WallpaperItem) -> some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 10) {
                Text(wp.displayName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Button {
                        onOpenPreview()
                    } label: {
                        HStack(spacing: 5) {
                            Text("View Wallpaper")
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .buttonStyle(HeroPrimaryButtonStyle())

                    if viewModel.activeWallpaperID != wp.id {
                        Button("Apply to Desktop") {
                            viewModel.applySelectedWallpaper()
                        }
                        .buttonStyle(HeroSecondaryButtonStyle())
                    } else {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.green.opacity(0.15), in: Capsule())
                    }
                }
            }

            Spacer()
        }
        .padding(.horizontal, 28)
    }

    // MARK: - Thumbnail Strip

    private var thumbnailStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(viewModel.wallpapers) { wallpaper in
                    stripCard(wallpaper)
                }
            }
            .padding(.horizontal, 28)
        }
    }

    private func stripCard(_ wallpaper: WallpaperItem) -> some View {
        let isSelected = wallpaper.id == viewModel.selectedWallpaperID

        return Button {
            viewModel.selectWallpaper(id: wallpaper.id)
        } label: {
            ZStack {
                // Thumbnail
                if let url = wallpaper.thumbnailURL(in: AppDirectories.thumbnails),
                   let img = NSImage(contentsOf: url) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(Color.wmSurface)
                        .overlay {
                            Image(systemName: "film")
                                .foregroundStyle(Color.wmTextSecondary)
                        }
                }
            }
            .frame(width: 148, height: 83)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.white : Color.white.opacity(0.12),
                        lineWidth: isSelected ? 2.5 : 1
                    )
            )
            .scaleEffect(isSelected ? 1.04 : 1.0)
            .animation(.easeOut(duration: 0.14), value: isSelected)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: "film.stack")
                .font(.system(size: 60))
                .foregroundStyle(Color.white.opacity(0.18))

            VStack(spacing: 6) {
                Text("No Wallpapers Yet")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Import .mp4 or .mov files to get started.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.wmTextSecondary)
            }

            Button("Import Videos") {
                viewModel.importWallpapers()
            }
            .buttonStyle(WallmovePrimaryButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Helpers

    private func selectInitialHero() {
        guard !viewModel.wallpapers.isEmpty else { return }
        if viewModel.selectedWallpaperID == nil {
            let id = viewModel.activeWallpaperID ?? viewModel.wallpapers.first?.id
            viewModel.selectWallpaper(id: id)
        }
    }
}

// MARK: - Button Styles

private struct HeroPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Color.white.opacity(configuration.isPressed ? 0.75 : 0.92),
                in: Capsule()
            )
    }
}

private struct HeroSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
            .background(
                Color.white.opacity(configuration.isPressed ? 0.18 : 0.12),
                in: Capsule()
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.3), lineWidth: 1)
            )
    }
}
