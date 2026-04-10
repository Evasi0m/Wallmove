import SwiftUI

struct WallpaperThumbnailCard: View {
    let wallpaper: WallpaperItem
    let isActive: Bool

    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            thumbnailImage
                .aspectRatio(16 / 9, contentMode: .fill)
                .clipped()
                .overlay {
                    LinearGradient(
                        colors: [
                            Color.black.opacity(isHovering ? 0.12 : 0.24),
                            Color.black.opacity(0.60)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                }

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    if isActive {
                        statusBadge("Desktop", color: .green)
                    }
                }

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 6) {
                    Text(wallpaper.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(wallpaper.importedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white.opacity(0.58))
                }
            }
            .padding(14)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 156)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovering ? 0.22 : 0.14),
                            Color.white.opacity(0.06)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isActive ? Color.green.opacity(0.16) : Color.black.opacity(0.22),
            radius: isActive ? 20 : 14,
            y: 12
        )
        .scaleEffect(isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.24, dampingFraction: 0.84), value: isHovering)
        .onHover { isHovering = $0 }
        .handCursor()
    }

    @ViewBuilder
    private var thumbnailImage: some View {
        if let url = wallpaper.thumbnailURL(in: AppDirectories.thumbnails),
           let img = NSImage(contentsOf: url) {
            Image(nsImage: img)
                .resizable()
                .scaledToFill()
        } else {
            Rectangle()
                .fill(Color.wmSurface)
                .overlay {
                    Image(systemName: "film")
                        .font(.system(size: 28))
                        .foregroundStyle(Color.wmTextSecondary)
                }
        }
    }

    private func statusBadge(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .glassCapsule(color: color)
    }
}
