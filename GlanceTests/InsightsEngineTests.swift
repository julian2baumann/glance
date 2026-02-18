import XCTest
import SwiftData
@testable import Glance

@MainActor
final class InsightsEngineTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext!
    let engine = InsightsEngine()

    override func setUp() async throws {
        try await super.setUp()
        container = try makeTestContainer()
        context = container.mainContext
    }

    override func tearDown() async throws {
        context = nil
        container = nil
        try await super.tearDown()
    }

    // MARK: - Helpers

    private func makeDefinition(
        low: Double? = nil,
        high: Double? = nil,
        higherIsBetter: Bool = false,
        plausibleMin: Double? = nil,
        plausibleMax: Double? = nil
    ) -> MarkerDefinition {
        let def = MarkerDefinition(
            displayName: "Test Marker",
            defaultUnit: "mg/dL",
            defaultReferenceLow: low,
            defaultReferenceHigh: high,
            plausibleMin: plausibleMin,
            plausibleMax: plausibleMax,
            higherIsBetter: higherIsBetter,
            isSystemDefined: true
        )
        context.insert(def)
        return def
    }

    private func makeUserMarker(
        definition: MarkerDefinition,
        customLow: Double? = nil,
        customHigh: Double? = nil
    ) -> UserMarker {
        let marker = UserMarker(
            markerDefinition: definition,
            customReferenceLow: customLow,
            customReferenceHigh: customHigh
        )
        context.insert(marker)
        return marker
    }

    private func makeEntry(value: Double, daysAgo: Int = 0, for marker: UserMarker) -> MarkerEntry {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        let entry = MarkerEntry(userMarker: marker, value: value, unit: "mg/dL", dateOfService: date)
        context.insert(entry)
        marker.entries.append(entry)
        return entry
    }

    // MARK: - effectiveLow / effectiveHigh

    func testEffectiveLowUsesDefinitionDefault() {
        let def = makeDefinition(low: 40)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.effectiveLow(for: marker), 40)
    }

    func testEffectiveLowUsesCustomOverride() {
        let def = makeDefinition(low: 40)
        let marker = makeUserMarker(definition: def, customLow: 50)
        XCTAssertEqual(engine.effectiveLow(for: marker), 50)
    }

    func testEffectiveHighUsesDefinitionDefault() {
        let def = makeDefinition(high: 100)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.effectiveHigh(for: marker), 100)
    }

    func testEffectiveHighUsesCustomOverride() {
        let def = makeDefinition(high: 100)
        let marker = makeUserMarker(definition: def, customHigh: 80)
        XCTAssertEqual(engine.effectiveHigh(for: marker), 80)
    }

    func testEffectiveLowNilWhenNeitherSet() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        XCTAssertNil(engine.effectiveLow(for: marker))
    }

    // MARK: - Status: Normal

    func testStatusNormalWithinRange() {
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 70), .normal)
    }

    func testStatusNormalAtExactLow() {
        // value == low means still within range (not below it)
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        // 40 is the boundary — within 10% (low * 1.1 = 44) → watch
        XCTAssertEqual(engine.status(for: marker, latestValue: 40), .watch)
    }

    func testStatusNormalAtExactHigh() {
        // value == high → within 10% (high * 0.9 = 90) → watch
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 100), .watch)
    }

    func testStatusNormalSafelyInsideBothBounds() {
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 65), .normal)
    }

    // MARK: - Status: Watch (High Side)

    func testStatusWatchApproachingHighBoundary() {
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        // 95 > 100 * 0.9 = 90, but 95 <= 100 → watch
        XCTAssertEqual(engine.status(for: marker, latestValue: 95), .watch)
    }

    func testStatusWatchExactlyAtHighWatchThreshold() {
        let def = makeDefinition(high: 100)
        let marker = makeUserMarker(definition: def)
        // 90 is exactly at high * 0.9 — NOT above it → normal
        XCTAssertEqual(engine.status(for: marker, latestValue: 90), .normal)
    }

    func testStatusWatchJustAboveHighWatchThreshold() {
        let def = makeDefinition(high: 100)
        let marker = makeUserMarker(definition: def)
        // 90.1 > 90 → watch
        XCTAssertEqual(engine.status(for: marker, latestValue: 90.1), .watch)
    }

    // MARK: - Status: Watch (Low Side)

    func testStatusWatchApproachingLowBoundary() {
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        // 43 < 40 * 1.1 = 44, but 43 >= 40 → watch
        XCTAssertEqual(engine.status(for: marker, latestValue: 43), .watch)
    }

    func testStatusWatchExactlyAtLowWatchThreshold() {
        let def = makeDefinition(low: 40)
        let marker = makeUserMarker(definition: def)
        // 44 == low * 1.1 — NOT below it → normal
        XCTAssertEqual(engine.status(for: marker, latestValue: 44), .normal)
    }

    func testStatusWatchJustBelowLowWatchThreshold() {
        let def = makeDefinition(low: 40)
        let marker = makeUserMarker(definition: def)
        // 43.9 < 44 → watch
        XCTAssertEqual(engine.status(for: marker, latestValue: 43.9), .watch)
    }

    // MARK: - Status: Out of Range

    func testStatusOutOfRangeAboveHigh() {
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 150), .outOfRange)
    }

    func testStatusOutOfRangeBelowLow() {
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 20), .outOfRange)
    }

    func testStatusOutOfRangeJustAboveHigh() {
        let def = makeDefinition(high: 100)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 100.1), .outOfRange)
    }

    func testStatusOutOfRangeJustBelowLow() {
        let def = makeDefinition(low: 40)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 39.9), .outOfRange)
    }

    // MARK: - Status: Boundary Configurations

    func testStatusOnlyHighBoundaryNormalBelow() {
        let def = makeDefinition(high: 100)   // LDL-style (only upper limit)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 80), .normal)
    }

    func testStatusOnlyHighBoundaryOutOfRange() {
        let def = makeDefinition(high: 100)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 110), .outOfRange)
    }

    func testStatusOnlyLowBoundaryNormalAbove() {
        let def = makeDefinition(low: 40)     // HDL-style (only lower limit)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 60), .normal)
    }

    func testStatusOnlyLowBoundaryOutOfRange() {
        let def = makeDefinition(low: 40)
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 30), .outOfRange)
    }

    func testStatusNoReferenceRangeReturnsNoData() {
        let def = makeDefinition()   // no low, no high
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.status(for: marker, latestValue: 50), .noData)
    }

    // MARK: - Status: Custom Override

    func testStatusCustomHighOverrideTakesPrecedence() {
        let def = makeDefinition(high: 100)
        let marker = makeUserMarker(definition: def, customHigh: 80)
        // 85 > 80 (custom high) → out of range, even though < 100 (default high)
        XCTAssertEqual(engine.status(for: marker, latestValue: 85), .outOfRange)
    }

    func testStatusCustomLowOverrideTakesPrecedence() {
        let def = makeDefinition(low: 40)
        let marker = makeUserMarker(definition: def, customLow: 60)
        // 55 < 60 (custom low) → out of range, even though > 40 (default low)
        XCTAssertEqual(engine.status(for: marker, latestValue: 55), .outOfRange)
    }

    // MARK: - Trend: Up

    func testTrendUpThreeStrictlyIncreasing() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 80, daysAgo: 10, for: marker)
        _ = makeEntry(value: 90, daysAgo: 5, for: marker)
        _ = makeEntry(value: 100, daysAgo: 0, for: marker)
        XCTAssertEqual(engine.trend(from: marker.entries), .up)
    }

    func testTrendUpFourConsecutiveIncreasing() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 70, daysAgo: 15, for: marker)
        _ = makeEntry(value: 80, daysAgo: 10, for: marker)
        _ = makeEntry(value: 90, daysAgo: 5, for: marker)
        _ = makeEntry(value: 100, daysAgo: 0, for: marker)
        // Only last 3 matter: 80→90→100 → up
        XCTAssertEqual(engine.trend(from: marker.entries), .up)
    }

    // MARK: - Trend: Down

    func testTrendDownThreeStrictlyDecreasing() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 100, daysAgo: 10, for: marker)
        _ = makeEntry(value: 90, daysAgo: 5, for: marker)
        _ = makeEntry(value: 80, daysAgo: 0, for: marker)
        XCTAssertEqual(engine.trend(from: marker.entries), .down)
    }

    // MARK: - Trend: Flat / Mixed

    func testTrendFlatMixedValues() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 100, daysAgo: 10, for: marker)
        _ = makeEntry(value: 80, daysAgo: 5, for: marker)
        _ = makeEntry(value: 90, daysAgo: 0, for: marker)
        XCTAssertEqual(engine.trend(from: marker.entries), .flat)
    }

    func testTrendFlatUpThenDown() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 80, daysAgo: 10, for: marker)
        _ = makeEntry(value: 100, daysAgo: 5, for: marker)
        _ = makeEntry(value: 90, daysAgo: 0, for: marker)
        XCTAssertEqual(engine.trend(from: marker.entries), .flat)
    }

    func testTrendFlatIdenticalValues() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 85, daysAgo: 10, for: marker)
        _ = makeEntry(value: 85, daysAgo: 5, for: marker)
        _ = makeEntry(value: 85, daysAgo: 0, for: marker)
        // Not strictly increasing or decreasing
        XCTAssertEqual(engine.trend(from: marker.entries), .flat)
    }

    // MARK: - Trend: Insufficient

    func testTrendInsufficientWithZeroEntries() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        XCTAssertEqual(engine.trend(from: marker.entries), .insufficient)
    }

    func testTrendInsufficientWithOneEntry() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 85, daysAgo: 0, for: marker)
        XCTAssertEqual(engine.trend(from: marker.entries), .insufficient)
    }

    func testTrendInsufficientWithTwoEntries() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 80, daysAgo: 5, for: marker)
        _ = makeEntry(value: 90, daysAgo: 0, for: marker)
        XCTAssertEqual(engine.trend(from: marker.entries), .insufficient)
    }

    func testTrendSufficientWithExactlyThreeEntries() {
        let def = makeDefinition()
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 80, daysAgo: 10, for: marker)
        _ = makeEntry(value: 85, daysAgo: 5, for: marker)
        _ = makeEntry(value: 90, daysAgo: 0, for: marker)
        XCTAssertNotEqual(engine.trend(from: marker.entries), .insufficient)
    }

    // MARK: - isTrendConcerning

    func testUpTrendConcerningWhenHigherIsNotBetter() {
        // LDL: lower is better, so up trend = concerning
        XCTAssertTrue(engine.isTrendConcerning(direction: .up, higherIsBetter: false))
    }

    func testUpTrendNotConcerningWhenHigherIsBetter() {
        // HDL: higher is better, so up trend = good
        XCTAssertFalse(engine.isTrendConcerning(direction: .up, higherIsBetter: true))
    }

    func testDownTrendConcerningWhenHigherIsBetter() {
        // HDL: higher is better, so down trend = concerning
        XCTAssertTrue(engine.isTrendConcerning(direction: .down, higherIsBetter: true))
    }

    func testDownTrendNotConcerningWhenLowerIsBetter() {
        // LDL: lower is better, so down trend = good
        XCTAssertFalse(engine.isTrendConcerning(direction: .down, higherIsBetter: false))
    }

    func testFlatTrendNeverConcerning() {
        XCTAssertFalse(engine.isTrendConcerning(direction: .flat, higherIsBetter: true))
        XCTAssertFalse(engine.isTrendConcerning(direction: .flat, higherIsBetter: false))
    }

    func testInsufficientTrendNeverConcerning() {
        XCTAssertFalse(engine.isTrendConcerning(direction: .insufficient, higherIsBetter: true))
        XCTAssertFalse(engine.isTrendConcerning(direction: .insufficient, higherIsBetter: false))
    }

    // MARK: - generateInsights

    func testNoInsightsForNormalMarkerWithGoodTrend() {
        let def = makeDefinition(low: 40, high: 100, higherIsBetter: true)
        let marker = makeUserMarker(definition: def)
        // Entries trending up (good for higherIsBetter=true), within range
        _ = makeEntry(value: 70, daysAgo: 10, for: marker)
        _ = makeEntry(value: 80, daysAgo: 5, for: marker)
        _ = makeEntry(value: 90, daysAgo: 0, for: marker)
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertTrue(insights.isEmpty)
    }

    func testInsightGeneratedForOutOfRangeMarker() {
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 150, daysAgo: 0, for: marker)
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights.first?.insightType, .outOfRange)
        XCTAssertTrue(insights.first?.suggestionText.contains("Consider asking your doctor") == true)
    }

    func testInsightGeneratedForConcerningUpTrend() {
        // LDL: lower is better, trending up = concerning
        let def = makeDefinition(low: nil, high: 100, higherIsBetter: false)
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 70, daysAgo: 10, for: marker)
        _ = makeEntry(value: 80, daysAgo: 5, for: marker)
        _ = makeEntry(value: 85, daysAgo: 0, for: marker)  // still within range
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights.first?.insightType, .trendingUp)
    }

    func testInsightGeneratedForConcerningDownTrend() {
        // HDL: higher is better, trending down = concerning
        let def = makeDefinition(low: 40, high: nil, higherIsBetter: true)
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 90, daysAgo: 10, for: marker)
        _ = makeEntry(value: 80, daysAgo: 5, for: marker)
        _ = makeEntry(value: 70, daysAgo: 0, for: marker)  // still within range
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights.first?.insightType, .trendingDown)
    }

    func testNoInsightForGoodDownTrend() {
        // LDL: lower is better, trending down = good
        let def = makeDefinition(high: 100, higherIsBetter: false)
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 90, daysAgo: 10, for: marker)
        _ = makeEntry(value: 80, daysAgo: 5, for: marker)
        _ = makeEntry(value: 70, daysAgo: 0, for: marker)
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertTrue(insights.isEmpty)
    }

    func testNoInsightForMarkerWithNoEntries() {
        let def = makeDefinition(low: 40, high: 100)
        let marker = makeUserMarker(definition: def)
        // No entries inserted
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertTrue(insights.isEmpty)
    }

    func testOutOfRangeTakesPriorityOverTrend() {
        // If marker is out of range AND trending badly, only outOfRange insight is generated
        let def = makeDefinition(high: 100, higherIsBetter: false)
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 90, daysAgo: 10, for: marker)
        _ = makeEntry(value: 100, daysAgo: 5, for: marker)
        _ = makeEntry(value: 120, daysAgo: 0, for: marker)  // out of range AND trending up
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertEqual(insights.count, 1)
        XCTAssertEqual(insights.first?.insightType, .outOfRange)
    }

    func testInsightTextContainsMarkerName() {
        let def = MarkerDefinition(
            displayName: "HDL Cholesterol",
            defaultUnit: "mg/dL",
            defaultReferenceLow: 40,
            higherIsBetter: true,
            isSystemDefined: true
        )
        context.insert(def)
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 90, daysAgo: 10, for: marker)
        _ = makeEntry(value: 80, daysAgo: 5, for: marker)
        _ = makeEntry(value: 70, daysAgo: 0, for: marker)
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertTrue(insights.first?.suggestionText.contains("HDL Cholesterol") == true)
    }

    func testMultipleMarkersProduceMultipleInsights() {
        let def1 = makeDefinition(high: 100)
        let marker1 = makeUserMarker(definition: def1)
        _ = makeEntry(value: 150, daysAgo: 0, for: marker1)

        let def2 = makeDefinition(high: 100)
        let marker2 = makeUserMarker(definition: def2)
        _ = makeEntry(value: 200, daysAgo: 0, for: marker2)

        try? context.save()

        let insights = engine.generateInsights(for: [marker1, marker2])
        XCTAssertEqual(insights.count, 2)
    }

    func testNoInsightWhenTrendInsufficientAndInRange() {
        let def = makeDefinition(low: 40, high: 100, higherIsBetter: false)
        let marker = makeUserMarker(definition: def)
        _ = makeEntry(value: 70, daysAgo: 0, for: marker)  // only 1 entry
        try? context.save()

        let insights = engine.generateInsights(for: [marker])
        XCTAssertTrue(insights.isEmpty)
    }
}
