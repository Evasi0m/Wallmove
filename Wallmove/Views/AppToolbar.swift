import SwiftUI

struct AppToolbar: View {
    @Binding var activeTab: AppTab
    let onImport: () -> Void
    @Namespace private var tabNamespace
    @State private var isImportHovering = false

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            brandChip

            Spacer(minLength: 18)

            navigationChip

            Spacer(minLength: 18)

            importButton
        }
        .padding(.leading, 92)
        .padding(.trailing, 28)
        .padding(.top, 22)
        .padding(.bottom, 6)
    }

    private var brandChip: some View {
        HStack(spacing: 10) {
            Image(systemName: "play.rectangle.on.rectangle.fill")
                .font(.system(size: 14, weight: .semibold))
            Text("Wallmove")
                .font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassCard(cornerRadius: 22)
    }

    private var navigationChip: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                        activeTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 13, weight: activeTab == tab ? .semibold : .medium))
                        .foregroundStyle(
                            activeTab == tab
                                ? Color.wmBackground
                                : Color.white.opacity(0.70)
                        )
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background {
                            if activeTab == tab {
                                Capsule()
                                    .fill(Color.white.opacity(0.94))
                                    .matchedGeometryEffect(id: "activeTab", in: tabNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
                .handCursor()
            }
        }
        .padding(5)
        .glassCard(cornerRadius: 24)
    }

    private var importButton: some View {
        Button {
            onImport()
        } label: {
            HStack(spacing: 9) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .bold))

                Text("Import Wallpaper")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize()
                    .opacity(isImportHovering ? 1 : 0)
                    .blur(radius: isImportHovering ? 0 : 3)
                    .frame(width: isImportHovering ? 126 : 0, alignment: .leading)
                    .clipped()
            }
            .foregroundStyle(.white)
            .padding(.leading, 14)
            .padding(.trailing, isImportHovering ? 18 : 14)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 22)
            .contentShape(Capsule())
            .animation(
                .spring(response: 0.34, dampingFraction: 0.82, blendDuration: 0.12),
                value: isImportHovering
            )
        }
        .buttonStyle(.plain)
        .handCursor()
        .help("Import Videos")
        .onHover { hovering in
            isImportHovering = hovering
        }
    }
}
