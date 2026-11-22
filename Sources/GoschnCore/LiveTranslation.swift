import Foundation
import Observation

/// Keeps a translation in sync with text that changes while the user types.
/// At most one request runs at a time; when it finishes, only the newest
/// text is translated next, so slow requests never pile up.
@MainActor
@Observable
public final class LiveTranslation {
    public struct Request: Equatable, Sendable {
        public let text: String
        public let pair: LanguagePair
    }

    public typealias Engine = @MainActor (_ lines: [String], _ pair: LanguagePair) async throws -> [String]

    public private(set) var output = ""
    public private(set) var isBusy = false
    public private(set) var error: (any Error)?

    @ObservationIgnored private var wanted: Request?
    @ObservationIgnored private var done: Request?
    @ObservationIgnored private var worker: Task<Void, Never>?
    @ObservationIgnored private var debounce: Task<Void, Never>?
    @ObservationIgnored private let delay: Duration
    @ObservationIgnored private let engine: Engine

    public init(delay: Duration = .milliseconds(180), engine: @escaping Engine) {
        self.delay = delay
        self.engine = engine
    }

    /// Schedules a translation; call on every keystroke.
    public func update(_ text: String, pair: LanguagePair) {
        guard prepare(text, pair) else { return }
        let delay = self.delay
        debounce = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.startWorker()
        }
    }

    /// Translates right away and returns the result, or nil if it failed,
    /// was empty, or was replaced by newer text in the meantime.
    public func finish(_ text: String, pair: LanguagePair) async -> String? {
        let request = Request(text: text, pair: pair)
        if prepare(text, pair) { startWorker() }
        await worker?.value
        guard done == request, !output.isEmpty else { return nil }
        return output
    }

    /// Returns true when a translation is needed.
    private func prepare(_ text: String, _ pair: LanguagePair) -> Bool {
        debounce?.cancel()
        let request = Request(text: text, pair: pair)
        guard !text.allSatisfy(\.isWhitespace) else {
            wanted = nil
            done = nil
            output = ""
            error = nil
            return false
        }
        wanted = request
        return done != request
    }

    private func startWorker() {
        guard worker == nil else { return }
        isBusy = true
        worker = Task {
            while let request = wanted, request != done {
                do {
                    let layout = TextLayout(request.text)
                    let bodies = layout.bodies
                    let translated = bodies.isEmpty ? [] : try await engine(bodies, request.pair)
                    guard wanted == request else { continue }
                    output = layout.rebuild(with: translated)
                    error = nil
                    done = request
                } catch {
                    guard wanted == request else { continue }
                    self.error = error
                    output = ""
                    done = nil
                    wanted = nil
                }
            }
            isBusy = false
            worker = nil
        }
    }
}
