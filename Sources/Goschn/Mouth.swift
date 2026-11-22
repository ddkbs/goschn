import SwiftUI

/// The little Goschn: shut while nothing happens, talks while translating
/// and grins when it is done.
struct Mouth: View {
    enum Mood {
        case quiet, talking, happy
    }

    let mood: Mood

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if mood == .talking, !reduceMotion {
                TimelineView(.animation) { context in
                    face(open: Self.talk(at: context.date))
                }
            } else {
                face(open: restingOpenness)
            }
        }
        .frame(width: PanelStyle.mouthSize.width, height: PanelStyle.mouthSize.height)
        .animation(.spring(duration: 0.35, bounce: 0.35), value: mood)
        .accessibilityHidden(true)
    }

    private var restingOpenness: Double {
        switch mood {
        case .quiet: 0
        case .talking: 0.45
        case .happy: 0.8
        }
    }

    /// Two slow waves on top of each other, like unhurried speech.
    private static func talk(at date: Date) -> Double {
        let time = date.timeIntervalSinceReferenceDate
        return 0.42 + 0.22 * sin(time * 7) + 0.14 * sin(time * 4.3)
    }

    private func face(open: Double) -> some View {
        let lips = Lips(open: open)
        return ZStack {
            lips.fill(Color(red: 0.36, green: 0.05, blue: 0.12))
            Inside().mask(lips)
            lips.stroke(.primary, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

/// Teeth and tongue; the lips decide how much of them shows.
private struct Inside: View {
    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            Ellipse()
                .fill(Color(red: 0.96, green: 0.42, blue: 0.47))
                .frame(width: size.width * 0.56, height: size.height * 0.5)
                .position(x: size.width / 2, y: size.height * 0.98)
            Rectangle()
                .fill(.white)
                .frame(width: size.width, height: size.height * 0.42)
                .position(x: size.width / 2, y: size.height * 0.2)
        }
    }
}

/// A smiling line that opens downwards.
private struct Lips: Shape {
    /// 0 is shut, 1 is wide open.
    var open: Double

    var animatableData: Double {
        get { open }
        set { open = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let left = CGPoint(x: rect.minX + 2, y: rect.minY + rect.height * 0.3)
        let right = CGPoint(x: rect.maxX - 2, y: left.y)
        // Shut, both lips share one curve: a smile.
        let shut = rect.height * 0.32
        let upper = shut * (1 - open) - rect.height * 0.06 * open
        let lower = shut + rect.height * 0.58 * open
        var path = Path()
        path.move(to: left)
        path.addCurve(
            to: right,
            control1: CGPoint(x: rect.minX + rect.width * 0.3, y: left.y + upper * 1.33),
            control2: CGPoint(x: rect.minX + rect.width * 0.7, y: left.y + upper * 1.33)
        )
        path.addCurve(
            to: left,
            control1: CGPoint(x: rect.minX + rect.width * (0.7 + 0.2 * open), y: left.y + lower * 1.33),
            control2: CGPoint(x: rect.minX + rect.width * (0.3 - 0.2 * open), y: left.y + lower * 1.33)
        )
        path.closeSubpath()
        return path
    }
}
