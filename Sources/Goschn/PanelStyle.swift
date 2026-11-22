import AppKit
import SwiftUI

/// Measurements of the panel in one place.
enum PanelStyle {
    static let width: CGFloat = 660
    static let cornerRadius: CGFloat = 26
    static let padding: CGFloat = 24
    static let textSize: CGFloat = 22
    static let maxOutputHeight: CGFloat = 270
    /// Invisible room around the panel for its shadow.
    static let margin: CGFloat = 60
    /// The window never resizes; the panel grows inside it, from its middle.
    static let windowSize = NSSize(width: width + margin * 2, height: 740)

    static var shape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
}
