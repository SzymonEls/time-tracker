import SwiftUI

/// One of the day's blocks, as a single tap target: clicking it starts that
/// project, or stops it when it is the one already running. There is no second
/// Stop button anywhere - the row you are on is the row you press.
struct SlotRow: View {
    let slot: Slot
    let trackedSeconds: Int
    let isPending: Bool
    let action: () -> Void

    private var isRunning: Bool { slot.isRunning }

    var body: some View {
        if let project = slot.project {
            Button(action: action) {
                content(project: project)
            }
            .buttonStyle(.plain)
            .disabled(isPending)
        } else {
            emptySlot
        }
    }

    private func content(project: Project) -> some View {
        HStack(alignment: .top, spacing: 10) {
            badge

            VStack(alignment: .leading, spacing: 2) {
                Text(project.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(project.focus.isEmpty ? project.shortGoal : project.focus)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 3) {
                Text(Duration.clock(trackedSeconds))
                    .font(.system(size: 12, weight: isRunning ? .semibold : .regular, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isRunning ? Color.accentColor : .secondary)

                glyph
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(isRunning ? Color.accentColor.opacity(0.13) : Color.primary.opacity(0.045))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(isRunning ? Color.accentColor.opacity(0.45) : .clear, lineWidth: 1)
        )
        .opacity(isPending ? 0.55 : 1)
        .contentShape(Rectangle())
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(isRunning ? Color.accentColor : Color.primary.opacity(0.1))
                .frame(width: 22, height: 22)

            if slot.isDone && !isRunning {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.green)
            } else {
                Text(slot.slot)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isRunning ? Color.white : .secondary)
            }
        }
        .padding(.top, 1)
    }

    @ViewBuilder
    private var glyph: some View {
        if isPending {
            ProgressView()
                .controlSize(.mini)
        } else {
            Image(systemName: isRunning ? "stop.fill" : "play.fill")
                .font(.system(size: 9))
                .foregroundStyle(isRunning ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary))
        }
    }

    private var emptySlot: some View {
        HStack(spacing: 10) {
            Text(slot.slot)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.tertiary)
                .frame(width: 22, height: 22)
                .background(Circle().strokeBorder(Color.primary.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [3, 2])))

            Text("Nothing booked")
                .font(.system(size: 12))
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
    }
}
