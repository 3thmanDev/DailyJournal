import Foundation

/// Keeps every entry in memory and mirrors it to a JSON file in Documents after each change.
final class JournalStore: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []

    private let fileURL: URL
    private let calendar = Calendar.journal

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = documents.appendingPathComponent("journal.json")
        load()
        seedWelcomeEntriesIfNeeded()
    }

    // MARK: - Queries

    func entry(with id: UUID) -> JournalEntry? {
        entries.first { $0.id == id }
    }

    func entries(in scope: JournalScope) -> [JournalEntry] {
        let filtered: [JournalEntry]
        switch scope {
        case .today:
            filtered = entries.filter { calendar.isDateInToday($0.date) }
        case .day(let day):
            filtered = entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
        case .week:
            let today = calendar.startOfDay(for: Date())
            let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            filtered = entries.filter { $0.date >= start }
        case .all:
            filtered = entries
        }
        return filtered.sorted { $0.date > $1.date }
    }

    func search(_ query: String) -> [JournalEntry] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries(in: .all) }
        return entries
            .filter { $0.title.localizedCaseInsensitiveContains(trimmed) || $0.text.localizedCaseInsensitiveContains(trimmed) }
            .sorted { $0.date > $1.date }
    }

    /// Consecutive days with at least one entry, ending today (or yesterday if today is still empty).
    var streak: Int {
        let writtenDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        var day = calendar.startOfDay(for: Date())
        if !writtenDays.contains(day), let yesterday = calendar.date(byAdding: .day, value: -1, to: day) {
            day = yesterday
        }
        var count = 0
        while writtenDays.contains(day), let previous = calendar.date(byAdding: .day, value: -1, to: day) {
            count += 1
            day = previous
        }
        return count
    }

    var importantCount: Int {
        entries.filter { $0.isImportant }.count
    }

    func latestMood(on day: Date) -> Mood? {
        let latest = entries
            .filter { calendar.isDate($0.date, inSameDayAs: day) }
            .max { $0.date < $1.date }
        return latest?.mood
    }

    func daysWritten(inMonthOf month: Date) -> Int {
        let days = entries
            .filter { calendar.isDate($0.date, equalTo: month, toGranularity: .month) }
            .map { calendar.startOfDay(for: $0.date) }
        return Set(days).count
    }

    // MARK: - Changes

    func add(_ entry: JournalEntry) {
        entries.append(entry)
        save()
    }

    func update(_ entry: JournalEntry) {
        mutate(entry.id) { $0 = entry }
    }

    func delete(_ id: UUID) {
        entries.removeAll { $0.id == id }
        save()
    }

    func toggleImportant(_ id: UUID) {
        mutate(id) { $0.isImportant.toggle() }
    }

    func setMood(_ mood: Mood, for id: UUID) {
        mutate(id) { $0.mood = mood }
    }

    func setDate(_ date: Date, for id: UUID) {
        mutate(id) { $0.date = date }
    }

    private func mutate(_ id: UUID, _ change: (inout JournalEntry) -> Void) {
        guard let index = entries.firstIndex(where: { $0.id == id }) else { return }
        change(&entries[index])
        save()
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            entries = try JSONDecoder().decode([JournalEntry].self, from: data)
        } catch {
            // Keep the unreadable file aside so the next save can't overwrite the user's entries.
            let backup = fileURL.deletingPathExtension().appendingPathExtension("backup-\(Int(Date().timeIntervalSince1970)).json")
            try? FileManager.default.copyItem(at: fileURL, to: backup)
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            print("Failed to save journal: \(error)")
        }
    }

    private func seedWelcomeEntriesIfNeeded() {
        let key = "didSeedWelcomeEntries"
        guard entries.isEmpty, !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)

        let now = Date()
        entries = [
            JournalEntry(
                title: "أهلاً بك في مذكراتي 👋",
                text: "هنا تكتب يومك بكل خصوصية. اضغط على أي مذكرة عشان تفتحها، ومن الشريط اللي تحتها تقدر تغيّر التاريخ أو المزاج، أو تعدّلها، أو تحذفها.",
                mood: .great,
                date: now,
                isImportant: false
            ),
            JournalEntry(
                title: "اضغط + تحت عشان تكتب مذكرة جديدة",
                text: "اكتب عنوان ومحتوى، واختر مزاجك اليوم. كل مذكراتك تنحفظ في جهازك بس.",
                mood: .good,
                date: now.addingTimeInterval(-60)
            ),
            JournalEntry(
                title: "فعّل قفل Face ID من الإعدادات ⚙️",
                text: "من زر الترس فوق تقدر تقفل التطبيق بـ Face ID أو رمز الجهاز، عشان محد يقرأ مذكراتك.",
                mood: .okay,
                date: now.addingTimeInterval(-120)
            ),
        ]
        save()
    }
}
