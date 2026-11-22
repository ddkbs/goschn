import AppKit
import Carbon.HIToolbox
import RueberCore

/// A small dialog that waits for the next key combination.
@MainActor
enum ShortcutRecorder {
    static func record(current: HotKey) -> HotKey? {
        let alert = NSAlert()
        alert.messageText = "Press a new shortcut"
        alert.informativeText = "Current: \(current.label)\nUse ⌘, ⌃ or ⌥ plus any key. Esc cancels."
        alert.addButton(withTitle: "Cancel")

        var result: HotKey?
        let monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if Int(event.keyCode) == kVK_Escape {
                NSApp.abortModal()
                return nil
            }
            let candidate = HotKey(keyCode: UInt32(event.keyCode), flags: event.modifierFlags)
            if candidate.isUsable {
                result = candidate
                NSApp.abortModal()
            }
            return nil
        }
        NSApp.activate()
        alert.runModal()
        alert.window.orderOut(nil)
        if let monitor { NSEvent.removeMonitor(monitor) }
        return result
    }
}
