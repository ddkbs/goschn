import Testing
@testable import GoschnCore

@Suite struct ScrambleTests {
    @Test func noiseKeepsTheShape() {
        let noise = Scramble.noise(like: "Hallo, Welt 42!\n- ü", tick: 3)
        #expect(noise.count == "Hallo, Welt 42!\n- ü".count)
        for (a, b) in zip("Hallo, Welt 42!\n- ü", noise) {
            #expect(a.isLetter == b.isLetter && a.isNumber == b.isNumber && a.isUppercase == b.isUppercase)
            if !a.isLetter, !a.isNumber { #expect(a == b) }
        }
    }

    @Test func noiseIsRepeatableAndRestless() {
        #expect(Scramble.noise(like: "translation", tick: 1) == Scramble.noise(like: "translation", tick: 1))
        #expect(Scramble.noise(like: "translation", tick: 1) != Scramble.noise(like: "translation", tick: 9))
    }

    @Test func otherScriptsUseTheirOwnLetters() {
        let noise = Scramble.noise(like: "今日は少し", tick: 4)
        #expect(noise.count == 5)
        #expect(noise.allSatisfy { "今日は少し".contains($0) })
    }

    @Test func frameSettlesFromTheSharedStart() {
        let start = Scramble.frame(from: "I am here", to: "I am late", progress: 0, tick: 1)
        #expect(start.solid == "I am ")
        #expect(start.noise.count == 4)
        let end = Scramble.frame(from: "I am here", to: "I am late", progress: 1, tick: 1)
        #expect(end == .init(solid: "I am late", noise: ""))
        #expect(Scramble.frame(from: "", to: "x", progress: 7, tick: 1).solid == "x")
    }

    @Test func pendingBeforeAnyTranslation() {
        let frame = Scramble.pending(input: "Hallo du", translated: "", output: "", tick: 1)
        #expect(frame.solid.isEmpty)
        #expect(frame.noise.count == 8)
    }

    @Test func pendingKeepsWhatIsKnown() {
        let frame = Scramble.pending(input: "Hallo du", translated: "Hallo", output: "Hello", tick: 1)
        #expect(frame.solid == "Hello")
        #expect(frame.noise.count == 3)
    }

    @Test func pendingAfterAnEditInTheMiddle() {
        let frame = Scramble.pending(input: "Hi du", translated: "Hallo", output: "Hello", tick: 1)
        #expect(frame.solid.isEmpty)
        #expect(frame.noise.count == 5)
    }

    @Test func durationIsBounded() {
        #expect(Scramble.duration(from: "", to: "a") < 0.3)
        #expect(Scramble.duration(from: "", to: String(repeating: "a", count: 900)) == 0.6)
    }
}
