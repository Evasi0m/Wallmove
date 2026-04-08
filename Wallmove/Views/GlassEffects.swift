import SwiftUI

// MARK: - App Color Palette

extension Color {
    /// Primary window background — very dark charcoal
    static let wmBackground = Color(red: 0.11, green: 0.11, blue: 0.11)
    /// Slightly elevated surface (cards, rows)
    static let wmSurface = Color(red: 0.17, green: 0.17, blue: 0.17)
    /// Hover / pressed state
    static let wmSurfaceHover = Color(red: 0.22, green: 0.22, blue: 0.22)
    /// Subtle border
    static let wmBorder = Color.white.opacity(0.10)
    /// Primary text
    static let wmText = Color.white
    /// Secondary text
    static let wmTextSecondary = Color.white.opacity(0.45)
}

// MARK: - Primary Button Style

struct WallmovePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.black)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.white, in: Capsule())
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}

// MARK: - Liquid Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(glassBackground(cornerRadius: cornerRadius))
    }

    private func glassBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.10), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.45), .white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}

// MARK: - Liquid Glass Capsule Modifier

struct GlassCapsuleModifier: ViewModifier {
    var color: Color

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    Capsule().fill(.ultraThinMaterial)
                    Capsule().fill(color.opacity(0.15))
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [color.opacity(0.6), color.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                }
            )
    }
}

// MARK: - Liquid Glass Button Background

struct GlassButtonBackground: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.14), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.5), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.75
                        )
                }
            )
    }
}

// MARK: - View Extensions

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }

    func glassCapsule(color: Color = .primary) -> some View {
        modifier(GlassCapsuleModifier(color: color))
    }

    func glassButton(cornerRadius: CGFloat = 8) -> some View {
        modifier(GlassButtonBackground(cornerRadius: cornerRadius))
    }
}
