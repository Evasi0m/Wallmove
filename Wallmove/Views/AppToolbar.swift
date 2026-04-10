import SwiftUI

struct AppToolbar: View {
    @Binding var activeTab: AppTab
    let onImport: () -> Void
    @Namespace private var tabNamespace
    @State private var isImportHovering = false

    var body: some View {
        HStack(spacing: 0) {
            brandChip

            Spacer(minLength: 8)

            navigationChip

            Spacer(minLength: 8)

            importButton
        }
        .frame(maxWidth: DashboardWindowMetrics.contentWidth)
        .padding(.leading, 76)
        .padding(.trailing, DashboardWindowMetrics.horizontalPadding)
        .padding(.top, 18)
        .padding(.bottom, 8)
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
        .padding(.vertical, 10)
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
        .padding(4)
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
                    .frame(width: isImportHovering ? nil : 0, alignment: .leading)
                    .clipped()
            }
            .foregroundStyle(.white)
            .padding(.leading, 13)
            .padding(.trailing, isImportHovering ? 16 : 13)
            .padding(.vertical, 10)
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
