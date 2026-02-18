import SwiftUI
import Charts

/// Time-series chart for a marker's entry history.
/// Shows data points connected by a line, with a shaded reference range band.
/// Handles sparse data: 0 entries (empty), 1 entry (dot only), 2+ (full chart).
struct TrendChart: View {

    let entries: [MarkerEntry]   // Must be sorted oldest → newest
    let userMarker: UserMarker
    let insights = InsightsEngine()

    var body: some View {
        if entries.isEmpty {
            emptyChartPlaceholder
        } else {
            chart
        }
    }

    // MARK: - Chart

    private var chart: some View {
        Chart {
            // Reference range band
            referenceRangeMark

            // Line (only when 2+ entries)
            if entries.count >= 2 {
                ForEach(entries) { entry in
                    LineMark(
                        x: .value("Date", entry.dateOfService),
                        y: .value("Value", entry.value)
                    )
                    .foregroundStyle(Color.accentColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
            }

            // Data points
            ForEach(entries) { entry in
                PointMark(
                    x: .value("Date", entry.dateOfService),
                    y: .value("Value", entry.value)
                )
                .foregroundStyle(pointColor(for: entry))
                .symbolSize(entries.count == 1 ? 80 : 50)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: xAxisCount)) { value in
                AxisGridLine()
                AxisValueLabel(format: xAxisFormat)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .chartYScale(domain: yAxisDomain)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Reference Range Band

    @ChartContentBuilder
    private var referenceRangeMark: some ChartContent {
        if let low = insights.effectiveLow(for: userMarker),
           let high = insights.effectiveHigh(for: userMarker),
           !entries.isEmpty {
            let xMin = entries.first!.dateOfService
            let xMax = entries.last!.dateOfService

            RectangleMark(
                xStart: .value("Start", xMin),
                xEnd: .value("End", xMax),
                yStart: .value("Low", low),
                yEnd: .value("High", high)
            )
            .foregroundStyle(Color("StatusGreen").opacity(0.12))
        }
    }

    // MARK: - Helpers

    private func pointColor(for entry: MarkerEntry) -> Color {
        let s = insights.status(for: userMarker, latestValue: entry.value)
        switch s {
        case .outOfRange: return Color("StatusRed")
        case .watch:      return Color("StatusAmber")
        case .normal:     return Color.accentColor
        case .noData:     return Color.accentColor
        }
    }

    // MARK: - Axis Configuration

    private var xAxisCount: Int {
        guard let first = entries.first, let last = entries.last else { return 4 }
        let days = Calendar.current.dateComponents([.day], from: first.dateOfService, to: last.dateOfService).day ?? 0
        return days > 365 ? 4 : min(entries.count, 5)
    }

    private var xAxisFormat: Date.FormatStyle {
        guard let first = entries.first, let last = entries.last else {
            return .dateTime.month(.abbreviated)
        }
        let days = Calendar.current.dateComponents([.day], from: first.dateOfService, to: last.dateOfService).day ?? 0
        if days > 730 { return .dateTime.year() }
        if days > 60  { return .dateTime.month(.abbreviated).year(.twoDigits) }
        return .dateTime.month(.abbreviated).day()
    }

    private var yAxisDomain: ClosedRange<Double> {
        guard !entries.isEmpty else { return 0...100 }

        let values = entries.map(\.value)
        let minVal = values.min()!
        let maxVal = values.max()!

        let def = userMarker.markerDefinition
        let plausibleMin = def?.plausibleMin
        let plausibleMax = def?.plausibleMax

        let effectiveLow = insights.effectiveLow(for: userMarker)
        let effectiveHigh = insights.effectiveHigh(for: userMarker)

        let padding = (maxVal - minVal) * 0.2 + 5

        var lower = minVal - padding
        var upper = maxVal + padding

        // Include reference range in domain
        if let l = effectiveLow  { lower = min(lower, l - padding) }
        if let h = effectiveHigh { upper = max(upper, h + padding) }

        // Clamp by plausible range to prevent outlier blowup
        if let pm = plausibleMin { lower = max(lower, pm) }
        if let px = plausibleMax { upper = min(upper, px) }

        return lower...upper
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let name = userMarker.markerDefinition?.displayName ?? "marker"
        let count = entries.count
        if count == 0 { return "\(name), no readings" }
        if count == 1 {
            let val = entries[0].value
            return "\(name), 1 reading: \(String(format: "%.1f", val)) \(entries[0].unit)"
        }
        let newest = entries.last!.value
        let oldest = entries.first!.value
        return "\(name), \(count) readings, most recent \(String(format: "%.1f", newest)) \(entries.last!.unit)"
            + (newest > oldest ? ", trending up" : newest < oldest ? ", trending down" : ", stable")
    }

    // MARK: - Empty State

    private var emptyChartPlaceholder: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color("AppBackground"))
            .overlay(
                Text("No data yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            )
    }
}

// MARK: - Previews

#Preview("TrendChart — Many Entries") {
    let data = PreviewData()
    TrendChart(
        entries: data.hdlMarker.entries.sorted { $0.dateOfService < $1.dateOfService },
        userMarker: data.hdlMarker
    )
    .frame(height: 220)
    .padding()
    .modelContainer(data.container)
}

#Preview("TrendChart — One Entry") {
    let data = PreviewData()
    TrendChart(
        entries: [data.hdlEntry],
        userMarker: data.hdlMarker
    )
    .frame(height: 220)
    .padding()
    .modelContainer(data.container)
}

#Preview("TrendChart — No Entries") {
    let data = PreviewData()
    TrendChart(
        entries: [],
        userMarker: data.glucoseMarker
    )
    .frame(height: 220)
    .padding()
    .modelContainer(data.container)
}

#Preview("TrendChart — Out of Range Points") {
    let data = PreviewData()
    TrendChart(
        entries: data.a1cMarker.entries.sorted { $0.dateOfService < $1.dateOfService },
        userMarker: data.a1cMarker
    )
    .frame(height: 220)
    .padding()
    .modelContainer(data.container)
}
