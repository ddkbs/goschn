import Foundation
import GoschnCore
import Translation

/// Apple's on-device translation: free, private and offline once the
/// language is installed.
@MainActor
final class AppleTranslator {
    private var sessions: [LanguagePair: TranslationSession] = [:]

    func translate(_ lines: [String], _ pair: LanguagePair) async throws -> [String] {
        let session = try await session(for: pair)
        do {
            let requests = lines.map { TranslationSession.Request(sourceText: $0) }
            return try await session.translations(from: requests).map(\.targetText)
        } catch {
            sessions[pair] = nil  // Never reuse a session that failed.
            throw error
        }
    }

    /// Loads the model ahead of time so the first keystrokes feel instant.
    func warmUp(_ pair: LanguagePair) {
        guard sessions[pair] == nil else { return }
        Task { _ = try? await translate(["Hallo"], pair) }
    }

    func forgetSessions() { sessions = [:] }

    private func session(for pair: LanguagePair) async throws -> TranslationSession {
        if let session = sessions[pair] { return session }
        let source = Locale.Language(identifier: pair.source)
        let target = Locale.Language(identifier: pair.target)
        let session: TranslationSession
        if #available(macOS 26.4, *) {
            // Prefer the better model and fall back to the small one.
            let best = LanguageAvailability(preferredStrategy: .highFidelity)
            let strategy: TranslationSession.Strategy =
                await best.status(from: source, to: target) == .installed ? .highFidelity : .lowLatency
            session = TranslationSession(installedSource: source, target: target, preferredStrategy: strategy)
        } else {
            session = TranslationSession(installedSource: source, target: target)
        }
        sessions[pair] = session
        return session
    }

    static func supportedLanguages() async -> [String] {
        var ids = await LanguageAvailability().supportedLanguages.map(\.minimalIdentifier)
        if #available(macOS 26.4, *) {
            // The larger model knows more languages than the default one.
            let best = LanguageAvailability(preferredStrategy: .highFidelity)
            ids += await best.supportedLanguages.map(\.minimalIdentifier)
        }
        return Array(Set(ids)).sorted { displayName($0).localizedCompare(displayName($1)) == .orderedAscending }
    }

    static func displayName(_ id: String) -> String {
        // English like the rest of the interface.
        Locale(identifier: "en").localizedString(forIdentifier: id) ?? id
    }
}
