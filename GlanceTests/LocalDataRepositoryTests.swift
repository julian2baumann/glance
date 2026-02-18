import XCTest
import SwiftData
@testable import Glance

@MainActor
final class LocalDataRepositoryTests: XCTestCase {

    var container: ModelContainer!
    var repository: LocalDataRepository!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
        repository = LocalDataRepository(context: container.mainContext)
    }

    override func tearDown() async throws {
        repository = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - Profile

    func testGetOrCreateDefaultProfileCreatesProfile() {
        let profile = repository.getOrCreateDefaultProfile()
        XCTAssertEqual(profile.name, "Me")
    }

    func testGetOrCreateDefaultProfileIsIdempotent() {
        let p1 = repository.getOrCreateDefaultProfile()
        let p2 = repository.getOrCreateDefaultProfile()
        XCTAssertEqual(p1.id, p2.id)
    }

    // MARK: - Tracked Markers

    func testAddTrackedMarkerCreatesUserMarker() {
        let context = container.mainContext
        let cat = makeSampleCategory(context: context)
        let def = makeSampleDefinition(category: cat, context: context)
        try? context.save()

        let marker = repository.addTrackedMarker(def)
        XCTAssertNotNil(marker)
        XCTAssertEqual(marker.markerDefinition?.id, def.id)
    }

    func testGetTrackedMarkersReturnsSortedByDisplayOrder() {
        let context = container.mainContext
        let cat = makeSampleCategory(context: context)
        let def1 = makeSampleDefinition(name: "Marker A", context: context)
        let def2 = makeSampleDefinition(name: "Marker B", category: cat, context: context)
        let def3 = makeSampleDefinition(name: "Marker C", context: context)
        try? context.save()

        let m1 = repository.addTrackedMarker(def1)
        let m2 = repository.addTrackedMarker(def2)
        let m3 = repository.addTrackedMarker(def3)

        let result = repository.getTrackedMarkers()
        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].id, m1.id)
        XCTAssertEqual(result[1].id, m2.id)
        XCTAssertEqual(result[2].id, m3.id)
    }

    func testRemoveTrackedMarkerDeletesIt() {
        let context = container.mainContext
        let def = makeSampleDefinition(context: context)
        try? context.save()

        let marker = repository.addTrackedMarker(def)
        XCTAssertEqual(repository.getTrackedMarkers().count, 1)

        repository.removeTrackedMarker(marker)
        XCTAssertEqual(repository.getTrackedMarkers().count, 0)
    }

    func testRemoveTrackedMarkerReordersRemaining() {
        let context = container.mainContext
        let def1 = makeSampleDefinition(name: "A", context: context)
        let def2 = makeSampleDefinition(name: "B", context: context)
        let def3 = makeSampleDefinition(name: "C", context: context)
        try? context.save()

        let m1 = repository.addTrackedMarker(def1)
        let m2 = repository.addTrackedMarker(def2)
        _ = repository.addTrackedMarker(def3)

        repository.removeTrackedMarker(m1)

        let remaining = repository.getTrackedMarkers()
        XCTAssertEqual(remaining.count, 2)
        XCTAssertEqual(remaining[0].id, m2.id)
        XCTAssertEqual(remaining[0].displayOrder, 0)
        XCTAssertEqual(remaining[1].displayOrder, 1)
    }

    func testUpdateMarkerOrderUpdatesDisplayOrder() {
        let context = container.mainContext
        let def1 = makeSampleDefinition(name: "A", context: context)
        let def2 = makeSampleDefinition(name: "B", context: context)
        try? context.save()

        let m1 = repository.addTrackedMarker(def1)
        let m2 = repository.addTrackedMarker(def2)

        // Reverse order
        repository.updateMarkerOrder([m2, m1])

        XCTAssertEqual(m2.displayOrder, 0)
        XCTAssertEqual(m1.displayOrder, 1)
    }

    // MARK: - Entries

    func testAddEntryAppearsInMarkerEntries() {
        let context = container.mainContext
        let def = makeSampleDefinition(context: context)
        try? context.save()
        let marker = repository.addTrackedMarker(def)

        let entry = MarkerEntry(userMarker: marker, value: 89.0, unit: "mg/dL", dateOfService: Date())
        repository.addEntry(entry)

        let entries = repository.getEntries(for: marker, in: nil)
        XCTAssertEqual(entries.count, 1)
        XCTAssertEqual(entries[0].value, 89.0)
    }

    func testGetEntriesReturnsSortedByDateDescending() {
        let context = container.mainContext
        let def = makeSampleDefinition(context: context)
        try? context.save()
        let marker = repository.addTrackedMarker(def)

        let older = Date(timeIntervalSinceNow: -86400 * 10)
        let newer = Date(timeIntervalSinceNow: -86400 * 1)

        let e1 = MarkerEntry(userMarker: marker, value: 75.0, unit: "mg/dL", dateOfService: older)
        let e2 = MarkerEntry(userMarker: marker, value: 85.0, unit: "mg/dL", dateOfService: newer)
        repository.addEntry(e1)
        repository.addEntry(e2)

        let entries = repository.getEntries(for: marker, in: nil)
        XCTAssertEqual(entries.count, 2)
        XCTAssertEqual(entries[0].value, 85.0) // newer first
        XCTAssertEqual(entries[1].value, 75.0)
    }

    func testGetEntriesWithDateRangeFiltersCorrectly() {
        let context = container.mainContext
        let def = makeSampleDefinition(context: context)
        try? context.save()
        let marker = repository.addTrackedMarker(def)

        let veryOld = Date(timeIntervalSinceNow: -86400 * 100)
        let recent = Date(timeIntervalSinceNow: -86400 * 5)
        let today = Date()

        let e1 = MarkerEntry(userMarker: marker, value: 60.0, unit: "mg/dL", dateOfService: veryOld)
        let e2 = MarkerEntry(userMarker: marker, value: 80.0, unit: "mg/dL", dateOfService: recent)
        let e3 = MarkerEntry(userMarker: marker, value: 90.0, unit: "mg/dL", dateOfService: today)
        repository.addEntry(e1)
        repository.addEntry(e2)
        repository.addEntry(e3)

        let range = (Date(timeIntervalSinceNow: -86400 * 10))...(Date(timeIntervalSinceNow: 86400))
        let filtered = repository.getEntries(for: marker, in: range)

        XCTAssertEqual(filtered.count, 2)
        XCTAssertTrue(filtered.allSatisfy { range.contains($0.dateOfService) })
    }

    func testGetLatestEntryReturnsNewest() {
        let context = container.mainContext
        let def = makeSampleDefinition(context: context)
        try? context.save()
        let marker = repository.addTrackedMarker(def)

        let older = Date(timeIntervalSinceNow: -86400 * 30)
        let newer = Date(timeIntervalSinceNow: -86400 * 1)

        let e1 = MarkerEntry(userMarker: marker, value: 70.0, unit: "mg/dL", dateOfService: older)
        let e2 = MarkerEntry(userMarker: marker, value: 88.0, unit: "mg/dL", dateOfService: newer)
        repository.addEntry(e1)
        repository.addEntry(e2)

        let latest = repository.getLatestEntry(for: marker)
        XCTAssertNotNil(latest)
        XCTAssertEqual(latest?.value, 88.0)
    }

    func testGetLatestEntryReturnsNilWhenNoEntries() {
        let context = container.mainContext
        let def = makeSampleDefinition(context: context)
        try? context.save()
        let marker = repository.addTrackedMarker(def)

        let latest = repository.getLatestEntry(for: marker)
        XCTAssertNil(latest)
    }

    func testDeleteEntryRemovesIt() {
        let context = container.mainContext
        let def = makeSampleDefinition(context: context)
        try? context.save()
        let marker = repository.addTrackedMarker(def)

        let entry = MarkerEntry(userMarker: marker, value: 89.0, unit: "mg/dL")
        repository.addEntry(entry)
        XCTAssertEqual(repository.getEntries(for: marker, in: nil).count, 1)

        repository.deleteEntry(entry)
        XCTAssertEqual(repository.getEntries(for: marker, in: nil).count, 0)
    }

    func testUpdateEntrySavesChanges() {
        let context = container.mainContext
        let def = makeSampleDefinition(context: context)
        try? context.save()
        let marker = repository.addTrackedMarker(def)

        let entry = MarkerEntry(userMarker: marker, value: 89.0, unit: "mg/dL")
        repository.addEntry(entry)

        entry.value = 95.0
        entry.note = "Updated note"
        repository.updateEntry(entry)

        let entries = repository.getEntries(for: marker, in: nil)
        XCTAssertEqual(entries[0].value, 95.0)
        XCTAssertEqual(entries[0].note, "Updated note")
    }

    // MARK: - Visits

    func testAddVisitCreatesVisitWithProfile() {
        let visit = Visit(doctorName: "Dr. Jones", visitType: "dental")
        repository.addVisit(visit)

        let visits = repository.getVisits(limit: nil)
        XCTAssertEqual(visits.count, 1)
        XCTAssertEqual(visits[0].doctorName, "Dr. Jones")
        XCTAssertNotNil(visits[0].profile)
    }

    func testGetVisitsReturnsSortedByDateDescending() {
        let older = Date(timeIntervalSinceNow: -86400 * 90)
        let newer = Date(timeIntervalSinceNow: -86400 * 30)

        let v1 = Visit(date: older, doctorName: "Dr. A", visitType: "physical")
        let v2 = Visit(date: newer, doctorName: "Dr. B", visitType: "dental")
        repository.addVisit(v1)
        repository.addVisit(v2)

        let visits = repository.getVisits(limit: nil)
        XCTAssertEqual(visits.count, 2)
        XCTAssertEqual(visits[0].doctorName, "Dr. B") // newer first
    }

    func testGetVisitsWithLimitRespectLimit() {
        for i in 0..<5 {
            let v = Visit(date: Date(timeIntervalSinceNow: Double(-86400 * i)), doctorName: "Dr. \(i)", visitType: "physical")
            repository.addVisit(v)
        }

        let limited = repository.getVisits(limit: 3)
        XCTAssertEqual(limited.count, 3)
    }

    func testGetLastVisitOfTypeReturnsCorrectVisit() {
        let oldDental = Date(timeIntervalSinceNow: -86400 * 200)
        let recentDental = Date(timeIntervalSinceNow: -86400 * 30)

        let v1 = Visit(date: oldDental, doctorName: "Dr. Dentist A", visitType: "dental")
        let v2 = Visit(date: recentDental, doctorName: "Dr. Dentist B", visitType: "dental")
        let v3 = Visit(date: Date(), doctorName: "Dr. Eye", visitType: "vision")
        repository.addVisit(v1)
        repository.addVisit(v2)
        repository.addVisit(v3)

        let lastDental = repository.getLastVisit(ofType: "dental")
        XCTAssertNotNil(lastDental)
        XCTAssertEqual(lastDental?.doctorName, "Dr. Dentist B")
    }

    func testGetLastVisitOfTypeReturnsNilWhenNoMatch() {
        let v = Visit(date: Date(), doctorName: "Dr. Jones", visitType: "physical")
        repository.addVisit(v)

        let result = repository.getLastVisit(ofType: "specialist")
        XCTAssertNil(result)
    }

    func testDeleteVisitRemovesIt() {
        let visit = Visit(doctorName: "Dr. Smith", visitType: "physical")
        repository.addVisit(visit)
        XCTAssertEqual(repository.getVisits(limit: nil).count, 1)

        repository.deleteVisit(visit)
        XCTAssertEqual(repository.getVisits(limit: nil).count, 0)
    }

    func testUpdateVisitSavesChanges() {
        let visit = Visit(doctorName: "Dr. Smith", visitType: "physical")
        repository.addVisit(visit)

        visit.doctorName = "Dr. Johnson"
        visit.notes = "Follow-up needed"
        repository.updateVisit(visit)

        let visits = repository.getVisits(limit: nil)
        XCTAssertEqual(visits[0].doctorName, "Dr. Johnson")
        XCTAssertEqual(visits[0].notes, "Follow-up needed")
    }

    // MARK: - Library

    func testGetCategoriesReturnsSortedByDisplayOrder() {
        let context = container.mainContext
        let c3 = MarkerCategory(name: "C", displayOrder: 3)
        let c1 = MarkerCategory(name: "A", displayOrder: 1)
        let c2 = MarkerCategory(name: "B", displayOrder: 2)
        context.insert(c3)
        context.insert(c1)
        context.insert(c2)
        try? context.save()

        let cats = repository.getCategories()
        XCTAssertEqual(cats.map(\.displayOrder), [1, 2, 3])
    }

    func testAddCustomMarkerCreatesDefinition() {
        let custom = MarkerDefinition(
            displayName: "My Custom Marker",
            defaultUnit: "units",
            higherIsBetter: true,
            isSystemDefined: false
        )
        let result = repository.addCustomMarker(custom)
        XCTAssertNotNil(result)

        let library = repository.getMarkerLibrary()
        XCTAssertTrue(library.contains(where: { $0.displayName == "My Custom Marker" }))
    }

    // MARK: - Export: JSON Round-Trip

    func testExportAllDataProducesValidJSON() {
        let context = container.mainContext
        let cat = makeSampleCategory(context: context)
        let def = makeSampleDefinition(name: "HDL Cholesterol", category: cat, context: context)
        try? context.save()

        let marker = repository.addTrackedMarker(def)
        let entry = MarkerEntry(userMarker: marker, value: 89.0, unit: "mg/dL", dateOfService: Date(), note: "Test note")
        repository.addEntry(entry)

        let visit = Visit(doctorName: "Dr. Chen", visitType: "physical", notes: "Good health")
        repository.addVisit(visit)

        let data = repository.exportAllData()
        XCTAssertFalse(data.isEmpty)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try? decoder.decode(GlanceExport.self, from: data)

        XCTAssertNotNil(decoded)
        XCTAssertEqual(decoded?.exportVersion, 1)
        XCTAssertEqual(decoded?.categories.count, 1)
        XCTAssertEqual(decoded?.markerDefinitions.count, 1)
        XCTAssertEqual(decoded?.userMarkers.count, 1)
        XCTAssertEqual(decoded?.entries.count, 1)
        XCTAssertEqual(decoded?.visits.count, 1)
    }

    func testExportRoundTripPreservesFieldValues() {
        let context = container.mainContext
        let cat = makeSampleCategory(name: "Heart", order: 1, context: context)
        let def = makeSampleDefinition(
            name: "HDL Cholesterol",
            unit: "mg/dL",
            category: cat,
            refLow: 40,
            refHigh: 100,
            plausibleMin: 10,
            plausibleMax: 200,
            higherIsBetter: true,
            aliases: ["good cholesterol"],
            isSystem: true,
            context: context
        )
        try? context.save()

        let marker = repository.addTrackedMarker(def)
        let entryDate = Date(timeIntervalSince1970: 1_700_000_000)
        let entry = MarkerEntry(
            userMarker: marker,
            value: 89.0,
            unit: "mg/dL",
            dateOfService: entryDate,
            note: "Post-diet check",
            sourceType: "batchEntry"
        )
        repository.addEntry(entry)

        let data = repository.exportAllData()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try? decoder.decode(GlanceExport.self, from: data)

        // Verify entry fields
        let exportedEntry = decoded?.entries.first
        XCTAssertEqual(exportedEntry?.value, 89.0)
        XCTAssertEqual(exportedEntry?.unit, "mg/dL")
        XCTAssertEqual(exportedEntry?.note, "Post-diet check")
        XCTAssertEqual(exportedEntry?.sourceType, "batchEntry")
        XCTAssertEqual(exportedEntry?.userMarkerId, marker.id)

        // Verify definition fields
        let exportedDef = decoded?.markerDefinitions.first
        XCTAssertEqual(exportedDef?.displayName, "HDL Cholesterol")
        XCTAssertEqual(exportedDef?.defaultUnit, "mg/dL")
        XCTAssertEqual(exportedDef?.defaultReferenceLow, 40)
        XCTAssertEqual(exportedDef?.defaultReferenceHigh, 100)
        XCTAssertEqual(exportedDef?.higherIsBetter, true)
        XCTAssertEqual(exportedDef?.aliases, ["good cholesterol"])
        XCTAssertEqual(exportedDef?.isSystemDefined, true)

        // Verify category linkage
        XCTAssertEqual(exportedDef?.categoryId, cat.id)
    }

    // MARK: - Export: CSV

    func testExportAsCSVProducesValidOutput() {
        let context = container.mainContext
        let def = makeSampleDefinition(name: "LDL Cholesterol", context: context)
        try? context.save()

        let marker = repository.addTrackedMarker(def)
        let entry = MarkerEntry(userMarker: marker, value: 98.0, unit: "mg/dL")
        repository.addEntry(entry)

        let csvData = repository.exportAsCSV()
        let csvString = String(data: csvData, encoding: .utf8) ?? ""

        XCTAssertTrue(csvString.contains("Marker Name,Value,Unit,Date of Service,Note,Source Type"))
        XCTAssertTrue(csvString.contains("LDL Cholesterol"))
        XCTAssertTrue(csvString.contains("98.0"))
        XCTAssertTrue(csvString.contains("mg/dL"))
    }

    func testExportCSVEscapesQuotesInNames() {
        let context = container.mainContext
        let def = makeSampleDefinition(name: "Marker \"Special\"", context: context)
        try? context.save()

        let marker = repository.addTrackedMarker(def)
        let entry = MarkerEntry(userMarker: marker, value: 5.0, unit: "units", note: "Has \"quotes\"")
        repository.addEntry(entry)

        let csvData = repository.exportAsCSV()
        let csvString = String(data: csvData, encoding: .utf8) ?? ""

        XCTAssertTrue(csvString.contains("\"\""))
    }
}
