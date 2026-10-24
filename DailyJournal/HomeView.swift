import SwiftUI

enum ActiveSheet: Identifiable {
    case newEntry
    case edit(JournalEntry)
    case date(JournalEntry)
    case calendar
    case settings

    var id: String {
        switch self {
        case .newEntry: return "new"
        case .edit(let entry): return "edit-\(entry.id)"
        case .date(let entry): return "date-\(entry.id)"
        case .calendar: return "calendar"
        case .settings: return "settings"
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var store: JournalStore
    @AppStorage("lockEnabled") private var lockEnabled = false
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var searchFocused: Bool

    @State private var scope: JournalScope = .today
    @State private var focusedID: UUID?
    @State private var activeSheet: ActiveSheet?
    @State private var pendingDeletion: JournalEntry?
    @State private var isSearching = false
    @State private var searchText = ""

    private var visibleEntries: [JournalEntry] {
        isSearching ? store.search(searchText) : store.entries(in: scope)
    }

    private var focusedEntry: JournalEntry? {
        guard let id = focusedID else { return nil }
        return store.entry(with: id)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    topBar
                    if isSearching {
                        searchBar
                    } else {
                        scopeCard
                    }
                    entriesCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, focusedEntry == nil ? 110 : 380)
            }

            if let entry = focusedEntry {
                VStack(spacing: 12) {
                    FocusedEntryCard(
                        entry: entry,
                        onToggleImportant: { store.toggleImportant(entry.id) },
                        onClose: collapse
                    )
                    actionBar(for: entry)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 92)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .zIndex(1)
            }

            bottomBar
                .padding(.bottom, 6)
                .zIndex(2)
        }
        .sheet(item: $activeSheet) { sheet in
            sheetContent(sheet)
        }
        .confirmationDialog(
            "حذف المذكرة؟",
            isPresented: isConfirmingDeletion,
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { entry in
            Button("حذف", role: .destructive) { delete(entry) }
            Button("إلغاء", role: .cancel) {}
        } message: { _ in
            Text("ما تقدر ترجعها بعد الحذف")
        }
        .onChange(of: scenePhase) { phase in
            guard phase == .background, lockEnabled else { return }
            activeSheet = nil
            focusedID = nil
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack {
            iconButton("square.grid.2x2") { activeSheet = .calendar }
            Spacer()
            Text("مذكراتي")
                .font(.cairo(28, .black))
                .foregroundColor(Theme.logo)
            Spacer()
            iconButton("gearshape.fill") { activeSheet = .settings }
        }
        .frame(height: 56)
    }

    private var scopeCard: some View {
        HStack(spacing: 12) {
            DayBadge(day: Calendar.journal.component(.day, from: scope.anchorDate))
            Text(scope.title)
                .font(.cairo(26, .bold))
                .foregroundColor(Theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            ProgressRing(value: store.streak, progress: Double(store.streak) / 7)
            Menu {
                scopeButton("اليوم", icon: "sun.max", scope: .today)
                scopeButton("آخر 7 أيام", icon: "calendar", scope: .week)
                scopeButton("كل المذكرات", icon: "books.vertical", scope: .all)
                Divider()
                Button { activeSheet = .calendar } label: {
                    Label("اختر يوم من التقويم", systemImage: "square.grid.2x2")
                }
            } label: {
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(Theme.icon)
                    .frame(width: 32, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 84)
        .card()
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.secondary)
            TextField("ابحث في مذكراتك", text: $searchText)
                .font(.cairo(18))
                .foregroundColor(Theme.ink)
                .disableAutocorrection(true)
                .focused($searchFocused)
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Theme.border)
                }
            }
            Button(action: closeSearch) {
                Text("إلغاء")
                    .font(.cairo(16, .semibold))
                    .foregroundColor(Theme.indigo)
            }
        }
        .padding(.horizontal, 20)
        .frame(height: 64)
        .card()
    }

    private var entriesCard: some View {
        let entries = visibleEntries
        let isDimmed = focusedID != nil
        return VStack(spacing: 0) {
            if entries.isEmpty {
                emptyState
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                    let depth = Double(max(index - 1, 0))
                    EntryRow(entry: entry, onToggleImportant: { store.toggleImportant(entry.id) })
                        .blur(radius: isDimmed ? CGFloat(min(depth * 0.9, 4)) : 0)
                        .opacity(isDimmed ? max(1 - depth * 0.18, 0.25) : 1)
                        .onTapGesture { focus(entry) }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .card()
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text(isSearching ? "🔍" : "✍️")
                .font(.system(size: 40))
            Text(isSearching ? "ما لقيت شي يطابق بحثك" : "ما كتبت شي هنا للحين")
                .font(.cairo(18, .semibold))
                .foregroundColor(Theme.ink)
            if !isSearching {
                Button { activeSheet = .newEntry } label: {
                    Text("اكتب مذكرة")
                        .font(.cairo(16, .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .frame(height: 46)
                        .background(Capsule().fill(Theme.indigo))
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    private func actionBar(for entry: JournalEntry) -> some View {
        HStack(spacing: 10) {
            Button(action: collapse) {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.square.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("تم")
                        .font(.cairo(18, .bold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 22)
                .frame(height: 60)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Theme.indigo)
                        .shadow(color: Theme.indigo.opacity(0.35), radius: 10, x: 0, y: 4)
                )
            }

            HStack(spacing: 0) {
                toolButton("calendar.badge.clock", color: Theme.pink) { activeSheet = .date(entry) }
                toolDivider
                toolButton("target", color: Theme.red) { store.toggleImportant(entry.id) }
                toolDivider
                Menu {
                    ForEach(Mood.allCases) { mood in
                        Button("\(mood.emoji)  \(mood.title)") { store.setMood(mood, for: entry.id) }
                    }
                } label: {
                    toolIcon("person.fill.badge.plus", color: Theme.blue)
                }
                toolDivider
                toolButton("pencil.circle", color: Theme.icon) { activeSheet = .edit(entry) }
                toolDivider
                toolButton("trash", color: Theme.icon) { pendingDeletion = entry }
            }
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.white.opacity(0.9))
                    .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white, lineWidth: 1)
            )
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 26) {
            Button(action: toggleSearch) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(isSearching ? Theme.indigo : Theme.icon)
                    .frame(width: 34, height: 34)
            }
            Button { activeSheet = .newEntry } label: {
                Image(systemName: "plus")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Theme.icon)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.background))
                    .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Theme.border, lineWidth: 1))
            }
            Button(action: goHome) {
                Image(systemName: "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 34, height: 34)
                    .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Theme.tile))
            }
        }
        .padding(.horizontal, 22)
        .frame(height: 62)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(red: 0.965, green: 0.965, blue: 0.97))
                .shadow(color: Color.black.opacity(0.08), radius: 16, x: 0, y: 6)
        )
    }

    // MARK: - Small builders

    private func iconButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(Theme.icon)
                .frame(width: 44, height: 44)
        }
    }

    private func scopeButton(_ title: String, icon: String, scope newScope: JournalScope) -> some View {
        Button { select(newScope) } label: {
            Label(title, systemImage: icon)
        }
    }

    private func toolIcon(_ icon: String, color: Color) -> some View {
        Image(systemName: icon)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(color)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
    }

    private func toolButton(_ icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            toolIcon(icon, color: color)
        }
    }

    private var toolDivider: some View {
        Rectangle()
            .fill(Theme.divider)
            .frame(width: 1, height: 26)
    }

    @ViewBuilder
    private func sheetContent(_ sheet: ActiveSheet) -> some View {
        switch sheet {
        case .newEntry:
            EntryEditor(entry: nil, defaultDate: scope.newEntryDate) { entry in
                store.add(entry)
            }
        case .edit(let entry):
            EntryEditor(entry: entry, defaultDate: entry.date) { updated in
                store.update(updated)
            }
        case .date(let entry):
            DateSheet(date: entry.date) { date in
                store.setDate(date, for: entry.id)
            }
        case .calendar:
            CalendarSheet(store: store) { day in
                closeSearch()
                select(.day(day))
            }
        case .settings:
            SettingsSheet(store: store)
        }
    }

    // MARK: - Actions

    private var isConfirmingDeletion: Binding<Bool> {
        Binding(
            get: { pendingDeletion != nil },
            set: { isPresented in
                if !isPresented { pendingDeletion = nil }
            }
        )
    }

    private func focus(_ entry: JournalEntry) {
        searchFocused = false
        withAnimation(.spring(response: 0.42, dampingFraction: 0.86)) {
            focusedID = entry.id
        }
    }

    private func collapse() {
        withAnimation(.spring(response: 0.38, dampingFraction: 0.9)) {
            focusedID = nil
        }
    }

    private func select(_ newScope: JournalScope) {
        withAnimation(.easeInOut(duration: 0.25)) {
            scope = newScope
            focusedID = nil
        }
    }

    private func toggleSearch() {
        if isSearching {
            closeSearch()
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            isSearching = true
            focusedID = nil
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            searchFocused = true
        }
    }

    private func closeSearch() {
        searchFocused = false
        withAnimation(.easeInOut(duration: 0.2)) {
            isSearching = false
            searchText = ""
        }
    }

    private func goHome() {
        closeSearch()
        select(.today)
    }

    private func delete(_ entry: JournalEntry) {
        withAnimation(.easeInOut(duration: 0.25)) {
            focusedID = nil
            store.delete(entry.id)
        }
        pendingDeletion = nil
    }
}
