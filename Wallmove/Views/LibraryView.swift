import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    let onWallpaperTap: (UUID) -> Void

    @State private var isDragTargeted = false

    private let columns = [GridItem(.adaptive(minimum: 210, maximum: 270), spacing: 12)]

    var body: some View {
        ZStack {
            Color.wmBackground.ignoresSafeArea()

            Group {
                if viewModel.wallpapers.isEmpty {
                    emptyState
                } else {
                    wallpaperGrid
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDragTargeted {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        Color.white.opacity(0.40),
                        style: StrokeStyle(lineWidth: 2, dash: [10])
                    )
                    .padding(12)
                    .allowsHitTesting(false)
            }
        }
    }

    // MARK: - Grid

    private var wallpaperGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.wallpapers) { wallpaper in
                    WallpaperThumbnailCard(
                        wallpaper: wallpaper,
                        isActive: wallpaper.id == viewModel.activeWallpaperID,
                        isScreenSaver: wallpaper.id == viewModel.screenSaverWallpaperID
                            && viewModel.screenSaverMode == .separate
                    )
                    .onTapGesture {
                        onWallpaperTap(wallpaper.id)
                    }
                }
            }
            .padding(20)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: isDragTargeted ? "film.stack.fill" : "film.stack")
                .font(.system(size: 60))
                .foregroundStyle(
                    isDragTargeted ? Color.white : Color.white.opacity(0.18)
                )
                .animation(.easeInOut(duration: 0.15), value: isDragTargeted)

            VStack(spacing: 6) {
                Text("Your Library is Empty")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Import .mp4 or .mov files, or drag and drop them here.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.wmTextSecondary)
                    .multilineTextAlignment(.center)
            }

            Button("Import Videos") {
                viewModel.importWallpapers()
            }
            .buttonStyle(WallmovePrimaryButtonStyle())
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers)
        }
    }

    // MARK: - Drop Handler

    @discardableResult
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            provider.loadItem(
                forTypeIdentifier: UTType.fileURL.identifier, options: nil
            ) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil),
                      ["mp4", "mov"].contains(url.pathExtension.lowercased())
                else { return }
                DispatchQueue.main.async {
                    self.viewModel.importDroppedURLs([url])
                }
            }
        }
        return true
    }
}
