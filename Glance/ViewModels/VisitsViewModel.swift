import Foundation

@Observable
@MainActor
final class VisitsViewModel {

    // MARK: - State

    var visits: [Visit] = []
    var insights: [VisitPrepInsight] = []
    var isShowingAddVisit: Bool = false
    var visitToEdit: Visit? = nil
    var visitToDelete: Visit? = nil
    var showDeleteConfirm: Bool = false

    var hasInsights: Bool { !insights.isEmpty }

    // MARK: - Dependencies

    private let repository: LocalDataRepository
    private let insightsEngine = InsightsEngine()

    // MARK: - Init

    init(repository: LocalDataRepository) {
        self.repository = repository
        load()
    }

    // MARK: - Data

    func load() {
        visits = repository.getVisits(limit: nil)
        let markers = repository.getTrackedMarkers()
        insights = insightsEngine.generateInsights(for: markers)
    }

    func deleteVisit(_ visit: Visit) {
        repository.deleteVisit(visit)
        load()
    }
}
