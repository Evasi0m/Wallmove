import AppKit
import AVFoundation
import SwiftUI
import UniformTypeIdentifiers

enum DashboardWindowMetrics {
    static let defaultSize = CGSize(width: 1320, height: 900)
    static let minimumSize = CGSize(width: 1020, height: 720)
    static let maximumSize = CGSize(width: 1440, height: 1020)
}

private enum DashboardSection: String, CaseIterable, Identifiable {
    case home = "Home"
    case library = "Library"
    case lockScreen = "Lock Screen"

    var id: String { rawValue }
}

struct DashboardView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    @State private var selectedSection: DashboardSection = .home
    @State private var isDragTargeted = false
    @State private var showDeleteConfirmation = false
    @State private var isHoveringPreview = false

    var body: some View {
        ZStack {
            dashboardBackground

            LinearGradient(
                colors: [.black.opacity(0.15), .black.opacity(0.45)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                headerBar
                currentSectionView
            }
            .padding(24)
        }
        .background(Color(nsColor: .windowBackgroundColor))
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
            Text("This removes the imported file from Wallmove storage.")
        }
        .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
            handleDrop(providers)
        }
        .overlay {
            if isDragTargeted {
                RoundedRectangle(cornerRadius: 30)
                    .strokeBorder(Color.white.opacity(0.65), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 30)
                            .fill(.ultraThinMaterial.opacity(0.55))
                    )
                    .padding(18)
                    .overlay {
                        VStack(spacing: 14) {
                            Image(systemName: "square.and.arrow.down.on.square")
                                .font(.system(size: 34, weight: .semibold))
                            Text("Drop videos to import")
                                .font(.title3.weight(.semibold))
                            Text("Wallmove will copy `.mp4` and `.mov` files into its own library.")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .transition(.opacity)
            }
        }
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
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }

    private var dashboardBackground: some View {
        Group {
            if let image = currentBackgroundImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 36)
                    .overlay(Color.black.opacity(0.22))
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.17, green: 0.22, blue: 0.29),
                        Color(red: 0.10, green: 0.12, blue: 0.17)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }
        }
    }

    private var headerBar: some View {
        HStack(spacing: 20) {
            HStack(spacing: 14) {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.ultraThinMaterial)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "play.rectangle.on.rectangle.fill")
                            .font(.title3.weight(.semibold))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text("Wallmove")
                        .font(.system(size: 26, weight: .bold, design: .rounded))

                    Text("Live wallpapers for desktop, screen saver, and lock screen setup.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 8) {
                ForEach(DashboardSection.allCases) { section in
                    Button {
                        selectedSection = section
                    } label: {
                        Text(section.rawValue)
                            .font(.headline)
                            .foregroundStyle(selectedSection == section ? .black : .white.opacity(0.92))
                            .padding(.horizontal, 22)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(selectedSection == section ? Color.white : Color.clear)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(6)
            .glassCard(cornerRadius: 26)

            Spacer()

            HStack(spacing: 12) {
                Button("Import", systemImage: "square.and.arrow.up") {
                    viewModel.importWallpapers()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .glassButton(cornerRadius: 22)

                Menu {
                    Toggle(
                        "Launch at Login",
                        isOn: Binding(
                            get: { viewModel.launchAtLoginEnabled },
                            set: { viewModel.setLaunchAtLoginEnabled($0) }
                        )
                    )

                    Divider()

                    Button("Open System Settings") {
                        viewModel.openSystemSettings()
                    }

                    Button("Clear Imported Cache", role: .destructive) {
                        viewModel.clearCache()
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.headline)
                        .frame(width: 54, height: 54)
                        .glassButton(cornerRadius: 27)
                }
                .menuStyle(.borderlessButton)
            }
        }
    }

    @ViewBuilder
    private var currentSectionView: some View {
        switch selectedSection {
        case .home:
            homeSection
        case .library:
            librarySection
        case .lockScreen:
            lockScreenSection
        }
    }

    private var homeSection: some View {
        ScrollView {
            VStack(spacing: 22) {
                if let wallpaper = viewModel.selectedWallpaper {
                    heroPreview(for: wallpaper)

                    HStack(alignment: .top, spacing: 18) {
                        quickStatusCard
                        screenSaverCard
                        lockScreenCard
                    }
                } else {
                    emptyHero
                }
            }
            .padding(.bottom, 12)
        }
        .scrollIndicators(.hidden)
    }

    private func heroPreview(for wallpaper: WallpaperItem) -> some View {
        ZStack(alignment: .bottomLeading) {
            LoopingVideoView(
                playerController: viewModel.previewController,
                videoGravity: .resizeAspectFill
            )
            .overlay {
                LinearGradient(
                    colors: [.clear, .black.opacity(0.82)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            VStack(alignment: .leading, spacing: 18) {
                Spacer()

                VStack(alignment: .leading, spacing: 10) {
                    Text("FEATURED")
                        .font(.subheadline.weight(.bold))
                        .tracking(3)
                        .foregroundStyle(.white.opacity(0.85))

                    Text(wallpaper.displayName)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        heroBadge(viewModel.activeWallpaperID == wallpaper.id ? "Desktop Active" : "Ready", tint: .white)
                        heroBadge(viewModel.screenSaverWallpaperID == wallpaper.id || viewModel.screenSaverMode == .mirrorDesktop ? "Screen Saver" : "Library", tint: .blue)
                        heroBadge(viewModel.cacheSize, tint: .white)
                    }
                }

                HStack(spacing: 12) {
                    Button("Apply to Desktop") {
                        viewModel.applySelectedWallpaper()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(Color.white, in: Capsule())
                    .foregroundStyle(.black)

                    Button("Open Lock Screen Setup") {
                        selectedSection = .lockScreen
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .glassButton(cornerRadius: 22)

                    Button {
                        viewModel.togglePreviewPlayback()
                    } label: {
                        Image(systemName: viewModel.isPreviewPaused ? "play.fill" : "pause.fill")
                            .font(.headline)
                            .frame(width: 48, height: 48)
                            .glassButton(cornerRadius: 24)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(36)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

            VStack {
                Spacer()
                wallpaperStrip
                    .padding(.horizontal, 26)
                    .padding(.bottom, 22)
            }
        }
        .frame(height: 520)
        .clipShape(RoundedRectangle(cornerRadius: 34))
        .overlay {
            RoundedRectangle(cornerRadius: 34)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.46), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.22), radius: 24, x: 0, y: 18)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.16)) {
                isHoveringPreview = hovering
            }
        }
    }

    private func heroBadge(_ title: String, tint: Color) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .foregroundStyle(.white)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial.opacity(0.9))
                    .overlay(
                        Capsule().strokeBorder(tint.opacity(0.45), lineWidth: 0.8)
                    )
            )
    }

    private var wallpaperStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(viewModel.wallpapers) { wallpaper in
                    Button {
                        viewModel.selectWallpaper(id: wallpaper.id)
                    } label: {
                        wallpaperThumbnail(for: wallpaper)
                            .frame(width: 168, height: 96)
                            .clipShape(RoundedRectangle(cornerRadius: 24))
                            .overlay {
                                RoundedRectangle(cornerRadius: 24)
                                    .strokeBorder(
                                        wallpaper.id == viewModel.selectedWallpaperID ? .white.opacity(0.95) : .white.opacity(0.14),
                                        lineWidth: wallpaper.id == viewModel.selectedWallpaperID ? 3 : 1
                                    )
                            }
                            .shadow(color: .black.opacity(0.28), radius: 18, x: 0, y: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var quickStatusCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Desktop", systemImage: "display")
                .font(.headline)

            Text(viewModel.activeWallpaper?.displayName ?? "No desktop wallpaper applied yet.")
                .font(.title3.weight(.semibold))

            Text("Choose a clip from the library strip, preview it instantly, then push it to the desktop in one click.")
                .foregroundStyle(.secondary)

            Button("Apply Selected Wallpaper") {
                viewModel.applySelectedWallpaper()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private var screenSaverCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Screen Saver", systemImage: "sparkles.rectangle.stack")
                .font(.headline)

            Text(viewModel.screenSaverSummaryTitle)
                .font(.title3.weight(.semibold))

            Text(viewModel.screenSaverSummaryDescription)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Match Desktop") {
                    viewModel.configureScreenSaverToMirrorDesktop()
                }
                .buttonStyle(.borderedProminent)

                Button("Use Selected") {
                    viewModel.configureScreenSaverWithSelectedWallpaper()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private var lockScreenCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Lock Screen", systemImage: "lock.square.stack")
                .font(.headline)

            Text(viewModel.lockScreenSummaryTitle)
                .font(.title3.weight(.semibold))

            Text(viewModel.lockScreenSummaryDescription)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                Button("Setup") {
                    selectedSection = .lockScreen
                }
                .buttonStyle(.borderedProminent)

                Button("System Settings") {
                    viewModel.openSystemSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24)
    }

    private var librarySection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                sectionHeading(
                    eyebrow: "LIBRARY",
                    title: "Manage your imported wallpapers",
                    subtitle: "Browse your local clips, change the active wallpaper, and keep the library clean."
                )

                if viewModel.wallpapers.isEmpty {
                    emptyLibraryState
                } else {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 270, maximum: 320), spacing: 18)],
                        spacing: 18
                    ) {
                        ForEach(viewModel.wallpapers) { wallpaper in
                            libraryTile(for: wallpaper)
                        }
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    private func libraryTile(for wallpaper: WallpaperItem) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                viewModel.selectWallpaper(id: wallpaper.id)
                selectedSection = .home
            } label: {
                ZStack(alignment: .bottomLeading) {
                    wallpaperThumbnail(for: wallpaper)
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 22))

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.72)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(wallpaper.displayName)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)

                        HStack(spacing: 8) {
                            if viewModel.activeWallpaperID == wallpaper.id {
                                tileBadge("Desktop", color: .green)
                            }

                            if viewModel.screenSaverMode == .separate && viewModel.screenSaverWallpaperID == wallpaper.id {
                                tileBadge("Screen Saver", color: .blue)
                            }
                        }
                    }
                    .padding(16)
                }
            }
            .buttonStyle(.plain)

            Text(wallpaper.videoFileName)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)

            HStack(spacing: 10) {
                Button("Preview") {
                    viewModel.selectWallpaper(id: wallpaper.id)
                    selectedSection = .home
                }
                .buttonStyle(.borderedProminent)

                Button("Delete", role: .destructive) {
                    viewModel.selectWallpaper(id: wallpaper.id)
                    showDeleteConfirmation = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(16)
        .glassCard(cornerRadius: 24)
    }

    private func tileBadge(_ title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .glassCapsule(color: color)
    }

    private var lockScreenSection: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                sectionHeading(
                    eyebrow: "LOCK SCREEN",
                    title: "Prepare your screen saver and lock screen flow",
                    subtitle: "macOS lock screen follows the screen saver path. Wallmove lets you decide which wallpaper should represent that experience."
                )

                HStack(alignment: .top, spacing: 18) {
                    lockScreenSetupPanel
                    lockScreenInfoPanel
                }

                generalSettingsPanel
            }
            .padding(.bottom, 20)
        }
        .scrollIndicators(.hidden)
    }

    private var lockScreenSetupPanel: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Choose a lock screen source")
                .font(.title3.weight(.semibold))

            Picker("Lock Screen Source", selection: $viewModel.selectedScreenSaverMode) {
                ForEach(WallpaperLibrary.ScreenSaverMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            if viewModel.selectedScreenSaverMode == .separate {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Wallpaper")
                        .font(.headline)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.wallpapers) { wallpaper in
                                Button {
                                    viewModel.selectedScreenSaverWallpaperID = wallpaper.id
                                } label: {
                                    wallpaperThumbnail(for: wallpaper)
                                        .frame(width: 150, height: 88)
                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 18)
                                                .strokeBorder(
                                                    viewModel.selectedScreenSaverWallpaperID == wallpaper.id ? .white.opacity(0.92) : .white.opacity(0.14),
                                                    lineWidth: viewModel.selectedScreenSaverWallpaperID == wallpaper.id ? 3 : 1
                                                )
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }

            HStack(spacing: 12) {
                Button("Apply Lock Screen Setup") {
                    viewModel.applyScreenSaverSettings()
                }
                .buttonStyle(.borderedProminent)

                Button("Open System Settings") {
                    viewModel.openSystemSettings()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .glassCard(cornerRadius: 26)
    }

    private var lockScreenInfoPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("What this controls")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 10) {
                infoRow(title: "Current setup", detail: viewModel.lockScreenSummaryTitle)
                infoRow(title: "Active wallpaper", detail: viewModel.activeWallpaper?.displayName ?? "None")
                infoRow(title: "Selected screen saver", detail: viewModel.screenSaverWallpaper?.displayName ?? "Follows desktop")
            }

            Divider()

            Text(viewModel.lockScreenCapabilityNote)
                .foregroundStyle(.secondary)

            Button("Mirror Desktop Wallpaper") {
                viewModel.configureScreenSaverToMirrorDesktop()
            }
            .buttonStyle(.bordered)

            if viewModel.selectedWallpaper != nil {
                Button("Use Selected Wallpaper") {
                    viewModel.configureScreenSaverWithSelectedWallpaper()
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .glassCard(cornerRadius: 26)
    }

    private var generalSettingsPanel: some View {
        HStack(alignment: .top, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .glassCard(cornerRadius: 24)

            VStack(alignment: .leading, spacing: 14) {
                Text("Storage")
                    .font(.headline)

                Text("Current cache: \(viewModel.cacheSize)")
                    .font(.title3.weight(.semibold))

                Text("Wallmove stores imported clips inside Application Support so deleting the source file never breaks your setup.")
                    .foregroundStyle(.secondary)

                Button("Clear Imported Cache", role: .destructive) {
                    viewModel.clearCache()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
            .glassCard(cornerRadius: 24)
        }
    }

    private func sectionHeading(eyebrow: String, title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(eyebrow)
                .font(.subheadline.weight(.bold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.78))

            Text(title)
                .font(.system(size: 34, weight: .bold, design: .rounded))

            Text(subtitle)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }

    private var emptyHero: some View {
        VStack(alignment: .leading, spacing: 18) {
            sectionHeading(
                eyebrow: "WELCOME",
                title: "Bring your desktop to life",
                subtitle: "Import a short `.mp4` or `.mov` clip, preview it instantly, and then decide how it should behave on desktop, screen saver, and lock screen setup."
            )

            HStack(spacing: 12) {
                Button("Import Videos", systemImage: "square.and.arrow.up") {
                    viewModel.importWallpapers()
                }
                .buttonStyle(.borderedProminent)

                Button("Open Lock Screen Setup") {
                    selectedSection = .lockScreen
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 420, alignment: .leading)
        .padding(28)
        .glassCard(cornerRadius: 34)
    }

    private var emptyLibraryState: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack.fill")
                .font(.system(size: 40))

            Text("Your library is empty")
                .font(.title3.weight(.semibold))

            Text("Import a few videos to start building a more cinematic dashboard.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Import Videos") {
                viewModel.importWallpapers()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, minHeight: 280)
        .padding(24)
        .glassCard(cornerRadius: 28)
    }

    private func infoRow(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(detail)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func wallpaperThumbnail(for wallpaper: WallpaperItem) -> some View {
        if let image = thumbnailImage(for: wallpaper) {
            Image(nsImage: image)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [.white.opacity(0.16), .white.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .overlay {
                Image(systemName: "film")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var currentBackgroundImage: NSImage? {
        guard let wallpaper = viewModel.selectedWallpaper ?? viewModel.activeWallpaper else {
            return nil
        }

        return thumbnailImage(for: wallpaper)
    }

    private func thumbnailImage(for wallpaper: WallpaperItem) -> NSImage? {
        guard let url = wallpaper.thumbnailURL(in: AppDirectories.thumbnails) else {
            return nil
        }

        return NSImage(contentsOf: url)
    }

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
                    viewModel.importDroppedURLs([url])
                }
                handled = true
            }
        }
        return handled
    }
}

#Preview {
    DashboardView(viewModel: WallmoveViewModel())
}
