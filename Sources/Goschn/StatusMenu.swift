import AppKit
import GoschnCore

/// The menu bar icon and its menu.
@MainActor
final class StatusMenu: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let settings: Settings
    private let onOpen: () -> Void
    private let onChangeShortcut: () -> Void
    private let model: PanelModel

    init(
        settings: Settings,
        onOpen: @escaping () -> Void,
        onChangeShortcut: @escaping () -> Void,
        model: PanelModel
    ) {
        self.settings = settings
        self.onOpen = onOpen
        self.onChangeShortcut = onChangeShortcut
        self.model = model
        super.init()
        item.button?.image = NSImage(systemSymbolName: "translate", accessibilityDescription: "Goschn")
        let menu = NSMenu()
        menu.delegate = self
        item.menu = menu
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        menu.addItem(entry("Translate  \(settings.hotKey.label)", #selector(open)))
        menu.addItem(.separator())
        menu.addItem(languageEntry())
        menu.addItem(entry("Change Shortcut…", #selector(changeShortcut)))
        if !Paster.canPaste {
            menu.addItem(entry("Allow Auto-Paste…", #selector(allowPaste)))
        }
        let login = entry("Launch at Login", #selector(toggleLogin))
        login.state = settings.launchesAtLogin ? .on : .off
        menu.addItem(login)
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

    @objc private func open() { onOpen() }
    @objc private func changeShortcut() { onChangeShortcut() }
    @objc private func allowPaste() { Paster.requestPermission() }

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
