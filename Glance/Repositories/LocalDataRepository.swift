import Foundation
import SwiftData

// MARK: - Export Types

struct GlanceExport: Codable {
    let exportVersion: Int
    let exportDate: Date
    let categories: [CategoryExport]
    let markerDefinitions: [MarkerDefinitionExport]
    let userMarkers: [UserMarkerExport]
    let entries: [MarkerEntryExport]
    let visits: [VisitExport]
}

struct CategoryExport: Codable {
    let id: UUID
    let name: String
    let displayOrder: Int
}

struct MarkerDefinitionExport: Codable {
    let id: UUID
    let displayName: String
    let categoryId: UUID?
    let defaultUnit: String
    let defaultReferenceLow: Double?
    let defaultReferenceHigh: Double?
    let plausibleMin: Double?
    let plausibleMax: Double?
    let higherIsBetter: Bool
    let aliases: [String]
    let isSystemDefined: Bool
}

struct UserMarkerExport: Codable {
    let id: UUID
    let markerDefinitionId: UUID?
    let customReferenceLow: Double?
    let customReferenceHigh: Double?
    let displayOrder: Int
    let addedAt: Date
}

struct MarkerEntryExport: Codable {
    let id: UUID
    let userMarkerId: UUID?
    let value: Double
    let unit: String
    let dateOfService: Date
    let entryTimestamp: Date
    let note: String?
    let sourceType: String
}

struct VisitExport: Codable {
    let id: UUID
    let date: Date
    let doctorName: String
    let visitType: String
    let visitTypeLabel: String?
    let notes: String?
    let entryTimestamp: Date
}

// MARK: - LocalDataRepository

@MainActor
final class LocalDataRepository: DataRepository {
    private let context: ModelContext
    private let searchService: SearchService

    init(context: ModelContext) {
        self.context = context
        self.searchService = SearchService()
    }

    // MARK: - Private Helpers

    func getOrCreateDefaultProfile() -> Profile {
        let descriptor = FetchDescriptor<Profile>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let profile = Profile()
        context.insert(profile)
        try? context.save()
        return profile
    }

    // MARK: - Tracked Markers

