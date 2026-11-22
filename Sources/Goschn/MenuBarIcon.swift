import AppKit

/// The optional icon in the menu bar.
@MainActor
final class MenuBarIcon {
    private let menu: NSMenu
    private var item: NSStatusItem?

    init(menu: NSMenu) {
        self.menu = menu
    }

    var isVisible: Bool {
        get { item != nil }
        set { newValue ? show() : hide() }
    }

    private func show() {
        guard item == nil else { return }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "mouth.fill", accessibilityDescription: "Goschn")
        item.menu = menu
        self.item = item
    }

    private func hide() {
        if let item { NSStatusBar.system.removeStatusItem(item) }
        item = nil
    }
}
