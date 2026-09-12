import SwiftUI

/// One of the day's blocks, as a single tap target: clicking it starts that
/// project, or stops it when it is the one already running. There is no second
/// Stop button anywhere - the row you are on is the row you press.
///
/// The look is the web app's slot card: a coloured bar down the left edge, the
/// same colour washed faintly behind it, and the same meanings attached to the
/// colours - so a glance here and a glance at the home page agree.
struct SlotRow: View {
    let slot: Slot
    let trackedSeconds: Int
    let isPending: Bool
    let action: () -> Void

    @State private var isHovering = false

    private var isRunning: Bool { slot.isRunning }
    private var accent: Color { slot.accent }

    var body: some View {
        if let project = slot.project {
            Button(action: action) {
                content(project: project)
            }
            .buttonStyle(.plain)
            .disabled(isPending)
            .onHover { isHovering = $0 }
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
                    .foregroundStyle(Color.mutedForeground)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 3) {
                Text(Duration.clock(trackedSeconds))
                    .font(.system(size: 12, weight: isRunning ? .semibold : .regular, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(isRunning ? accent : Color.mutedForeground)

                glyph
            }
        }
        .padding(.vertical, 9)
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
        .opacity(isPending ? 0.55 : 1)
        .contentShape(Rectangle())
    }

    private var background: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 10)
                .fill(accent.opacity(isRunning ? 0.16 : (isHovering ? 0.13 : 0.08)))

            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(accent.opacity(isRunning ? 0.55 : 0.22), lineWidth: 1)

            // The left bar, clipped back to the card's own corners so it hugs
            // the rounding instead of poking out of it.
            Rectangle()
                .fill(accent)
                .frame(width: 3)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }

    private var badge: some View {
        ZStack {
            Circle()
                .fill(isRunning ? accent : accent.opacity(0.16))
                .frame(width: 22, height: 22)

            if slot.isDone && !isRunning {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(accent)
            } else {
                Text(slot.slot)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(isRunning ? Color.white : accent)
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
                .foregroundStyle(isRunning ? accent : accent.opacity(0.55))
        }
    }

    private var emptySlot: some View {
        HStack(spacing: 10) {
            Text(slot.slot)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(Color.mutedForeground.opacity(0.7))
                .frame(width: 22, height: 22)
                .background(
                    Circle().strokeBorder(
                        Color.mutedForeground.opacity(0.35),
                        style: StrokeStyle(lineWidth: 1, dash: [3, 2])
                    )
                )

            Text("Nothing booked")
                .font(.system(size: 12))
                .foregroundStyle(Color.mutedForeground.opacity(0.8))

            Spacer()
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    Color.cardBorder,
                    style: StrokeStyle(lineWidth: 1, dash: [4, 3])
                )
        )
    }
}
