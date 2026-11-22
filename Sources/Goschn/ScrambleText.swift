import GoschnCore
import SwiftUI

/// The translation. While it is being worked on, its letters are restless;
/// when it arrives, they settle from left to right.
struct ScrambleText: View {
    let live: LiveTranslation
    let input: String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var previous = ""
    @State private var arrival = Date.distantPast
    @State private var isSettling = false

    private static let frameTime = 1.0 / 30

    var body: some View {
        // Scrolls only when a long translation outgrows the panel. ViewThatFits
        // rebuilds its children, so the animation state has to live out here.
        ViewThatFits(in: .vertical) {
            aligned
            ScrollView { aligned }
        }
        .frame(maxHeight: PanelStyle.maxOutputHeight)
        .accessibilityElement()
        .accessibilityLabel(live.output.isEmpty ? "Translating" : live.output)
        .onChange(of: live.output, initial: true) { old, new in settle(from: old, to: new) }
        .task(id: arrival) { await finishSettling() }
    }

    private var aligned: some View {
        content.frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var content: some View {
        if reduceMotion {
            Text(live.output.isEmpty ? "…" : live.output).opacity(live.isPending ? 0.5 : 1)
        } else if live.isPending || isSettling {
            TimelineView(.animation(minimumInterval: Self.frameTime)) { context in
                text(frame(at: context.date))
            }
        } else {
            Text(live.output).textSelection(.enabled)
        }
    }

    private func frame(at date: Date) -> Scramble.Frame {
        let tick = Int(date.timeIntervalSinceReferenceDate * 14)
        guard isSettling else {
            return Scramble.pending(
                input: input, translated: live.translatedText, output: live.output, tick: tick
            )
        }
        let duration = Scramble.duration(from: previous, to: live.output)
        let progress = date.timeIntervalSince(arrival) / duration
        let frame = Scramble.frame(from: previous, to: live.output, progress: progress, tick: tick)
        guard live.isPending, input.hasPrefix(live.translatedText) else { return frame }
        // Still typing while the last result settles: keep the tail going.
        let rest = String(input.dropFirst(live.translatedText.count))
        let tail = Scramble.noise(like: rest, tick: tick, offset: live.output.count)
        return Scramble.Frame(solid: frame.solid, noise: frame.noise + tail)
    }

    private func text(_ frame: Scramble.Frame) -> Text {
        Text("\(Text(frame.solid))\(Text(frame.noise).foregroundStyle(.tertiary))")
    }

    private func settle(from old: String, to new: String) {
        guard !new.isEmpty else { return isSettling = false }
        previous = old == new ? "" : old
        arrival = .now
        isSettling = true
    }

    private func finishSettling() async {
        guard isSettling else { return }
        try? await Task.sleep(for: .seconds(Scramble.duration(from: previous, to: live.output)))
        guard !Task.isCancelled else { return }
        isSettling = false
    }
}
