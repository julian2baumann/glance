import Foundation
import SwiftData

@Model
final class MarkerEntry {
    var id: UUID
    var userMarker: UserMarker?
    var value: Double
    var unit: String
    var dateOfService: Date
    var entryTimestamp: Date
    var note: String?
    var sourceType: String

    init(
        userMarker: UserMarker? = nil,
        value: Double,
        unit: String,
        dateOfService: Date = Date(),
        note: String? = nil,
        sourceType: String = "quickAdd"
    ) {
        self.id = UUID()
        self.userMarker = userMarker
        self.value = value
        self.unit = unit
        self.dateOfService = dateOfService
        self.entryTimestamp = Date()
        self.note = note
        self.sourceType = sourceType
    }
}
