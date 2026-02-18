import Foundation
import SwiftData

@Observable
@MainActor
final class MarkerDetailViewModel {

    // MARK: - State

    var entries: [MarkerEntry] = []
    var isShowingAddEntry: Bool = false
    var entryToEdit: MarkerEntry? = nil
    var isShowingRangeEditor: Bool = false
    var status: MarkerStatus = .noData
    var trend: TrendDirection = .insufficient
    var isTrendConcerning: Bool = false

    // MARK: - Dependencies

    let userMarker: UserMarker
    private let repository: LocalDataRepository
    private let insights = InsightsEngine()

    // MARK: - Init

    init(userMarker: UserMarker, repository: LocalDataRepository) {
        self.userMarker = userMarker
        self.repository = repository
        load()
    }

    // MARK: - Data

    func load() {
        // Newest first for the entry list display
        entries = repository.getEntries(for: userMarker, in: nil)
        refreshInsights()
    }

    func refreshInsights() {
        if let latest = entries.first {
            status = insights.status(for: userMarker, latestValue: latest.value)
        } else {
            status = .noData
        }
        trend = insights.trend(from: entries)
        let higherIsBetter = userMarker.markerDefinition?.higherIsBetter ?? false
        isTrendConcerning = insights.isTrendConcerning(direction: trend, higherIsBetter: higherIsBetter)
    }

    func deleteEntry(_ entry: MarkerEntry) {
        repository.deleteEntry(entry)
        load()
    }

    /// Entries sorted oldest → newest for the chart (time-series left to right).
    var entriesForChart: [MarkerEntry] {
        entries.sorted { $0.dateOfService < $1.dateOfService }
    }
}
