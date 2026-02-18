import Foundation

struct VisitPrepInsight: Identifiable {
    var id: UUID
    var userMarker: UserMarker
    var insightType: InsightType
    var suggestionText: String
    var triggeringValues: [MarkerEntry]
    var generatedAt: Date

    enum InsightType: String {
        case outOfRange = "outOfRange"
        case trendingUp = "trendingUp"
        case trendingDown = "trendingDown"
    }

    init(
        userMarker: UserMarker,
        insightType: InsightType,
        suggestionText: String,
        triggeringValues: [MarkerEntry]
    ) {
        self.id = UUID()
        self.userMarker = userMarker
        self.insightType = insightType
        self.suggestionText = suggestionText
        self.triggeringValues = triggeringValues
        self.generatedAt = Date()
    }
}
