import SwiftUI

/// Compact single-row display of a tracked marker on the home screen.
/// Shows: status dot, marker name, latest value with unit, trend arrow.
struct MarkerRow: View {

    let userMarker: UserMarker
    let status: MarkerStatus
    let trend: TrendDirection
    let latestEntry: MarkerEntry?
    let higherIsBetter: Bool

    var body: some View {
        HStack(spacing: 12) {
            // Status accent dot (left edge)
            StatusBadge(status: status, size: .dot)

            // Marker name
            Text(userMarker.markerDefinition?.displayName ?? "Unknown")
                .font(.headline)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            // Value + unit + trend arrow
            VStack(alignment: .trailing, spacing: 2) {
                if let entry = latestEntry {
                    Text(formattedValue(entry))
                        .font(.body)
                        .foregroundStyle(.primary)
                        .monospacedDigit()

                    if showTrendArrow {
                        Image(systemName: trendArrowIcon)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(trendArrowColor)
                    }
                } else {
                    Text("—")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)  // Minimum 44pt touch target
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    // MARK: - Trend Arrow

    private var showTrendArrow: Bool {
        trend == .up || trend == .down
    }

    private var trendArrowIcon: String {
        trend == .up ? "arrow.up" : "arrow.down"
    }

    private var trendArrowColor: Color {
        let concerning: Bool
        switch trend {
        case .up:   concerning = !higherIsBetter
        case .down: concerning = higherIsBetter
        default:    concerning = false
        }
        return concerning ? Color("StatusRed") : Color("StatusGreen")
    }

    // MARK: - Formatting

    private func formattedValue(_ entry: MarkerEntry) -> String {
        let val = entry.value
        let formatted: String
        if val.truncatingRemainder(dividingBy: 1) == 0 {
            formatted = String(Int(val))
        } else {
            formatted = String(format: "%.1f", val)
        }
        return "\(formatted) \(entry.unit)"
    }

    // MARK: - Accessibility

    private var accessibilityLabel: String {
        let name = userMarker.markerDefinition?.displayName ?? "Unknown marker"

        var parts = [name]

        if let entry = latestEntry {
            parts.append(formattedValue(entry))
        } else {
            parts.append("no readings")
        }

        switch trend {
        case .up:   parts.append("trending up")
        case .down: parts.append("trending down")
        case .flat: parts.append("stable")
        case .insufficient: break
        }

        switch status {
        case .normal:    parts.append("within normal range")
        case .watch:     parts.append("approaching boundary")
        case .outOfRange: parts.append("out of normal range")
        case .noData:    break
        }

        return parts.joined(separator: ", ")
    }
}

// MARK: - Previews

#Preview("MarkerRow — Various States") {
    let data = PreviewData()
    List {
        MarkerRow(
            userMarker: data.hdlMarker,
            status: .normal,
            trend: .up,
            latestEntry: data.hdlEntry,
            higherIsBetter: true
        )
        MarkerRow(
            userMarker: data.ldlMarker,
            status: .watch,
            trend: .up,
            latestEntry: data.ldlEntry,
            higherIsBetter: false
        )
        MarkerRow(
            userMarker: data.a1cMarker,
            status: .outOfRange,
            trend: .down,
            latestEntry: data.a1cEntry,
            higherIsBetter: false
        )
        MarkerRow(
            userMarker: data.glucoseMarker,
            status: .noData,
            trend: .insufficient,
            latestEntry: nil,
            higherIsBetter: false
        )
    }
    .listStyle(.plain)
    .modelContainer(data.container)
}

#Preview("MarkerRow — iPhone SE") {
    let data = PreviewData()
    List {
        MarkerRow(
            userMarker: data.hdlMarker,
            status: .normal,
            trend: .up,
            latestEntry: data.hdlEntry,
            higherIsBetter: true
        )
    }
    .listStyle(.plain)
    .modelContainer(data.container)
    .previewDevice("iPhone SE (3rd generation)")
}

#Preview("MarkerRow — Large Text") {
    let data = PreviewData()
    List {
        MarkerRow(
            userMarker: data.hdlMarker,
            status: .normal,
            trend: .up,
            latestEntry: data.hdlEntry,
            higherIsBetter: true
        )
    }
    .listStyle(.plain)
    .modelContainer(data.container)
    .dynamicTypeSize(.accessibility2)
}
