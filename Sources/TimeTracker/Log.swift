import OSLog

/// A desktop app has no terminal to print to. `log stream --predicate
/// 'subsystem == "com.szymonels.timetracker"'` is the equivalent, and this is
/// what writes to it.
let log = Logger(subsystem: "com.szymonels.timetracker", category: "app")
