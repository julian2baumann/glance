import Foundation
import SwiftData

@Model
final class Visit {
    var id: UUID
    var profile: Profile?
    var date: Date
    var doctorName: String
    var visitType: String
    var visitTypeLabel: String?
    var notes: String?
    var entryTimestamp: Date

    init(
        profile: Profile? = nil,
        date: Date = Date(),
        doctorName: String,
        visitType: String,
        visitTypeLabel: String? = nil,
        notes: String? = nil
    ) {
        self.id = UUID()
        self.profile = profile
        self.date = date
        self.doctorName = doctorName
        self.visitType = visitType
        self.visitTypeLabel = visitTypeLabel
        self.notes = notes
        self.entryTimestamp = Date()
    }
}
