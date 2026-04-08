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
    @Published var isPreviewPaused = false

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

    var screenSaverSummaryTitle: String {
        switch screenSaverMode {
        case .off:
            return "Screen saver is currently off"
        case .mirrorDesktop:
            return "Screen saver matches the desktop wallpaper"
        case .separate:
            return screenSaverWallpaper?.displayName ?? "A separate screen saver wallpaper is selected"
        }
    }

    var screenSaverSummaryDescription: String {
        switch screenSaverMode {
        case .off:
            return "Turn it on if you want Wallmove to keep the same mood when your Mac goes idle."
        case .mirrorDesktop:
            return "Your selected desktop wallpaper is also being used for the screen saver flow."
        case .separate:
            return "Use a different clip for the screen saver without changing the live desktop wallpaper."
        }
    }

    var lockScreenSummaryTitle: String {
        switch screenSaverMode {
        case .off:
            return "No lock screen setup is prepared yet"
        case .mirrorDesktop:
            return "Lock screen path is prepared to mirror the desktop"
        case .separate:
            return "Lock screen path is prepared with a separate wallpaper"
        }
    }

    var lockScreenSummaryDescription: String {
        switch screenSaverMode {
        case .off:
            return "Pick a screen saver source first, then use System Settings to finish the lock screen flow."
        case .mirrorDesktop:
            return "Wallmove has prepared the same wallpaper for desktop and screen saver to keep the transition consistent."
        case .separate:
            return "Wallmove has prepared a dedicated screen saver wallpaper that you can use as the lock screen path."
        }
    }

    var lockScreenCapabilityNote: String {
        "macOS lock screen follows the screen saver path. Wallmove can prepare that wallpaper choice here, but true secure lock-screen playback still requires a dedicated ScreenSaver extension."
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
        isPreviewPaused = false
        refreshPreview()
    }

    func togglePreviewPlayback() {
        isPreviewPaused.toggle()
        previewController.setPaused(isPreviewPaused)
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

    func configureScreenSaverToMirrorDesktop() {
        selectedScreenSaverMode = .mirrorDesktop
        selectedScreenSaverWallpaperID = nil
        applyScreenSaverSettings()
    }

    func configureScreenSaverWithSelectedWallpaper() {
        selectedScreenSaverMode = .separate
        selectedScreenSaverWallpaperID = selectedWallpaperID ?? activeWallpaperID
        applyScreenSaverSettings()
    }

    func openSystemSettings() {
        let settingsURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
        NSWorkspace.shared.open(settingsURL)
    }

    func renameWallpaper(id: UUID, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try library.renameWallpaper(id: id, to: trimmed)
            refreshState(preferredSelection: selectedWallpaperID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func importDroppedURLs(_ urls: [URL]) {
        let videoURLs = urls.filter { ["mp4", "mov"].contains($0.pathExtension.lowercased()) }
        guard !videoURLs.isEmpty else { return }
        do {
            let imported = try library.importVideos(from: videoURLs)
            refreshState(preferredSelection: imported.first?.id)
            refreshPreview()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var cacheSize: String {
        let fm = FileManager.default
        let total = wallpapers.compactMap { item -> Int64? in
            let url = item.videoURL(in: AppDirectories.wallpapers)
            return (try? fm.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
        }.reduce(0, +)
        let bytes = Measurement(value: Double(total), unit: UnitInformationStorage.bytes)
            .converted(to: .gigabytes)
        if bytes.value >= 1 {
            return String(format: "%.1f GB", bytes.value)
        }
        let mb = Measurement(value: Double(total), unit: UnitInformationStorage.bytes)
            .converted(to: .megabytes)
        return String(format: "%.0f MB", mb.value)
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
        previewController.setPaused(isPreviewPaused)
    }
}
