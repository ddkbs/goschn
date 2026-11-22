import Foundation
import RueberCore

/// `Rueber --translate "Text"` prints a translation without any UI.
enum CommandLineMode {
    @MainActor
    static func run(text: String) -> Never {
        Task {
            let translator = AppleTranslator()
            let live = LiveTranslation { try await translator.translate($0, $1) }
            if let result = await live.finish(text, pair: Settings().pair) {
                print(result)
                exit(0)
            }
            let reason = live.error?.localizedDescription ?? "Nothing to translate"
            FileHandle.standardError.write(Data("\(reason)\n".utf8))
            exit(1)
        }
        dispatchMain()
    }
}
