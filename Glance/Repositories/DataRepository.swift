import Foundation

struct SearchResults {
    var trackedMarkers: [UserMarker]
    var untrackedDefinitions: [MarkerDefinition]
}

@MainActor
protocol DataRepository {
    // MARK: - Tracked Markers
    func getTrackedMarkers() -> [UserMarker]
    func addTrackedMarker(_ definition: MarkerDefinition) -> UserMarker
    func removeTrackedMarker(_ marker: UserMarker)
    func updateMarkerOrder(_ markers: [UserMarker])

    // MARK: - Entries
    func getEntries(for marker: UserMarker, in dateRange: ClosedRange<Date>?) -> [MarkerEntry]
    func getLatestEntry(for marker: UserMarker) -> MarkerEntry?
    func addEntry(_ entry: MarkerEntry)
    func updateEntry(_ entry: MarkerEntry)
    func deleteEntry(_ entry: MarkerEntry)

    // MARK: - Visits
    func getVisits(limit: Int?) -> [Visit]
    func getLastVisit(ofType type: String) -> Visit?
    func addVisit(_ visit: Visit)
    func updateVisit(_ visit: Visit)
    func deleteVisit(_ visit: Visit)

    // MARK: - Library
    func getMarkerLibrary() -> [MarkerDefinition]
    func getCategories() -> [MarkerCategory]
    func addCustomMarker(_ definition: MarkerDefinition) -> MarkerDefinition

    // MARK: - Search
    func search(query: String) -> SearchResults

    // MARK: - Export
    func exportAllData() -> Data
    func exportAsCSV() -> Data
}
