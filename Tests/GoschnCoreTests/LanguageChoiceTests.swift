import Testing
@testable import GoschnCore

@Suite struct LanguageChoiceTests {
    private func pair(_ source: String?, _ target: String, home: String = "de", detected: String?) -> String {
        let pair = LanguageChoice(source: source, target: target, home: home).pair(detected: detected)
        return "\(pair.source)>\(pair.target)"
    }

    @Test func detectedLanguageGoesToTheTarget() {
        #expect(pair(nil, "en", detected: "de") == "de>en")
        #expect(pair(nil, "en", detected: "fr") == "fr>en")
        #expect(pair(nil, "ja", detected: "tr") == "tr>ja")
    }

    @Test func unknownTextCountsAsHomeLanguage() {
        #expect(pair(nil, "en", detected: nil) == "de>en")
    }

    @Test func targetLanguageTextGoesHome() {
        #expect(pair(nil, "en", detected: "en") == "en>de")
        #expect(pair(nil, "en", detected: "en-GB") == "en-GB>de")
    }

    @Test func homeAsTarget() {
        #expect(pair(nil, "de", detected: "fr") == "fr>de")
        #expect(pair(nil, "de", detected: "de") == "de>en")
        #expect(pair(nil, "de", detected: nil) == "en>de")
        #expect(pair(nil, "en", home: "en", detected: "en") == "en>es")
    }

    @Test func fixedSourceIgnoresDetection() {
        #expect(pair("fr", "es", detected: "de") == "fr>es")
        #expect(pair("fr", "fr", detected: "de") == "fr>de")
    }
}
