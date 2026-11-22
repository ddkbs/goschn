import Foundation
import Observation
import GoschnCore
import Translation

/// Everything the panel shows.
@MainActor
@Observable
final class PanelModel {
    let live: LiveTranslation
    var input = "" { didSet { if input != oldValue { refresh() } } }
    private(set) var choice: LanguageChoice
    private(set) var quickTargets: QuickTargets
    private(set) var languages: [String] = []
    /// Set while the user swapped the direction with Tab.
    private(set) var swapped: LanguagePair?
    var canPaste = false
    /// Animations rest while the panel is hidden.
    var isOpen = false
    private(set) var position: PanelPosition
    /// Changes on every opening so the view can focus the text field.
    var focusToken = 0
    var download: TranslationSession.Configuration?

    @ObservationIgnored var showMenu: (() -> Void)?
    @ObservationIgnored let translator = AppleTranslator()
    @ObservationIgnored private let settings: Settings

    init(settings: Settings) {
        self.settings = settings
        choice = settings.choice
        quickTargets = settings.quickTargets
        position = settings.position
        let translator = self.translator
        live = LiveTranslation { try await translator.translate($0, $1) }
    }

    var pair: LanguagePair { swapped ?? choice.pair(detected: detected) }

    private var detected: String? {
        guard choice.source == nil else { return nil }
        return LanguageDetector(supported: languages).detect(input, home: choice.home, target: choice.target)
    }

    func loadLanguages() async {
        languages = await AppleTranslator.supportedLanguages()
        refresh()
    }

    /// nil turns detection back on.
    func chooseSource(_ id: String?) {
        swapped = nil
        choice.source = id
        settings.source = id
        refresh()
    }

    func chooseTarget(_ id: String) {
        swapped = nil
        choice.target = id
        settings.target = id
        quickTargets.use(id)
        settings.quickTargets = quickTargets
        refresh()
    }

    func chooseQuickTarget(_ number: Int) -> Bool {
        guard let id = quickTargets.language(at: number) else { return false }
        chooseTarget(id)
        return true
    }

    func chooseHome(_ id: String) {
        swapped = nil
        choice.home = id
        settings.homeLanguage = id
        refresh()
    }

    func choosePosition(_ position: PanelPosition) {
        self.position = position
        settings.position = position
    }

    func swap() {
        swapped = swapped == nil ? pair.reversed : nil
        refresh()
    }

    /// Clears the text after it was used; the swap was meant for that text.
    func reset() {
        swapped = nil
        input = ""
    }

    var hasText: Bool { !input.allSatisfy(\.isWhitespace) }

    var needsDownload: Bool {
        guard let error = live.error else { return false }
        return TranslationError.notInstalled ~= error
    }

    var errorText: String? {
        guard let error = live.error, !needsDownload else { return nil }
        return error.localizedDescription
    }

    func refresh() { live.update(input, pair: pair) }

    func result() async -> String? { await live.finish(input, pair: pair) }

    func startDownload() {
        let source = Locale.Language(identifier: pair.source)
        let target = Locale.Language(identifier: pair.target)
        if #available(macOS 26.4, *) {
            download = .init(source: source, target: target, preferredStrategy: .lowLatency)
        } else {
            download = .init(source: source, target: target)
        }
    }

    func downloadEnded() {
        download = nil
        translator.forgetSessions()
        refresh()
    }
}
