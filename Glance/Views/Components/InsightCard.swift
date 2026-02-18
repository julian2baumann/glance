import SwiftUI

/// Insight card for the Next Visit Prep section on the Visits tab.
/// Light blue tinted background, icon indicating insight type, marker name, and suggestion text.
/// Tappable via NavigationLink — navigates to the relevant MarkerDetailView.
struct InsightCard: View {

    let insight: VisitPrepInsight

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: insightIcon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, alignment: .center)

            VStack(alignment: .leading, spacing: 4) {
                Text(markerName)
                    .font(.subheadline.weight(.semibold))

                Text(insight.suggestionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(12)
        .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(markerName): \(insight.suggestionText)")
        .accessibilityHint("Tap to view marker details")
    }

    private var markerName: String {
        insight.userMarker.markerDefinition?.displayName ?? "Marker"
    }

    private var insightIcon: String {
        switch insight.insightType {
        case .outOfRange:   return "exclamationmark.circle"
        case .trendingUp:   return "arrow.up.circle"
        case .trendingDown: return "arrow.down.circle"
        }
    }
}

// MARK: - Previews

#Preview("InsightCard — Out of Range") {
    let data = PreviewData()
    let insight = VisitPrepInsight(
        userMarker: data.a1cMarker,
        insightType: .outOfRange,
        suggestionText: "Consider asking your doctor about your Hemoglobin A1C — it's currently outside the typical range.",
        triggeringValues: [data.a1cEntry]
    )
    return List {
        InsightCard(insight: insight)
    }
    .listStyle(.insetGrouped)
    .modelContainer(data.container)
}

#Preview("InsightCard — Trending") {
    let data = PreviewData()
    let insight = VisitPrepInsight(
        userMarker: data.ldlMarker,
        insightType: .trendingUp,
        suggestionText: "Consider asking your doctor about your LDL Cholesterol — it has been trending up over your last 3 readings.",
        triggeringValues: [data.ldlEntry]
    )
    return List {
        InsightCard(insight: insight)
    }
    .listStyle(.insetGrouped)
    .modelContainer(data.container)
}

#Preview("InsightCard — Large Text") {
    let data = PreviewData()
    let insight = VisitPrepInsight(
        userMarker: data.a1cMarker,
        insightType: .outOfRange,
        suggestionText: "Consider asking your doctor about your Hemoglobin A1C — it's currently outside the typical range.",
        triggeringValues: [data.a1cEntry]
    )
    return List {
        InsightCard(insight: insight)
    }
    .listStyle(.insetGrouped)
    .modelContainer(data.container)
    .dynamicTypeSize(.accessibility2)
}
