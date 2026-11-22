import GoschnCore
import SwiftUI

/// Languages on the left, options and what Enter does on the right.
struct PanelFooter: View {
    let model: PanelModel

    var body: some View {
        HStack(spacing: 8) {
            languages.chip()
            Spacer()
            if !model.canPaste {
                Button("Enable pasting") { Paster.requestPermission() }
                    .chip()
                    .help("Needs the Accessibility permission. Without it, ↩ only copies.")
            }
            Button { model.showMenu?() } label: {
                Image(systemName: "ellipsis").frame(height: 14)
            }
            .chip()
            .help("Options")
            .accessibilityLabel("Options")
            enterHint.chip()
        }
        .buttonStyle(.plain)
        .font(.system(size: 12, weight: .medium))
        .padding(.horizontal, PanelStyle.padding - 10)
        .padding(.bottom, 14)
    }

    private var enterHint: some View {
        HStack(spacing: 6) {
            Text(model.canPaste ? "Paste" : "Copy")
            Text("↩").foregroundStyle(.secondary)
        }
        .help("↩ \(model.canPaste ? "pastes" : "copies"), ⌘↩ only copies")
        .accessibilityElement(children: .combine)
    }

    private var languages: some View {
        HStack(spacing: 7) {
            Menu(sourceName) {
                choice("Detect Language", isOn: model.choice.source == nil) { model.chooseSource(nil) }
                Divider()
                ForEach(model.languages, id: \.self) { id in
                    choice(name(id), isOn: model.choice.source == id) { model.chooseSource(id) }
                }
            }
            .accessibilityLabel("Translate from \(sourceName)")
            Button { model.swap() } label: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .help("Swap direction (Tab)")
            .accessibilityLabel("Swap direction")
            Menu(name(model.pair.target)) {
                // Key equivalents are only shown here; the panel handles them.
                ForEach(Array(model.quickTargets.languages.enumerated()), id: \.element) { index, id in
                    choice(name(id), isOn: model.choice.target == id) { model.chooseTarget(id) }
                        .keyboardShortcut(KeyEquivalent(Character("\(index + 1)")), modifiers: .command)
                }
                Divider()
                ForEach(model.languages, id: \.self) { id in
                    choice(name(id), isOn: model.choice.target == id) { model.chooseTarget(id) }
                }
            }
            .accessibilityLabel("Translate to \(name(model.pair.target))")
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
        .lineLimit(1)
        .fixedSize()
    }

    /// Nothing is detected before the user types.
    private var sourceName: String {
        model.hasText || model.choice.source != nil ? name(model.pair.source) : "Auto"
    }

    private func choice(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Toggle(title, isOn: Binding(get: { isOn }, set: { _ in action() }))
    }

    private func name(_ id: String) -> String { AppleTranslator.displayName(id) }
}

private extension View {
    /// A small pill on the glass.
    func chip() -> some View {
        padding(.horizontal, 11)
            .frame(height: 26)
            .background(.primary.opacity(0.11), in: .capsule)
            .contentShape(.capsule)
    }
}
