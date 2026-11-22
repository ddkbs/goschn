import AppKit
import Carbon.HIToolbox
import SwiftUI

private final class FloatingPanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

/// Shows the floating panel without activating the app, so the app the user
/// came from keeps its cursor position and receives the paste.
@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    private let model: PanelModel
    private let panel: FloatingPanel
    private var keyMonitor: Any?
    private var commitTask: Task<Void, Never>?

    init(model: PanelModel) {
        self.model = model
        panel = FloatingPanel(
            contentRect: NSRect(origin: .zero, size: PanelStyle.windowSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false
        )
        super.init()
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false  // Drawn by the view; the window is larger than the panel.
        panel.hidesOnDeactivate = false
        panel.animationBehavior = .none
        panel.isReleasedWhenClosed = false
        panel.title = "Goschn"
        panel.delegate = self
        panel.contentView = NSHostingView(rootView: PanelView(model: model))
    }

    func toggle() { panel.isVisible ? hide() : show() }

    func show() {
        model.canPaste = Paster.canPaste
        model.translator.warmUp(model.pair)
        place()
        model.isOpen = true
        panel.makeKeyAndOrderFront(nil)
        model.focusToken += 1
        installKeyMonitor()
        // Keep an unfinished draft, but let the next keystroke replace it.
        DispatchQueue.main.async { (self.panel.firstResponder as? NSTextView)?.selectAll(nil) }
    }

    /// Pass false when a dialog of this app follows; otherwise the focus goes
    /// back to the app the user came from.
    func hide(returningFocus: Bool = true) {
        commitTask?.cancel()
        commitTask = nil
        removeKeyMonitor()
        panel.orderOut(nil)
        model.isOpen = false
        if returningFocus, NSApp.isActive { NSApp.hide(nil) }
    }

    func windowDidResignKey(_ notification: Notification) {
        // The system's download sheet takes the focus; stay open for it.
        if model.download == nil, panel.isVisible { hide() }
    }

    // MARK: - Keyboard

    private func installKeyMonitor() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, event.window === self.panel else { return event }
            return self.handle(event) ? nil : event
        }
    }

    private func removeKeyMonitor() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    /// Returns true when the key was used up.
    private func handle(_ event: NSEvent) -> Bool {
        let editor = panel.firstResponder as? NSTextView
        // Input methods (e.g. Japanese) need these keys while composing.
        if editor?.hasMarkedText() == true { return false }
        let flags = event.modifierFlags.intersection([.command, .shift, .option, .control])

        switch Int(event.keyCode) {
        case kVK_Escape:
            hide()
        case kVK_Return, kVK_ANSI_KeypadEnter:
            if flags.contains(.shift) || flags.contains(.option) {
                editor?.insertNewlineIgnoringFieldEditor(nil)
            } else {
                commit(paste: !flags.contains(.command))
            }
        case kVK_Tab:
            model.swap()
        default:
            return handleEditShortcut(event, flags: flags)
        }
        return true
    }

    /// A menu-bar app has no Edit menu, so ⌘C and friends are routed here.
    private func handleEditShortcut(_ event: NSEvent, flags: NSEvent.ModifierFlags) -> Bool {
        guard flags.contains(.command), let key = event.charactersIgnoringModifiers?.lowercased() else { return false }
        if let number = Int(key), model.chooseQuickTarget(number) { return true }
        let selector: Selector
        switch (key, flags.contains(.shift)) {
        case ("a", false): selector = #selector(NSText.selectAll(_:))
        case ("c", false): selector = #selector(NSText.copy(_:))
        case ("v", false): selector = #selector(NSText.paste(_:))
        case ("x", false): selector = #selector(NSText.cut(_:))
        case ("z", false): selector = Selector(("undo:"))
        case ("z", true): selector = Selector(("redo:"))
        default: return false
        }
        return NSApp.sendAction(selector, to: nil, from: nil)
    }

    // MARK: - Commit

    private func commit(paste: Bool) {
        guard commitTask == nil else { return }
        commitTask = Task {
            let text = await model.result()
            // Closed while waiting: do nothing behind the user's back.
            guard !Task.isCancelled else { return }
            commitTask = nil
            guard let text else { return }
            Paster.copy(text)
            hide()
            model.reset()
            guard paste, Paster.canPaste else { return }
            // Let the previous app get its focus back first.
            try? await Task.sleep(for: .milliseconds(80))
            Paster.pressPaste()
        }
    }

    // MARK: - Layout

    /// Upper third of the screen the mouse is on.
    private func place() {
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { NSMouseInRect(mouse, $0.frame, false) } ?? NSScreen.main
        guard let area = screen?.visibleFrame else { return }
        panel.setFrameTopLeftPoint(NSPoint(
            x: area.midX - panel.frame.width / 2,
            y: area.maxY - area.height * 0.2 + PanelStyle.margin
        ))
    }
}
