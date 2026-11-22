import AppKit
import SwiftUI

/// Measurements of the panel in one place.
enum PanelStyle {
    static let width: CGFloat = 400
    static let cornerRadius: CGFloat = 22
    static let padding: CGFloat = 16
    static let textSize: CGFloat = 16
    static let maxOutputHeight: CGFloat = 200
    static let mouthSize = CGSize(width: 26, height: 20)
    static let mouthSpacing: CGFloat = 12
    /// Distance to the edges of the screen.
    static let gap: CGFloat = 14
    /// Invisible room around the panel for its shadow.
    static let margin: CGFloat = 60
    /// The window never resizes; the panel grows inside it.
    static let windowSize = NSSize(width: width + margin * 2, height: 560)

    static var shape: RoundedRectangle { RoundedRectangle(cornerRadius: cornerRadius, style: .continuous) }
}
