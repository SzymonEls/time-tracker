import AppKit

/// The productivity app's diamond, drawn for the menu bar.
///
/// Menu bar icons must be template images: macOS throws away their colour and
/// repaints them to suit the bar, which is why the brand gradient cannot come
/// along. The shape is what carries the identity here - hollow while nothing
/// runs, solid once something does, so the state reads at a glance.
@MainActor
enum BrandMark {
    static let idle = diamond(filled: false)
    static let running = diamond(filled: true)

    private static func diamond(filled: Bool) -> NSImage {
        let side: CGFloat = 15
        // The drawing-handler initialiser, not lockFocus(): this one re-runs
        // the drawing at whatever resolution it is asked for, so the mark stays
        // sharp on a Retina bar. lockFocus() rasterises once, at one scale, and
        // everything after that is an enlargement of those pixels.
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            let inset: CGFloat = filled ? 1.5 : 2
            let centre = CGPoint(x: rect.midX, y: rect.midY)
            let reach = rect.width / 2 - inset

            let path = NSBezierPath()
            path.move(to: NSPoint(x: centre.x, y: centre.y + reach))
            path.line(to: NSPoint(x: centre.x + reach, y: centre.y))
            path.line(to: NSPoint(x: centre.x, y: centre.y - reach))
            path.line(to: NSPoint(x: centre.x - reach, y: centre.y))
            path.close()

            NSColor.black.set()
            if filled {
                path.fill()
            } else {
                path.lineWidth = 1.6
                path.lineJoinStyle = .round
                path.stroke()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
