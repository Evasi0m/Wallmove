import AppKit
import SwiftUI

// MARK: - Window Metrics

enum DashboardWindowMetrics {
    static let defaultSize = CGSize(width: 1240, height: 780)
    // Fixed-size window — min/max handled in WindowConfigurationView
    static let minimumSize = defaultSize
    static let maximumSize = defaultSize
    static let contentWidth: CGFloat = 1120
    static let horizontalPadding: CGFloat = 24
    static let topInset: CGFloat = 88
    static let bottomInset: CGFloat = 24
}

// MARK: - Navigation

enum AppTab: String, CaseIterable {
    case home     = "Home"
    case library  = "Library"
    case settings = "Settings"
}

// MARK: - Dashboard (Coordinator)

struct DashboardView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    @State private var activeTab: AppTab = .home
    @State private var showingPreview = false

    var body: some View {
        ZStack(alignment: .top) {
            dashboardBackdrop

            currentContent
                .id(activeTab)
                .transition(.opacity.combined(with: .scale(scale: 0.985)))

            AppToolbar(activeTab: $activeTab, onImport: viewModel.importWallpapers)
        }
        .preferredColorScheme(.dark)
        .wallmoveWindowChrome()
        .animation(.easeInOut(duration: 0.2), value: activeTab)
        .onAppear {
            syncPreviewVisibility()
        }
        .onChange(of: activeTab) { _, _ in
            syncPreviewVisibility()
        }
        .onChange(of: showingPreview) { _, _ in
            syncPreviewVisibility()
        }
        .onDisappear {
            viewModel.setPreviewPresentation(isVisible: false)
        }
        .overlay {
            if showingPreview, viewModel.selectedWallpaper != nil {
                WallpaperPreviewView(
                    viewModel: viewModel,
                    onDismiss: dismissPreview
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.18)))
            }
        }
        .alert("Error", isPresented: errorIsPresented, actions: {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        }, message: {
            Text(viewModel.errorMessage ?? "")
        })
    }

    private var dashboardBackdrop: some View {
        ZStack {
            if let image = selectedThumbnailImage {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 60)
                    .saturation(0.82)
                    .overlay(Color.black.opacity(activeTab == .home ? 0.28 : 0.54))
                    .ignoresSafeArea()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.24, blue: 0.27),
                        Color(red: 0.07, green: 0.08, blue: 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            LinearGradient(
                colors: [.clear, .black.opacity(0.68)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var currentContent: some View {
        switch activeTab {
        case .home:
            HomeView(viewModel: viewModel, onOpenPreview: openPreview)
                .id(viewModel.previewSurfaceID)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
        case .library:
            LibraryView(viewModel: viewModel, onWallpaperTap: { id in
                viewModel.selectWallpaper(id: id)
                openPreview()
            })
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .settings:
            SettingsView(viewModel: viewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var selectedThumbnailImage: NSImage? {
        guard let wallpaper = viewModel.selectedWallpaper ?? viewModel.activeWallpaper,
              let thumbnailURL = wallpaper.thumbnailURL(in: AppDirectories.thumbnails)
        else {
            return nil
        }

        return NSImage(contentsOf: thumbnailURL)
    }

    private func openPreview() {
        guard viewModel.selectedWallpaper != nil else { return }
        showingPreview = true
    }

    private func dismissPreview() {
        showingPreview = false

        DispatchQueue.main.async {
            viewModel.rebindPreviewSurface()
        }
    }

    private func syncPreviewVisibility() {
        viewModel.setPreviewPresentation(isVisible: activeTab == .home || showingPreview)
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

private extension View {
    @ViewBuilder
    func wallmoveWindowChrome() -> some View {
        if #available(macOS 15.0, *) {
            self
                .toolbar(removing: .title)
                .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
        } else {
            self
        }
    }
}
