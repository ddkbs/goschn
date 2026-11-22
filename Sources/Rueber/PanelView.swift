import RueberCore
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
            .accessibilityLabel("Translation")
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Button { model.isReversed.toggle() } label: {
                Text(model.pair.label).fontWeight(.semibold)
            }
            .buttonStyle(.plain)
            .help("Swap direction (Tab)")
            hint("⇥", "Swap")
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
