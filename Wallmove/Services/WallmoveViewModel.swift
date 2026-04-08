import AppKit
import Combine
import Foundation
import UniformTypeIdentifiers

@MainActor
final class WallmoveViewModel: ObservableObject {
    @Published private(set) var wallpapers: [WallpaperItem] = []
    @Published private(set) var activeWallpaperID: UUID?
    @Published private(set) var screenSaverWallpaperID: UUID?
    @Published private(set) var screenSaverMode: WallpaperLibrary.ScreenSaverMode = .off
    @Published var selectedWallpaperID: UUID?
    @Published var selectedScreenSaverWallpaperID: UUID?
    @Published var selectedScreenSaverMode: WallpaperLibrary.ScreenSaverMode = .off
    @Published var launchAtLoginEnabled = false
    @Published var launchAtLoginDescription = ""
    @Published var errorMessage: String?

    let previewController = LoopingVideoPlayerController()
    let launchAtLoginController = LaunchAtLoginController()

    private let library = WallpaperLibrary()
    private let wallpaperEngine = WallpaperEngine()
    private var cancellables: Set<AnyCancellable> = []

    init() {
        bindLaunchAtLogin()
        refreshState()
        applyEngineConfiguration()
        refreshPreview()
    }

    var selectedWallpaper: WallpaperItem? {
        wallpapers.first(where: { $0.id == selectedWallpaperID })
    }

    var activeWallpaper: WallpaperItem? {
        wallpapers.first(where: { $0.id == activeWallpaperID })
    }

    var screenSaverWallpaper: WallpaperItem? {
        wallpapers.first(where: { $0.id == screenSaverWallpaperID })
    }

    func importWallpapers() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.mpeg4Movie, .movie]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Choose one or more video files to copy into Wallmove."

        guard panel.runModal() == .OK else {
            return
        }

        do {
            let importedWallpapers = try library.importVideos(from: panel.urls)
            refreshState(preferredSelection: importedWallpapers.first?.id)
            refreshPreview()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applySelectedWallpaper() {
        guard let selectedWallpaper else {
            return
        }

        do {
            try library.setActiveWallpaper(id: selectedWallpaper.id)
            refreshState(preferredSelection: selectedWallpaper.id)
            applyEngineConfiguration()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteSelectedWallpaper() {
        guard let selectedWallpaper else {
            return
        }

        do {
            try library.deleteWallpaper(id: selectedWallpaper.id)
            let nextSelection = wallpapers
                .filter { $0.id != selectedWallpaper.id }
                .first?
                .id

            refreshState(preferredSelection: nextSelection)
            applyEngineConfiguration()
            refreshPreview()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func selectWallpaper(id: UUID?) {
        selectedWallpaperID = id
        refreshPreview()
    }

    func setLaunchAtLoginEnabled(_ enabled: Bool) {
        do {
            try launchAtLoginController.setEnabled(enabled)
        } catch {
            errorMessage = error.localizedDescription
            launchAtLoginController.refresh()
        }
    }

    func applyScreenSaverSettings() {
        do {
            try library.setScreenSaverMode(selectedScreenSaverMode)
            if selectedScreenSaverMode == .separate {
                try library.setScreenSaverWallpaper(id: selectedScreenSaverWallpaperID ?? selectedWallpaperID)
            }
            refreshState(preferredSelection: selectedWallpaperID)
            applyEngineConfiguration()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearCache() {
        do {
            try library.clearCache()
            refreshState(preferredSelection: nil)
            previewController.loadVideo(url: nil)
            wallpaperEngine.hideAll()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func refreshState(preferredSelection: UUID? = nil) {
        wallpapers = library.wallpapers
        activeWallpaperID = library.activeWallpaperID
        screenSaverWallpaperID = library.screenSaverWallpaperID
        screenSaverMode = library.screenSaverMode
        selectedScreenSaverMode = library.screenSaverMode
        selectedScreenSaverWallpaperID = library.screenSaverWallpaperID ?? library.activeWallpaperID

        if let preferredSelection,
           wallpapers.contains(where: { $0.id == preferredSelection }) {
            selectedWallpaperID = preferredSelection
        } else if let selectedWallpaperID,
                  wallpapers.contains(where: { $0.id == selectedWallpaperID }) {
            self.selectedWallpaperID = selectedWallpaperID
        } else {
            selectedWallpaperID = activeWallpaperID ?? wallpapers.first?.id
        }
    }

    private func bindLaunchAtLogin() {
        launchAtLoginController.$isEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.launchAtLoginEnabled = $0 }
            .store(in: &cancellables)

        launchAtLoginController.$statusDescription
            .receive(on: RunLoop.main)
            .sink { [weak self] in self?.launchAtLoginDescription = $0 }
            .store(in: &cancellables)
    }

    private func applyEngineConfiguration() {
        wallpaperEngine.configure(
            desktopURL: library.activeWallpaperURL(),
            screenSaverURL: library.screenSaverWallpaperURL()
        )
    }

    private func refreshPreview() {
        let previewURL = selectedWallpaper?.videoURL(in: AppDirectories.wallpapers)
        previewController.loadVideo(url: previewURL)
        previewController.setPaused(false)
    }
}
