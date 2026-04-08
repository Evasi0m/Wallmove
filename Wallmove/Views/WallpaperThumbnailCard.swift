import SwiftUI

struct WallpaperThumbnailCard: View {
    let wallpaper: WallpaperItem
    let isActive: Bool
    let isScreenSaver: Bool

    @State private var isHovering = false

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // ── Thumbnail ───────────────────────────────
            thumbnailImage
                .aspectRatio(16 / 9, contentMode: .fill)
                .clipped()
                .overlay {
                    if isHovering {
                        Color.black.opacity(0.30)
                            .transition(.opacity)
                    }
                }

            // ── Play icon on hover ──────────────────────
            if isHovering {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(Color.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.5), radius: 8, y: 2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity)
            }

            // ── Bottom gradient + name ──────────────────
            LinearGradient(
                colors: [.clear, .black.opacity(0.80)],
                startPoint: .center,
                endPoint: .bottom
            )
            .frame(maxWidth: .infinity)
            .overlay(alignment: .bottomLeading) {
                Text(wallpaper.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 8)
            }

            // ── Status badges (top-right) ───────────────
            VStack(alignment: .trailing, spacing: 4) {
                HStack {
                    Spacer()
                    if isActive {
                        statusBadge("Desktop", color: .green)
                    }
                    if isScreenSaver {
                        statusBadge("Screen Saver", color: .blue)
                    }
                }
                Spacer()
            }
            .padding(8)
        }
        .frame(height: 126)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(
                    isActive ? Color.green.opacity(0.70) : Color.white.opacity(0.09),
                    lineWidth: isActive ? 2 : 1
                )
        )
        .scaleEffect(isHovering ? 1.025 : 1.0)
        .animation(.easeOut(duration: 0.14), value: isHovering)
        .onHover { isHovering = $0 }
        .cursor(.pointingHand)
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
            .background(color.opacity(0.85), in: Capsule())
    }
}

// MARK: - Cursor helper

private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        onHover { inside in
            if inside { cursor.push() } else { NSCursor.pop() }
        }
    }
}
