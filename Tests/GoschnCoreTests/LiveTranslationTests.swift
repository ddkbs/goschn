import Foundation
import Testing
@testable import GoschnCore

@MainActor
@Suite struct LiveTranslationTests {
    final class FakeEngine {
        var calls: [[String]] = []
        var failure: (any Error)?
        func translate(_ lines: [String], _ pair: LanguagePair) async throws -> [String] {
            calls.append(lines)
            try? await Task.sleep(for: .milliseconds(20))
            if let failure { throw failure }
            return lines.map { "\($0)@\(pair.target)" }
        }
    }

    let engine = FakeEngine()
    let pair = LanguagePair(source: "de", target: "en")

    private func make() -> LiveTranslation {
        LiveTranslation(delay: .milliseconds(5)) { [engine] in try await engine.translate($0, $1) }
    }

    @Test func finishReturnsTheTranslation() async {
        #expect(await make().finish("hallo", pair: pair) == "hallo@en")
    }

    @Test func finishedTextIsNotTranslatedTwice() async {
        let live = make()
        _ = await live.finish("hallo", pair: pair)
        _ = await live.finish("hallo", pair: pair)
        #expect(engine.calls.count == 1)
    }

    @Test func directionChangeTranslatesAgain() async {
        let live = make()
        _ = await live.finish("hallo", pair: pair)
        #expect(await live.finish("hallo", pair: pair.reversed) == "hallo@de")
    }

    @Test func onlyTheNewestTextIsTranslatedNext() async {
        let live = make()
        async let first = live.finish("a", pair: pair)
        await Task.yield()
        live.update("ab", pair: pair)
        live.update("abc", pair: pair)
        let last = await live.finish("abcd", pair: pair)
        #expect(await first == nil)
        #expect(last == "abcd@en")
        #expect(engine.calls.last == ["abcd"])
        #expect(!engine.calls.contains(["ab"]))
    }

    @Test func updateDebounces() async throws {
        let live = make()
        for text in ["a", "ab", "abc"] { live.update(text, pair: pair) }
        for _ in 0..<100 where live.output.isEmpty { try await Task.sleep(for: .milliseconds(10)) }
        #expect(engine.calls == [["abc"]])
        #expect(live.output == "abc@en")
        #expect(!live.isBusy)
    }

    @Test func isPendingFromKeystrokeToResult() async {
        let live = make()
        live.update("hallo", pair: pair)
        #expect(live.isPending)
        _ = await live.finish("hallo", pair: pair)
        #expect(!live.isPending)
        live.update("hallo du", pair: pair)
        #expect(live.isPending)
        live.update("", pair: pair)
        #expect(!live.isPending)
    }

    @Test func emptyTextClearsTheOutput() async {
        let live = make()
        _ = await live.finish("hallo", pair: pair)
        #expect(await live.finish("  \n", pair: pair) == nil)
        #expect(live.output.isEmpty)
    }

    @Test func clearingWhileBusyDropsTheResult() async {
        let live = make()
        async let first = live.finish("hallo", pair: pair)
        await Task.yield()
        live.update("", pair: pair)
        #expect(await first == nil)
        #expect(live.output.isEmpty)
    }

    @Test func errorsAreReportedAndRetried() async {
        let live = make()
        engine.failure = CocoaError(.featureUnsupported)
        #expect(await live.finish("hallo", pair: pair) == nil)
        #expect(live.error != nil)
        engine.failure = nil
        #expect(await live.finish("hallo", pair: pair) == "hallo@en")
        #expect(live.error == nil)
    }
}
