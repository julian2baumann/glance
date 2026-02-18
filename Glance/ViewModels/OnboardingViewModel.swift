import Foundation
import SwiftData

@Observable
@MainActor
final class OnboardingViewModel {

    // MARK: - State

    var searchQuery: String = ""
    var selectedDefinitionIDs: Set<UUID> = []
    var isShowingCustomForm: Bool = false
    var customMarkerName: String = ""
    var customMarkerUnit: String = ""
    var customMarkerLowText: String = ""
    var customMarkerHighText: String = ""

    // MARK: - Data

    private var allCategories: [MarkerCategory] = []
    private var allDefinitions: [MarkerDefinition] = []
    private let repository: LocalDataRepository

    init(repository: LocalDataRepository) {
        self.repository = repository
        load()
    }

    func load() {
        allCategories = repository.getCategories()
        allDefinitions = repository.getMarkerLibrary()
    }

    // MARK: - Computed

    /// Categories and their markers filtered by the current search query.
    var filteredCategories: [(MarkerCategory, [MarkerDefinition])] {
        let trimmed = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()

        return allCategories
            .sorted { $0.displayOrder < $1.displayOrder }
            .compactMap { category in
                let markers: [MarkerDefinition]
                if trimmed.isEmpty {
                    markers = allDefinitions
                        .filter { $0.category?.id == category.id }
                        .sorted { $0.displayName < $1.displayName }
                } else {
                    markers = allDefinitions
                        .filter { $0.category?.id == category.id }
                        .filter { def in
                            def.displayName.lowercased().contains(trimmed) ||
                            def.aliases.contains { $0.lowercased().contains(trimmed) }
                        }
                        .sorted { $0.displayName < $1.displayName }
                }
                return markers.isEmpty ? nil : (category, markers)
            }
    }

    var selectedCount: Int { selectedDefinitionIDs.count }

    // MARK: - Selection

    func isSelected(_ definition: MarkerDefinition) -> Bool {
        selectedDefinitionIDs.contains(definition.id)
    }

    func toggleSelection(_ definition: MarkerDefinition) {
        if selectedDefinitionIDs.contains(definition.id) {
            selectedDefinitionIDs.remove(definition.id)
        } else {
            selectedDefinitionIDs.insert(definition.id)
        }
    }

    // MARK: - Confirm

    /// Creates UserMarker entities for all selected definitions and calls the completion.
    func confirmSelection(completion: () -> Void) {
        let selected = allDefinitions.filter { selectedDefinitionIDs.contains($0.id) }
        for (index, definition) in selected.enumerated() {
            let marker = repository.addTrackedMarker(definition)
            var markers = repository.getTrackedMarkers()
            marker.displayOrder = index
            _ = markers  // suppress unused warning
        }
        // Re-save order
        repository.updateMarkerOrder(repository.getTrackedMarkers())
        completion()
    }

    // MARK: - Custom Marker

    var canAddCustomMarker: Bool {
        !customMarkerName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !customMarkerUnit.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func addCustomMarker() {
        let low = Double(customMarkerLowText)
        let high = Double(customMarkerHighText)
        let definition = MarkerDefinition(
            displayName: customMarkerName.trimmingCharacters(in: .whitespaces),
            defaultUnit: customMarkerUnit.trimmingCharacters(in: .whitespaces),
            defaultReferenceLow: low,
            defaultReferenceHigh: high,
            isSystemDefined: false
        )
        let added = repository.addCustomMarker(definition)
        selectedDefinitionIDs.insert(added.id)
        allDefinitions.append(added)

        // Reset form
        customMarkerName = ""
        customMarkerUnit = ""
        customMarkerLowText = ""
        customMarkerHighText = ""
        isShowingCustomForm = false
    }
}
