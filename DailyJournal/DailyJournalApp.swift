import SwiftUI

@main
struct DailyJournalApp: App {
    @StateObject private var store = JournalStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .journalEnvironment()
        }
    }
}

struct RootView: View {
    @AppStorage("lockEnabled") private var lockEnabled = false
    // Starts locked on launch; turning the lock on in Settings doesn't lock until the app leaves the foreground.
    @State private var isLocked = UserDefaults.standard.bool(forKey: "lockEnabled")
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            HomeView()

            if lockEnabled && isLocked {
                LockView {
                    withAnimation(.easeOut(duration: 0.25)) { isLocked = false }
                }
                .transition(.opacity)
                .zIndex(3)
            }
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background && lockEnabled {
                isLocked = true
            }
        }
    }
}
