import Foundation

/// Turns text into restless letters and back. Each letter is swapped for one
/// of similar width, so lines do not jump around while it happens.
public enum Scramble {
    public struct Frame: Equatable, Sendable {
        /// Already final.
        public let solid: String
        /// Still changing.
        public let noise: String

        public init(solid: String, noise: String) {
            self.solid = solid
            self.noise = noise
        }
    }

    /// Restless letters in the shape of `text`. Every tick looks different.
    public static func noise(like text: String, tick: Int, offset: Int = 0) -> String {
        // Other scripts shuffle their own letters.
        let own = text.filter { $0.isLetter && !$0.isASCII }.map { $0 }
        return String(text.enumerated().map { index, character in
            let position = index + offset
            // Letters change at different moments, which looks livelier.
            let seed = hash(position, (tick + position * 7) / 2)
            return replacement(for: character, own: own, seed: seed)
        })
    }

    /// One step of the way from `old` to `new`. What both start with stays put;
    /// the rest settles from left to right as `progress` goes from 0 to 1.
    public static func frame(from old: String, to new: String, progress: Double, tick: Int) -> Frame {
        let letters = Array(new)
        let shared = zip(old, new).prefix { $0 == $1 }.count
        let settled = shared + Int(Double(letters.count - shared) * min(max(progress, 0), 1))
        return Frame(
            solid: String(letters[..<settled]),
            noise: noise(like: String(letters[settled...]), tick: tick, offset: settled)
        )
    }

    /// What to show while `input` is being translated and only the
    /// translation `output` of the earlier text `translated` is known.
    public static func pending(input: String, translated: String, output: String, tick: Int) -> Frame {
        guard !output.isEmpty else { return Frame(solid: "", noise: noise(like: input, tick: tick)) }
        guard input.hasPrefix(translated) else { return Frame(solid: "", noise: noise(like: output, tick: tick)) }
        // The user kept typing: keep what is known and work on the rest.
        let rest = String(input.dropFirst(translated.count))
        return Frame(solid: output, noise: noise(like: rest, tick: tick, offset: output.count))
    }

    /// Seconds a change should take: quick, but long enough to be seen.
    public static func duration(from old: String, to new: String) -> Double {
        let shared = zip(old, new).prefix { $0 == $1 }.count
        return min(0.22 + Double(new.count - shared) * 0.008, 0.6)
    }

    private static let groups: [[Character]] = [
        Array("ijltfr"), Array("aceosuvxzbdghknpqy"), Array("mw"),
        Array("IJ"), Array("ABCDEFGHKLNOPQRSTUVXYZ"), Array("MW"), Array("0123456789"),
    ]

    private static func replacement(for character: Character, own: [Character], seed: Int) -> Character {
        if let group = groups.first(where: { $0.contains(character) }) { return group[seed % group.count] }
        guard character.isLetter else { return character }
        // Accented Latin letters: use the plain letter's group.
        let plain = String(character).folding(options: .diacriticInsensitive, locale: nil).first
        if let plain, let group = groups.first(where: { $0.contains(plain) }) { return group[seed % group.count] }
        return own.isEmpty ? character : own[seed % own.count]
    }

    private static func hash(_ a: Int, _ b: Int) -> Int {
        var value = UInt64(truncatingIfNeeded: a &* 73_856_093 ^ b &* 19_349_663)
        value ^= value >> 13
        value &*= 0x9E37_79B9_7F4A_7C15
        value ^= value >> 29
        return Int(value % 1_000_003)
    }
}
