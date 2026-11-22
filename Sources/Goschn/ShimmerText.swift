import SwiftUI

/// Dimmed text with a soft light passing over it: "working on it".
struct ShimmerText: View {
    let text: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Seconds for one pass of the light.
    private static let period = 1.8
    /// Width of the light, relative to the text.
    private static let band = 0.35

    var body: some View {
        Text(text)
            .foregroundStyle(.primary.opacity(0.38))
            .overlay {
                if !reduceMotion {
                    TimelineView(.animation) { context in
                        Text(text).mask { light(at: context.date) }
                    }
                    .accessibilityHidden(true)
                }
            }
    }

    /// Follows the clock instead of a start time, so typing never restarts it.
    private func light(at date: Date) -> some View {
        let progress = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: Self.period) / Self.period
        let center = -Self.band + progress * (1 + Self.band * 2)
        return LinearGradient(
            colors: [.clear, .white.opacity(0.9), .clear],
            startPoint: UnitPoint(x: center - Self.band, y: 0.5),
            endPoint: UnitPoint(x: center + Self.band, y: 0.5)
        )
    }
}
