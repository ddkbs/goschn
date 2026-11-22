import Foundation

public struct LanguagePair: Hashable, Sendable {
    public let source: String
    public let target: String

    public init(source: String, target: String) {
        self.source = source
        self.target = target
    }

    public var reversed: LanguagePair { LanguagePair(source: target, target: source) }

    /// The user's own language: the first preferred one.
    public static func homeLanguage(preferred: [String] = Locale.preferredLanguages) -> String {
        preferred.first.map(minimal) ?? "en"
    }

    /// The first target to offer: another language the user knows, else English.
    public static func defaultTarget(preferred: [String] = Locale.preferredLanguages) -> String {
        let home = homeLanguage(preferred: preferred)
        return preferred.map(minimal).first { !$0.isSameLanguage(as: home) } ?? fallback(for: home)
    }

    /// Something useful to translate to when only one language is known.
    static func fallback(for home: String) -> String {
        home.isSameLanguage(as: "en") ? "es" : "en"
    }

    private static func minimal(_ id: String) -> String {
        Locale.Language(identifier: id).minimalIdentifier
    }
}
