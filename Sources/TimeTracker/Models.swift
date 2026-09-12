import Foundation

/// The shape of `GET /api/v1/today`, which is also what start and stop answer
/// with - one round trip leaves the whole panel up to date.
struct Today: Decodable, Sendable {
    let date: String
    let timezone: String
    let slots: [Slot]
    let active: ActiveEntry?
    let dayTotalSeconds: Int
    let dayTotalLabel: String
}

/// One of the day's A/B/C blocks. A block with no project booked still comes
/// back, with `project` nil - the panel shows it as an empty slot rather than
/// silently listing two rows on a three-row day.
struct Slot: Decodable, Identifiable, Sendable {
    let slot: String
    let isDone: Bool
    let trackedSeconds: Int
    let trackedLabel: String
    let isRunning: Bool
    let project: Project?

    var id: String { slot }
}

struct Project: Decodable, Identifiable, Sendable {
    let id: Int
    let title: String
    let shortGoal: String
    /// First heading of the project's plan - what the session is meant to be about.
    let focus: String
}

struct ActiveEntry: Decodable, Sendable {
    let entryId: Int
    let projectId: Int?
    let projectTitle: String
    /// An absolute instant, so the counter can run locally instead of polling.
    let startedAt: Date
    let elapsedSeconds: Int
    let description: String

    /// Seconds since the timer started, measured against the given moment
    /// rather than against `elapsedSeconds`, which ages the instant it arrives.
    func elapsed(at moment: Date) -> Int {
        max(Int(moment.timeIntervalSince(startedAt)), 0)
    }
}

/// The error body every failing endpoint returns.
struct APIErrorBody: Decodable, Sendable {
    let ok: Bool
    let message: String
}

/// `01:23:45` for a panel, `1h 23m` for the menu bar, where every pixel of
/// width is taken from the app next door.
enum Duration {
    static func clock(_ seconds: Int) -> String {
        let seconds = max(seconds, 0)
        return String(format: "%02d:%02d:%02d", seconds / 3600, (seconds % 3600) / 60, seconds % 60)
    }

    static func compact(_ seconds: Int) -> String {
        let seconds = max(seconds, 0)
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        return hours > 0 ? "\(hours)h \(minutes)m" : "\(minutes)m"
    }
}
