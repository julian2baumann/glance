import Foundation
import SwiftData

@Model
final class MarkerDefinition {
    var id: UUID
    var displayName: String
    var category: MarkerCategory?
    var defaultUnit: String
    var defaultReferenceLow: Double?
    var defaultReferenceHigh: Double?
    var plausibleMin: Double?
    var plausibleMax: Double?
    var higherIsBetter: Bool
    var aliases: [String]
    var isSystemDefined: Bool

    init(
        displayName: String,
        category: MarkerCategory? = nil,
        defaultUnit: String,
        defaultReferenceLow: Double? = nil,
        defaultReferenceHigh: Double? = nil,
        plausibleMin: Double? = nil,
        plausibleMax: Double? = nil,
        higherIsBetter: Bool = false,
        aliases: [String] = [],
        isSystemDefined: Bool = true
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.category = category
        self.defaultUnit = defaultUnit
        self.defaultReferenceLow = defaultReferenceLow
        self.defaultReferenceHigh = defaultReferenceHigh
        self.plausibleMin = plausibleMin
        self.plausibleMax = plausibleMax
        self.higherIsBetter = higherIsBetter
        self.aliases = aliases
        self.isSystemDefined = isSystemDefined
    }
}
