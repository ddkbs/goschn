import AppKit
import GoschnCore

/// The color that fits the app the user is in.
@MainActor
enum AppColor {
    private static var known: [String: PulseColor] = [:]

    /// Gray icons get a silver pulse.
    static func of(_ app: NSRunningApplication) -> PulseColor {
        let key = app.bundleIdentifier ?? app.localizedName ?? ""
        if let color = known[key] { return color }
        let color = app.icon.flatMap(pixels).flatMap(PulseColor.dominant) ?? .silver
        known[key] = color
        return color
    }

    private static func pixels(_ icon: NSImage) -> [UInt8]? {
        let side = 32
        var rect = CGRect(x: 0, y: 0, width: side, height: side)
        guard
            let image = icon.cgImage(forProposedRect: &rect, context: nil, hints: nil),
            let context = CGContext(
                data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
        guard let data = context.data else { return nil }
        return [UInt8](UnsafeRawBufferPointer(start: data, count: side * side * 4))
    }
}
