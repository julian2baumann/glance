import Foundation
import SwiftData

@MainActor
final class SearchService {

    func search(
        query: String,
        in context: ModelContext,
        trackedMarkers: [UserMarker]
    ) -> SearchResults {
        let trimmed = query.trimmingCharacters(in: .whitespaces).lowercased()

        guard !trimmed.isEmpty else {
            return SearchResults(trackedMarkers: [], untrackedDefinitions: [])
        }

        let descriptor = FetchDescriptor<MarkerDefinition>()
        let allDefinitions = (try? context.fetch(descriptor)) ?? []

        let matchingDefinitions = allDefinitions.filter { definition in
            definition.displayName.lowercased().contains(trimmed) ||
            definition.aliases.contains(where: { $0.lowercased().contains(trimmed) })
        }

        let trackedDefinitionIDs = Set(
            trackedMarkers.compactMap { $0.markerDefinition?.id }
        )

        var trackedResults: [UserMarker] = []
        var untrackedResults: [MarkerDefinition] = []

        for definition in matchingDefinitions {
            if trackedDefinitionIDs.contains(definition.id) {
                if let userMarker = trackedMarkers.first(where: { $0.markerDefinition?.id == definition.id }) {
                    trackedResults.append(userMarker)
                }
            } else {
                untrackedResults.append(definition)
            }
        }

        return SearchResults(
            trackedMarkers: trackedResults,
            untrackedDefinitions: untrackedResults
        )
    }
}
