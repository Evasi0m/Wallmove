import SwiftUI

struct WallpaperRowView: View {
    let wallpaper: WallpaperItem
    let isActive: Bool
    let isScreenSaver: Bool
    let isCompact: Bool

    var body: some View {
        HStack(spacing: isCompact ? 0 : 12) {
            thumbnail
                .frame(width: isCompact ? 56 : 92, height: isCompact ? 56 : 52)
                .clipShape(RoundedRectangle(cornerRadius: isCompact ? 12 : 10))

            if !isCompact {
                VStack(alignment: .leading, spacing: 4) {
                    Text(wallpaper.displayName)
                        .font(.headline)
                        .lineLimit(1)

                    Text(wallpaper.videoFileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if isActive {
                            label("Desktop", color: .green)
                        }

                        if isScreenSaver {
                            label("Screen Saver", color: .blue)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: isCompact ? .center : .leading)
        .padding(.vertical, isCompact ? 6 : 4)
    }

    private func label(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .glassCapsule(color: color)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let thumbnailURL = wallpaper.thumbnailURL(in: AppDirectories.thumbnails),
           let nsImage = NSImage(contentsOf: thumbnailURL) {
            Image(nsImage: nsImage)
                .resizable()
                .scaledToFill()
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary)
                Image(systemName: "film")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
