import SwiftUI

/// What sits in the menu bar: the brand diamond, and - while a timer runs - the
/// project and how long it has been going. It stays deliberately narrow, since
/// every pixel here is taken from the app next door.
struct MenuBarLabel: View {
    @Environment(TimerStore.self) private var store

    var body: some View {
        if let active = store.active {
            HStack(spacing: 4) {
                Image(nsImage: BrandMark.running)
                Text(title(for: active))
            }
        } else {
            Image(nsImage: BrandMark.idle)
        }
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
