import SwiftUI

struct DayBadge: View {
    let day: Int

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Theme.yellow)
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color.white.opacity(0.6))
                .frame(width: 19, height: 16)
                .offset(y: 2)
            Text(String(day))
                .font(.cairo(10, .black))
                .foregroundColor(Color(red: 0.74, green: 0.50, blue: 0.0))
                .offset(y: 2)
        }
        .frame(width: 30, height: 30)
    }
}

struct ProgressRing: View {
    let value: Int
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Theme.divider, lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(Theme.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
            Text(String(value))
                .font(.cairo(15, .semibold))
                .foregroundColor(Theme.secondary)
        }
        .frame(width: 34, height: 34)
    }
}

struct CheckBox: View {
    let isChecked: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isChecked ? Theme.indigo : Color.white)
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .stroke(isChecked ? Theme.indigo : Theme.border, lineWidth: 1.5)
            if isChecked {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(width: 26, height: 26)
    }
}

/// Stands in for the avatar bubbles of the reference design: the entry's mood emoji in a soft yellow circle.
struct MoodAvatar: View {
    let mood: Mood

    var body: some View {
        Text(mood.emoji)
            .font(.system(size: 16))
            .frame(width: 32, height: 32)
            .background(Circle().fill(Theme.avatar))
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
    }
}

struct DueLabel: View {
    let date: Date

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "target")
                .font(.system(size: 15, weight: .semibold))
            Text("\(Format.dayMonth(date)) / \(Format.time(date))")
                .font(.cairo(15, .semibold))
                .lineLimit(1)
        }
        .foregroundColor(Theme.red)
    }
}

struct EntryRow: View {
    let entry: JournalEntry
    let onToggleImportant: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggleImportant) {
                CheckBox(isChecked: entry.isImportant)
            }
            .buttonStyle(.plain)

            Text(entry.displayTitle)
                .font(.cairo(17, .medium))
                .foregroundColor(Theme.ink)
                .lineLimit(1)

            Spacer(minLength: 8)

            if entry.isImportant {
                DueLabel(date: entry.date)
            } else {
                MoodAvatar(mood: entry.mood)
            }
        }
        .frame(minHeight: 50)
        .contentShape(Rectangle())
    }
}

struct FocusedEntryCard: View {
    let entry: JournalEntry
    let onToggleImportant: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: onToggleImportant) {
                    CheckBox(isChecked: entry.isImportant)
                }
                .buttonStyle(.plain)

                Text(entry.displayTitle)
                    .font(.cairo(17, .semibold))
                    .foregroundColor(Theme.ink)
                    .lineLimit(2)

                Spacer(minLength: 8)

                MoodAvatar(mood: entry.mood)
            }

            if !entry.text.isEmpty {
                Text(entry.text)
                    .font(.cairo(16))
                    .foregroundColor(Theme.body)
                    .lineSpacing(2)
                    .lineLimit(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            HStack(spacing: 8) {
                Text("كُتبت \(Format.full(entry.date))")
                    .font(.cairo(15))
                    .foregroundColor(Theme.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Theme.inboxBlue)
                    Text(entry.mood.title)
                        .font(.cairo(16, .semibold))
                        .foregroundColor(Theme.inboxBlue)
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Theme.secondary)
                            .frame(width: 22, height: 22)
                    }
                }
                .padding(.leading, 14)
                .padding(.trailing, 8)
                .frame(height: 44)
                .background(Capsule().fill(Theme.pill))
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Theme.card)
                .shadow(color: Color.black.opacity(0.08), radius: 24, x: 0, y: 10)
        )
    }
}

struct SheetHeader: View {
    let title: String
    var cancelTitle = "إلغاء"
    let onCancel: () -> Void
    var confirmTitle: String? = nil
    var confirmDisabled = false
    var onConfirm: (() -> Void)? = nil

    var body: some View {
        ZStack {
            Text(title)
                .font(.cairo(18, .bold))
                .foregroundColor(Theme.ink)

            HStack {
                Button(action: onCancel) {
                    Text(cancelTitle)
                        .font(.cairo(16, .medium))
                        .foregroundColor(Theme.secondary)
                }
                Spacer()
                if let confirmTitle = confirmTitle, let onConfirm = onConfirm {
                    Button(action: onConfirm) {
                        Text(confirmTitle)
                            .font(.cairo(16, .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 38)
                            .background(Capsule().fill(confirmDisabled ? Theme.border : Theme.indigo))
                    }
                    .disabled(confirmDisabled)
                }
            }
        }
        .frame(height: 48)
    }
}

struct StatTile: View {
    let value: Int
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(color)
            Text(String(value))
                .font(.cairo(26, .bold))
                .foregroundColor(Theme.ink)
            Text(title)
                .font(.cairo(13, .medium))
                .foregroundColor(Theme.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .card(cornerRadius: 22)
    }
}
