import Testing
@testable import RueberCore

@Suite struct LanguagePairTests {
    @Test func labelAndReverse() {
        let pair = LanguagePair(source: "de", target: "en")
        #expect(pair.label == "DE → EN")
        #expect(pair.reversed.label == "EN → DE")
        #expect(LanguagePair(source: "pt-BR", target: "en").label == "PT → EN")
    }

    @Test func homeLanguageSkipsEnglish() {
        #expect(LanguagePair.homeLanguage(preferred: ["en-US", "de-DE"]) == "de")
        #expect(LanguagePair.homeLanguage(preferred: ["fr-FR"]) == "fr")
        #expect(LanguagePair.homeLanguage(preferred: ["en-GB"]) == "de")
    }
}
