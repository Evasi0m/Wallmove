import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

enum DashboardWindowMetrics {
    static let defaultSize = CGSize(width: 1180, height: 860)
    static let minimumSize = CGSize(width: 920, height: 640)
    static let maximumSize = CGSize(width: 1440, height: 1080)
    static let sidebarWidth: CGFloat = 346
}

struct DashboardView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    @State private var isSidebarVisible = true
    @State private var isDragTargeted = false
    @State private var showDeleteConfirmation = false
    @State private var isRenaming = false
    @State private var renameText = ""
    @State private var isHoveringPreview = false

    var body: some View {
        VStack(spacing: 0) {
            topBar

            Divider()

            HStack(spacing: 0) {
                if isSidebarVisible {
                    sidebar
                        .frame(width: DashboardWindowMetrics.sidebarWidth)

                    Divider()
                }

                previewPanel
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .animation(.easeInOut(duration: 0.18), value: isSidebarVisible)
        .alert("Wallmove Error", isPresented: errorIsPresented, actions: {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
        .confirmationDialog(
            "Delete \"\(viewModel.selectedWallpaper?.displayName ?? "")\"?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                viewModel.deleteSelectedWallpaper()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove the video file from Wallmove.")
        }
    }

    // MARK: - Bindings

    private var wallpaperSelection: Binding<UUID?> {
        Binding(
            get: { viewModel.selectedWallpaperID },
            set: { viewModel.selectWallpaper(id: $0) }
        )
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 10) {
            Button {
                isSidebarVisible.toggle()
            } label: {
                Image(systemName: isSidebarVisible ? "sidebar.left" : "sidebar.right")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .glassButton(cornerRadius: 8)
            .help(isSidebarVisible ? "Hide Sidebar" : "Show Sidebar")

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text("Wallmove")
                    .font(.system(size: 30, weight: .bold, design: .rounded))

                Text("Minimal live wallpapers for your desktop and screen saver.")
                    .foregroundStyle(.secondary)

                HStack {
                    Button("Import Videos", systemImage: "plus") {
                        viewModel.importWallpapers()
                    }
                    .buttonStyle(.borderedProminent)

                    if !viewModel.wallpapers.isEmpty {
                        Text("\(viewModel.wallpapers.count) video\(viewModel.wallpapers.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 12)
            .background(Color(nsColor: .windowBackgroundColor))

            List(selection: wallpaperSelection) {
                if viewModel.wallpapers.isEmpty {
                    dropZoneEmptyState
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(viewModel.wallpapers) { wallpaper in
                        WallpaperRowView(
                            wallpaper: wallpaper,
                            isActive: wallpaper.id == viewModel.activeWallpaperID,
                            isScreenSaver: wallpaper.id == viewModel.screenSaverWallpaperID
                                && viewModel.screenSaverMode == .separate
                        )
                        .tag(wallpaper.id)
                    }
                }
            }
            .listStyle(.sidebar)
            .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
                handleDrop(providers)
            }
            .overlay(alignment: .bottom) {
                if isDragTargeted {
                    dropHighlight
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    private var dropZoneEmptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: isDragTargeted ? "film.stack.fill" : "film.stack")
                .font(.system(size: 40))
                .foregroundStyle(isDragTargeted ? Color.accentColor : Color.secondary)
                .animation(.easeInOut(duration: 0.15), value: isDragTargeted)

            Text(isDragTargeted ? "Drop to Import" : "No Wallpapers Yet")
                .font(.headline)

            Text("Import a `.mp4` or `.mov` file, or drop videos here to start building your library.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers)
        }
    }

    private var dropHighlight: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(Color.accentColor, lineWidth: 2)
            .padding(6)
            .transition(.opacity)
    }

    // MARK: - Preview Panel

    @ViewBuilder
    private var previewPanel: some View {
        if let wallpaper = viewModel.selectedWallpaper {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    wallpaperHeader(for: wallpaper)

                    previewSurface

                    actionButtons

                    settingsCard

                    storageCard
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 20)
            }
            .background(Color(nsColor: .windowBackgroundColor))
        } else {
            ContentUnavailableView(
                "Select a Wallpaper",
                systemImage: "play.rectangle",
                description: Text("Choose a video from the sidebar to preview it and apply it to the desktop.")
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
                handleDrop(providers)
            }
        }
    }

    private func wallpaperHeader(for wallpaper: WallpaperItem) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if isRenaming {
                HStack(spacing: 8) {
                    TextField("Name", text: $renameText)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .textFieldStyle(.plain)
                        .onSubmit { commitRename(for: wallpaper) }

                    Button("Done") { commitRename(for: wallpaper) }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)

                    Button("Cancel") { isRenaming = false }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
            } else {
                HStack(alignment: .center, spacing: 10) {
                    Text(wallpaper.displayName)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))

                    Button {
                        renameText = wallpaper.displayName
                        isRenaming = true
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Rename")

                    if wallpaper.id == viewModel.activeWallpaperID {
                        Label("Active", systemImage: "checkmark.circle.fill")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .glassCapsule(color: .green)
                    }
                }
            }

            Text("Choose how this clip behaves on the desktop and in screen saver mode.")
                .foregroundStyle(.secondary)
        }
        .onChange(of: viewModel.selectedWallpaperID) { _ in
            isRenaming = false
        }
    }

    private func commitRename(for wallpaper: WallpaperItem) {
        viewModel.renameWallpaper(id: wallpaper.id, to: renameText)
        isRenaming = false
    }

    // MARK: - Preview Surface

    private var previewSurface: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width, 1)
            let targetWidth = max(width, 320)
            let targetHeight = min(max(targetWidth * 9 / 16, 260), 430)

            ZStack {
                LoopingVideoView(
                    playerController: viewModel.previewController,
                    videoGravity: .resizeAspectFill
                )

                playPauseOverlay
            }
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
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.25), .white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isHoveringPreview = hovering
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(height: 430)
    }

    private var playPauseOverlay: some View {
        Button {
            viewModel.togglePreviewPlayback()
        } label: {
            Image(systemName: viewModel.isPreviewPaused ? "play.circle.fill" : "pause.circle.fill")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.85))
                .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .opacity(viewModel.isPreviewPaused || isHoveringPreview ? 1 : 0)
        .animation(.easeInOut(duration: 0.15), value: isHoveringPreview)
        .contentShape(Rectangle())
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button("Apply to Desktop") {
                viewModel.applySelectedWallpaper()
            }
            .buttonStyle(.borderedProminent)

            Button("Delete") {
                showDeleteConfirmation = true
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - Settings Card

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
        .glassCard(cornerRadius: 20)
    }

    // MARK: - Storage Card

    private var storageCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Storage")
                    .font(.headline)

                Spacer()

                Text(viewModel.cacheSize)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .glassCapsule(color: .secondary)
            }

            Text("Imported videos are copied into `~/Library/Application Support/Wallmove/Wallpapers/`, so deleting the original file will not break Wallmove.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Clear Imported Cache") {
                viewModel.clearCache()
            }
            .buttonStyle(.bordered)
        }
        .padding(18)
        .glassCard(cornerRadius: 20)
    }

    // MARK: - Drag & Drop

    @discardableResult
    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                let ext = url.pathExtension.lowercased()
                guard ["mp4", "mov"].contains(ext) else { return }
                DispatchQueue.main.async {
                    self.viewModel.importDroppedURLs([url])
                }
                handled = true
            }
        }
        return true
    }
}

#Preview {
    DashboardView(viewModel: WallmoveViewModel())
}
