import SwiftUI

/// Sheet for editing a marker's custom reference range.
/// Shows the definition's default range for context, then allows user overrides.
/// Resetting clears both fields and restores the definition defaults.
struct ReferenceRangeEditorView: View {

    let marker: UserMarker
    let repository: LocalDataRepository
    let onSave: () -> Void

    @State private var lowText: String
    @State private var highText: String
    @Environment(\.dismiss) private var dismiss

    init(marker: UserMarker, repository: LocalDataRepository, onSave: @escaping () -> Void) {
        self.marker = marker
        self.repository = repository
        self.onSave = onSave
        _lowText = State(initialValue: marker.customReferenceLow.map { formatVal($0) } ?? "")
        _highText = State(initialValue: marker.customReferenceHigh.map { formatVal($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                // Show definition's default range for reference
                let defLow = marker.markerDefinition?.defaultReferenceLow
                let defHigh = marker.markerDefinition?.defaultReferenceHigh
                let unit = marker.markerDefinition?.defaultUnit ?? ""

                if defLow != nil || defHigh != nil {
                    Section("Default Range") {
                        if let low = defLow, let high = defHigh {
                            Text("\(formatVal(low))–\(formatVal(high)) \(unit)")
                                .foregroundStyle(.secondary)
                        } else if let high = defHigh {
                            Text("Max \(formatVal(high)) \(unit)")
                                .foregroundStyle(.secondary)
                        } else if let low = defLow {
                            Text("Min \(formatVal(low)) \(unit)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Custom range inputs
                Section("Custom Range") {
                    HStack {
                        Text("Low")
                        Spacer()
                        TextField(defLow.map { formatVal($0) } ?? "None", text: $lowText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    .frame(minHeight: 44)
                    HStack {
                        Text("High")
                        Spacer()
                        TextField(defHigh.map { formatVal($0) } ?? "None", text: $highText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                    }
                    .frame(minHeight: 44)
                }

                // Reset option (only visible when a custom range exists)
                if marker.customReferenceLow != nil || marker.customReferenceHigh != nil {
                    Section {
                        Button("Reset to Default", role: .destructive) {
                            lowText = ""
                            highText = ""
                            save(reset: true)
                        }
                        .frame(minHeight: 44)
                    }
                }
            }
            .navigationTitle(marker.markerDefinition?.displayName ?? "Reference Range")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(reset: false) }
                }
            }
        }
    }

    private func save(reset: Bool) {
        if reset {
            marker.customReferenceLow = nil
            marker.customReferenceHigh = nil
        } else {
            marker.customReferenceLow = Double(lowText)
            marker.customReferenceHigh = Double(highText)
        }
        repository.updateMarker(marker)
        onSave()
        dismiss()
    }
}

// MARK: - Previews

#Preview("Reference Range — With Defaults") {
    let data = PreviewData()
    ReferenceRangeEditorView(marker: data.hdlMarker, repository: data.repository) { }
        .modelContainer(data.container)
}

#Preview("Reference Range — No Defaults") {
    let data = PreviewData()
    // Glucose marker has no custom range set
    ReferenceRangeEditorView(marker: data.glucoseMarker, repository: data.repository) { }
        .modelContainer(data.container)
}

// MARK: - Private Helpers

private func formatVal(_ v: Double) -> String {
    v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
}
