import SwiftUI

/// What sits in the menu bar: the brand diamond, and - while a timer runs - the
/// project and how long it has been going. It stays deliberately narrow, since
/// every pixel here is taken from the app next door.
struct MenuBarLabel: View {
    @Environment(TimerStore.self) private var store

    var body: some View {
        // 6 rather than the 4 a square glyph would want: a diamond is at its
        // widest across the middle and tapers away from the text, so the gap
        // reads as smaller than it measures.
        HStack(spacing: 6) {
            if let active = store.active {
                mark(BrandMark.running)
                Text(title(for: active))
            } else {
                // The idle mark alone: other menu bar items collapse to an icon
                // when there is nothing to say, and the idle diamond already
                // differs from the running one.
                mark(BrandMark.idle)
            }
        }
    }

    /// Drops the mark by 0.8pt so it sits where the eye expects it.
    ///
    /// Centring the image's box against the text's box puts the diamond 0.4pt
    /// above the centre of the capitals and 1.35pt above the centre of the
    /// whole line - measured, not guessed. Neither is where it belongs: the
    /// eye reads the centre of the ink, and words like "No project" carry
    /// theirs low, on the descenders. This lands between the two.
    private func mark(_ image: NSImage) -> some View {
        Image(nsImage: image)
            .alignmentGuide(VerticalAlignment.center) { $0[VerticalAlignment.center] - 0.8 }
    }

    private func title(for active: ActiveEntry) -> String {
        let elapsed = Duration.compact(store.elapsedSeconds)
        // A long project title would push every other menu bar item off a
        // 13-inch screen, so it is cut rather than trusted.
        let name = active.projectTitle.count > 18
            ? active.projectTitle.prefix(17) + "…"
            : active.projectTitle[...]
        return "\(name) \(elapsed)"
    }
}
