import AppKit
import Carbon.HIToolbox

/// A global keyboard shortcut.
public struct HotKey: Codable, Equatable, Sendable {
    public let keyCode: UInt32
    /// Raw `NSEvent.ModifierFlags`, limited to ⌃⌥⇧⌘.
    public let modifiers: UInt

    /// ⌘⇧Space
    public static let standard = HotKey(keyCode: UInt32(kVK_Space), flags: [.command, .shift])

    public init(keyCode: UInt32, flags: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = flags.intersection([.control, .option, .shift, .command]).rawValue
    }

    public var flags: NSEvent.ModifierFlags { NSEvent.ModifierFlags(rawValue: modifiers) }

    /// Needs ⌘, ⌃ or ⌥ so it cannot swallow normal typing. F-keys work alone.
    public var isUsable: Bool {
        !flags.isDisjoint(with: [.command, .control, .option]) || Self.functionKeys[Int(keyCode)] != nil
    }

    public var carbonModifiers: UInt32 {
        var result = 0
        if flags.contains(.command) { result |= cmdKey }
        if flags.contains(.shift) { result |= shiftKey }
        if flags.contains(.option) { result |= optionKey }
        if flags.contains(.control) { result |= controlKey }
        return UInt32(result)
    }

    /// Display text such as "⇧⌘Space", in Apple's modifier order.
    public var label: String {
        var text = ""
        if flags.contains(.control) { text += "⌃" }
        if flags.contains(.option) { text += "⌥" }
        if flags.contains(.shift) { text += "⇧" }
        if flags.contains(.command) { text += "⌘" }
        return text + keyName
    }

    private var keyName: String {
        let code = Int(keyCode)
        return Self.namedKeys[code] ?? Self.functionKeys[code] ?? Self.character(for: keyCode) ?? "Key \(code)"
    }

    private static let namedKeys: [Int: String] = [
        kVK_Space: "Space", kVK_Return: "↩", kVK_Tab: "⇥", kVK_Escape: "⎋", kVK_Delete: "⌫",
        kVK_LeftArrow: "←", kVK_RightArrow: "→", kVK_UpArrow: "↑", kVK_DownArrow: "↓",
    ]

    private static let functionKeys: [Int: String] = [
        kVK_F1: "F1", kVK_F2: "F2", kVK_F3: "F3", kVK_F4: "F4", kVK_F5: "F5", kVK_F6: "F6",
        kVK_F7: "F7", kVK_F8: "F8", kVK_F9: "F9", kVK_F10: "F10", kVK_F11: "F11", kVK_F12: "F12",
    ]

    /// The character on that key in the current keyboard layout.
    private static func character(for keyCode: UInt32) -> String? {
        guard let source = TISCopyCurrentASCIICapableKeyboardLayoutInputSource()?.takeRetainedValue(),
              let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData)
        else { return nil }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue() as Data
        var deadKeys: UInt32 = 0
        var length = 0
        var chars = [UniChar](repeating: 0, count: 4)
        let status = data.withUnsafeBytes { bytes -> OSStatus in
            guard let layout = bytes.bindMemory(to: UCKeyboardLayout.self).baseAddress else { return OSStatus(paramErr) }
            return UCKeyTranslate(
                layout, UInt16(keyCode), UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()),
                OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeys, chars.count, &length, &chars
            )
        }
        guard status == noErr, length > 0 else { return nil }
        return String(utf16CodeUnits: chars, count: length).uppercased()
    }
}
