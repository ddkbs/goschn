import CoreGraphics

/// Where the panel opens on the screen.
public enum PanelPosition: String, CaseIterable, Sendable {
    case topRight, topLeft, bottomRight, bottomLeft, center

    public var title: String {
        switch self {
        case .topRight: "Top Right"
        case .topLeft: "Top Left"
        case .bottomRight: "Bottom Right"
        case .bottomLeft: "Bottom Left"
        case .center: "Center"
        }
    }

    public var isBottom: Bool { self == .bottomRight || self == .bottomLeft }
    public var isLeft: Bool { self == .topLeft || self == .bottomLeft }
    public var isRight: Bool { self == .topRight || self == .bottomRight }

    /// Origin of a window that holds the panel with an invisible `margin`
    /// around it, so that the panel itself keeps `gap` to the screen edge.
    public func origin(window: CGSize, margin: CGFloat, gap: CGFloat, in area: CGRect) -> CGPoint {
        let x = if isLeft {
            area.minX + gap - margin
        } else if isRight {
            area.maxX - gap + margin - window.width
        } else {
            area.midX - window.width / 2
        }
        let y = if isBottom {
            area.minY + gap - margin
        } else if self == .center {
            area.maxY - area.height * 0.2 + margin - window.height
        } else {
            area.maxY - gap + margin - window.height
        }
        return CGPoint(x: x, y: y)
    }
}
