import SwiftUI

struct DateSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var date: Date
    private let onSave: (Date) -> Void

    init(date: Date, onSave: @escaping (Date) -> Void) {
        _date = State(initialValue: date)
        self.onSave = onSave
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                SheetHeader(
                    title: "تاريخ المذكرة",
                    onCancel: { dismiss() },
                    confirmTitle: "حفظ",
                    onConfirm: {
                        onSave(date)
                        dismiss()
                    }
                )

                DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .accentColor(Theme.indigo)
                    .padding(12)
                    .card()

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .journalEnvironment()
    }
}

struct CalendarSheet: View {
    @ObservedObject var store: JournalStore
    let onSelect: (Date) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var month = Calendar.journal.startOfMonth(for: Date())

    private let calendar = Calendar.journal
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    private var dayCells: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: month) else { return [] }
        let weekday = calendar.component(.weekday, from: month)
        let leadingBlanks = (weekday - calendar.firstWeekday + 7) % 7
        let days: [Date?] = range.map { calendar.date(byAdding: .day, value: $0 - 1, to: month) }
        return [Date?](repeating: nil, count: leadingBlanks) + days
    }

    private var summary: String {
        "كتبت في \(store.daysWritten(inMonthOf: month)) يوم هذا الشهر"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
                SheetHeader(title: "التقويم", cancelTitle: "إغلاق", onCancel: { dismiss() })

                VStack(spacing: 14) {
                    HStack {
                        monthButton("chevron.backward", offset: -1)
                        Spacer()
                        Text(Format.monthYear(month))
                            .font(.cairo(19, .bold))
                            .foregroundColor(Theme.ink)
                        Spacer()
                        monthButton("chevron.forward", offset: 1)
                    }

                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                            Text(symbol)
                                .font(.cairo(12, .semibold))
                                .foregroundColor(Theme.secondary)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                        }
                        ForEach(Array(dayCells.enumerated()), id: \.offset) { _, day in
                            if let day = day {
                                dayCell(day)
                            } else {
                                Color.clear.frame(height: 54)
                            }
                        }
                    }
                }
                .padding(18)
                .card()

                Text(summary)
                    .font(.cairo(15, .medium))
                    .foregroundColor(Theme.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
        }
        .journalEnvironment()
    }

    private func monthButton(_ icon: String, offset: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                month = calendar.date(byAdding: .month, value: offset, to: month) ?? month
            }
        } label: {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.icon)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Theme.background))
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let mood = store.latestMood(on: day)
        let isToday = calendar.isDateInToday(day)
        let fill: Color = isToday ? Theme.indigo : (mood == nil ? Color.clear : Theme.background)

        return Button {
            onSelect(day)
            dismiss()
        } label: {
            VStack(spacing: 0) {
                Text(String(calendar.component(.day, from: day)))
                    .font(.cairo(15, isToday ? .bold : .medium))
                    .foregroundColor(isToday ? .white : Theme.ink)
                Text(mood?.emoji ?? " ")
                    .font(.system(size: 12))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill))
        }
        .buttonStyle(.plain)
    }
}

struct SettingsSheet: View {
    @ObservedObject var store: JournalStore

    @Environment(\.dismiss) private var dismiss
    @AppStorage("lockEnabled") private var lockEnabled = false
    @State private var lockMessage: String?

    private let lockIcon = AppLock.biometryIcon

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    SheetHeader(title: "الإعدادات", cancelTitle: "إغلاق", onCancel: { dismiss() })

                    HStack(spacing: 10) {
                        StatTile(value: store.entries.count, title: "مذكرة", icon: "book.closed.fill", color: Theme.indigo)
                        StatTile(value: store.streak, title: "يوم متتالي", icon: "flame.fill", color: Theme.red)
                        StatTile(value: store.importantCount, title: "مهمة", icon: "target", color: Theme.pink)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(isOn: lockBinding) {
                            HStack(spacing: 10) {
                                Image(systemName: lockIcon)
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(Theme.indigo)
                                Text("قفل التطبيق")
                                    .font(.cairo(17, .semibold))
                                    .foregroundColor(Theme.ink)
                            }
                        }
                        .tint(Theme.indigo)

                        Text(lockMessage ?? "يطلب Face ID أو رمز الجهاز كل ما فتحت التطبيق")
                            .font(.cairo(13))
                            .foregroundColor(lockMessage == nil ? Theme.secondary : Theme.red)
                    }
                    .padding(20)
                    .card()

                    HStack {
                        Text("الإصدار")
                            .font(.cairo(17, .semibold))
                            .foregroundColor(Theme.ink)
                        Spacer()
                        Text(appVersion)
                            .font(.cairo(17))
                            .foregroundColor(Theme.secondary)
                    }
                    .padding(.horizontal, 20)
                    .frame(height: 62)
                    .card()
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
            }
        }
        .journalEnvironment()
    }

    private var lockBinding: Binding<Bool> {
        Binding(
            get: { lockEnabled },
            set: { isOn in
                guard isOn else {
                    lockEnabled = false
                    return
                }
                AppLock.authenticate(reason: "تفعيل قفل مذكراتي", allowWhenUnavailable: false) { success in
                    if success {
                        lockEnabled = true
                        lockMessage = nil
                    } else {
                        lockMessage = "ما تفعّل القفل. تأكد إن رمز القفل أو Face ID شغال في جهازك"
                    }
                }
            }
        )
    }
}
