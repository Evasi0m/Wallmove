import AVFoundation
import CoreMedia
import SwiftUI

// MARK: - Full-Screen Preview

struct WallpaperPreviewView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    let onDismiss: () -> Void

    @State private var showScreenSaverPanel = false
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
            // ── Full-screen video ─────────────────────
            Color.black.ignoresSafeArea()

            LoopingVideoView(
                playerController: viewModel.previewController,
                videoGravity: .resizeAspectFill
            )
            .ignoresSafeArea()

            // ── Bottom HUD ────────────────────────────
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
        .onChange(of: viewModel.selectedWallpaper == nil) { isNil in
            if isNil { onDismiss() }
        }
    }

    // MARK: - Bottom HUD

    private func bottomHUD(for wp: WallpaperItem) -> some View {
        HStack(spacing: 0) {
            // Back
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
            }
            .buttonStyle(.plain)

            // Separator
            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 1, height: 28)
                .padding(.horizontal, 14)

            // Name + metadata
            nameMetadataSection(for: wp)

            Spacer(minLength: 12)

            // Action buttons
            HStack(spacing: 6) {
                hudIconButton("display.2") {
                    showScreenSaverPanel.toggle()
                }
                .popover(isPresented: $showScreenSaverPanel, arrowEdge: .top) {
                    ScreenSaverPopoverView(viewModel: viewModel)
                }

                hudIconButton("trash") {
                    showDeleteConfirmation = true
                }
            }
            .padding(.trailing, 12)

            // Apply button
            applyButton(for: wp)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .environment(\.colorScheme, .dark)
    }

    // MARK: - Name / Metadata

    private func nameMetadataSection(for wp: WallpaperItem) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if isRenaming {
                HStack(spacing: 8) {
                    TextField("Name", text: $renameText)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                        .frame(maxWidth: 200)
                        .onSubmit { commitRename(for: wp) }

                    Button("Done") { commitRename(for: wp) }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.wmBackground)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white, in: Capsule())
                        .buttonStyle(.plain)
                }
            } else {
                HStack(spacing: 7) {
                    Text(wp.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Button {
                        renameText = wp.displayName
                        isRenaming = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                    .help("Rename")

                    if viewModel.activeWallpaperID == wp.id {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 7, height: 7)
                            .help("Currently active on desktop")
                    }
                }
            }

            // Metadata row
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

    // MARK: - Apply Button

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
    }

    // MARK: - Icon Button Helper

    private func hudIconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.white.opacity(0.70))
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.10), in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Rename

    private func commitRename(for wp: WallpaperItem) {
        viewModel.renameWallpaper(id: wp.id, to: renameText)
        isRenaming = false
    }

    // MARK: - Metadata Loading

    private func loadMetadata() async {
        guard let wp = wallpaper else { return }
        let url = wp.videoURL(in: AppDirectories.wallpapers)

        // File size
        if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
           let bytes = attrs[.size] as? Int64 {
            let mb = Double(bytes) / 1_000_000
            fileSize = mb >= 1000
                ? String(format: "%.1f GB", mb / 1000)
                : String(format: "%.0f MB", mb)
        }

        // Duration
        let asset = AVURLAsset(url: url)
        if let dur = try? await asset.load(.duration) {
            let secs = max(0, Int(CMTimeGetSeconds(dur)))
            duration = secs >= 60
                ? String(format: "%d:%02d", secs / 60, secs % 60)
                : "\(secs)s"
        }
    }
}

// MARK: - Screen Saver Popover

struct ScreenSaverPopoverView: View {
    @ObservedObject var viewModel: WallmoveViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Screen Saver")
                .font(.headline)

            Picker("Mode", selection: $viewModel.selectedScreenSaverMode) {
                ForEach(WallpaperLibrary.ScreenSaverMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if viewModel.selectedScreenSaverMode == .separate {
                Picker("Wallpaper", selection: Binding(
                    get: { viewModel.selectedScreenSaverWallpaperID },
                    set: { viewModel.selectedScreenSaverWallpaperID = $0 }
                )) {
                    ForEach(viewModel.wallpapers) { w in
                        Text(w.displayName).tag(Optional(w.id))
                    }
                }
                .labelsHidden()
            }

            Button("Apply") {
                viewModel.applyScreenSaverSettings()
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)
        }
        .padding(18)
        .frame(width: 300)
    }
}
