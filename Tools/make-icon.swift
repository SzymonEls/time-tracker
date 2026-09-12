import AppKit

// Redraws the productivity app's mark - a white diamond on an indigo-to-violet
// gradient - at every size macOS asks for, and hands the set to iconutil.
//
// The web app's own PNG is a full-bleed square. macOS wants a rounded square
// sitting inside a margin, so the mark is redrawn here rather than resized.

let brandStart = NSColor(srgbRed: 0x4f / 255, green: 0x46 / 255, blue: 0xe5 / 255, alpha: 1)
let brandEnd = NSColor(srgbRed: 0x8b / 255, green: 0x5c / 255, blue: 0xf6 / 255, alpha: 1)

func drawIcon(size: Int) -> Data? {
    let side = CGFloat(size)
    let image = NSImage(size: NSSize(width: side, height: side))
    image.lockFocus()

    // Apple's icon grid: the artwork covers about 80% of the canvas, with a
    // corner radius of just under a quarter of its own width.
    let inset = side * 0.10
    let rect = NSRect(x: inset, y: inset, width: side - inset * 2, height: side - inset * 2)
    let squircle = NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.width * 0.225)
    squircle.addClip()
    NSGradient(starting: brandStart, ending: brandEnd)?
        .draw(in: rect, angle: -45)

    let centre = NSPoint(x: rect.midX, y: rect.midY)
    let reach = rect.width * 0.27
    let diamond = NSBezierPath()
    diamond.move(to: NSPoint(x: centre.x, y: centre.y + reach))
    diamond.line(to: NSPoint(x: centre.x + reach, y: centre.y))
    diamond.line(to: NSPoint(x: centre.x, y: centre.y - reach))
    diamond.line(to: NSPoint(x: centre.x - reach, y: centre.y))
    diamond.close()
    NSColor.white.setFill()
    diamond.fill()

    image.unlockFocus()

    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff)
    else { return nil }
    bitmap.size = NSSize(width: side, height: side)
    return bitmap.representation(using: .png, properties: [:])
}

let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "Resources/AppIcon.iconset"
try? FileManager.default.createDirectory(atPath: output, withIntermediateDirectories: true)

// The names are iconutil's, not ours - it refuses a set that is missing any.
let wanted: [(String, Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for (name, size) in wanted {
    guard let data = drawIcon(size: size) else {
        FileHandle.standardError.write(Data("Could not render \(name)\n".utf8))
        exit(1)
    }
    try? data.write(to: URL(fileURLWithPath: "\(output)/\(name).png"))
}
print("Wrote \(wanted.count) images to \(output)")
