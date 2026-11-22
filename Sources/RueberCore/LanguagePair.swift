import Foundation

public struct LanguagePair: Hashable, Sendable {
    public let source: String
    public let target: String

    public init(source: String, target: String) {
        self.source = source
        self.target = target
    }

    public var reversed: LanguagePair { LanguagePair(source: target, target: source) }

    /// Short label such as "DE → EN".
    public var label: String { "\(Self.short(source)) → \(Self.short(target))" }

    private static func short(_ id: String) -> String {
        id.split(separator: "-").first.map { $0.uppercased() } ?? id.uppercased()
    }

    /// The user's own language: the first preferred one that is not English.
    public static func homeLanguage(preferred: [String] = Locale.preferredLanguages) -> String {
        preferred
            .map { Locale.Language(identifier: $0).minimalIdentifier }
            .first { !$0.hasPrefix("en") } ?? "de"
    }
}
