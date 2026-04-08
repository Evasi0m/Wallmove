import Foundation

struct WallpaperItem: Identifiable, Codable, Hashable {
    let id: UUID
    let displayName: String
    let storedVideoFileName: String
    let storedThumbnailFileName: String?
    let importedAt: Date

    var videoFileName: String {
        storedVideoFileName
    }

    func videoURL(in directory: URL) -> URL {
        directory.appendingPathComponent(storedVideoFileName, isDirectory: false)
    }

    func thumbnailURL(in directory: URL) -> URL? {
        guard let storedThumbnailFileName else {
            return nil
        }

        return directory.appendingPathComponent(storedThumbnailFileName, isDirectory: false)
    }
}
