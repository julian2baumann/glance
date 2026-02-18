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
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
                .onAppear {
                    MarkerLibrary.shared.seedIfNeeded(context: container.mainContext)
                }
        }
    }
}
