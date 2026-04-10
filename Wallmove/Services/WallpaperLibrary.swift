import AVFoundation
import AppKit
import CoreMedia
import Foundation

@MainActor
final class WallpaperLibrary {
    enum LibraryError: LocalizedError {
        case unsupportedVideoFile(URL)
        case wallpaperNotFound(UUID)

        var errorDescription: String? {
            switch self {
            case .unsupportedVideoFile(let url):
                return "\"\(url.lastPathComponent)\" is not a supported video. Please use .mp4 or .mov files."
            case .wallpaperNotFound:
                return "The selected wallpaper could not be found."
            }
        }
    }

    private struct PersistedLibrary: Codable {
        var wallpapers: [WallpaperItem]
        var activeWallpaperID: UUID?

        init(wallpapers: [WallpaperItem] = [], activeWallpaperID: UUID? = nil) {
            self.wallpapers = wallpapers
            self.activeWallpaperID = activeWallpaperID
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            wallpapers = try container.decodeIfPresent([WallpaperItem].self, forKey: .wallpapers) ?? []
            activeWallpaperID = try container.decodeIfPresent(UUID.self, forKey: .activeWallpaperID)
        }
    }

    private let fileManager = FileManager.default
    private var persistedLibrary: PersistedLibrary

    var wallpapers: [WallpaperItem] {
        persistedLibrary.wallpapers.sorted { $0.importedAt > $1.importedAt }
    }

    var activeWallpaperID: UUID? {
        persistedLibrary.activeWallpaperID
    }

    init() {
        do {
            try AppDirectories.prepare()
            persistedLibrary = try Self.loadPersistedLibrary()
            try cleanMissingFiles()
            try save()
        } catch {
            persistedLibrary = PersistedLibrary()
        }
    }

    func wallpaper(with id: UUID?) -> WallpaperItem? {
        guard let id else {
            return nil
        }

        return persistedLibrary.wallpapers.first(where: { $0.id == id })
    }

    func activeWallpaper() -> WallpaperItem? {
        wallpaper(with: persistedLibrary.activeWallpaperID)
    }

    func activeWallpaperURL() -> URL? {
        guard let item = activeWallpaper() else {
            return nil
        }

        return item.videoURL(in: AppDirectories.wallpapers)
    }

    func importVideos(from sourceURLs: [URL]) throws -> [WallpaperItem] {
        try AppDirectories.prepare()

        var importedItems: [WallpaperItem] = []

        for sourceURL in sourceURLs {
            let cleanedExtension = sourceURL.pathExtension.lowercased()
            guard ["mp4", "mov"].contains(cleanedExtension) else {
                throw LibraryError.unsupportedVideoFile(sourceURL)
            }

            let accessedSecurityScope = sourceURL.startAccessingSecurityScopedResource()
            defer {
                if accessedSecurityScope {
                    sourceURL.stopAccessingSecurityScopedResource()
                }
            }

            let wallpaperID = UUID()
            let destinationVideoURL = AppDirectories.wallpapers
                .appendingPathComponent(wallpaperID.uuidString, isDirectory: false)
                .appendingPathExtension(cleanedExtension)

            if fileManager.fileExists(atPath: destinationVideoURL.path) {
                try fileManager.removeItem(at: destinationVideoURL)
            }

            try fileManager.copyItem(at: sourceURL, to: destinationVideoURL)

            let thumbnailFileName = try generateThumbnail(for: destinationVideoURL, wallpaperID: wallpaperID)

            let wallpaper = WallpaperItem(
                id: wallpaperID,
                displayName: sourceURL.deletingPathExtension().lastPathComponent,
                storedVideoFileName: destinationVideoURL.lastPathComponent,
                storedThumbnailFileName: thumbnailFileName,
                importedAt: Date()
            )

            persistedLibrary.wallpapers.append(wallpaper)
            importedItems.append(wallpaper)
        }

        try save()
        return importedItems.sorted { $0.importedAt > $1.importedAt }
    }

    func setActiveWallpaper(id: UUID?) throws {
        if let id, wallpaper(with: id) == nil {
            throw LibraryError.wallpaperNotFound(id)
        }

        persistedLibrary.activeWallpaperID = id
        try save()
    }

    func renameWallpaper(id: UUID, to newName: String) throws {
        guard let index = persistedLibrary.wallpapers.firstIndex(where: { $0.id == id }) else {
            throw LibraryError.wallpaperNotFound(id)
        }

        persistedLibrary.wallpapers[index].displayName = newName
        try save()
    }

    func deleteWallpaper(id: UUID) throws {
        guard let item = wallpaper(with: id) else {
            throw LibraryError.wallpaperNotFound(id)
        }

        let videoURL = item.videoURL(in: AppDirectories.wallpapers)
        if fileManager.fileExists(atPath: videoURL.path) {
            try fileManager.removeItem(at: videoURL)
        }

        if let thumbnailURL = item.thumbnailURL(in: AppDirectories.thumbnails),
           fileManager.fileExists(atPath: thumbnailURL.path) {
            try fileManager.removeItem(at: thumbnailURL)
        }

        persistedLibrary.wallpapers.removeAll(where: { $0.id == id })
        if persistedLibrary.activeWallpaperID == id {
            persistedLibrary.activeWallpaperID = nil
        }

        try save()
    }

    func clearCache() throws {
        let allItems = persistedLibrary.wallpapers

        for item in allItems {
            let videoURL = item.videoURL(in: AppDirectories.wallpapers)
            if fileManager.fileExists(atPath: videoURL.path) {
                try fileManager.removeItem(at: videoURL)
            }

            if let thumbnailURL = item.thumbnailURL(in: AppDirectories.thumbnails),
               fileManager.fileExists(atPath: thumbnailURL.path) {
                try fileManager.removeItem(at: thumbnailURL)
            }
        }

        persistedLibrary = PersistedLibrary()
        try save()
    }

    private static func loadPersistedLibrary() throws -> PersistedLibrary {
        let url = AppDirectories.libraryMetadata
        guard FileManager.default.fileExists(atPath: url.path) else {
            return PersistedLibrary()
        }

        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(PersistedLibrary.self, from: data)
    }

    private func cleanMissingFiles() throws {
        persistedLibrary.wallpapers.removeAll { item in
            !fileManager.fileExists(atPath: item.videoURL(in: AppDirectories.wallpapers).path)
        }

        if let activeWallpaperID,
           wallpaper(with: activeWallpaperID) == nil {
            persistedLibrary.activeWallpaperID = nil
        }
    }

    private func generateThumbnail(for videoURL: URL, wallpaperID: UUID) throws -> String? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 480, height: 270)

        let thumbnailName = "\(wallpaperID.uuidString).jpg"
        let thumbnailURL = AppDirectories.thumbnails.appendingPathComponent(thumbnailName, isDirectory: false)

        let candidateTimes = [
            CMTime(seconds: 0.2, preferredTimescale: 600),
            CMTime(seconds: 1.0, preferredTimescale: 600),
            .zero
        ]

        for time in candidateTimes {
            do {
                let image = try generator.copyCGImage(at: time, actualTime: nil)
                let representation = NSBitmapImageRep(cgImage: image)
                let properties: [NSBitmapImageRep.PropertyKey: Any] = [.compressionFactor: 0.8]
                guard let data = representation.representation(using: .jpeg, properties: properties) else {
                    continue
                }

                try data.write(to: thumbnailURL, options: .atomic)
                return thumbnailName
            } catch {
                continue
            }
        }

        return nil
    }

    private func save() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(persistedLibrary)
        try data.write(to: AppDirectories.libraryMetadata, options: .atomic)
    }
}
