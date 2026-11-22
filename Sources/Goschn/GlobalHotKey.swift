import AppKit
import Carbon.HIToolbox
import GoschnCore

/// Registers one system-wide shortcut. Carbon hot keys need no permission.
@MainActor
final class GlobalHotKey {
    private var reference: EventHotKeyRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return noErr }
            let hotKey = Unmanaged<GlobalHotKey>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { hotKey.action() }
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    /// Returns false if the system refuses the shortcut.
    @discardableResult
    func register(_ hotKey: HotKey) -> Bool {
        unregister()
        let id = EventHotKeyID(signature: OSType(0x474F_5348), id: 1)  // "GOSH"
        let status = RegisterEventHotKey(
            hotKey.keyCode, hotKey.carbonModifiers, id, GetApplicationEventTarget(), 0, &reference
        )
        return status == noErr
    }

    func unregister() {
        if let reference { UnregisterEventHotKey(reference) }
        reference = nil
    }
}
