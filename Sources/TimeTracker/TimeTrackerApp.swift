import SwiftUI

/// The app's two long-lived objects.
///
/// Not `@State` on the App struct and not an `NSApplicationDelegateAdaptor`.
/// `@State` would let SwiftUI rebuild the struct and quietly leave a second
/// store polling behind the one the views can see; the adaptor is never
/// constructed at all here, because `MenuBarExtra`'s closures are lazy and
/// nothing touches it until the panel opens. A static is created once, on
/// first use, and every view reaches the same one.
@MainActor
enum Shared {
    static let settings = AppSettings()
    static let store = TimerStore(settings: settings)
}

@main
struct TimeTrackerApp: App {
    init() {
        log.notice("Launching")
        // The clock has to run whether or not anyone opens the panel - the
        // whole point is a menu bar that counts while you work elsewhere.
        Shared.store.activate()
    }

    var body: some Scene {
        MenuBarExtra {
            TodayPanel()
                .environment(Shared.store)
                .environment(Shared.settings)
        } label: {
            MenuBarLabel()
                .environment(Shared.store)
        }
        // .window rather than the default .menu: a menu can only hold menu
        // items, and this panel is a layout.
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(Shared.store)
                .environment(Shared.settings)
        }
    }
}
