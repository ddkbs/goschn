import GoschnCore
import SwiftUI

/// The translation; shimmers while a newer one is on its way.
struct TranslationText: View {
    let live: LiveTranslation

    var body: some View {
        // Scrolls only when a long translation outgrows the panel.
        ViewThatFits(in: .vertical) {
            aligned
            ScrollView { aligned }
        }
        .frame(maxHeight: PanelStyle.maxOutputHeight)
        .animation(.easeOut(duration: 0.2), value: live.isPending)
    }

    private var aligned: some View {
        content.frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var content: some View {
        if live.output.isEmpty {
            ShimmerText(text: "Translating…").transition(.opacity)
        } else if live.isPending {
            ShimmerText(text: live.output).transition(.opacity)
        } else {
            Text(live.output)
                .textSelection(.enabled)
                .accessibilityLabel("Translation: \(live.output)")
                .transition(.opacity)
        }
    }
}
