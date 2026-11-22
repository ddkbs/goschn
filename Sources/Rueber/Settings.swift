import Foundation
import RueberCore
import ServiceManagement

@MainActor
final class Settings {
    private let defaults = UserDefaults.standard

    var hotKey: HotKey {
        get {
            defaults.data(forKey: "hotKey").flatMap { try? JSONDecoder().decode(HotKey.self, from: $0) } ?? .standard
        }
        set { defaults.set(try? JSONEncoder().encode(newValue), forKey: "hotKey") }
    }

    var homeLanguage: String {
        get { defaults.string(forKey: "homeLanguage") ?? LanguagePair.homeLanguage() }
        set { defaults.set(newValue, forKey: "homeLanguage") }
    }

    /// nil means: detect it.
    var source: String? {
        get { defaults.string(forKey: "source") }
        set { defaults.set(newValue, forKey: "source") }
    }

    var target: String {
        get { defaults.string(forKey: "target") ?? LanguagePair.defaultTarget() }
        set { defaults.set(newValue, forKey: "target") }
    }

    var quickTargets: QuickTargets {
        get { QuickTargets(defaults.stringArray(forKey: "quickTargets") ?? [target, homeLanguage]) }
        set { defaults.set(newValue.languages, forKey: "quickTargets") }
    }

    var choice: LanguageChoice { LanguageChoice(source: source, target: target, home: homeLanguage) }

    var launchesAtLogin: Bool { SMAppService.mainApp.status == .enabled }

    func setLaunchAtLogin(_ isOn: Bool) throws {
        if isOn { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
    }

    /// Turns on launch at login once; later the user's own choice counts.
    func enableLaunchAtLoginOnFirstRun() {
        guard !defaults.bool(forKey: "didFirstRun") else { return }
        defaults.set(true, forKey: "didFirstRun")
        try? setLaunchAtLogin(true)
    }
}
