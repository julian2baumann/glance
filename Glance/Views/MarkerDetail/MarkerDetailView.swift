import SwiftUI

/// Detail view for a single tracked marker: chart, status, and entry history.
struct MarkerDetailView: View {

    let userMarker: UserMarker
    let repository: LocalDataRepository
    @State private var viewModel: MarkerDetailViewModel

    init(userMarker: UserMarker, repository: LocalDataRepository) {
        self.userMarker = userMarker
        self.repository = repository
        _viewModel = State(wrappedValue: MarkerDetailViewModel(userMarker: userMarker, repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Hero: Trend Chart
                chartSection

                // Status + reference range
                statusSection
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Entry list
                entryListSection
                    .padding(.top, 8)
            }
        }
        .background(Color("AppBackground"))
        .navigationTitle(userMarker.markerDefinition?.displayName ?? "Marker")
        .navigationBarTitleDisplayMode(.large)
        .toolbar { toolbarContent }
        .sheet(isPresented: $viewModel.isShowingAddEntry, onDismiss: {
            viewModel.load()
        }) {
            QuickAddView(repository: repository, preselectedMarker: userMarker) {
                viewModel.load()
            }
        }
        .sheet(item: $viewModel.entryToEdit) { entry in
            EditEntryView(entry: entry, repository: repository) {
                viewModel.load()
            }
        }
        .sheet(isPresented: $viewModel.isShowingRangeEditor) {
            ReferenceRangeEditorView(marker: userMarker, repository: repository) {
                viewModel.load()
            }
        }
    }

    // MARK: - Chart Section

    @ViewBuilder
    private var chartSection: some View {
        let chartEntries = viewModel.entriesForChart

        if chartEntries.isEmpty {
            // 0 entries empty state
            VStack(spacing: 12) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("No readings yet")
                    .font(.headline)
                Text("Add your first reading to start tracking your \(userMarker.markerDefinition?.displayName ?? "marker").")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                Button("Add First Reading") {
                    viewModel.isShowingAddEntry = true
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
            .padding(.horizontal, 16)

        } else if chartEntries.count == 1 {
            // 1 entry state
            VStack(spacing: 8) {
                TrendChart(entries: chartEntries, userMarker: userMarker)
                    .frame(height: 180)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Text("Add another reading to start seeing your trend.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
            }
        } else {
            // 2+ entries: full chart
            TrendChart(entries: chartEntries, userMarker: userMarker)
                .frame(height: 220)
                .padding(.horizontal, 16)
                .padding(.top, 12)
        }
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        if viewModel.status != .noData {
            HStack(spacing: 12) {
                StatusBadge(status: viewModel.status, size: .full)

                Spacer()

                // Reference range display
                if let low = repository.getCategories().isEmpty ? nil : effectiveLow,
                   let high = effectiveHigh {
                    Text("Range: \(formatVal(low))–\(formatVal(high)) \(userMarker.markerDefinition?.defaultUnit ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let low = effectiveLow {
                    Text("Min: \(formatVal(low)) \(userMarker.markerDefinition?.defaultUnit ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let high = effectiveHigh {
                    Text("Max: \(formatVal(high)) \(userMarker.markerDefinition?.defaultUnit ?? "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(12)
            .background(Color("CardBackground"), in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var effectiveLow: Double? {
        userMarker.customReferenceLow ?? userMarker.markerDefinition?.defaultReferenceLow
    }

    private var effectiveHigh: Double? {
        userMarker.customReferenceHigh ?? userMarker.markerDefinition?.defaultReferenceHigh
    }

    private func formatVal(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }

    // MARK: - Entry List

    private var entryListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !viewModel.entries.isEmpty {
                Text("Readings")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            ForEach(viewModel.entries) { entry in
                EntryRow(
                    entry: entry,
                    onEdit: { viewModel.entryToEdit = entry },
                    onDelete: {
                        viewModel.deleteEntry(entry)
                    }
                )
                .padding(.horizontal, 16)

                Divider()
                    .padding(.leading, 16)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                viewModel.isShowingAddEntry = true
            } label: {
                Label("Add Reading", systemImage: "plus")
            }
        }
        ToolbarItem(placement: .secondaryAction) {
            Button {
                viewModel.isShowingRangeEditor = true
            } label: {
                Label("Edit Range", systemImage: "slider.horizontal.3")
            }
        }
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: MarkerEntry
    let onEdit: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    var body: some View {
        HStack(spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.dateOfService.formatted(date: .abbreviated, time: .omitted))
                    .font(.body)
                if let note = entry.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Value
            Text(formattedValue)
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)

            // Actions
            Menu {
                Button("Edit", action: onEdit)
                Button("Delete", role: .destructive) {
                    showDeleteConfirm = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.vertical, 10)
        .frame(minHeight: 44)
        .confirmationDialog(
            "Delete Reading",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete \(formattedValue) from \(entry.dateOfService.formatted(date: .abbreviated, time: .omitted))", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(formattedValue), \(entry.dateOfService.formatted(date: .abbreviated, time: .omitted))")
    }

    private var formattedValue: String {
        let v = entry.value
        let num = v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
        return "\(num) \(entry.unit)"
    }
}

// MARK: - Edit Entry View

struct EditEntryView: View {
    let entry: MarkerEntry
    let repository: LocalDataRepository
    let onSave: () -> Void

    @State private var valueText: String
    @State private var dateOfService: Date
    @State private var note: String
    @Environment(\.dismiss) private var dismiss

    init(entry: MarkerEntry, repository: LocalDataRepository, onSave: @escaping () -> Void) {
        self.entry = entry
        self.repository = repository
        self.onSave = onSave
        _valueText = State(initialValue: {
            let v = entry.value
            return v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
        }())
        _dateOfService = State(initialValue: entry.dateOfService)
        _note = State(initialValue: entry.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Value") {
                    HStack {
                        TextField("Value", text: $valueText)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                        Text(entry.unit)
                            .foregroundStyle(.secondary)
                    }
                }

                DatePicker("Date", selection: $dateOfService,
                           in: ...Date(), displayedComponents: .date)

                TextField("Note (optional)", text: $note, axis: .vertical)
                    .lineLimit(2...4)
            }
            .navigationTitle("Edit Reading")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(Double(valueText) == nil)
                }
            }
        }
    }

    private func save() {
        guard let value = Double(valueText) else { return }
        entry.value = value
        entry.dateOfService = dateOfService
        entry.note = note.isEmpty ? nil : note
        repository.updateEntry(entry)
        onSave()
        dismiss()
    }
}

// MARK: - Previews

#Preview("Detail — Many Entries") {
    let data = PreviewData()
    NavigationStack {
        MarkerDetailView(userMarker: data.hdlMarker, repository: data.repository)
    }
    .modelContainer(data.container)
}

#Preview("Detail — Out of Range") {
    let data = PreviewData()
    NavigationStack {
        MarkerDetailView(userMarker: data.a1cMarker, repository: data.repository)
    }
    .modelContainer(data.container)
}

#Preview("Detail — No Entries") {
    let data = PreviewData()
    NavigationStack {
        MarkerDetailView(userMarker: data.glucoseMarker, repository: data.repository)
    }
    .modelContainer(data.container)
}

#Preview("Detail — Large Text") {
    let data = PreviewData()
    NavigationStack {
        MarkerDetailView(userMarker: data.hdlMarker, repository: data.repository)
    }
    .modelContainer(data.container)
    .dynamicTypeSize(.accessibility2)
}
