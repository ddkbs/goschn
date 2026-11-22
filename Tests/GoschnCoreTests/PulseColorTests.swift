import Testing
@testable import GoschnCore

@Suite struct PulseColorTests {
    private func pixels(_ parts: [(color: [UInt8], count: Int)]) -> [UInt8] {
        parts.flatMap { part in (0..<part.count).flatMap { _ in part.color } }
    }

    private let white: [UInt8] = [255, 255, 255, 255]
    private let clear: [UInt8] = [0, 0, 0, 0]
    private let green: [UInt8] = [40, 200, 80, 255]
    private let blue: [UInt8] = [30, 60, 220, 255]

    @Test func theLargestColorWinsOverWhite() throws {
        let color = try #require(PulseColor.dominant(rgba: pixels([(white, 80), (green, 15), (blue, 5), (clear, 40)])))
        #expect(abs(color.green - 200.0 / 255) < 0.01)
        #expect(abs(color.red - 40.0 / 255) < 0.01)
    }

    @Test func grayIconsHaveNoColor() {
        #expect(PulseColor.dominant(rgba: pixels([(white, 50), ([40, 40, 42, 255], 50)])) == nil)
        #expect(PulseColor.dominant(rgba: pixels([(clear, 10)])) == nil)
        #expect(PulseColor.dominant(rgba: []) == nil)
    }

    @Test func transparencyIsUndone() throws {
        let color = try #require(PulseColor.dominant(rgba: [100, 0, 0, 100]))
        #expect(abs(color.red - 1) < 0.01)
    }

    @Test func redAroundTheStartOfTheHueCircleIsOneColor() throws {
        let color = try #require(PulseColor.dominant(rgba: pixels([
            ([250, 20, 40, 255], 10), ([250, 40, 20, 255], 10), (green, 14),
        ])))
        #expect(color.red > 0.9 && color.green < 0.2)
    }

    @Test(arguments: [true, false]) func glowingKeepsTheHue(onDark: Bool) {
        for color in [PulseColor(red: 0.1, green: 0.1, blue: 0.4), PulseColor(red: 0.9, green: 0.8, blue: 0.2)] {
            let glowing = color.glowing(onDark: onDark)
            #expect(abs(glowing.hue - color.hue) < 0.001)
            #expect(glowing.brightness > 0.9 && glowing.saturation >= 0.54)
        }
        let silver = PulseColor.silver.glowing(onDark: onDark)
        #expect(silver.saturation == 0 && (silver.brightness > 0.5) == onDark)
    }

    @Test func mixedWithWhite() {
        #expect(PulseColor(red: 1, green: 0, blue: 0.5).mixedWithWhite(0.5) == PulseColor(red: 1, green: 0.5, blue: 0.75))
    }
}
