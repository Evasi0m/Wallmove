import SwiftUI

struct AppToolbar: View {
    @Binding var activeTab: AppTab
    let onImport: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // ── Logo ──────────────────────────────────────
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.on.rectangle.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                Text("Wallmove")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
            }
            .padding(.leading, 76)   // leave room for traffic lights

            Spacer()

            // ── Center nav pill ───────────────────────────
            HStack(spacing: 2) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            activeTab = tab
                        }
                    } label: {
                        Text(tab.rawValue)
                            .font(.system(
                                size: 13,
                                weight: activeTab == tab ? .semibold : .regular
                            ))
                            .foregroundStyle(
                                activeTab == tab
                                    ? Color.wmBackground
                                    : Color.white.opacity(0.60)
                            )
                            .padding(.horizontal, 16)
                            .padding(.vertical, 7)
                            .background {
                                if activeTab == tab {
                                    Capsule().fill(Color.white)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(4)
            .background(Color.white.opacity(0.10), in: Capsule())

            Spacer()

            // ── Right actions ─────────────────────────────
            Button {
                onImport()
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.11), in: Circle())
            }
            .buttonStyle(.plain)
            .help("Import Videos")
            .padding(.trailing, 20)
        }
        .frame(height: 52)
    }
}
