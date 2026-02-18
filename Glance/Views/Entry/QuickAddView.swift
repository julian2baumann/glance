import SwiftUI

/// Bottom sheet for quickly logging a single marker reading.
/// Pre-selects marker if opened from a detail view.
struct QuickAddView: View {

    let repository: LocalDataRepository
    var preselectedMarker: UserMarker? = nil
    let onSave: () -> Void

    @State private var viewModel: EntryViewModel
    @Environment(\.dismiss) private var dismiss

    init(repository: LocalDataRepository, preselectedMarker: UserMarker? = nil, onSave: @escaping () -> Void) {
        self.repository = repository
        self.preselectedMarker = preselectedMarker
        self.onSave = onSave
        _viewModel = State(wrappedValue: EntryViewModel(repository: repository, preselectedMarker: preselectedMarker))
    }

    var body: some View {
        NavigationStack {
            Form {
                // Marker picker (only when not pre-selected)
                if preselectedMarker == nil {
                    Section("Marker") {
                        Picker("Select Marker", selection: $viewModel.selectedMarker) {
                            Text("Choose...").tag(Optional<UserMarker>(nil))
                            ForEach(viewModel.availableMarkers) { marker in
                                Text(marker.markerDefinition?.displayName ?? "Unknown")
                                    .tag(Optional(marker))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                } else {
                    Section {
                        HStack {
                            Text(preselectedMarker!.markerDefinition?.displayName ?? "")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }

                // Value input
                Section {
                    HStack(alignment: .center, spacing: 12) {
                        TextField("0", text: $viewModel.valueText)
                            .keyboardType(.decimalPad)
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .frame(minHeight: 56)
                            .accessibilityLabel("Value")

                        if let unit = viewModel.selectedMarker?.markerDefinition?.defaultUnit {
                            Text(unit)
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Value")
                }

                // Date
                Section {
                    DatePicker(
                        "Date of Service",
                        selection: $viewModel.dateOfService,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                }

                // Note
                Section {
                    TextField("Note (optional)", text: $viewModel.note, axis: .vertical)
                        .lineLimit(1...4)
                } header: {
                    Text("Note")
                }
            }
            .navigationTitle("Add Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.save()
                    }
                    .disabled(!viewModel.canSave)
                    .fontWeight(.semibold)
                }
            }
        }
        .onChange(of: viewModel.entrySaved) { _, saved in
            if saved {
                onSave()
                dismiss()
            }
        }
        // Plausible range alert
        .alert("Unusual Value", isPresented: $viewModel.showPlausibleRangeAlert) {
            Button("Add Anyway") { viewModel.confirmSave() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(viewModel.plausibleRangeMessage)
        }
        // Outlier alert
        .alert(
            outlierAlertTitle,
            isPresented: $viewModel.showOutlierAlert
        ) {
            if let suggestion = viewModel.outlierSuggestion {
                Button("Use \(formatValue(suggestion))") {
                    viewModel.valueText = formatValue(suggestion)
                    viewModel.confirmSave()
                }
            }
            Button("Keep \(viewModel.valueText)") { viewModel.confirmSave() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("The value you entered looks like it might be off by a factor of 10.")
        }
        // Duplicate alert
        .alert("Duplicate Entry", isPresented: $viewModel.showDuplicateAlert) {
            Button("Add Anyway") { viewModel.confirmSave() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("You already have a \(viewModel.selectedMarker?.markerDefinition?.displayName ?? "marker") entry of \(viewModel.valueText) for this date.")
        }
    }

    private var outlierAlertTitle: String {
        if let suggestion = viewModel.outlierSuggestion {
            return "Did you mean \(formatValue(suggestion))?"
        }
        return "Unusual Value"
    }

    private func formatValue(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Previews

#Preview("Quick Add — No Preselection") {
    let data = PreviewData()
    QuickAddView(repository: data.repository) { }
        .modelContainer(data.container)
}

#Preview("Quick Add — Preselected Marker") {
    let data = PreviewData()
    QuickAddView(repository: data.repository, preselectedMarker: data.hdlMarker) { }
        .modelContainer(data.container)
}

#Preview("Quick Add — Large Text") {
    let data = PreviewData()
    QuickAddView(repository: data.repository) { }
        .modelContainer(data.container)
        .dynamicTypeSize(.accessibility2)
}
