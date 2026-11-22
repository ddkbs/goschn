/// Target languages reachable with ⌘1…⌘5. Slots keep their position so the
/// shortcuts can become muscle memory; only the last slot is replaced.
public struct QuickTargets: Equatable, Sendable {
    public static let limit = 5
    public private(set) var languages: [String]

    public init(_ languages: [String]) {
        self.languages = []
        for id in languages.prefix(Self.limit) where !self.languages.contains(id) { self.languages.append(id) }
    }

    public mutating func use(_ id: String) {
        guard !languages.contains(id) else { return }
        if languages.count == Self.limit { languages.removeLast() }
        languages.append(id)
    }

    /// Language for ⌘1, ⌘2, … (1-based).
    public func language(at number: Int) -> String? {
        languages.indices.contains(number - 1) ? languages[number - 1] : nil
    }
}
