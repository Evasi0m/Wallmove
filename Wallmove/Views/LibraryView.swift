import SwiftUI
import UniformTypeIdentifiers

struct LibraryView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    let onWallpaperTap: (UUID) -> Void

    @State private var isDragTargeted = false

    private let columns = [GridItem(.adaptive(minimum: 220, maximum: 220), spacing: 12, alignment: .top)]

    var body: some View {
        ZStack {
            Color.clear.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerDeck

                    if viewModel.wallpapers.isEmpty {
                        emptyState
                    } else {
                        wallpaperGrid
                    }
                }
                .frame(maxWidth: DashboardWindowMetrics.contentWidth, alignment: .leading)
                .padding(.horizontal, DashboardWindowMetrics.horizontalPadding)
                .padding(.top, DashboardWindowMetrics.topInset)
                .padding(.bottom, DashboardWindowMetrics.bottomInset)
                .frame(maxWidth: .infinity)
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
                    .padding(20)
                    .allowsHitTesting(false)
            }
        }
    }

    private var headerDeck: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Library")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(.white)

                Text("Your imported clips live here. Drag videos into the window or open a wallpaper to preview, apply, rename, or delete it.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            metricCard(title: "Clips", value: "\(viewModel.wallpapers.count)", icon: "film.stack.fill")

            metricCard(
                title: "Desktop",
                value: viewModel.activeWallpaper?.displayName ?? "Not applied",
                icon: "display"
            )
        }
    }

    private var wallpaperGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Imported Wallpapers")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("Click any card to open the immersive preview.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.58))
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(viewModel.wallpapers) { wallpaper in
                    Button {
                        onWallpaperTap(wallpaper.id)
                    } label: {
                        WallpaperThumbnailCard(
                            wallpaper: wallpaper,
                            isActive: wallpaper.id == viewModel.activeWallpaperID
                        )
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .glassCard(cornerRadius: 30)
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            Image(systemName: isDragTargeted ? "film.stack.fill" : "square.and.arrow.down.on.square.fill")
                .font(.system(size: 42))
                .foregroundStyle(isDragTargeted ? Color.white : Color.white.opacity(0.88))
                .animation(.easeInOut(duration: 0.15), value: isDragTargeted)

            VStack(spacing: 8) {
                Text("Your Library is Empty")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Import .mp4 or .mov files, or drag and drop them here.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }

            Button("Import Videos") {
                viewModel.importWallpapers()
            }
            .buttonStyle(WallmovePrimaryButtonStyle())
            .handCursor()
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassCard(cornerRadius: 30)
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func metricCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.58))

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .frame(maxWidth: 220, alignment: .leading)
        }
        .padding(18)
        .frame(minWidth: 180, alignment: .leading)
        .glassCard(cornerRadius: 24)
    }

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
