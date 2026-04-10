import AppKit
import SwiftUI

// MARK: - App Color Palette

extension Color {
    static let wmBackground = Color(red: 0.06, green: 0.07, blue: 0.08)
    static let wmSurface = Color(red: 0.15, green: 0.17, blue: 0.18)
    static let wmSurfaceHover = Color(red: 0.22, green: 0.24, blue: 0.26)
    static let wmBorder = Color.white.opacity(0.10)
    static let wmText = Color.white
    static let wmTextSecondary = Color.white.opacity(0.45)
    static let wmShadow = Color.black.opacity(0.30)
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
            .shadow(color: Color.black.opacity(0.18), radius: 18, y: 8)
            .opacity(configuration.isPressed ? 0.75 : 1.0)
    }
}

// MARK: - Liquid Glass Card Modifier

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(glassBackground(cornerRadius: cornerRadius))
            .shadow(color: Color.black.opacity(0.28), radius: 32, y: 18)
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
                    Capsule().fill(color.opacity(0.12))
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

    func handCursor() -> some View {
        onHover { inside in
            if inside {
                NSCursor.pointingHand.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
