import AppKit
import RueberCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings = Settings()
    private lazy var model = PanelModel(settings: settings)
    private lazy var panel = PanelController(model: model)
    private lazy var hotKey = GlobalHotKey { [weak self] in self?.panel.toggle() }
    private var menu: StatusMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        menu = StatusMenu(
            settings: settings,
            onOpen: { [weak self] in self?.panel.show() },
            onChangeShortcut: { [weak self] in self?.changeShortcut() },
            onLanguageChange: { [weak self] in self?.model.refresh() }
        )
        settings.enableLaunchAtLoginOnFirstRun()
        model.translator.warmUp(model.pair)
        if !hotKey.register(settings.hotKey) {
            showWarning("\(settings.hotKey.label) is not available. Choose another shortcut in the menu bar.")
        }
    }

    /// Opening the app again (Finder, Spotlight) shows the panel.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool) -> Bool {
        panel.show()
        return false
    }

    private func changeShortcut() {
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

    private func showWarning(_ text: String) {
        let alert = NSAlert()
        alert.messageText = text
        NSApp.activate()
        alert.runModal()
    }
}
