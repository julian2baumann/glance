import SwiftUI
import SwiftData
import LocalAuthentication

/// Root view. Detects first launch and routes to either Onboarding or the main tab shell.
/// Also enforces biometric lock when enabled — locks on background, prompts on foreground.
struct ContentView: View {

    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase

    @State private var repository: LocalDataRepository?
    @State private var showOnboarding: Bool = false
    @State private var isReady: Bool = false
    @State private var isLocked: Bool = false

    var body: some View {
        Group {
            if !isReady {
                // Brief initialization — avoids flash of wrong state
                Color("AppBackground").ignoresSafeArea()
            } else if showOnboarding, let repo = repository {
                OnboardingView(repository: repo) {
                    withAnimation {
                        showOnboarding = false
                    }
                }
            } else if let repo = repository {
                MainTabView(repository: repo)
            }
        }
        .onAppear {
            guard repository == nil else { return }
            let repo = LocalDataRepository(context: context)
            repository = repo
            showOnboarding = repo.getTrackedMarkers().isEmpty
            if repo.getBiometricLockEnabled() {
                isLocked = true
            }
            isReady = true
        }
        .onChange(of: scenePhase) { _, phase in
            guard let repo = repository else { return }
            if phase == .background {
                if repo.getBiometricLockEnabled() {
                    isLocked = true
                }
            } else if phase == .active && isLocked {
                authenticate(repository: repo)
            }
        }
        .fullScreenCover(isPresented: $isLocked) {
            BiometricLockScreen {
                if let repo = repository {
                    authenticate(repository: repo)
                }
            }
        }
    }

    private func authenticate(repository: LocalDataRepository) {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics unavailable (device passcode fallback or no biometrics configured)
            isLocked = false
            return
        }
        context.evaluatePolicy(
            .deviceOwnerAuthentication,
            localizedReason: "Unlock Glance to access your health data"
        ) { success, _ in
            Task { @MainActor in
                if success { isLocked = false }
            }
        }
    }
}

// MARK: - Biometric Lock Screen

private struct BiometricLockScreen: View {
    let onUnlock: () -> Void

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()
            VStack(spacing: 32) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.accentColor)

                Text("Glance")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Button {
                    onUnlock()
                } label: {
                    Label("Unlock", systemImage: "faceid")
                        .font(.headline)
                        .frame(minWidth: 160, minHeight: 44)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear { onUnlock() }
    }
}

// MARK: - Main Tab Shell

struct MainTabView: View {
    let repository: LocalDataRepository

    var body: some View {
        TabView {
            HomeView(repository: repository)
                .tabItem {
                    Label("Markers", systemImage: "heart.text.square.fill")
                }

            VisitsPlaceholderView()
                .tabItem {
                    Label("Visits", systemImage: "calendar")
                }

            SettingsView(repository: repository)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(Color.accentColor)
    }
}

// MARK: - Placeholder Views (replaced in M4)

struct VisitsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Visits Coming Soon",
                systemImage: "calendar.badge.clock",
                description: Text("Visit logging and doctor prep insights will be available in a future update.")
            )
            .navigationTitle("Visits")
        }
    }
}

// MARK: - Previews

#Preview("Content — Onboarding") {
    let schema = Schema([
        Profile.self, MarkerCategory.self, MarkerDefinition.self,
        UserMarker.self, MarkerEntry.self, Visit.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    ContentView()
        .modelContainer(container)
}

#Preview("Content — Main App") {
    let data = PreviewData()
    ContentView()
        .modelContainer(data.container)
}
