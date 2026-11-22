import AppKit

@main
enum RueberApp {
    // Kept alive here because NSApplication only holds its delegate weakly.
    @MainActor private static let delegate = AppDelegate()

    @MainActor
    static func main() {
        if let index = CommandLine.arguments.firstIndex(of: "--translate") {
            CommandLineMode.run(text: CommandLine.arguments.dropFirst(index + 1).joined(separator: " "))
        }
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
