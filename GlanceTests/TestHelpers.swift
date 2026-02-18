import Foundation
import SwiftData
@testable import Glance

func makeTestContainer() throws -> ModelContainer {
    let schema = Schema([
        Profile.self,
        MarkerCategory.self,
        MarkerDefinition.self,
        UserMarker.self,
        MarkerEntry.self,
        Visit.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(for: schema, configurations: config)
}

func makeSampleCategory(name: String = "Heart", order: Int = 1, context: ModelContext) -> MarkerCategory {
    let cat = MarkerCategory(name: name, displayOrder: order)
    context.insert(cat)
    return cat
}

func makeSampleDefinition(
    name: String = "HDL Cholesterol",
    unit: String = "mg/dL",
    category: MarkerCategory? = nil,
    refLow: Double? = 40,
    refHigh: Double? = 100,
    plausibleMin: Double? = 10,
    plausibleMax: Double? = 200,
    higherIsBetter: Bool = true,
    aliases: [String] = ["good cholesterol", "HDL-C"],
    isSystem: Bool = true,
    context: ModelContext
) -> MarkerDefinition {
    let def = MarkerDefinition(
        displayName: name,
        category: category,
        defaultUnit: unit,
        defaultReferenceLow: refLow,
        defaultReferenceHigh: refHigh,
        plausibleMin: plausibleMin,
        plausibleMax: plausibleMax,
        higherIsBetter: higherIsBetter,
        aliases: aliases,
        isSystemDefined: isSystem
    )
    context.insert(def)
    return def
}

func makeSampleUserMarker(
    definition: MarkerDefinition,
    profile: Profile,
    order: Int = 0,
    context: ModelContext
) -> UserMarker {
    let um = UserMarker(profile: profile, markerDefinition: definition, displayOrder: order)
    context.insert(um)
    return um
}

func makeSampleEntry(
    userMarker: UserMarker,
    value: Double = 89.0,
    unit: String = "mg/dL",
    date: Date = Date(),
    note: String? = nil,
    sourceType: String = "quickAdd",
    context: ModelContext
) -> MarkerEntry {
    let entry = MarkerEntry(
        userMarker: userMarker,
        value: value,
        unit: unit,
        dateOfService: date,
        note: note,
        sourceType: sourceType
    )
    context.insert(entry)
    return entry
}

func makeSampleVisit(
    profile: Profile,
    date: Date = Date(),
    doctorName: String = "Dr. Smith",
    visitType: String = "physical",
    notes: String? = nil,
    context: ModelContext
) -> Visit {
    let visit = Visit(
        profile: profile,
        date: date,
        doctorName: doctorName,
        visitType: visitType,
        notes: notes
    )
    context.insert(visit)
    return visit
}
