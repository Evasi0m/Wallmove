import Foundation

enum AppDirectories {
    static let appFolderName = "Wallmove"

    static var applicationSupport: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent(appFolderName, isDirectory: true)
    }

    static var wallpapers: URL {
        applicationSupport.appendingPathComponent("Wallpapers", isDirectory: true)
    }

    static var thumbnails: URL {
        applicationSupport.appendingPathComponent("Thumbnails", isDirectory: true)
    }

    static var libraryMetadata: URL {
        applicationSupport.appendingPathComponent("library.json", isDirectory: false)
    }

    static func prepare() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: applicationSupport, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: wallpapers, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: thumbnails, withIntermediateDirectories: true)
    }
}
