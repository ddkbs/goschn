import AppKit

@main
enum GoschnApp {
    // Kept alive here because NSApplication only holds its delegate weakly.
    @MainActor private static let delegate = AppDelegate()

    @MainActor
    static func main() {
        if CommandLine.arguments.contains("--translate") {
            CommandLineMode.run(arguments: CommandLine.arguments)
        }
        let app = NSApplication.shared
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
