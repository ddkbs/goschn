import Foundation
import RueberCore

/// `Rueber [--from de] [--to fr] --translate "Text"` prints a translation without any UI.
enum CommandLineMode {
    @MainActor
    static func run(arguments: [String]) -> Never {
        Task {
            let settings = Settings()
            var choice = settings.choice
            choice.source = value(of: "--from", in: arguments) ?? choice.source
            choice.target = value(of: "--to", in: arguments) ?? choice.target
            let text = value(of: "--translate", in: arguments) ?? ""

            let translator = AppleTranslator()
            let detector = LanguageDetector(supported: await AppleTranslator.supportedLanguages())
            let detected = detector.detect(text, home: choice.home, target: choice.target)
            let live = LiveTranslation { try await translator.translate($0, $1) }
            if let result = await live.finish(text, pair: choice.pair(detected: detected)) {
                print(result)
                exit(0)
            }
            let reason = live.error?.localizedDescription ?? "Nothing to translate"
            FileHandle.standardError.write(Data("\(reason)\n".utf8))
            exit(1)
        }
        dispatchMain()
    }

    private static func value(of flag: String, in arguments: [String]) -> String? {
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else { return nil }
        return arguments[index + 1]
    }
}
