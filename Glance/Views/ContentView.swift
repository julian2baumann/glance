import SwiftUI
import SwiftData

/// Root view. Detects first launch and routes to either Onboarding or the main tab shell.
struct ContentView: View {

    @Environment(\.modelContext) private var context
    @State private var repository: LocalDataRepository?
    @State private var showOnboarding: Bool = false
    @State private var isReady: Bool = false

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
            isReady = true
        }
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

            SettingsPlaceholderView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .tint(Color.accentColor)
    }
}

// MARK: - Placeholder Views (replaced in M3/M4)

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

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Settings Coming Soon",
                systemImage: "gear",
                description: Text("Marker management, export, and reference range editing will be available in a future update.")
            )
            .navigationTitle("Settings")
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
