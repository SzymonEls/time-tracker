import Foundation
import Observation

/// Everything the panel and the menu bar label read. Kept on the main actor
/// because every one of its properties ends up in a view.
@MainActor
@Observable
final class TimerStore {
    enum Phase: Equatable {
        case needsSetup
        case loading
        case ready
        case failed(String)
    }

    private(set) var phase: Phase = .needsSetup
    private(set) var today: Today?
    /// The project whose button is waiting on the server, so only that one row
    /// shows a spinner instead of the whole panel flickering.
    private(set) var pendingProjectID: Int?
    /// Ticks once a second while something is running. The elapsed time is
    /// measured against this rather than against the server's count, which is
    /// already stale by the time it arrives.
    private(set) var now = Date()

    private let settings: AppSettings
    private var clock: Task<Void, Never>?
    private var poller: Task<Void, Never>?

    init(settings: AppSettings) {
        self.settings = settings
    }

    var active: ActiveEntry? { today?.active }

    var elapsedSeconds: Int { active?.elapsed(at: now) ?? 0 }

    /// What the menu bar shows: the running project and its time, or a hint
    /// that there is nothing to show yet.
    var menuBarTitle: String? {
        guard let active else { return nil }
        return "\(active.projectTitle) · \(Duration.compact(elapsedSeconds))"
    }

    /// Seconds tracked today, with the running entry counted up to `now` - the
    /// server's own total stopped being right the moment it was serialised.
    var dayTotalSeconds: Int {
        guard let today else { return 0 }
        guard let active else { return today.dayTotalSeconds }
        return today.dayTotalSeconds - active.elapsedSeconds + active.elapsed(at: now)
    }

    func tracked(in slot: Slot) -> Int {
        guard slot.isRunning, let active else { return slot.trackedSeconds }
        return slot.trackedSeconds - active.elapsedSeconds + active.elapsed(at: now)
    }

    // MARK: - Lifecycle

    /// Start the background work. Safe to call again - it replaces the tasks it
    /// finds rather than stacking a second clock on top of the first.
    func activate() {
        clock?.cancel()
        clock = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(1))
                guard let self else { return }
                if self.active != nil { self.now = Date() }
            }
        }

        poller?.cancel()
        poller = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                // The panel refreshes itself when it opens, so this only has to
                // catch changes made elsewhere - on the phone, or in a browser.
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }


    // MARK: - Actions

    func refresh() async {
        // The token comes off the Keychain, which is slow at best and can block
        // on a prompt, so it is fetched here rather than when the app starts.
        if !settings.isLoaded { await settings.load() }

        guard case .success(let client) = settings.makeClient() else {
            log.notice("Refresh skipped: settings incomplete (address empty: \(self.settings.address.isEmpty), token empty: \(self.settings.token.isEmpty))")
            phase = .needsSetup
            today = nil
            return
        }

        if today == nil { phase = .loading }
        await perform { try await client.today() }
    }

    func start(projectID: Int) async {
        guard case .success(let client) = settings.makeClient() else { return }
        pendingProjectID = projectID
        defer { pendingProjectID = nil }
        await perform { try await client.start(projectID: projectID) }
    }

    func stop() async {
        guard case .success(let client) = settings.makeClient() else { return }
        pendingProjectID = active?.projectId
        defer { pendingProjectID = nil }
        await perform { try await client.stop(description: nil) }
    }

    /// Run a call, fold its result into the state, and never leave the panel
    /// blank because one request failed - stale data plus the reason beats an
    /// empty window.
    private func perform(_ call: () async throws -> Today) async {
        do {
            today = try await call()
            now = Date()
            phase = .ready
            log.debug("Loaded today: \(self.today?.slots.count ?? 0) slots, running: \(self.active?.projectTitle ?? "nothing")")
        } catch let error as APIError {
            log.error("Request failed: \(error.errorDescription ?? "unknown")")
            phase = .failed(error.errorDescription ?? "Something went wrong.")
        } catch {
            log.error("Request failed: \(error.localizedDescription)")
            phase = .failed(error.localizedDescription)
        }
    }
}
