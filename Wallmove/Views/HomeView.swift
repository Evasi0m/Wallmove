import AVFoundation
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    let onOpenPreview: () -> Void
    @State private var previewFadeOpacity = 0.0
    @State private var pendingSelectionTask: Task<Void, Never>?
    @FocusState private var isHomeFocused: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Color.black.ignoresSafeArea()

                if viewModel.wallpapers.isEmpty {
                    emptyState
                } else {
                    heroContent(in: proxy.size)
                }
            }
        }
        .focusable()
        .focusEffectDisabled()
        .focused($isHomeFocused)
        .onMoveCommand(perform: handleMoveCommand)
        .onAppear {
            selectInitialHero()
            isHomeFocused = true
        }
        .onDisappear {
            pendingSelectionTask?.cancel()
        }
    }

    private func heroContent(in size: CGSize) -> some View {
        let contentWidth = min(
            DashboardWindowMetrics.contentWidth,
            max(880, size.width - (DashboardWindowMetrics.horizontalPadding * 2))
        )
        let usesCompactHeroLayout = contentWidth < 1040

        return ZStack(alignment: .bottom) {
            LoopingVideoView(
                playerController: viewModel.previewController,
                videoGravity: .resizeAspectFill
            )
            .ignoresSafeArea()

            backgroundOverlays

            Color.black
                .opacity(previewFadeOpacity)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Spacer(minLength: 118)

                if let wallpaper = viewModel.selectedWallpaper {
                    Group {
                        if usesCompactHeroLayout {
                            VStack(spacing: 16) {
                                heroStoryCard(for: wallpaper)
                                statusCard
                            }
                        } else {
                            HStack(alignment: .bottom, spacing: 16) {
                                heroStoryCard(for: wallpaper)
                                statusCard
                            }
                        }
                    }
                    .frame(maxWidth: contentWidth, alignment: .leading)
                }

                thumbnailDeck
                    .frame(maxWidth: contentWidth)
                    .padding(.bottom, DashboardWindowMetrics.bottomInset)
            }
            .padding(.horizontal, DashboardWindowMetrics.horizontalPadding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var backgroundOverlays: some View {
        ZStack {
            LinearGradient(
                colors: [.black.opacity(0.34), .clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.0), location: 0.00),
                    .init(color: .black.opacity(0.25), location: 0.22),
                    .init(color: .black.opacity(0.50), location: 0.48),
                    .init(color: .black.opacity(0.75), location: 0.74),
                    .init(color: .black.opacity(1.0), location: 1.00)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
        }
    }

    private func heroStoryCard(for wp: WallpaperItem) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Selected Wallpaper")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.58))
                    .textCase(.uppercase)

                Text(wp.displayName)
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                Text("Imported \(wp.importedAt.formatted(date: .abbreviated, time: .omitted)) and stored locally inside Wallmove so the live wallpaper keeps working even if the original file is removed.")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 8) {
                metadataPill("Stored in App Support", icon: "externaldrive.badge.checkmark")
                metadataPill(
                    viewModel.activeWallpaperID == wp.id ? "Desktop Live" : "Ready to Apply",
                    icon: viewModel.activeWallpaperID == wp.id ? "sparkles.tv.fill" : "display"
                )
            }

            HStack(spacing: 12) {
                Button {
                    onOpenPreview()
                } label: {
                    Label("Open Preview", systemImage: "arrow.up.forward.app")
                }
                .buttonStyle(WallmovePrimaryButtonStyle())
                .handCursor()

                if viewModel.activeWallpaperID != wp.id {
                    Button {
                        viewModel.applySelectedWallpaper()
                    } label: {
                        Label("Apply to Desktop", systemImage: "play.rectangle.on.rectangle.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .controlSize(.regular)
                    .handCursor()
                } else {
                    Label("Active on Desktop", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .glassCapsule(color: .green)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .glassCard(cornerRadius: 28)
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Live Status")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            VStack(alignment: .leading, spacing: 14) {
                statusRow(
                    title: "Desktop",
                    value: viewModel.activeWallpaper?.displayName ?? "Not applied yet",
                    isActive: viewModel.activeWallpaperID == viewModel.selectedWallpaperID
                )
                statusRow(
                    title: "Library",
                    value: "\(viewModel.wallpapers.count) imported clip\(viewModel.wallpapers.count == 1 ? "" : "s")",
                    isActive: !viewModel.wallpapers.isEmpty
                )
                statusRow(
                    title: "Launch at Login",
                    value: viewModel.launchAtLoginEnabled ? "Enabled" : "Disabled",
                    isActive: viewModel.launchAtLoginEnabled
                )
            }
        }
        .frame(width: 246, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 28)
    }

    private var thumbnailDeck: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Select")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                    Text("Switch clips with one click or use your keyboard arrows.")
                        .font(.system(size: 13))
                        .foregroundStyle(Color.white.opacity(0.58))
                }

                Spacer()

                Text("\(viewModel.wallpapers.count) wallpapers")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.58))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(viewModel.wallpapers) { wallpaper in
                        stripCard(wallpaper)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .glassCard(cornerRadius: 28)
    }

    private func stripCard(_ wallpaper: WallpaperItem) -> some View {
        let isSelected = wallpaper.id == viewModel.selectedWallpaperID

        return Button {
            selectWallpaperWithFade(wallpaper.id)
        } label: {
            ZStack(alignment: .bottomLeading) {
                if let url = wallpaper.thumbnailURL(in: AppDirectories.thumbnails),
                   let img = NSImage(contentsOf: url) {
                    Image(nsImage: img)
                        .resizable()
                        .scaledToFill()
                        .brightness(isSelected ? 0 : -0.18)
                        .saturation(isSelected ? 1 : 0.84)
                } else {
                    Rectangle()
                        .fill(Color.wmSurface)
                        .overlay {
                            Image(systemName: "film")
                                .foregroundStyle(Color.wmTextSecondary)
                        }
                        .brightness(isSelected ? 0 : -0.14)
                }

                if !isSelected {
                    Color.black.opacity(0.22)
                }

                LinearGradient(
                    colors: [.clear, .black.opacity(0.66)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                HStack(spacing: 8) {
                    Text(wallpaper.displayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    if viewModel.activeWallpaperID == wallpaper.id {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
            .frame(width: 156, height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(
                color: isSelected ? Color.white.opacity(0.34) : .clear,
                radius: isSelected ? 16 : 0
            )
            .shadow(
                color: isSelected ? Color.white.opacity(0.18) : .clear,
                radius: isSelected ? 34 : 0
            )
            .shadow(
                color: Color.black.opacity(isSelected ? 0.18 : 0.32),
                radius: isSelected ? 18 : 12,
                y: 10
            )
            .scaleEffect(isSelected ? 1.02 : 0.985)
            .animation(.spring(response: 0.22, dampingFraction: 0.84), value: isSelected)
        }
        .buttonStyle(.plain)
        .handCursor()
        .help("\(wallpaper.displayName)\(isSelected ? " selected" : "")")
    }

    private var emptyState: some View {
        VStack {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "film.stack.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Build Your First Live Wallpaper")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Import .mp4 or .mov clips and Wallmove will copy them into local storage so your desktop keeps playing smoothly.")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Button("Import Videos") {
                    viewModel.importWallpapers()
                }
                .buttonStyle(WallmovePrimaryButtonStyle())
                .handCursor()
            }
            .padding(26)
            .frame(width: 420, alignment: .leading)
            .glassCard(cornerRadius: 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func metadataPill(_ text: String, icon: String) -> some View {
        Label(text, systemImage: icon)
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.white.opacity(0.88))
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .glassCapsule(color: .white)
    }

    private func statusRow(title: String, value: String, isActive: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Circle()
                    .fill(isActive ? Color.green : Color.white.opacity(0.22))
                    .frame(width: 8, height: 8)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.58))
                    .textCase(.uppercase)
            }

            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
    }

    private func selectInitialHero() {
        guard !viewModel.wallpapers.isEmpty else { return }
        if viewModel.selectedWallpaperID == nil {
            let id = viewModel.activeWallpaperID ?? viewModel.wallpapers.first?.id
            viewModel.selectWallpaper(id: id)
        }
    }

    private func selectWallpaperWithFade(_ id: UUID) {
        guard viewModel.selectedWallpaperID != id else { return }

        pendingSelectionTask?.cancel()
        pendingSelectionTask = Task { @MainActor in
            withAnimation(.easeInOut(duration: 0.16)) {
                previewFadeOpacity = 1
            }

            try? await Task.sleep(for: .milliseconds(130))
            guard !Task.isCancelled else { return }

            viewModel.selectWallpaper(id: id)

            try? await Task.sleep(for: .milliseconds(40))
            guard !Task.isCancelled else { return }

            withAnimation(.easeOut(duration: 0.24)) {
                previewFadeOpacity = 0
            }
        }
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        guard !viewModel.wallpapers.isEmpty else { return }

        switch direction {
        case .left:
            moveSelection(offset: -1)
        case .right:
            moveSelection(offset: 1)
        default:
            break
        }
    }

    private func moveSelection(offset: Int) {
        guard let currentID = viewModel.selectedWallpaperID,
              let currentIndex = viewModel.wallpapers.firstIndex(where: { $0.id == currentID })
        else {
            if let firstID = viewModel.wallpapers.first?.id {
                selectWallpaperWithFade(firstID)
            }
            return
        }

        let nextIndex = min(
            max(currentIndex + offset, viewModel.wallpapers.startIndex),
            viewModel.wallpapers.index(before: viewModel.wallpapers.endIndex)
        )
        let nextID = viewModel.wallpapers[nextIndex].id
        selectWallpaperWithFade(nextID)
    }
}
