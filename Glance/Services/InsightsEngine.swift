import Foundation

// MARK: - Supporting Enums

enum MarkerStatus {
    case normal      // within reference range — green + checkmark
    case watch       // approaching boundary (within 10%) — amber + triangle
    case outOfRange  // outside reference range — red + exclamation
    case noData      // no entries or no reference range — no indicator
}

enum TrendDirection {
    case up           // last 3 entries strictly increasing
    case down         // last 3 entries strictly decreasing
    case flat         // mixed or no consistent direction
    case insufficient // fewer than 3 entries — no trend arrow shown
}

// MARK: - InsightsEngine

@MainActor
final class InsightsEngine {

    // MARK: - Reference Range

    /// Effective low boundary: user override takes precedence over definition default.
    func effectiveLow(for marker: UserMarker) -> Double? {
        marker.customReferenceLow ?? marker.markerDefinition?.defaultReferenceLow
    }

    /// Effective high boundary: user override takes precedence over definition default.
    func effectiveHigh(for marker: UserMarker) -> Double? {
        marker.customReferenceHigh ?? marker.markerDefinition?.defaultReferenceHigh
    }

    // MARK: - Status

    /// Compares a value against the marker's effective reference range.
    /// Watch zone = within 10% of the boundary value on the approaching side.
    func status(for marker: UserMarker, latestValue value: Double) -> MarkerStatus {
        let low = effectiveLow(for: marker)
        let high = effectiveHigh(for: marker)

        guard low != nil || high != nil else { return .noData }

        // Check out of range first
        if let high = high, value > high { return .outOfRange }
        if let low = low, value < low { return .outOfRange }

        // Check watch zone (within 10% of boundary)
        if let high = high, value > high * 0.9 { return .watch }
        if let low = low, value < low * 1.1 { return .watch }

        return .normal
    }

    // MARK: - Trend

    /// Calculates trend from the last 3+ entries (sorted newest-first by dateOfService).
    /// Returns .insufficient if fewer than 3 entries.
    /// All 3 strictly increasing → .up; all strictly decreasing → .down; else .flat.
    func trend(from entries: [MarkerEntry]) -> TrendDirection {
        guard entries.count >= 3 else { return .insufficient }

        // Sort newest-first, take last 3
        let sorted = entries.sorted { $0.dateOfService > $1.dateOfService }
        let newest = sorted[0].value   // most recent
        let middle = sorted[1].value
        let oldest = sorted[2].value   // 3rd most recent

        if newest > middle && middle > oldest { return .up }
        if newest < middle && middle < oldest { return .down }
        return .flat
    }

    /// Returns true if the given trend direction is concerning for a marker
    /// based on its `higherIsBetter` property.
    func isTrendConcerning(direction: TrendDirection, higherIsBetter: Bool) -> Bool {
        switch direction {
        case .up:
            return !higherIsBetter   // going up is bad when lower is better (e.g., LDL)
        case .down:
            return higherIsBetter    // going down is bad when higher is better (e.g., HDL)
        case .flat, .insufficient:
            return false
        }
    }

    // MARK: - Visit Prep Insights

    /// Generates VisitPrepInsight items for markers that are out of range
    /// or trending in a concerning direction.
    /// Language follows PRD constraints: "Consider asking your doctor about..."
    func generateInsights(for markers: [UserMarker]) -> [VisitPrepInsight] {
        var insights: [VisitPrepInsight] = []

        for marker in markers {
            let entries = marker.entries.sorted { $0.dateOfService > $1.dateOfService }
            guard let latest = entries.first else { continue }

            let markerName = marker.markerDefinition?.displayName ?? "this marker"
            let higherIsBetter = marker.markerDefinition?.higherIsBetter ?? false
            let currentStatus = status(for: marker, latestValue: latest.value)
            let currentTrend = trend(from: entries)

            // Out of range insight
            if currentStatus == .outOfRange {
                let text = "Consider asking your doctor about your \(markerName) — it's currently outside the typical range."
                insights.append(VisitPrepInsight(
                    userMarker: marker,
                    insightType: .outOfRange,
                    suggestionText: text,
                    triggeringValues: [latest]
                ))
                continue  // outOfRange takes priority — don't also add a trend insight
            }

            // Concerning trend insight
            let concerningTrend = isTrendConcerning(direction: currentTrend, higherIsBetter: higherIsBetter)
            if concerningTrend, entries.count >= 3 {
                let n = min(entries.count, 3)
                let direction = (currentTrend == .up) ? "trending up" : "trending down"
                let text = "Consider asking your doctor about your \(markerName) — it has been \(direction) over your last \(n) readings."
                let insightType: VisitPrepInsight.InsightType = (currentTrend == .up) ? .trendingUp : .trendingDown
                insights.append(VisitPrepInsight(
                    userMarker: marker,
                    insightType: insightType,
                    suggestionText: text,
                    triggeringValues: Array(entries.prefix(n))
                ))
            }
        }

        return insights
    }
}
