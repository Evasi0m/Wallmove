import SwiftUI

// MARK: - Window Metrics

enum DashboardWindowMetrics {
    static let defaultSize = CGSize(width: 1320, height: 900)
    static let minimumSize = CGSize(width: 1020, height: 720)
    static let maximumSize = CGSize(width: 1600, height: 1100)
}

// MARK: - Navigation

enum AppTab: String, CaseIterable {
    case library  = "Library"
    case settings = "Settings"
}

// MARK: - Dashboard (Coordinator)

struct DashboardView: View {
    @ObservedObject var viewModel: WallmoveViewModel
    @State private var activeTab: AppTab = .library
    @State private var showingPreview = false

    var body: some View {
        ZStack {
            Color.wmBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                AppToolbar(activeTab: $activeTab, onImport: viewModel.importWallpapers)

                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Full-screen preview overlay
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

    @ViewBuilder
    private var tabContent: some View {
        switch activeTab {
        case .library:
            LibraryView(viewModel: viewModel, onWallpaperTap: { id in
                viewModel.selectWallpaper(id: id)
                showingPreview = true
            })
        case .settings:
            SettingsView(viewModel: viewModel)
        }
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
