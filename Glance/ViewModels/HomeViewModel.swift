import Foundation
import SwiftData

@Observable
@MainActor
final class HomeViewModel {

    // MARK: - State

    var trackedMarkers: [UserMarker] = []
    var searchQuery: String = ""
    var searchResults: SearchResults = SearchResults(trackedMarkers: [], untrackedDefinitions: [])
    var isShowingQuickAdd: Bool = false

    var isSearching: Bool {
        !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Dependencies

    private let repository: LocalDataRepository
    private let insights = InsightsEngine()

    // MARK: - Init

    init(repository: LocalDataRepository) {
        self.repository = repository
        load()
    }

    // MARK: - Data Loading

    func load() {
        trackedMarkers = repository.getTrackedMarkers()
    }

    func refresh() {
        load()
        if isSearching {
            updateSearch()
        }
    }

    func updateSearch() {
        searchResults = repository.search(query: searchQuery)
    }

    // MARK: - Insights Helpers

    func latestEntry(for marker: UserMarker) -> MarkerEntry? {
        repository.getLatestEntry(for: marker)
    }

    func status(for marker: UserMarker) -> MarkerStatus {
        guard let latest = latestEntry(for: marker) else { return .noData }
        return insights.status(for: marker, latestValue: latest.value)
    }

    func trend(for marker: UserMarker) -> TrendDirection {
        let entries = repository.getEntries(for: marker, in: nil)
        return insights.trend(from: entries)
    }

    func isTrendConcerning(for marker: UserMarker) -> Bool {
        let direction = trend(for: marker)
        let higherIsBetter = marker.markerDefinition?.higherIsBetter ?? false
        return insights.isTrendConcerning(direction: direction, higherIsBetter: higherIsBetter)
    }
}
