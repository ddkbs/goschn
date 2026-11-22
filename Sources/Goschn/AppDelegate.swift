import AppKit
import GoschnCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings()
    private lazy var model = PanelModel(settings: settings)
    private lazy var panel = PanelController(model: model)
    private lazy var hotKey = GlobalHotKey { [weak self] in self?.panel.toggle() }
    private lazy var menu = AppMenu(settings: settings, model: model, actions: .init(
        open: { [weak self] in self?.panel.show() },
        changeShortcut: { [weak self] in self?.changeShortcut() },
        setMenuBarIcon: { [weak self] in self?.setMenuBarIcon($0) }
    ))
    private lazy var icon = MenuBarIcon(menu: menu.menu)

    func applicationDidFinishLaunching(_ notification: Notification) {
        icon.isVisible = settings.showsMenuBarIcon
        model.showMenu = { [weak self] in self?.menu.popUpAtMouse() }
        Task { await model.loadLanguages() }
        settings.enableLaunchAtLoginOnFirstRun()
        model.translator.warmUp(model.pair)
        if !hotKey.register(settings.hotKey) {
            showWarning("\(settings.hotKey.label) is not available. Choose another one in the menu (⋯).")
        }
    }

    /// Opening the app again (Finder, Spotlight) shows the panel.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        panel.show()
        return false
    }

    private func changeShortcut() {
        panel.hide(returningFocus: false)
        hotKey.unregister()  // So the current shortcut can be pressed again.
        if let new = ShortcutRecorder.record(current: settings.hotKey) {
            if hotKey.register(new) {
                settings.hotKey = new
                return
            }
            showWarning("\(new.label) is not available.")
        }
        hotKey.register(settings.hotKey)
    }

    private func setMenuBarIcon(_ isVisible: Bool) {
        if !isVisible {
            panel.hide(returningFocus: false)
            guard confirmHidingIcon() else { return }
        }
        settings.showsMenuBarIcon = isVisible
        icon.isVisible = isVisible
    }

    /// Without the icon, people need to know how to get back to the menu.
    private func confirmHidingIcon() -> Bool {
        let alert = NSAlert()
        alert.messageText = "Remove Goschn from the menu bar?"
        alert.informativeText = """
            Goschn keeps running and \(settings.hotKey.label) still opens it. \
            To bring the icon back, click ⋯ in the panel.
            """
        alert.addButton(withTitle: "Remove")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate()
        return alert.runModal() == .alertFirstButtonReturn
    }

    private func showWarning(_ text: String) {
        let alert = NSAlert()
        alert.messageText = text
        NSApp.activate()
        alert.runModal()
    }
}
