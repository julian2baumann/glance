import SwiftUI

/// A compact color + icon badge communicating marker status.
/// Color is never the only signifier — always paired with an icon.
struct StatusBadge: View {

    let status: MarkerStatus
    var size: BadgeSize = .dot

    enum BadgeSize {
        case dot    // Small dot for MarkerRow left accent
        case full   // Larger badge with icon for detail views
    }

    var body: some View {
        switch size {
        case .dot:
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
                .accessibilityHidden(true)  // Context provided by parent row

        case .full:
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .font(.subheadline.weight(.semibold))
                Text(statusLabel)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(statusColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(statusColor.opacity(0.12), in: Capsule())
            .accessibilityLabel(statusLabel)
        }
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch status {
        case .normal:    return Color("StatusGreen")
        case .watch:     return Color("StatusAmber")
        case .outOfRange: return Color("StatusRed")
        case .noData:    return Color.secondary
        }
    }

    private var iconName: String {
        switch status {
        case .normal:    return "checkmark"
        case .watch:     return "exclamationmark.triangle"
        case .outOfRange: return "exclamationmark"
        case .noData:    return "minus"
        }
    }

    private var statusLabel: String {
        switch status {
        case .normal:    return "Normal"
        case .watch:     return "Watch"
        case .outOfRange: return "Out of Range"
        case .noData:    return "No Data"
        }
    }
}

// MARK: - Previews

#Preview("Status Badge — All States") {
    VStack(spacing: 24) {
        Text("Dot size").font(.caption).foregroundStyle(.secondary)
        HStack(spacing: 16) {
            StatusBadge(status: .normal, size: .dot)
            StatusBadge(status: .watch, size: .dot)
            StatusBadge(status: .outOfRange, size: .dot)
            StatusBadge(status: .noData, size: .dot)
        }
        Text("Full size").font(.caption).foregroundStyle(.secondary)
        VStack(spacing: 8) {
            StatusBadge(status: .normal, size: .full)
            StatusBadge(status: .watch, size: .full)
            StatusBadge(status: .outOfRange, size: .full)
            StatusBadge(status: .noData, size: .full)
        }
    }
    .padding()
}
