import Foundation
import SwiftData

@Model
final class UserMarker {
    var id: UUID
    var profile: Profile?
    var markerDefinition: MarkerDefinition?
    var customReferenceLow: Double?
    var customReferenceHigh: Double?
    var displayOrder: Int
    var addedAt: Date

    @Relationship(deleteRule: .cascade)
    var entries: [MarkerEntry] = []

    init(
        profile: Profile? = nil,
        markerDefinition: MarkerDefinition? = nil,
        customReferenceLow: Double? = nil,
        customReferenceHigh: Double? = nil,
        displayOrder: Int = 0
    ) {
        self.id = UUID()
        self.profile = profile
        self.markerDefinition = markerDefinition
        self.customReferenceLow = customReferenceLow
        self.customReferenceHigh = customReferenceHigh
        self.displayOrder = displayOrder
        self.addedAt = Date()
    }
}
