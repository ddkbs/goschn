import SwiftUI

extension View {
    /// Puts the view on a sheet of glass: see-through, with a glossy edge and
    /// a soft shadow that stays outside, so it never darkens the glass.
    func glassPanel() -> some View { modifier(GlassPanel()) }
}

private struct GlassPanel: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }
    private var shape: RoundedRectangle { PanelStyle.shape }

    func body(content: Content) -> some View {
        content
            .background(gloss)
            .clipShape(shape)
            // Just enough tint to read text over any wallpaper.
            .glassEffect(.clear.tint(isDark ? .black.opacity(0.42) : .white.opacity(0.42)), in: shape)
            .overlay(edge.allowsHitTesting(false))
            .background(shadow)
    }

    /// Light falling on the upper part of the sheet.
    private var gloss: some View {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(isDark ? 0.11 : 0.35), location: 0),
                .init(color: .white.opacity(isDark ? 0.02 : 0.08), location: 0.45),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top, endPoint: .bottom
        )
    }

    /// Bright where light hits the rim, fading along the sides.
    private var edge: some View {
        shape.strokeBorder(
            LinearGradient(
                stops: [
                    .init(color: .white.opacity(isDark ? 0.55 : 0.95), location: 0),
                    .init(color: .white.opacity(isDark ? 0.12 : 0.4), location: 0.35),
                    .init(color: .white.opacity(isDark ? 0.08 : 0.3), location: 0.7),
                    .init(color: .white.opacity(isDark ? 0.28 : 0.7), location: 1),
                ],
                startPoint: .topLeading, endPoint: .bottomTrailing
            ),
            lineWidth: 1
        )
    }

    private var shadow: some View {
        ZStack {
            shape.fill(.black).shadow(color: .black.opacity(isDark ? 0.35 : 0.2), radius: 26, y: 14)
            shape.fill(.black).blendMode(.destinationOut)
        }
        .compositingGroup()
        .allowsHitTesting(false)
    }
}
