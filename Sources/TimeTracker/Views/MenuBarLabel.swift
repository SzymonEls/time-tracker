import SwiftUI

/// What sits in the menu bar. It stays deliberately narrow: a dot, a project
/// and a rounded time when something runs, and a bare icon when nothing does.
struct MenuBarLabel: View {
    @Environment(TimerStore.self) private var store

    var body: some View {
        if let active = store.active {
            HStack(spacing: 4) {
                Image(systemName: "record.circle")
                Text(title(for: active))
            }
        } else {
            Image(systemName: "timer")
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
