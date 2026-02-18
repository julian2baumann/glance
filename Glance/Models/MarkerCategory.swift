import Foundation
import SwiftData

@Model
final class MarkerCategory {
    var id: UUID
    var name: String
    var displayOrder: Int

    @Relationship(deleteRule: .nullify, inverse: \MarkerDefinition.category)
    var markers: [MarkerDefinition] = []

    init(name: String, displayOrder: Int) {
        self.id = UUID()
        self.name = name
        self.displayOrder = displayOrder
    }
}
