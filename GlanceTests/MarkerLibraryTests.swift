import XCTest
import SwiftData
@testable import Glance

@MainActor
final class MarkerLibraryTests: XCTestCase {

    var container: ModelContainer!
    let library = MarkerLibrary.shared
    // Load JSON from the source directory at compile time — avoids bundle lookup issues in test targets
    var markerData: Data = {
        let jsonURL = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()              // remove MarkerLibraryTests.swift
            .deletingLastPathComponent()              // remove GlanceTests/
            .appendingPathComponent("Glance/Resources/MarkerData.json")
        return try! Data(contentsOf: jsonURL)
    }()

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
    }

    override func tearDown() async throws {
        container = nil
        try await super.tearDown()
    }

    // MARK: - Seeding

    func testSeedingCreatesCorrectCategoryCount() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerCategory>()
        let categories = (try? container.mainContext.fetch(descriptor)) ?? []
        XCTAssertEqual(categories.count, 8)
    }

    func testSeedingCreatesCorrectMarkerCount() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate<MarkerDefinition> { $0.isSystemDefined == true }
        )
        let markers = (try? container.mainContext.fetch(descriptor)) ?? []
        XCTAssertEqual(markers.count, 31)
    }

    func testAllRequiredMarkersPresent() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerDefinition>()
        let markers = (try? container.mainContext.fetch(descriptor)) ?? []
        let names = Set(markers.map(\.displayName))

        let required = [
            "HDL Cholesterol", "LDL Cholesterol", "Total Cholesterol", "Triglycerides",
            "Hemoglobin A1C", "Fasting Glucose",
            "ALT", "AST", "GGT",
            "Creatinine", "eGFR", "BUN",
            "Hemoglobin", "Hematocrit", "WBC", "Platelets",
            "Vitamin D", "Vitamin B12", "Calcium", "Iron", "Ferritin",
            "TSH", "Free T4",
            "Systolic Blood Pressure", "Diastolic Blood Pressure", "Heart Rate",
            "BMI", "Weight",
            "PSA", "CRP", "Uric Acid"
        ]

        for name in required {
            XCTAssertTrue(names.contains(name), "Missing required marker: \(name)")
        }
    }

    func testSeedingIsIdempotent() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate<MarkerDefinition> { $0.isSystemDefined == true }
        )
        let markers = (try? container.mainContext.fetch(descriptor)) ?? []
        XCTAssertEqual(markers.count, 31)

        let catDescriptor = FetchDescriptor<MarkerCategory>()
        let categories = (try? container.mainContext.fetch(catDescriptor)) ?? []
        XCTAssertEqual(categories.count, 8)
    }

    func testAllMarkersHaveRequiredFields() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate<MarkerDefinition> { $0.isSystemDefined == true }
        )
        let markers = (try? container.mainContext.fetch(descriptor)) ?? []

        for marker in markers {
            XCTAssertFalse(marker.displayName.isEmpty, "\(marker.displayName) has empty displayName")
            XCTAssertFalse(marker.defaultUnit.isEmpty, "\(marker.displayName) has empty unit")
            XCTAssertFalse(marker.aliases.isEmpty, "\(marker.displayName) has no aliases")
        }
    }

    func testAllMarkersHaveCategory() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate<MarkerDefinition> { $0.isSystemDefined == true }
        )
        let markers = (try? container.mainContext.fetch(descriptor)) ?? []

        for marker in markers {
            XCTAssertNotNil(marker.category, "\(marker.displayName) has no category")
        }
    }

    func testCategoriesHaveCorrectDisplayOrder() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerCategory>(
            sortBy: [SortDescriptor(\.displayOrder)]
        )
        let categories = (try? container.mainContext.fetch(descriptor)) ?? []

        let expectedOrder = ["Heart", "Metabolic", "Liver", "Kidney", "Blood", "Vitamins & Minerals", "Thyroid", "General"]
        let actualOrder = categories.map(\.name)

        XCTAssertEqual(actualOrder, expectedOrder)
    }

    func testHDLHasCorrectConfiguration() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate<MarkerDefinition> { $0.displayName == "HDL Cholesterol" }
        )
        let markers = (try? container.mainContext.fetch(descriptor)) ?? []
        let hdl = markers.first

        XCTAssertNotNil(hdl)
        XCTAssertEqual(hdl?.defaultUnit, "mg/dL")
        XCTAssertEqual(hdl?.higherIsBetter, true)
        XCTAssertEqual(hdl?.defaultReferenceLow, 40)
        XCTAssertEqual(hdl?.category?.name, "Heart")
    }

    func testLDLHasCorrectConfiguration() {
        library.seedIfNeeded(context: container.mainContext, jsonData: markerData)

        let descriptor = FetchDescriptor<MarkerDefinition>(
            predicate: #Predicate<MarkerDefinition> { $0.displayName == "LDL Cholesterol" }
        )
        let markers = (try? container.mainContext.fetch(descriptor)) ?? []
        let ldl = markers.first

        XCTAssertNotNil(ldl)
        XCTAssertEqual(ldl?.higherIsBetter, false)
        XCTAssertEqual(ldl?.defaultReferenceHigh, 100)
        XCTAssertEqual(ldl?.category?.name, "Heart")
    }
}
