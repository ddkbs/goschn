import Foundation

/// Splits text into lines so each line's wording can be translated while its
/// layout (indentation, bullets, blank lines) is kept exactly as typed.
public struct TextLayout: Equatable, Sendable {
    public struct Line: Equatable, Sendable {
        public let prefix: String
        public let body: String
        public let suffix: String
        public var isTranslatable: Bool { body.contains(where: \.isLetter) }
    }

    public let lines: [Line]

    public init(_ text: String) {
        lines = text
            .split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
            .map { Self.parse($0) }
    }

    /// The pieces that need translating, in order.
    public var bodies: [String] { lines.filter(\.isTranslatable).map(\.body) }

    /// Puts translated bodies back into the original layout.
    /// Lines without a matching translation keep their original body.
    public func rebuild(with translations: [String]) -> String {
        var rest = translations[...]
        return lines.map { line in
            let body = line.isTranslatable ? (rest.popFirst() ?? line.body) : line.body
            return line.prefix + body + line.suffix
        }.joined(separator: "\n")
    }

    private static func parse(_ line: Substring) -> Line {
        // Indentation, then an optional list, quote or heading marker.
        let marker = #/^\s*(?:(?:[-*+•>]|#{1,6}|\d{1,3}[.)])\s+)?/#
        let prefix = line.prefixMatch(of: marker).map { String($0.output) } ?? ""
        var body = line.dropFirst(prefix.count)
        var suffix = ""
        while let last = body.last, last.isWhitespace {
            suffix.insert(last, at: suffix.startIndex)
            body.removeLast()
        }
        return Line(prefix: prefix, body: String(body), suffix: suffix)
    }
}
