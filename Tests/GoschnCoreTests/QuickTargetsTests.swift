import Testing
@testable import GoschnCore

@Suite struct QuickTargetsTests {
    @Test func slotsKeepTheirPosition() {
        var quick = QuickTargets(["en", "de", "en"])
        #expect(quick.languages == ["en", "de"])
        quick.use("fr")
        quick.use("de")
        #expect(quick.languages == ["en", "de", "fr"])
        #expect(quick.language(at: 3) == "fr")
        #expect(quick.language(at: 4) == nil)
        #expect(quick.language(at: 0) == nil)
    }

    @Test func onlyTheLastSlotIsReplaced() {
        var quick = QuickTargets(["en", "de", "fr", "es", "it"])
        quick.use("ja")
        #expect(quick.languages == ["en", "de", "fr", "es", "ja"])
    }
}
