import AppKit
import GoschnCore

/// The app's menu. It opens from the menu bar icon and from the panel, so it
/// stays reachable when the icon is hidden.
@MainActor
final class AppMenu: NSObject, NSMenuDelegate {
    struct Actions {
        let open: () -> Void
        let changeShortcut: () -> Void
        let setMenuBarIcon: (Bool) -> Void
    }

    let menu = NSMenu()
    private let settings: Settings
    private let model: PanelModel
    private let actions: Actions

    init(settings: Settings, model: PanelModel, actions: Actions) {
        self.settings = settings
        self.model = model
        self.actions = actions
        super.init()
        menu.delegate = self
    }

    func popUpAtMouse() {
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(entry("Translate  \(settings.hotKey.label)", #selector(open)))
        menu.addItem(.separator())
        menu.addItem(languageEntry())
        menu.addItem(entry("Change Shortcut…", #selector(changeShortcut)))
        if !Paster.canPaste {
            menu.addItem(entry("Enable Pasting…", #selector(allowPaste)))
        }
        let login = entry("Launch at Login", #selector(toggleLogin))
        login.state = settings.launchesAtLogin ? .on : .off
        menu.addItem(login)
        menu.addItem(settings.showsMenuBarIcon
            ? entry("Remove from Menu Bar…", #selector(hideIcon))
            : entry("Show in Menu Bar", #selector(showIcon)))
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Goschn", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
    }

    private func languageEntry() -> NSMenuItem {
        let parent = NSMenuItem(title: "My Language", action: nil, keyEquivalent: "")
        let submenu = NSMenu()
        for id in model.languages {
            let language = entry(AppleTranslator.displayName(id), #selector(chooseLanguage(_:)))
            language.representedObject = id
            language.state = id == settings.homeLanguage ? .on : .off
            submenu.addItem(language)
        }
        parent.submenu = submenu
        return parent
    }

    private func entry(_ title: String, _ action: Selector) -> NSMenuItem {
        let entry = NSMenuItem(title: title, action: action, keyEquivalent: "")
        entry.target = self
        return entry
    }

    @objc private func open() { actions.open() }
    @objc private func changeShortcut() { actions.changeShortcut() }
    @objc private func allowPaste() { Paster.requestPermission() }
    @objc private func hideIcon() { actions.setMenuBarIcon(false) }
    @objc private func showIcon() { actions.setMenuBarIcon(true) }

    @objc private func chooseLanguage(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? String else { return }
        model.chooseHome(id)
    }

    @objc private func toggleLogin() {
        do {
            try settings.setLaunchAtLogin(!settings.launchesAtLogin)
        } catch {
            NSApp.activate()
            NSAlert(error: error).runModal()
        }
    }
}
