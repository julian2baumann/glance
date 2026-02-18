#if DEBUG
import SwiftData
import Foundation

/// In-memory sample data for SwiftUI previews.
@MainActor
final class PreviewData {

    let container: ModelContainer
    let repository: LocalDataRepository

    let heartCategory: MarkerCategory
    let metabolicCategory: MarkerCategory

    let hdlDefinition: MarkerDefinition
    let ldlDefinition: MarkerDefinition
    let a1cDefinition: MarkerDefinition
    let glucoseDefinition: MarkerDefinition

    let hdlMarker: UserMarker
    let ldlMarker: UserMarker
    let a1cMarker: UserMarker
    let glucoseMarker: UserMarker

    let hdlEntry: MarkerEntry
    let ldlEntry: MarkerEntry
    let a1cEntry: MarkerEntry

    init() {
        let schema = Schema([
            Profile.self, MarkerCategory.self, MarkerDefinition.self,
            UserMarker.self, MarkerEntry.self, Visit.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try! ModelContainer(for: schema, configurations: config)
        repository = LocalDataRepository(context: container.mainContext)
        let ctx = container.mainContext

        // Categories
        heartCategory = MarkerCategory(name: "Heart", displayOrder: 1)
        metabolicCategory = MarkerCategory(name: "Metabolic", displayOrder: 2)
        ctx.insert(heartCategory)
        ctx.insert(metabolicCategory)

        // Definitions
        hdlDefinition = MarkerDefinition(
            displayName: "HDL Cholesterol",
            category: heartCategory,
            defaultUnit: "mg/dL",
            defaultReferenceLow: 40,
            defaultReferenceHigh: 60,
            plausibleMin: 10,
            plausibleMax: 200,
            higherIsBetter: true,
            aliases: ["good cholesterol", "HDL"],
            isSystemDefined: true
        )
        ldlDefinition = MarkerDefinition(
            displayName: "LDL Cholesterol",
            category: heartCategory,
            defaultUnit: "mg/dL",
            defaultReferenceHigh: 100,
            plausibleMin: 10,
            plausibleMax: 400,
            higherIsBetter: false,
            aliases: ["bad cholesterol", "LDL"],
            isSystemDefined: true
        )
        a1cDefinition = MarkerDefinition(
            displayName: "Hemoglobin A1C",
            category: metabolicCategory,
            defaultUnit: "%",
            defaultReferenceLow: 4.0,
            defaultReferenceHigh: 5.7,
            plausibleMin: 3.0,
            plausibleMax: 15.0,
            higherIsBetter: false,
            aliases: ["A1C", "HbA1c"],
            isSystemDefined: true
        )
        glucoseDefinition = MarkerDefinition(
            displayName: "Fasting Glucose",
            category: metabolicCategory,
            defaultUnit: "mg/dL",
            defaultReferenceLow: 70,
            defaultReferenceHigh: 99,
            plausibleMin: 20,
            plausibleMax: 600,
            higherIsBetter: false,
            aliases: ["blood sugar", "glucose"],
            isSystemDefined: true
        )
        ctx.insert(hdlDefinition)
        ctx.insert(ldlDefinition)
        ctx.insert(a1cDefinition)
        ctx.insert(glucoseDefinition)

        // Profile
        let profile = Profile()
        ctx.insert(profile)

        // User Markers
        hdlMarker = UserMarker(profile: profile, markerDefinition: hdlDefinition, displayOrder: 0)
        ldlMarker = UserMarker(profile: profile, markerDefinition: ldlDefinition, displayOrder: 1)
        a1cMarker = UserMarker(profile: profile, markerDefinition: a1cDefinition, displayOrder: 2)
        glucoseMarker = UserMarker(profile: profile, markerDefinition: glucoseDefinition, displayOrder: 3)
        ctx.insert(hdlMarker)
        ctx.insert(ldlMarker)
        ctx.insert(a1cMarker)
        ctx.insert(glucoseMarker)

        // Entries — multiple per marker for trend arrows
        let base = Date()
        func daysAgo(_ n: Int) -> Date {
            Calendar.current.date(byAdding: .day, value: -n, to: base)!
        }

        // HDL: trending up (good)
        let e1 = MarkerEntry(userMarker: hdlMarker, value: 52, unit: "mg/dL", dateOfService: daysAgo(30))
        let e2 = MarkerEntry(userMarker: hdlMarker, value: 55, unit: "mg/dL", dateOfService: daysAgo(15))
        let e3 = MarkerEntry(userMarker: hdlMarker, value: 58, unit: "mg/dL", dateOfService: daysAgo(0))
        hdlEntry = e3
        ctx.insert(e1); ctx.insert(e2); ctx.insert(e3)
        hdlMarker.entries.append(contentsOf: [e1, e2, e3])

        // LDL: trending up (concerning), approaching boundary
        let l1 = MarkerEntry(userMarker: ldlMarker, value: 80, unit: "mg/dL", dateOfService: daysAgo(30))
        let l2 = MarkerEntry(userMarker: ldlMarker, value: 88, unit: "mg/dL", dateOfService: daysAgo(15))
        let l3 = MarkerEntry(userMarker: ldlMarker, value: 95, unit: "mg/dL", dateOfService: daysAgo(0))
        ldlEntry = l3
        ctx.insert(l1); ctx.insert(l2); ctx.insert(l3)
        ldlMarker.entries.append(contentsOf: [l1, l2, l3])

        // A1C: out of range
        let a1 = MarkerEntry(userMarker: a1cMarker, value: 6.0, unit: "%", dateOfService: daysAgo(90))
        let a2 = MarkerEntry(userMarker: a1cMarker, value: 6.3, unit: "%", dateOfService: daysAgo(45))
        let a3 = MarkerEntry(userMarker: a1cMarker, value: 6.8, unit: "%", dateOfService: daysAgo(0))
        a1cEntry = a3
        ctx.insert(a1); ctx.insert(a2); ctx.insert(a3)
        a1cMarker.entries.append(contentsOf: [a1, a2, a3])

        // Glucose: no entries (empty state)

        try? ctx.save()
    }
}
#endif
