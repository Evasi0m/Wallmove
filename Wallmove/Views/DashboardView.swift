import SwiftUI

// MARK: - Window Metrics

enum DashboardWindowMetrics {
    static let defaultSize = CGSize(width: 1320, height: 900)
    // Fixed-size window — min/max handled in WindowConfigurationView
    static let minimumSize = defaultSize
    static let maximumSize = defaultSize
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
            Color.wmBackground.ignoresSafeArea()

            // ── Tab content ──────────────────────────────
            Group {
                switch activeTab {
                case .home:
                    HomeView(viewModel: viewModel, onOpenPreview: openPreview)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea()
                case .library:
                    VStack(spacing: 0) {
                        Spacer().frame(height: 52)
                        LibraryView(viewModel: viewModel, onWallpaperTap: { id in
                            viewModel.selectWallpaper(id: id)
                            openPreview()
                        })
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                case .settings:
                    VStack(spacing: 0) {
                        Spacer().frame(height: 52)
                        SettingsView(viewModel: viewModel)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // ── Toolbar (always on top) ───────────────────
            AppToolbar(activeTab: $activeTab, onImport: viewModel.importWallpapers)
                .background {
                    if activeTab == .home {
                        // Gradient so nav text stays readable over hero video
                        LinearGradient(
                            colors: [Color.black.opacity(0.60), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 90)
                    } else {
                        Color.wmBackground
                    }
                }
        }
        // ── Full-screen preview overlay ──────────────────
        .overlay {
            if showingPreview, viewModel.selectedWallpaper != nil {
                WallpaperPreviewView(
                    viewModel: viewModel,
                    onDismiss: { showingPreview = false }
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

    private func openPreview() {
        guard viewModel.selectedWallpaper != nil else { return }
        showingPreview = true
    }

    private var errorIsPresented: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )
    }
}

#Preview {
    DashboardView(viewModel: WallmoveViewModel())
}
