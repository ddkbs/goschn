import GoschnCore
import SwiftUI

/// A glowing pulse that keeps racing around the edge, in a color that fits
/// the app the user came from.
struct EdgePulse: View {
    let shape: RoundedRectangle
    let color: PulseColor
    let isRunning: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var colorScheme

    private var tail: PulseColor { color.glowing(onDark: colorScheme == .dark) }
    /// White would vanish on a light panel.
    private var head: PulseColor { tail.mixedWithWhite(colorScheme == .dark ? 0.6 : 0.15) }

    var body: some View {
        Group {
            if reduceMotion {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color(cgColor: tail.cgColor), .clear, Color(cgColor: tail.cgColor)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .opacity(0.7)
            } else if isRunning {
                Pulse(shape: shape, tail: tail.cgColor, head: head.cgColor)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Pulse: NSViewRepresentable {
    let shape: RoundedRectangle
    let tail: CGColor
    let head: CGColor

    func makeNSView(context: Context) -> PulseView { PulseView(shape: shape) }
    func updateNSView(_ view: PulseView, context: Context) { view.setColors(tail: tail, head: head) }
}

private extension PulseColor {
    var cgColor: CGColor { CGColor(srgbRed: red, green: green, blue: blue, alpha: 1) }
}

/// Core Animation moves the pulse, so it costs the app no CPU time per frame.
private final class PulseView: NSView {
    /// Seconds for one lap.
    private static let lap = 2.6
    /// Share of the edge that the tail covers.
    private static let tail = 0.34
    /// Share of the edge that the bright head covers.
    private static let head = 0.10
    /// Copies in the tail, close enough to overlap.
    private static let tailCopies = 190
    private static let dash: CGFloat = 14
    private static let inset: CGFloat = 0.6

    private let shape: RoundedRectangle
    private let glowTrail = CAReplicatorLayer()
    private let tailTrail = CAReplicatorLayer()
    private let headTrail = CAReplicatorLayer()
    private var movers: [CALayer] = []
    private var drawnSize = CGSize.zero

    init(shape: RoundedRectangle) {
        self.shape = shape
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = false
        add(glowTrail, Self.glow(radius: 11), opacity: 0.11, share: Self.tail)
        add(tailTrail, Self.line, opacity: 0.6, share: Self.tail)
        add(headTrail, Self.line, opacity: 0.8, share: Self.head)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

    func setColors(tail: CGColor, head: CGColor) {
        glowTrail.instanceColor = tail
        tailTrail.instanceColor = tail
        headTrail.instanceColor = head
    }

    override var isFlipped: Bool { true }
    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func layout() {
        super.layout()
        guard bounds.size != drawnSize, !bounds.isEmpty else { return }
        drawnSize = bounds.size
        let edge = shape.path(in: bounds.insetBy(dx: Self.inset, dy: Self.inset)).cgPath
        let move = CAKeyframeAnimation(keyPath: "position")
        move.path = edge
        move.calculationMode = .paced
        move.rotationMode = .rotateAuto
        move.duration = Self.lap
        move.repeatCount = .infinity
        // A fixed start keeps the pulse in step when the panel grows, and shows
        // the whole tail from the first frame.
        move.beginTime = 0.001
        for mover in movers { mover.add(move, forKey: "move") }
    }

    /// A row of copies that follow each other and fade out.
    private func add(_ trail: CAReplicatorLayer, _ mover: CALayer, opacity: Float, share: Double) {
        let copies = max(2, Int(Double(Self.tailCopies) * share / Self.tail))
        trail.instanceCount = copies
        trail.instanceDelay = Self.lap * share / Double(copies)
        trail.instanceAlphaOffset = -1 / Float(copies)
        mover.opacity = opacity
        trail.addSublayer(mover)
        layer?.addSublayer(trail)
        movers.append(mover)
    }

    private static var line: CALayer {
        // Soft ends, so overlapping copies add up to an even line.
        let layer = CAGradientLayer()
        layer.bounds = CGRect(x: 0, y: 0, width: dash, height: 1.6)
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.colors = [0, 1, 0].map { CGColor(gray: 1, alpha: $0) }
        return layer
    }

    private static func glow(radius: CGFloat) -> CALayer {
        let layer = CAGradientLayer()
        layer.type = .radial
        layer.bounds = CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)
        layer.startPoint = CGPoint(x: 0.5, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 1)
        layer.colors = [1, 0.45, 0.12, 0].map { CGColor(gray: 1, alpha: $0) }
        return layer
    }
}
