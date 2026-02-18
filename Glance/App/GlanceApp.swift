import SwiftUI
import SwiftData

@main
struct GlanceApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Profile.self,
            MarkerCategory.self,
            MarkerDefinition.self,
            UserMarker.self,
            MarkerEntry.self,
            Visit.self
        ])
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--ui-testing")
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: isUITesting)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
        // Seed synchronously before any view appears — avoids race with ContentView.onAppear
        MarkerLibrary.shared.seedIfNeeded(context: container.mainContext)
        if ProcessInfo.processInfo.arguments.contains("--with-sample-data") {
            Self.seedUITestMarker(in: container.mainContext)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }

    /// Seeds one tracked UserMarker (HDL Cholesterol) for UI test scenarios that need
    /// at least one marker tracked without going through onboarding.
    /// Uses LocalDataRepository so getOrCreateDefaultProfile() is handled automatically.
    private static func seedUITestMarker(in ctx: ModelContext) {
        let repo = LocalDataRepository(context: ctx)
        guard repo.getTrackedMarkers().isEmpty else { return }
        var defDescriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate { $0.displayName == "HDL Cholesterol" }
        )
        defDescriptor.fetchLimit = 1
        guard let hdl = try? ctx.fetch(defDescriptor).first else { return }
        _ = repo.addTrackedMarker(hdl)
    }
}
