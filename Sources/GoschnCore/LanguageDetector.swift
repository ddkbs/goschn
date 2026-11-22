import Foundation
import NaturalLanguage

/// Guesses the language of a text, leaning towards the user's own languages
/// because short texts are ambiguous.
public struct LanguageDetector: Sendable {
    /// Languages the translator offers, e.g. "de", "pt", "zh-TW".
    public let supported: [String]

    public init(supported: [String]) {
        self.supported = supported
    }

    /// Returns nil when there is too little text or no clear answer.
    public func detect(_ text: String, home: String, target: String) -> String? {
        guard text.filter(\.isLetter).count >= 3 else { return nil }
        let recognizer = NLLanguageRecognizer()
        recognizer.languageHints = hints(home: home, target: target)
        recognizer.processString(text)
        guard let (language, confidence) = recognizer.languageHypotheses(withMaximum: 1).first,
              confidence >= 0.6
        else { return nil }
        return match(language.rawValue, preferring: [home, target])
    }

    /// Finds the offered variant for a detected language ("zh-Hant" → "zh-TW").
    func match(_ detected: String, preferring preferred: [String]) -> String? {
        let id = Locale.Language(identifier: detected).minimalIdentifier
        if let variant = preferred.first(where: { $0.isSameLanguage(as: id) }) { return variant }
        if supported.contains(id) { return id }
        return supported.first { $0.isSameLanguage(as: id) }
    }

    private func hints(home: String, target: String) -> [NLLanguage: Double] {
        var hints: [NLLanguage: Double] = [:]
        for id in supported { hints[Self.naturalLanguage(id)] = 0.02 }
        hints[Self.naturalLanguage(target)] = 0.2
        hints[Self.naturalLanguage(home)] = 0.4
        return hints
    }

    private static func naturalLanguage(_ id: String) -> NLLanguage {
        let language = Locale.Language(identifier: id)
        let code = language.languageCode?.identifier ?? id
        switch code {
        case "zh": return language.script?.identifier == "Hant" ? .traditionalChinese : .simplifiedChinese
        case "nb": return .norwegian
        default: return NLLanguage(rawValue: code)
        }
    }
}

extension String {
    /// Compares language identifiers without region: "en-GB" equals "en".
    /// Simplified and traditional Chinese stay separate.
    func isSameLanguage(as other: String) -> Bool {
        let a = Locale.Language(identifier: self)
        let b = Locale.Language(identifier: other)
        return Self.baseCode(a) == Self.baseCode(b) && a.script == b.script
    }

    private static func baseCode(_ language: Locale.Language) -> String? {
        let code = language.languageCode?.identifier
        return code == "no" ? "nb" : code
    }
}
