import AppKit
import SwiftUI

/// Measurements and colors of the panel in one place.
enum PanelStyle {
    static let width: CGFloat = 680
    static let cornerRadius: CGFloat = 14
    static let padding: CGFloat = 18
    static let textSize: CGFloat = 20
    static let footerHeight: CGFloat = 38
    static let maxOutputHeight: CGFloat = 260
    /// Invisible room around the panel for its shadow.
    static let margin: CGFloat = 60
    /// The window never resizes; the panel grows inside it.
    static let windowSize = NSSize(width: width + margin * 2, height: 720)

    static let background = dynamic(light: NSColor(white: 1, alpha: 1), dark: NSColor(white: 0.11, alpha: 1))
    static let footer = dynamic(light: NSColor(white: 0.965, alpha: 1), dark: NSColor(white: 0.135, alpha: 1))
    static let line = Color.primary.opacity(0.08)
    static let border = Color.primary.opacity(0.14)

    private static func dynamic(light: NSColor, dark: NSColor) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua ? dark : light
        })
    }
}
