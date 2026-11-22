import GoschnCore
import SwiftUI
import Translation

struct PanelView: View {
    @Bindable var model: PanelModel
    let onHeightChange: (CGFloat) -> Void
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            inputField
            if showsResult {
                Divider()
                result
            }
            Divider()
            footer
        }
        .frame(width: 640)
        .fixedSize(horizontal: false, vertical: true)
        .onGeometryChange(for: CGFloat.self, of: \.size.height, action: onHeightChange)
        .onChange(of: model.focusToken, initial: true) { isFocused = true }
        .translationTask(model.download) { session in
            try? await session.prepareTranslation()
            model.downloadEnded()
        }
    }

    private var showsResult: Bool {
        !model.live.output.isEmpty || model.live.error != nil
    }

    private var inputField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            TextField("Type to translate…", text: $model.input, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 22))
                .lineLimit(1...8)
                .focused($isFocused)
                .accessibilityLabel("Text to translate")
            if model.live.isBusy {
                ProgressView().controlSize(.small)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
    }

    @ViewBuilder private var result: some View {
        Group {
            if model.needsDownload {
                HStack {
                    Text("This language is not on your Mac yet.")
                    Spacer()
                    Button("Download…") { model.startDownload() }
                }
            } else if let error = model.errorText {
                Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
            } else {
                // Scrolls only when a long translation outgrows the panel.
                ViewThatFits(in: .vertical) {
                    output
                    ScrollView { output }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }

    private var output: some View {
        Text(model.live.output)
            .font(.system(size: 20, weight: .medium))
            .opacity(model.live.isBusy ? 0.5 : 1)
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
            .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
            .accessibilityLabel("Translation")
    }

    private var footer: some View {
        HStack(spacing: 16) {
            languagePicker
            Button { model.swap() } label: { hint("⇥", "Swap") }
                .buttonStyle(.plain)
            Spacer()
            if !model.canPaste {
                Button("Allow auto-paste…") { Paster.requestPermission() }
                    .buttonStyle(.link)
                    .help("Needs the Accessibility permission. Without it, ↩ only copies.")
            }
            if model.canPaste { hint("⌘↩", "Copy") }
            hint("↩", model.canPaste ? "Paste" : "Copy")
        }
        .font(.system(size: 12))
        .foregroundStyle(.secondary)
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var languagePicker: some View {
        HStack(spacing: 6) {
            Menu(name(model.pair.source)) {
                choice("Detect Language", isOn: model.choice.source == nil) { model.chooseSource(nil) }
                Divider()
                ForEach(model.languages, id: \.self) { id in
                    choice(name(id), isOn: model.choice.source == id) { model.chooseSource(id) }
                }
            }
            .accessibilityLabel("Translate from \(name(model.pair.source))")
            Image(systemName: "arrow.right").imageScale(.small).accessibilityHidden(true)
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
        .buttonStyle(.plain)
        .fontWeight(.semibold)
        .lineLimit(1)
        .fixedSize()
    }

    private func choice(_ title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Toggle(title, isOn: Binding(get: { isOn }, set: { _ in action() }))
    }

    private func name(_ id: String) -> String { AppleTranslator.displayName(id) }

    private var isRightToLeft: Bool {
        Locale.Language(identifier: model.pair.target).characterDirection == .rightToLeft
    }

    private func hint(_ key: String, _ text: String) -> some View {
        HStack(spacing: 5) {
            Text(text)
            Text(key)
                .padding(.horizontal, 5)
                .padding(.vertical, 1)
                .background(.quaternary, in: .rect(cornerRadius: 4))
        }
    }
}
