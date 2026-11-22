import Foundation
import Observation
import RueberCore
import Translation

/// Everything the panel shows.
@MainActor
@Observable
final class PanelModel {
    let live: LiveTranslation
    var input = "" { didSet { if input != oldValue { refresh() } } }
    var isReversed = false { didSet { if isReversed != oldValue { refresh() } } }
    var canPaste = false
    /// Changes on every opening so the view can focus the text field.
    var focusToken = 0
    var download: TranslationSession.Configuration?

    @ObservationIgnored let translator = AppleTranslator()
    @ObservationIgnored private let settings: Settings

    init(settings: Settings) {
        self.settings = settings
        let translator = self.translator
        live = LiveTranslation { try await translator.translate($0, $1) }
    }

    var pair: LanguagePair { isReversed ? settings.pair.reversed : settings.pair }

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
