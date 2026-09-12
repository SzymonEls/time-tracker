import AppKit
import SwiftUI

/// The productivity app's design tokens, carried over so the two look like one
/// product. Values are lifted from `app/static/css/theme.css` - the light ones
/// from `:root`, the dark ones from `[data-bs-theme="dark"]`.
///
/// Each colour is built from an `NSColor` with a dynamic provider rather than
/// read off `@Environment(\.colorScheme)`. AppKit then resolves it per
/// appearance wherever it is drawn, which matters here: the menu bar panel
/// picks its own appearance, and a colour chosen from the environment at build
/// time would be the wrong one half the time.
extension Color {
    /// `--primary`: the indigo accent, and what a running timer is painted in.
    static let brand = dynamic(light: 0x4f46e5, dark: 0x6366f1)
    /// `--primary-soft`: the accent as a background wash.
    static let brandSoft = dynamic(light: 0x4f46e5, dark: 0x6366f1, lightAlpha: 0.10, darkAlpha: 0.18)

    /// `--slot-accent`: amber, what a booked A or B block wears in the web app.
    static let slotBooked = dynamic(light: 0xd97706, dark: 0xfbbf24)
    /// `--slot-optional-accent`: the optional C block, deliberately quieter.
    static let slotOptional = dynamic(light: 0x9ca3af, dark: 0x71717a)
    /// `--success`: a session ticked off.
    static let slotDone = dynamic(light: 0x16a34a, dark: 0x22c55e)
    /// `--warning`. The web app gives it the same values as `--slot-accent`;
    /// both are kept so a warning does not start meaning "booked".
    static let warning = dynamic(light: 0xd97706, dark: 0xfbbf24)
    /// `--danger`.
    static let danger = dynamic(light: 0xdc2626, dark: 0xf87171)

    /// `--surface` / `--border` / `--muted-foreground`.
    static let cardSurface = dynamic(light: 0xffffff, dark: 0x17171a, lightAlpha: 0.72, darkAlpha: 0.55)
    static let cardBorder = dynamic(light: 0xe6e6ea, dark: 0x2a2a30)
    static let mutedForeground = dynamic(light: 0x6b7280, dark: 0xa1a1aa)

    private static func dynamic(
        light: Int,
        dark: Int,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
            return NSColor(hex: isDark ? dark : light, alpha: isDark ? darkAlpha : lightAlpha)
        })
    }
}

extension NSColor {
    convenience init(hex: Int, alpha: CGFloat) {
        self.init(
            srgbRed: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8) & 0xff) / 255,
            blue: CGFloat(hex & 0xff) / 255,
            alpha: alpha
        )
    }
}

/// The brand mark in full colour, for use inside the panel - where, unlike the
/// menu bar, the gradient is allowed to survive.
struct BrandDiamond: View {
    var side: CGFloat = 13

    var body: some View {
        Diamond()
            .fill(
                LinearGradient(
                    colors: [Color(nsColor: NSColor(hex: 0x4f46e5, alpha: 1)),
                             Color(nsColor: NSColor(hex: 0x8b5cf6, alpha: 1))],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: side, height: side)
    }
}

struct Diamond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

extension Slot {
    /// The colour this block is drawn in, following the web app's own rules:
    /// amber once booked, grey for the optional C, green when the session is
    /// done - and the brand indigo while its timer actually runs, which is a
    /// state the web app has no need to show.
    var accent: Color {
        if isRunning { return .brand }
        if isDone { return .slotDone }
        return slot == "C" ? .slotOptional : .slotBooked
    }
}
