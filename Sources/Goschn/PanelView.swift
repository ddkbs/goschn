import GoschnCore
import SwiftUI
import Translation

struct PanelView: View {
    @Bindable var model: PanelModel
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            input
            if model.hasText {
                line
                result
            }
            PanelFooter(model: model)
        }
        .frame(width: PanelStyle.width)
        .fixedSize(horizontal: false, vertical: true)
        .glassPanel()
        .overlay(EdgePulse(shape: PanelStyle.shape, isRunning: model.isOpen))
        .padding(PanelStyle.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
        .tint(.primary)
        .onChange(of: model.focusToken, initial: true) { isFocused = true }
        .translationTask(model.download) { session in
            try? await session.prepareTranslation()
            model.downloadEnded()
        }
    }

    /// A hairline that fades out before it reaches the edges.
    private var line: some View {
        LinearGradient(
            colors: [.clear, .primary.opacity(0.2), .primary.opacity(0.2), .clear],
            startPoint: .leading, endPoint: .trailing
        )
        .frame(height: 1)
    }

    private var alignment: Alignment {
        model.position.isBottom ? .bottom : .top
    }

    private var input: some View {
        TextField("Type to translate…", text: $model.input, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: PanelStyle.textSize))
            .lineLimit(1...5)
            .focused($isFocused)
            .accessibilityLabel("Text to translate")
            .padding(.horizontal, PanelStyle.padding)
            .padding(.vertical, 15)
    }

    @ViewBuilder private var result: some View {
        Group {
            if model.needsDownload {
                HStack {
                    Text("This language is not on your Mac yet.").foregroundStyle(.secondary)
                    Spacer()
                    Button("Download…") { model.startDownload() }
                }
                .font(.system(size: 13))
            } else if let error = model.errorText {
                Text(error).font(.system(size: 13)).foregroundStyle(.secondary)
            } else {
                TranslationText(live: model.live)
                    .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
            }
        }
        .font(.system(size: PanelStyle.textSize, weight: .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, PanelStyle.padding)
        .padding(.vertical, 14)
    }

    private var isRightToLeft: Bool {
        Locale.Language(identifier: model.pair.target).characterDirection == .rightToLeft
    }
}
