/// The color of the pulse, taken from an app icon.
public struct PulseColor: Equatable, Sendable {
    public var red, green, blue: Double

    public static let silver = PulseColor(red: 0.75, green: 0.75, blue: 0.75)

    public init(red: Double, green: Double, blue: Double) {
        self.red = red
        self.green = green
        self.blue = blue
    }

    /// The color that stands out most, or nil if the icon is (almost) gray.
    /// Expects 8-bit RGBA with premultiplied alpha.
    public static func dominant(rgba: [UInt8]) -> PulseColor? {
        let count = 24
        var buckets = [(weight: Double, red: Double, green: Double, blue: Double)](repeating: (0, 0, 0, 0), count: count)
        var visible = 0.0
        for i in stride(from: 0, to: rgba.count - 3, by: 4) where rgba[i + 3] > 0 {
            let alpha = Double(rgba[i + 3]) / 255
            let color = PulseColor(
                red: Double(rgba[i]) / 255 / alpha, green: Double(rgba[i + 1]) / 255 / alpha,
                blue: Double(rgba[i + 2]) / 255 / alpha
            )
            visible += alpha
            let weight = alpha * color.saturation * color.brightness
            let bucket = Int(color.hue * Double(count)) % count
            buckets[bucket].weight += weight
            buckets[bucket].red += weight * color.red
            buckets[bucket].green += weight * color.green
            buckets[bucket].blue += weight * color.blue
        }
        // Similar hues may fall into neighboring buckets.
        let groups = (0..<count).map { index in
            [count - 1, 0, 1].map { buckets[(index + $0) % count] }
        }
        func weight(_ group: [(weight: Double, red: Double, green: Double, blue: Double)]) -> Double {
            group.reduce(0) { $0 + $1.weight }
        }
        guard let best = groups.max(by: { weight($0) < weight($1) }), visible > 0, weight(best) / visible > 0.03 else {
            return nil
        }
        let total = weight(best)
        return PulseColor(
            red: best.reduce(0) { $0 + $1.red } / total,
            green: best.reduce(0) { $0 + $1.green } / total,
            blue: best.reduce(0) { $0 + $1.blue } / total
        )
    }

    /// The same hue, bright enough to glow on a dark panel and strong enough
    /// to be seen on a light one. Gray stays gray.
    public func glowing(onDark: Bool) -> PulseColor {
        if saturation < 0.05 { return PulseColor(hue: 0, saturation: 0, brightness: onDark ? 1 : 0.45) }
        let saturation = onDark ? min(max(saturation, 0.55), 0.78) : min(max(saturation, 0.7), 0.95)
        return PulseColor(hue: hue, saturation: saturation, brightness: onDark ? 1 : 0.92)
    }

    public func mixedWithWhite(_ share: Double) -> PulseColor {
        PulseColor(red: red + (1 - red) * share, green: green + (1 - green) * share, blue: blue + (1 - blue) * share)
    }

    // MARK: - Hue, saturation, brightness

    init(hue: Double, saturation: Double, brightness: Double) {
        func channel(_ n: Double) -> Double {
            let k = (n + hue * 6).truncatingRemainder(dividingBy: 6)
            return brightness - brightness * saturation * max(0, min(k, 4 - k, 1))
        }
        self.init(red: channel(5), green: channel(3), blue: channel(1))
    }

    var brightness: Double { max(red, green, blue) }

    var saturation: Double { brightness == 0 ? 0 : (brightness - min(red, green, blue)) / brightness }

    /// 0 is red, 1/3 green, 2/3 blue.
    var hue: Double {
        let range = brightness - min(red, green, blue)
        guard range > 0 else { return 0 }
        let sixth = switch brightness {
        case red: (green - blue) / range
        case green: (blue - red) / range + 2
        default: (red - green) / range + 4
        }
        return (sixth < 0 ? sixth + 6 : sixth) / 6
    }
}
