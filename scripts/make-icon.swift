// Draws the app icon, a big mouth: swift scripts/make-icon.swift <output.iconset>
import AppKit

let folder = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> NSColor { NSColor(srgbRed: r, green: g, blue: b, alpha: 1) }

func draw(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let s = CGFloat(pixels)
    let tile = NSRect(x: s * 0.1, y: s * 0.1, width: s * 0.8, height: s * 0.8)
    let shape = NSBezierPath(roundedRect: tile, xRadius: s * 0.18, yRadius: s * 0.18)
    NSGradient(starting: color(0.25, 0.66, 0.94), ending: color(0.05, 0.42, 0.78))!.draw(in: shape, angle: -90)

    // Wide open mouth: flat on top, round at the bottom.
    let mouth = NSBezierPath()
    mouth.move(to: NSPoint(x: s * 0.23, y: s * 0.60))
    mouth.curve(
        to: NSPoint(x: s * 0.77, y: s * 0.60),
        controlPoint1: NSPoint(x: s * 0.36, y: s * 0.645), controlPoint2: NSPoint(x: s * 0.64, y: s * 0.645)
    )
    mouth.curve(
        to: NSPoint(x: s * 0.50, y: s * 0.27),
        controlPoint1: NSPoint(x: s * 0.77, y: s * 0.40), controlPoint2: NSPoint(x: s * 0.66, y: s * 0.27)
    )
    mouth.curve(
        to: NSPoint(x: s * 0.23, y: s * 0.60),
        controlPoint1: NSPoint(x: s * 0.34, y: s * 0.27), controlPoint2: NSPoint(x: s * 0.23, y: s * 0.40)
    )
    mouth.close()
    NSGraphicsContext.saveGraphicsState()
    let lift = NSAffineTransform()  // Centers the mouth in the tile.
    lift.translateX(by: 0, yBy: s * 0.045)
    lift.concat()
    mouth.addClip()
    color(0.36, 0.05, 0.12).setFill()
    mouth.fill()
    color(0.95, 0.40, 0.45).setFill()
    NSBezierPath(ovalIn: NSRect(x: s * 0.33, y: s * 0.17, width: s * 0.34, height: s * 0.24)).fill()
    NSColor.white.setFill()
    NSRect(x: 0, y: s * 0.545, width: s, height: s * 0.2).fill()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    try draw(pixels: points).write(to: folder.appending(path: "icon_\(points)x\(points).png"))
    try draw(pixels: points * 2).write(to: folder.appending(path: "icon_\(points)x\(points)@2x.png"))
}
