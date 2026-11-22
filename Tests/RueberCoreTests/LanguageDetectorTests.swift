import Testing
@testable import RueberCore

@Suite struct LanguageDetectorTests {
    let detector = LanguageDetector(supported: [
        "ar-SA", "da", "de", "en", "en-GB", "es", "fr", "it", "ja", "ko", "nb", "nl", "pl", "pt", "ru", "sv", "tr",
        "uk", "zh", "zh-TW",
    ])

    @Test(arguments: [
        ("schau mal ob der Button noch kaputt ist", "de"),
        ("ok mach das", "de"),
        ("see you tomorrow at the station", "en"),
        ("je suis un peu en retard ce soir", "fr"),
        ("nos vemos mañana por la tarde", "es"),
        ("bugün biraz geç kalacağım", "tr"),
        ("今日は少し遅れます", "ja"),
        ("сегодня я немного опоздаю", "ru"),
        ("我今天會晚一點到", "zh-TW"),
        ("我今天会晚一点到", "zh"),
    ])
    func detects(text: String, expected: String) {
        #expect(detector.detect(text, home: "de", target: "en") == expected)
    }

    @Test(arguments: ["", "ok", "12:30", "🙂"])
    func tooShort(text: String) {
        #expect(detector.detect(text, home: "de", target: "en") == nil)
    }

    @Test func matchesVariants() {
        #expect(detector.match("no", preferring: []) == "nb")
        #expect(detector.match("ar", preferring: []) == "ar-SA")
        #expect(detector.match("en", preferring: ["de", "en-GB"]) == "en-GB")
        #expect(detector.match("fi", preferring: []) == nil)
    }
}
