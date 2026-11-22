import CoreGraphics
import Testing
@testable import GoschnCore

@Suite struct PanelPositionTests {
    let window = CGSize(width: 500, height: 600)
    let area = CGRect(x: 100, y: 50, width: 1400, height: 900)

    /// The visible panel touches the window minus its margin.
    private func inner(_ position: PanelPosition) -> CGRect {
        let origin = position.origin(window: window, margin: 60, gap: 14, in: area)
        return CGRect(origin: origin, size: window).insetBy(dx: 60, dy: 60)
    }

    @Test func cornersKeepTheGap() {
        #expect(inner(.topRight).maxX == area.maxX - 14)
        #expect(inner(.topRight).maxY == area.maxY - 14)
        #expect(inner(.topLeft).minX == area.minX + 14)
        #expect(inner(.bottomLeft).minY == area.minY + 14)
        #expect(inner(.bottomRight).maxX == area.maxX - 14)
    }

    @Test func centerIsInTheUpperPart() {
        #expect(inner(.center).midX == area.midX)
        #expect(inner(.center).maxY == area.maxY - 180)
    }
}
