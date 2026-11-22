import Foundation

/// Which languages the user picked, and the pair that follows for a text.
public struct LanguageChoice: Equatable, Sendable {
    /// nil means: detect it.
    public var source: String?
    public var target: String
    public var home: String

    public init(source: String? = nil, target: String, home: String) {
        self.source = source
        self.target = target
        self.home = home
    }

    /// Text that is already in the target language is translated back to the
    /// user's own language, so one shortcut works in both directions.
    public func pair(detected: String?) -> LanguagePair {
        let source = self.source ?? detected ?? home
        guard source.isSameLanguage(as: target) else { return LanguagePair(source: source, target: target) }
        let other = home.isSameLanguage(as: target) ? LanguagePair.fallback(for: home) : home
        // Nothing detected and home is the target: the text is foreign.
        if self.source == nil, detected == nil { return LanguagePair(source: other, target: target) }
        return LanguagePair(source: source, target: other)
    }
}
