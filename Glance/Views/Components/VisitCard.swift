import SwiftUI

/// Card component displaying a logged visit with doctor, date, type badge, and notes preview.
/// Provides explicit Edit and Delete actions via a menu button (not gesture-only).
struct VisitCard: View {

    let visit: Visit
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Date column — prominent, fixed width
            VStack(spacing: 2) {
                Text(visit.date, format: .dateTime.month(.abbreviated))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(visit.date, format: .dateTime.day())
                    .font(.title2.weight(.semibold))
            }
            .frame(width: 44)

            // Main content
            VStack(alignment: .leading, spacing: 6) {
                Text(visit.doctorName)
                    .font(.headline)
                    .lineLimit(1)

                // Visit type badge
                Text(displayedVisitType)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor, in: Capsule())

                // Truncated note preview
                if let notes = visit.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            // Explicit edit/delete menu — 44pt touch target (not gesture-only)
            Menu {
                Button { onEdit() } label: {
                    Label("Edit", systemImage: "pencil")
                }
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Visit options")
        }
        .padding(.vertical, 4)
        .frame(minHeight: 44)
    }

    private var displayedVisitType: String {
        if visit.visitType == VisitType.other.rawValue,
           let label = visit.visitTypeLabel,
           !label.isEmpty {
            return label
        }
        return VisitType(rawValue: visit.visitType)?.displayName ?? visit.visitType
    }
}

// MARK: - Previews

#Preview("VisitCard — Full") {
    let visit = Visit(
        date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
        doctorName: "Dr. Sarah Chen",
        visitType: "physical",
        notes: "Annual checkup. Blood panel ordered. Follow up in 3 months to review A1C."
    )
    return List {
        VisitCard(visit: visit, onEdit: {}, onDelete: {})
    }
    .listStyle(.insetGrouped)
}

#Preview("VisitCard — Minimal") {
    let visit = Visit(
        date: Date(),
        doctorName: "Dr. James Park",
        visitType: "specialist"
    )
    return List {
        VisitCard(visit: visit, onEdit: {}, onDelete: {})
    }
    .listStyle(.insetGrouped)
}

#Preview("VisitCard — Large Text") {
    let visit = Visit(
        date: Date(),
        doctorName: "Dr. Sarah Chen",
        visitType: "labWork",
        notes: "Fasting blood draw. Results in 2–3 days."
    )
    return List {
        VisitCard(visit: visit, onEdit: {}, onDelete: {})
    }
    .listStyle(.insetGrouped)
    .dynamicTypeSize(.accessibility2)
}
