import SwiftUI

/// A glowing pulse that keeps racing around the edge, like a signal running
/// through redstone.
struct EdgePulse: View {
    let shape: RoundedRectangle
    let isRunning: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if reduceMotion {
                shape.strokeBorder(
                    LinearGradient(
                        colors: [Color(cgColor: PulseView.red), .clear, Color(cgColor: PulseView.red)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.2
                )
                .opacity(0.7)
            } else if isRunning {
                Pulse(shape: shape)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct Pulse: NSViewRepresentable {
    let shape: RoundedRectangle

    func makeNSView(context: Context) -> PulseView { PulseView(shape: shape) }
    func updateNSView(_ view: PulseView, context: Context) {}
}

/// Core Animation moves the pulse, so it costs the app no CPU time per frame.
final class PulseView: NSView {
    static let red = CGColor(srgbRed: 1, green: 0.16, blue: 0.12, alpha: 1)
    private static let hot = CGColor(srgbRed: 1, green: 0.72, blue: 0.58, alpha: 1)

    /// Seconds for one lap.
    private static let lap = 2.6
    /// Share of the edge that the tail covers.
    private static let tail = 0.34
    /// Share of the edge that the hot head covers.
    private static let head = 0.10
    /// Copies in the tail, close enough to overlap.
    private static let tailCopies = 110
    private static let dash: CGFloat = 14
    private static let inset: CGFloat = 0.6

    private let shape: RoundedRectangle
    private var movers: [CALayer] = []
    private var drawnSize = CGSize.zero

    init(shape: RoundedRectangle) {
        self.shape = shape
        super.init(frame: .zero)
        wantsLayer = true
        layer?.masksToBounds = false
        addTrail(Self.glow(radius: 11), color: Self.red, opacity: 0.11, share: Self.tail)
        addTrail(Self.line, color: Self.red, opacity: 0.6, share: Self.tail)
        addTrail(Self.line, color: Self.hot, opacity: 0.8, share: Self.head)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

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
    private func addTrail(_ mover: CALayer, color: CGColor, opacity: Float, share: Double) {
        let copies = max(2, Int(Double(Self.tailCopies) * share / Self.tail))
        let trail = CAReplicatorLayer()
        trail.instanceCount = copies
        trail.instanceDelay = Self.lap * share / Double(copies)
        trail.instanceAlphaOffset = -1 / Float(copies)
        trail.instanceColor = color
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
