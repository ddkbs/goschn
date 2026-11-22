import Testing
@testable import RueberCore

@Suite struct LanguagePairTests {
    @Test func reverse() {
        #expect(LanguagePair(source: "de", target: "en").reversed == LanguagePair(source: "en", target: "de"))
    }

    @Test func homeLanguageIsTheFirstPreferredOne() {
        #expect(LanguagePair.homeLanguage(preferred: ["en-US", "de-DE"]) == "en")
        #expect(LanguagePair.homeLanguage(preferred: ["fr-FR"]) == "fr")
        #expect(LanguagePair.homeLanguage(preferred: []) == "en")
    }

    @Test func defaultTarget() {
        #expect(LanguagePair.defaultTarget(preferred: ["de-DE"]) == "en")
        #expect(LanguagePair.defaultTarget(preferred: ["en-US", "en-GB"]) == "es")
        #expect(LanguagePair.defaultTarget(preferred: ["de-DE", "fr-FR", "en-US"]) == "fr")
    }
}
