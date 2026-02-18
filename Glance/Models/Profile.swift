import Foundation
import SwiftData

@Model
final class Profile {
    var id: UUID
    var name: String
    var createdAt: Date
    var biometricLockEnabled: Bool = false

    @Relationship(deleteRule: .cascade)
    var userMarkers: [UserMarker] = []

    @Relationship(deleteRule: .cascade)
    var visits: [Visit] = []

    init(name: String = "Me") {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
