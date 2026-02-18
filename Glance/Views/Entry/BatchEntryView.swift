import SwiftUI

/// Full-screen sheet for entering a lab panel — one date applies to all fields.
/// Each tracked marker gets its own numeric input; empty fields are not saved.
struct BatchEntryView: View {

    let repository: LocalDataRepository
    let onSave: () -> Void

    @State private var viewModel: BatchEntryViewModel
    @Environment(\.dismiss) private var dismiss

    init(repository: LocalDataRepository, onSave: @escaping () -> Void) {
        self.repository = repository
        self.onSave = onSave
        _viewModel = State(wrappedValue: BatchEntryViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Single date for the entire panel
                Section {
                    DatePicker(
                        "Date of Service",
                        selection: $viewModel.dateOfService,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                } header: {
                    Text("Panel Date")
                }

                // One section per tracked marker
                if viewModel.rows.isEmpty {
                    Section {
                        Text("No markers tracked yet. Add markers in Settings.")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ForEach(viewModel.rows.indices, id: \.self) { idx in
                        Section {
                            HStack(alignment: .center, spacing: 12) {
                                TextField("—", text: $viewModel.rows[idx].valueText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                                    .frame(minHeight: 44)
                                    .accessibilityLabel(
                                        viewModel.rows[idx].userMarker.markerDefinition?.displayName ?? "Value"
                                    )

                                if !viewModel.rows[idx].unit.isEmpty {
                                    Text(viewModel.rows[idx].unit)
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Text(viewModel.rows[idx].userMarker.markerDefinition?.displayName ?? "Marker")
                        }
                    }
                }
            }
            .navigationTitle("Add Lab Panel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.hasAnyValue)
                    .fontWeight(.semibold)
                }
            }
        }
        .onChange(of: viewModel.batchSaved) { _, saved in
            if saved {
                onSave()
                dismiss()
            }
        }
        // Plausible range alert
        .alert("Unusual Value", isPresented: $viewModel.showPlausibleRangeAlert) {
            Button("Save Anyway") { viewModel.confirmCurrent() }
            Button("Skip This Marker", role: .cancel) { viewModel.skipCurrent() }
        } message: {
            Text(viewModel.plausibleRangeMessage)
        }
        // Outlier alert
        .alert(
            viewModel.outlierAlertTitle,
            isPresented: $viewModel.showOutlierAlert
        ) {
            if let s = viewModel.outlierSuggestion {
                Button("Use \(formatValue(s))") {
                    viewModel.useOutlierSuggestion()
                    viewModel.confirmCurrent()
                }
            }
            Button("Save Anyway") { viewModel.confirmCurrent() }
            Button("Skip This Marker", role: .cancel) { viewModel.skipCurrent() }
        } message: {
            Text("The value you entered looks like it might be off by a factor of 10.")
        }
        // Duplicate alert
        .alert("Duplicate Entry", isPresented: $viewModel.showDuplicateAlert) {
            Button("Add Anyway") { viewModel.confirmCurrent() }
            Button("Skip This Marker", role: .cancel) { viewModel.skipCurrent() }
        } message: {
            Text(viewModel.duplicateMessage)
        }
    }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Previews

#Preview("Batch Entry — Default") {
    let data = PreviewData()
    BatchEntryView(repository: data.repository) { }
        .modelContainer(data.container)
}

#Preview("Batch Entry — Large Text") {
    let data = PreviewData()
    BatchEntryView(repository: data.repository) { }
        .modelContainer(data.container)
        .dynamicTypeSize(.accessibility2)
}

#Preview("Batch Entry — iPhone SE") {
    let data = PreviewData()
    BatchEntryView(repository: data.repository) { }
        .modelContainer(data.container)
        .previewDevice("iPhone SE (3rd generation)")
}
