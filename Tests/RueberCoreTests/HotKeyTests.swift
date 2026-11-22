import AppKit
import Carbon.HIToolbox
import Testing
@testable import RueberCore

@Suite struct HotKeyTests {
    @Test func labels() {
        #expect(HotKey.standard.label == "⇧⌘Space")
        #expect(HotKey(keyCode: UInt32(kVK_F5), flags: [.control, .option]).label == "⌃⌥F5")
    }

    @Test func needsAModifierUnlessFunctionKey() {
        #expect(HotKey.standard.isUsable)
        #expect(!HotKey(keyCode: UInt32(kVK_Space), flags: [.shift]).isUsable)
        #expect(!HotKey(keyCode: UInt32(kVK_Space), flags: []).isUsable)
        #expect(HotKey(keyCode: UInt32(kVK_F5), flags: []).isUsable)
    }

    @Test func carbonModifiers() {
        #expect(HotKey.standard.carbonModifiers == UInt32(cmdKey | shiftKey))
    }

    @Test func dropsIrrelevantFlags() {
        #expect(HotKey(keyCode: 0, flags: [.command, .capsLock]) == HotKey(keyCode: 0, flags: [.command]))
    }

    @Test func survivesEncoding() throws {
        let data = try JSONEncoder().encode(HotKey.standard)
        #expect(try JSONDecoder().decode(HotKey.self, from: data) == .standard)
    }
}
