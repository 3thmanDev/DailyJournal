import SwiftUI

struct EntryEditor: View {
    @Environment(\.dismiss) private var dismiss

    private let original: JournalEntry?
    private let onSave: (JournalEntry) -> Void

    @State private var title: String
    @State private var text: String
    @State private var mood: Mood
    @State private var date: Date

    init(entry: JournalEntry?, defaultDate: Date, onSave: @escaping (JournalEntry) -> Void) {
        original = entry
        self.onSave = onSave
        _title = State(initialValue: entry?.title ?? "")
        _text = State(initialValue: entry?.text ?? "")
        _mood = State(initialValue: entry?.mood ?? .good)
        _date = State(initialValue: entry?.date ?? defaultDate)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 12) {
                SheetHeader(
                    title: original == nil ? "مذكرة جديدة" : "تعديل المذكرة",
                    onCancel: { dismiss() },
                    confirmTitle: "حفظ",
                    confirmDisabled: !canSave,
                    onConfirm: save
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        TextField("العنوان", text: $title)
                            .font(.cairo(22, .bold))
                            .foregroundColor(Theme.ink)
                            .padding(.horizontal, 20)
                            .frame(height: 66)
                            .card()

                        moodPicker

                        DatePicker(selection: $date, displayedComponents: [.date, .hourAndMinute]) {
                            HStack(spacing: 10) {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundColor(Theme.pink)
                                Text("التاريخ")
                                    .font(.cairo(17, .semibold))
                                    .foregroundColor(Theme.ink)
                            }
                        }
                        .padding(.horizontal, 20)
                        .frame(height: 66)
                        .card()

                        textCard
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .journalEnvironment()
    }

    private var moodPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("كيف كان يومك؟")
                .font(.cairo(17, .semibold))
                .foregroundColor(Theme.ink)

            HStack(spacing: 0) {
                ForEach(Mood.allCases) { option in
                    let isSelected = option == mood
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { mood = option }
                    } label: {
                        VStack(spacing: 4) {
                            Text(option.emoji)
                                .font(.system(size: 26))
                                .frame(width: 50, height: 50)
                                .background(Circle().fill(isSelected ? Theme.avatar : Theme.background))
                                .overlay(Circle().stroke(isSelected ? Theme.yellow : Color.clear, lineWidth: 2))
                                .scaleEffect(isSelected ? 1.08 : 1)
                            Text(option.title)
                                .font(.cairo(13, isSelected ? .bold : .medium))
                                .foregroundColor(isSelected ? Theme.ink : Theme.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(20)
        .card()
    }

    private var textCard: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(.cairo(17))
                .foregroundColor(Theme.ink)
                .frame(minHeight: 280)
            if text.isEmpty {
                Text("اكتب يومياتك هنا...")
                    .font(.cairo(17))
                    .foregroundColor(Theme.secondary.opacity(0.7))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 8)
                    .allowsHitTesting(false)
            }
        }
        .padding(16)
        .card()
    }

    private func save() {
        var entry = original ?? JournalEntry(title: "", text: "", mood: mood, date: date)
        entry.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.mood = mood
        entry.date = date
        onSave(entry)
        dismiss()
    }
}
