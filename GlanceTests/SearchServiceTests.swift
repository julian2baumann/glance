import XCTest
import SwiftData
@testable import Glance

@MainActor
final class SearchServiceTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    var searchService: SearchService!

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
        context = container.mainContext
        searchService = SearchService()

        // Seed test markers
        seedTestMarkers()
    }

    override func tearDown() async throws {
        searchService = nil
        context = nil
        container = nil
        try await super.tearDown()
    }

    private func seedTestMarkers() {
        let heartCat = MarkerCategory(name: "Heart", displayOrder: 1)
        context.insert(heartCat)

        let hdl = MarkerDefinition(
            displayName: "HDL Cholesterol",
            category: heartCat,
            defaultUnit: "mg/dL",
            higherIsBetter: true,
            aliases: ["good cholesterol", "HDL-C", "high-density lipoprotein", "HDL"],
            isSystemDefined: true
        )
        let ldl = MarkerDefinition(
            displayName: "LDL Cholesterol",
            category: heartCat,
            defaultUnit: "mg/dL",
            higherIsBetter: false,
            aliases: ["bad cholesterol", "LDL-C", "low-density lipoprotein", "LDL"],
            isSystemDefined: true
        )
        let totalChol = MarkerDefinition(
            displayName: "Total Cholesterol",
            category: heartCat,
            defaultUnit: "mg/dL",
            higherIsBetter: false,
            aliases: ["cholesterol", "total chol", "TC"],
            isSystemDefined: true
        )
        let glucose = MarkerDefinition(
            displayName: "Fasting Glucose",
            category: heartCat,
            defaultUnit: "mg/dL",
            higherIsBetter: false,
            aliases: ["blood sugar", "fasting blood sugar", "glucose"],
            isSystemDefined: true
        )

        context.insert(hdl)
        context.insert(ldl)
        context.insert(totalChol)
        context.insert(glucose)
        try? context.save()
    }

    // MARK: - Empty Query

    func testEmptyQueryReturnsEmptyResults() {
        let results = searchService.search(query: "", in: context, trackedMarkers: [])
        XCTAssertTrue(results.trackedMarkers.isEmpty)
        XCTAssertTrue(results.untrackedDefinitions.isEmpty)
    }

    func testWhitespaceOnlyQueryReturnsEmptyResults() {
        let results = searchService.search(query: "   ", in: context, trackedMarkers: [])
        XCTAssertTrue(results.trackedMarkers.isEmpty)
        XCTAssertTrue(results.untrackedDefinitions.isEmpty)
    }

    // MARK: - Alias Resolution

    func testAliasResolutionGoodCholesterolFindsHDL() {
        let results = searchService.search(query: "good cholesterol", in: context, trackedMarkers: [])
        XCTAssertFalse(results.untrackedDefinitions.isEmpty)
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "HDL Cholesterol" }))
    }

    func testAliasResolutionBadCholesterolFindsLDL() {
        let results = searchService.search(query: "bad cholesterol", in: context, trackedMarkers: [])
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "LDL Cholesterol" }))
    }

    func testAliasResolutionBloodSugarFindsGlucose() {
        let results = searchService.search(query: "blood sugar", in: context, trackedMarkers: [])
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "Fasting Glucose" }))
    }

    // MARK: - Partial Match

    func testPartialMatchCholFindsMultiple() {
        let results = searchService.search(query: "chol", in: context, trackedMarkers: [])
        let names = results.untrackedDefinitions.map(\.displayName)
        XCTAssertTrue(names.contains("HDL Cholesterol"))
        XCTAssertTrue(names.contains("LDL Cholesterol"))
        XCTAssertTrue(names.contains("Total Cholesterol"))
    }

    func testPartialMatchHDLFindsHDLCholesterol() {
        let results = searchService.search(query: "HDL", in: context, trackedMarkers: [])
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "HDL Cholesterol" }))
    }

    // MARK: - Case Insensitivity

    func testCaseInsensitiveLowercaseQuery() {
        let results = searchService.search(query: "hdl", in: context, trackedMarkers: [])
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "HDL Cholesterol" }))
    }

    func testCaseInsensitiveUppercaseQuery() {
        let results = searchService.search(query: "CHOLESTEROL", in: context, trackedMarkers: [])
        XCTAssertFalse(results.untrackedDefinitions.isEmpty)
    }

    func testCaseInsensitiveMixedCaseQuery() {
        let results = searchService.search(query: "GoOd ChOlEsTeRoL", in: context, trackedMarkers: [])
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "HDL Cholesterol" }))
    }

    // MARK: - Tracked vs Untracked Partitioning

    func testTrackedMarkerAppearsInTrackedResults() {
        let descriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate<MarkerDefinition> { $0.displayName == "HDL Cholesterol" }
        )
        let hdlDef = (try? context.fetch(descriptor))?.first!

        let profile = Profile()
        context.insert(profile)
        let userMarker = UserMarker(profile: profile, markerDefinition: hdlDef, displayOrder: 0)
        context.insert(userMarker)
        try? context.save()

        let results = searchService.search(query: "HDL", in: context, trackedMarkers: [userMarker])

        XCTAssertTrue(results.trackedMarkers.contains(where: { $0.id == userMarker.id }))
        XCTAssertFalse(results.untrackedDefinitions.contains(where: { $0.displayName == "HDL Cholesterol" }))
    }

    func testUntrackedMarkerAppearsInUntrackedResults() {
        let results = searchService.search(query: "LDL", in: context, trackedMarkers: [])
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "LDL Cholesterol" }))
        XCTAssertTrue(results.trackedMarkers.isEmpty)
    }

    // MARK: - Custom Marker Search

    func testCustomMarkerIsSearchable() {
        let custom = MarkerDefinition(
            displayName: "My Special Enzyme",
            defaultUnit: "U/L",
            higherIsBetter: false,
            aliases: ["special enzyme", "my enzyme"],
            isSystemDefined: false
        )
        context.insert(custom)
        try? context.save()

        let results = searchService.search(query: "special enzyme", in: context, trackedMarkers: [])
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "My Special Enzyme" }))
    }

    func testCustomMarkerSearchByDisplayName() {
        let custom = MarkerDefinition(
            displayName: "Cortisol",
            defaultUnit: "µg/dL",
            higherIsBetter: false,
            aliases: ["stress hormone"],
            isSystemDefined: false
        )
        context.insert(custom)
        try? context.save()

        let results = searchService.search(query: "cortisol", in: context, trackedMarkers: [])
        XCTAssertTrue(results.untrackedDefinitions.contains(where: { $0.displayName == "Cortisol" }))
    }

    // MARK: - No Match

    func testNoMatchQueryReturnsEmptyResults() {
        let results = searchService.search(query: "zzzyyyxxx", in: context, trackedMarkers: [])
        XCTAssertTrue(results.trackedMarkers.isEmpty)
        XCTAssertTrue(results.untrackedDefinitions.isEmpty)
    }
}
