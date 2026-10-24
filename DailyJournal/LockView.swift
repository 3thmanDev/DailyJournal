import SwiftUI
import LocalAuthentication

enum AppLock {
    /// Face ID / Touch ID with passcode fallback. `allowWhenUnavailable` lets the app open on devices with no passcode at all.
    static func authenticate(reason: String, allowWhenUnavailable: Bool, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(allowWhenUnavailable)
            return
        }
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    static var biometryIcon: String {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock.fill"
        }
    }
}

struct LockView: View {
    let onUnlock: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @State private var didAutoPrompt = false
    @State private var isAuthenticating = false

    private let unlockIcon = AppLock.biometryIcon

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                Image(systemName: "lock.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundColor(Theme.indigo)
                    .frame(width: 96, height: 96)
                    .card(cornerRadius: 32)

                VStack(spacing: 6) {
                    Text("مذكراتي مقفلة")
                        .font(.cairo(26, .bold))
                        .foregroundColor(Theme.ink)
                    Text("افتح القفل عشان تشوف مذكراتك")
                        .font(.cairo(16))
                        .foregroundColor(Theme.secondary)
                }

                Spacer()

                Button(action: unlock) {
                    HStack(spacing: 10) {
                        Image(systemName: unlockIcon)
                            .font(.system(size: 20, weight: .semibold))
                        Text("فتح القفل")
                            .font(.cairo(18, .bold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Theme.indigo))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .onAppear(perform: autoPromptIfActive)
        .onChange(of: scenePhase) { _ in autoPromptIfActive() }
    }

    /// Prompts once per lock; after a cancel the user taps the button, so the prompt can't loop.
    private func autoPromptIfActive() {
        guard scenePhase == .active, !didAutoPrompt else { return }
        didAutoPrompt = true
        unlock()
    }

    private func unlock() {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        AppLock.authenticate(reason: "افتح مذكراتي", allowWhenUnavailable: true) { success in
            isAuthenticating = false
            if success { onUnlock() }
        }
    }
}
