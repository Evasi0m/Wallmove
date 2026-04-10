import AVFoundation
import CoreMedia
import SwiftUI

struct WallpaperPreviewView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    let onDismiss: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var fileSize: String = ""
    @State private var duration: String = ""

    private var wallpaper: WallpaperItem? {
        viewModel.selectedWallpaper
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()

            LoopingVideoView(
                playerController: viewModel.previewController,
                videoGravity: .resizeAspectFill
            )
            .ignoresSafeArea()

            if let wp = wallpaper {
                bottomHUD(for: wp)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
        .task(id: wallpaper?.id) {
            await loadMetadata()
        }
        .confirmationDialog(
            "Delete \"\(wallpaper?.displayName ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedWallpaper()
                onDismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the video file from Wallmove.")
        }
        .onChange(of: viewModel.selectedWallpaper == nil) { _, isNil in
            if isNil { onDismiss() }
        }
    }

    private func bottomHUD(for wp: WallpaperItem) -> some View {
        HStack(spacing: 0) {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)
            .handCursor()

            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 1, height: 28)
                .padding(.horizontal, 14)

            nameMetadataSection(for: wp)
                .layoutPriority(-1)

            Spacer(minLength: 12)

            HStack(spacing: 12) {
                hudIconButton("trash") {
                    showDeleteConfirmation = true
                }

                applyButton(for: wp)
            }
            .layoutPriority(1)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .frame(maxWidth: DashboardWindowMetrics.contentWidth)
        .glassCard(cornerRadius: 20)
        .environment(\.colorScheme, .dark)
    }

    private func nameMetadataSection(for wp: WallpaperItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if isRenaming {
                HStack(spacing: 8) {
                    TextField("Name", text: $renameText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                        .frame(minWidth: 100, maxWidth: 260)
                        .onSubmit { commitRename(for: wp) }

                    Button("Done") { commitRename(for: wp) }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.wmBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.96), in: Capsule())
                        .buttonStyle(.plain)
                        .handCursor()
                }
            } else {
                HStack(spacing: 7) {
                    Text(wp.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Button {
                        renameText = wp.displayName
                        isRenaming = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                    .handCursor()
                    .help("Rename")

                    if viewModel.activeWallpaperID == wp.id {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                            .help("Currently active on desktop")
                    }
                }
            }

            HStack(spacing: 12) {
                if !fileSize.isEmpty {
                    metaLabel(fileSize, icon: "doc")
                }
                if !duration.isEmpty {
                    metaLabel(duration, icon: "clock")
                }
            }
        }
    }

    private func metaLabel(_ text: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.system(size: 11))
        .foregroundStyle(Color.white.opacity(0.45))
    }

    private func applyButton(for wp: WallpaperItem) -> some View {
        let isApplied = viewModel.activeWallpaperID == wp.id
        return Button {
            viewModel.applySelectedWallpaper()
        } label: {
            Text(isApplied ? "Applied" : "Apply to Desktop")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(isApplied ? Color.white.opacity(0.45) : Color.black)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    isApplied ? Color.white.opacity(0.12) : Color.white,
                    in: Capsule()
                )
        }
        .buttonStyle(.plain)
        .disabled(isApplied)
        .handCursor()
    }

    private func hudIconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.70))
                .frame(width: 36, height: 36)
                .glassButton(cornerRadius: 9)
        }
        .buttonStyle(.plain)
        .handCursor()
    }

    private func commitRename(for wp: WallpaperItem) {
        viewModel.renameWallpaper(id: wp.id, to: renameText)
        isRenaming = false
    }

    private func loadMetadata() async {
        let currentWallpaperID = wallpaper?.id
        fileSize = ""
        duration = ""

        guard let wp = wallpaper else { return }
        let url = wp.videoURL(in: AppDirectories.wallpapers)
        var nextFileSize = ""
        var nextDuration = ""

        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let bytes = attrs[.size] as? Int64 {
            let mb = Double(bytes) / 1_000_000
            nextFileSize = mb >= 1000
                ? String(format: "%.1f GB", mb / 1000)
                : String(format: "%.0f MB", mb)
        }

        let asset = AVURLAsset(url: url)
        if let dur = try? await asset.load(.duration) {
            let secs = max(0, Int(CMTimeGetSeconds(dur)))
            nextDuration = secs >= 60
                ? String(format: "%d:%02d", secs / 60, secs % 60)
                : "\(secs)s"
        }

        guard wallpaper?.id == currentWallpaperID else {
            return
        }

        fileSize = nextFileSize
        duration = nextDuration
    }
}
