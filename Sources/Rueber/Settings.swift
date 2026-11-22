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

    var pair: LanguagePair { LanguagePair(source: homeLanguage, target: "en") }

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
