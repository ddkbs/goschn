// Draws the app icon: swift scripts/make-icon.swift <output.iconset>
import AppKit

let folder = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

func draw(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let side = CGFloat(pixels)
    let tile = NSRect(x: side * 0.1, y: side * 0.1, width: side * 0.8, height: side * 0.8)
    let shape = NSBezierPath(roundedRect: tile, xRadius: side * 0.18, yRadius: side * 0.18)
    NSGradient(
        starting: NSColor(srgbRed: 0.10, green: 0.42, blue: 0.40, alpha: 1),
        ending: NSColor(srgbRed: 0.05, green: 0.20, blue: 0.24, alpha: 1)
    )!.draw(in: shape, angle: -90)

    // "ü" moving across: the letter plus a small arrow.
    let font = NSFont.systemFont(ofSize: side * 0.5, weight: .bold)
    let letter = NSAttributedString(string: "ü", attributes: [.font: font, .foregroundColor: NSColor.white])
    let size = letter.size()
    letter.draw(at: NSPoint(x: side * 0.4 - size.width / 2, y: side * 0.53 - size.height / 2))
    let arrow = NSBezierPath()
    arrow.lineWidth = side * 0.055
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    arrow.move(to: NSPoint(x: side * 0.6, y: side * 0.47))
    arrow.line(to: NSPoint(x: side * 0.78, y: side * 0.47))
    arrow.move(to: NSPoint(x: side * 0.70, y: side * 0.55))
    arrow.line(to: NSPoint(x: side * 0.78, y: side * 0.47))
    arrow.line(to: NSPoint(x: side * 0.70, y: side * 0.39))
    NSColor(srgbRed: 0.98, green: 0.78, blue: 0.36, alpha: 1).setStroke()
    arrow.stroke()
    return rep.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    try draw(pixels: points).write(to: folder.appending(path: "icon_\(points)x\(points).png"))
    try draw(pixels: points * 2).write(to: folder.appending(path: "icon_\(points)x\(points)@2x.png"))
}
