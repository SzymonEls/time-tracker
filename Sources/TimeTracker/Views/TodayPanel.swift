import SwiftUI

/// The window that drops out of the menu bar: today's three blocks, what is
/// running, and nothing else. Anything that needs more room than this belongs
/// in the web app.
struct TodayPanel: View {
    @Environment(TimerStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().opacity(0.5)

            Group {
                switch store.phase {
                case .needsSetup:
                    setupPrompt
                case .loading where store.today == nil:
                    placeholder
                default:
                    slots
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)

            if case .failed(let message) = store.phase {
                errorBanner(message)
            }

            Divider().opacity(0.5)
            footer
        }
        .frame(width: 320)
        .task { await store.refresh() }
    }

    // MARK: - Sections

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            BrandDiamond()
                .padding(.top, 3)

            VStack(alignment: .leading, spacing: 1) {
                Text("Today")
                    .font(.system(size: 14, weight: .semibold))
                Text(headerDate)
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mutedForeground)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 1) {
                Text(Duration.clock(store.dayTotalSeconds))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(store.active == nil ? Color.primary : Color.brand)
                Text("tracked")
                    .font(.system(size: 11))
                    .foregroundStyle(Color.mutedForeground)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 11)
        .padding(.bottom, 9)
    }

    private var slots: some View {
        VStack(spacing: 6) {
            ForEach(store.today?.slots ?? []) { slot in
                SlotRow(
                    slot: slot,
                    trackedSeconds: store.tracked(in: slot),
                    isPending: store.pendingProjectID == slot.project?.id
                ) {
                    Task { await toggle(slot) }
                }
            }
        }
    }

    private var setupPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Not connected yet")
                .font(.system(size: 13, weight: .semibold))
            Text("Point the app at your productivity instance and paste the API token from its account page.")
                .font(.system(size: 11))
                .foregroundStyle(Color.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open Settings", action: showSettings)
                .controlSize(.small)
                .tint(.brand)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var placeholder: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Loading today…")
                .font(.system(size: 12))
                .foregroundStyle(Color.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 14)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(Color.warning)
                .padding(.top, 1)

            Text(message)
                .font(.system(size: 11))
                .foregroundStyle(Color.mutedForeground)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    private var footer: some View {
        HStack(spacing: 4) {
            FooterButton(icon: "arrow.clockwise", help: "Refresh") {
                Task { await store.refresh() }
            }
            FooterButton(icon: "gearshape", help: "Settings", action: showSettings)
            FooterButton(icon: "safari", help: "Open in browser", action: openWebApp)

            Spacer()

            FooterButton(icon: "power", help: "Quit TimeTracker", tint: .danger) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
    }

    // MARK: - Actions

    private func toggle(_ slot: Slot) async {
        guard let project = slot.project else { return }
        if slot.isRunning {
            await store.stop()
        } else {
            await store.start(projectID: project.id)
        }
    }

    private func openWebApp() {
        guard case .success(let client) = settings.makeClient() else { return }
        NSWorkspace.shared.open(client.baseURL)
    }

    private func showSettings() {
        // An accessory app has no windows in front of anything, so the Settings
        // scene would open behind whatever you were using without this.
        NSApplication.shared.activate(ignoringOtherApps: true)
        openSettings()
    }

    private var headerDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMMM"
        return formatter.string(from: Date())
    }
}

private struct FooterButton: View {
    let icon: String
    let help: String
    var tint: Color = .brand
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundStyle(isHovering ? tint : Color.mutedForeground)
                .frame(width: 26, height: 22)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(isHovering ? tint.opacity(0.12) : .clear)
                )
        }
        .buttonStyle(.plain)
        .help(help)
        .onHover { isHovering = $0 }
    }
}
