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
            line
            PanelFooter(model: model)
        }
        .frame(width: PanelStyle.width)
        .fixedSize(horizontal: false, vertical: true)
        .background(PanelStyle.background)
        .clipShape(shape)
        .overlay(shape.strokeBorder(PanelStyle.border, lineWidth: 1))
        .background(shape.fill(.black).shadow(color: .black.opacity(0.28), radius: 24, y: 12))
        .padding(PanelStyle.margin)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .tint(.primary)
        .onChange(of: model.focusToken, initial: true) { isFocused = true }
        .translationTask(model.download) { session in
            try? await session.prepareTranslation()
            model.downloadEnded()
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: PanelStyle.cornerRadius, style: .continuous)
    }

    private var line: some View {
        PanelStyle.line.frame(height: 1)
    }

    private var input: some View {
        TextField("Type to translate…", text: $model.input, axis: .vertical)
            .textFieldStyle(.plain)
            .font(.system(size: PanelStyle.textSize))
            .lineLimit(1...6)
            .focused($isFocused)
            .accessibilityLabel("Text to translate")
            .padding(PanelStyle.padding)
    }

    @ViewBuilder private var result: some View {
        Group {
            if model.needsDownload {
                HStack {
                    Text("This language is not on your Mac yet.").foregroundStyle(.secondary)
                    Spacer()
                    Button("Download…") { model.startDownload() }
                }
                .font(.system(size: 14))
            } else if let error = model.errorText {
                Text(error).font(.system(size: 14)).foregroundStyle(.secondary)
            } else {
                TranslationText(live: model.live)
                    .environment(\.layoutDirection, isRightToLeft ? .rightToLeft : .leftToRight)
            }
        }
        .font(.system(size: PanelStyle.textSize, weight: .medium))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(PanelStyle.padding)
    }

    private var isRightToLeft: Bool {
        Locale.Language(identifier: model.pair.target).characterDirection == .rightToLeft
    }
}