    func getTrackedMarkers() -> [UserMarker] {
        let descriptor = FetchDescriptor<UserMarker>(
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func addTrackedMarker(_ definition: MarkerDefinition) -> UserMarker {
        let existing = getTrackedMarkers()
        let profile = getOrCreateDefaultProfile()
        let marker = UserMarker(
            profile: profile,
            markerDefinition: definition,
            displayOrder: existing.count
        )
        context.insert(marker)
        try? context.save()
        return marker
    }

    func removeTrackedMarker(_ marker: UserMarker) {
        context.delete(marker)
        try? context.save()
        let remaining = getTrackedMarkers()
        for (index, m) in remaining.enumerated() {
            m.displayOrder = index
        }
        try? context.save()
    }

    func updateMarkerOrder(_ markers: [UserMarker]) {
        for (index, marker) in markers.enumerated() {
            marker.displayOrder = index
        }
        try? context.save()
    }

    func updateMarker(_ marker: UserMarker) {
        try? context.save()
    }

    // MARK: - Biometric Lock (not in protocol — settings-only)

    func getBiometricLockEnabled() -> Bool {
        let descriptor = FetchDescriptor<Profile>()
        return (try? context.fetch(descriptor))?.first?.biometricLockEnabled ?? false
    }

    func setBiometricLock(_ enabled: Bool) {
        let profile = getOrCreateDefaultProfile()
        profile.biometricLockEnabled = enabled
        try? context.save()
    }

    // MARK: - Entries

    func getEntries(for marker: UserMarker, in dateRange: ClosedRange<Date>?) -> [MarkerEntry] {
        var entries = marker.entries
        if let range = dateRange {
            entries = entries.filter { range.contains($0.dateOfService) }
        }
        return entries.sorted { $0.dateOfService > $1.dateOfService }
    }

    func getLatestEntry(for marker: UserMarker) -> MarkerEntry? {
        return marker.entries.max(by: { $0.dateOfService < $1.dateOfService })
    }

    func addEntry(_ entry: MarkerEntry) {
        context.insert(entry)
        try? context.save()
    }

    func updateEntry(_ entry: MarkerEntry) {
        try? context.save()
    }

    func deleteEntry(_ entry: MarkerEntry) {
        context.delete(entry)
        try? context.save()
    }

    // MARK: - Visits

    func getVisits(limit: Int?) -> [Visit] {
        var descriptor = FetchDescriptor<Visit>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        if let limit {
            descriptor.fetchLimit = limit
        }
        return (try? context.fetch(descriptor)) ?? []
    }

    func getLastVisit(ofType type: String) -> Visit? {
        let visitTypeStr = type
        var descriptor = FetchDescriptor<Visit>(
            predicate: #Predicate<Visit> { visit in
                visit.visitType == visitTypeStr
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    func addVisit(_ visit: Visit) {
        let profile = getOrCreateDefaultProfile()
        visit.profile = profile
        context.insert(visit)
        try? context.save()
    }

    func updateVisit(_ visit: Visit) {
        try? context.save()
    }

    func deleteVisit(_ visit: Visit) {
        context.delete(visit)
        try? context.save()
    }

    // MARK: - Library

    func getMarkerLibrary() -> [MarkerDefinition] {
        let descriptor = FetchDescriptor<MarkerDefinition>(
            sortBy: [SortDescriptor(\.displayName)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func getCategories() -> [MarkerCategory] {
        let descriptor = FetchDescriptor<MarkerCategory>(
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func addCustomMarker(_ definition: MarkerDefinition) -> MarkerDefinition {
        context.insert(definition)
        try? context.save()
        return definition
    }

    // MARK: - Search

    func search(query: String) -> SearchResults {
        let tracked = getTrackedMarkers()
        return searchService.search(query: query, in: context, trackedMarkers: tracked)
    }

    // MARK: - Export

    func exportAllData() -> Data {
        let categories = getCategories().map { cat in
            CategoryExport(id: cat.id, name: cat.name, displayOrder: cat.displayOrder)
        }

        let definitions = getMarkerLibrary().map { def in
            MarkerDefinitionExport(
                id: def.id,
                displayName: def.displayName,
                categoryId: def.category?.id,
                defaultUnit: def.defaultUnit,
                defaultReferenceLow: def.defaultReferenceLow,
                defaultReferenceHigh: def.defaultReferenceHigh,
                plausibleMin: def.plausibleMin,
                plausibleMax: def.plausibleMax,
                higherIsBetter: def.higherIsBetter,
                aliases: def.aliases,
                isSystemDefined: def.isSystemDefined
            )
        }

        let userMarkers = getTrackedMarkers().map { um in
            UserMarkerExport(
                id: um.id,
                markerDefinitionId: um.markerDefinition?.id,
                customReferenceLow: um.customReferenceLow,
                customReferenceHigh: um.customReferenceHigh,
                displayOrder: um.displayOrder,
                addedAt: um.addedAt
            )
        }

        let allEntries: [MarkerEntryExport] = getTrackedMarkers().flatMap { um in
            um.entries.map { entry in
                MarkerEntryExport(
                    id: entry.id,
                    userMarkerId: entry.userMarker?.id,
                    value: entry.value,
                    unit: entry.unit,
                    dateOfService: entry.dateOfService,
                    entryTimestamp: entry.entryTimestamp,
                    note: entry.note,
                    sourceType: entry.sourceType
                )
            }
        }

        let allVisits = getVisits(limit: nil).map { visit in
            VisitExport(
                id: visit.id,
                date: visit.date,
                doctorName: visit.doctorName,
                visitType: visit.visitType,
                visitTypeLabel: visit.visitTypeLabel,
                notes: visit.notes,
                entryTimestamp: visit.entryTimestamp
            )
        }

        let export = GlanceExport(
            exportVersion: 1,
            exportDate: Date(),
            categories: categories,
            markerDefinitions: definitions,
            userMarkers: userMarkers,
            entries: allEntries,
            visits: allVisits
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        return (try? encoder.encode(export)) ?? Data()
    }

    func exportAsCSV() -> Data {
        var lines: [String] = []
        lines.append("Marker Name,Value,Unit,Date of Service,Note,Source Type")

        let tracked = getTrackedMarkers()
        let dateFormatter = ISO8601DateFormatter()

        for userMarker in tracked {
            let name = userMarker.markerDefinition?.displayName ?? "Unknown"
            let entriesSorted = userMarker.entries.sorted { $0.dateOfService < $1.dateOfService }
            for entry in entriesSorted {
                let dateStr = dateFormatter.string(from: entry.dateOfService)
                let note = (entry.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
                let escapedName = name.replacingOccurrences(of: "\"", with: "\"\"")
                lines.append("\"\(escapedName)\",\(entry.value),\"\(entry.unit)\",\"\(dateStr)\",\"\(note)\",\"\(entry.sourceType)\"")
            }
        }

        let csv = lines.joined(separator: "\n")
        return csv.data(using: .utf8) ?? Data()
    }
}
