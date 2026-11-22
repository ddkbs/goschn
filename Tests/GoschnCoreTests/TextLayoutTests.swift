import Testing
@testable import GoschnCore

@Suite struct TextLayoutTests {
    private func upper(_ text: String) -> String {
        let layout = TextLayout(text)
        return layout.rebuild(with: layout.bodies.map { $0.uppercased() })
    }

    @Test(arguments: [
        ("hallo", "HALLO"),
        ("a\n\nb", "A\n\nB"),
        ("- eins\n- zwei", "- EINS\n- ZWEI"),
        ("  1. eins\n  2) zwei", "  1. EINS\n  2) ZWEI"),
        ("## titel\n> zitat", "## TITEL\n> ZITAT"),
        ("ende \n", "ENDE \n"),
        ("12:30\n---\n🙂", "12:30\n---\n🙂"),
        ("-5 grad", "-5 GRAD"),
    ])
    func keepsLayout(input: String, expected: String) {
        #expect(upper(input) == expected)
    }

    @Test func windowsLineEndingsBecomeNewlines() {
        #expect(upper("a\r\nb") == "A\nB")
    }

    @Test func missingTranslationsKeepTheOriginal() {
        #expect(TextLayout("a\nb").rebuild(with: ["x"]) == "x\nb")
    }

    @Test func emptyText() {
        #expect(TextLayout("").bodies.isEmpty)
        #expect(TextLayout("").rebuild(with: []) == "")
    }
}
