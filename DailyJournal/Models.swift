import SwiftUI

enum Mood: String, Codable, CaseIterable, Identifiable {
    case great, good, okay, sad, upset

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .okay: return "😐"
        case .sad: return "😢"
        case .upset: return "😠"
        }
    }

    var title: String {
        switch self {
        case .great: return "رائع"
        case .good: return "جيد"
        case .okay: return "عادي"
        case .sad: return "حزين"
        case .upset: return "متضايق"
        }
    }
}

struct JournalEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var text: String
    var mood: Mood
    var date: Date
    var createdAt = Date()
    /// The checkbox in the list and the red target in the toolbar both flip this.
    var isImportant = false

    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        let firstLine = text.split(whereSeparator: \.isNewline).first.map { String($0) } ?? ""
        return firstLine.isEmpty ? "مذكرة بدون عنوان" : String(firstLine.prefix(40))
    }
}

enum JournalScope: Equatable {
    case today, week, all
    case day(Date)

    var title: String {
        switch self {
        case .today: return "اليوم"
        case .week: return "آخر 7 أيام"
        case .all: return "كل المذكرات"
        case .day(let date): return Calendar.journal.isDateInToday(date) ? "اليوم" : Format.dayMonth(date)
        }
    }

    var anchorDate: Date {
        if case .day(let date) = self { return date }
        return Date()
    }

    var isSingleDay: Bool {
        switch self {
        case .today, .day: return true
        case .week, .all: return false
        }
    }

    /// A new entry lands on the day being viewed, at the current time of day.
    var newEntryDate: Date {
        let calendar = Calendar.journal
        guard case .day(let day) = self, !calendar.isDateInToday(day) else { return Date() }
        let now = calendar.dateComponents([.hour, .minute], from: Date())
        return calendar.date(bySettingHour: now.hour ?? 12, minute: now.minute ?? 0, second: 0, of: day) ?? day
    }
}
