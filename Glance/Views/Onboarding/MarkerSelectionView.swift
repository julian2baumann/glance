import SwiftUI

/// Full-screen marker library browser shown during onboarding.
/// User browses by category or searches by name/alias, selects markers, and taps Done.
struct MarkerSelectionView: View {

    let repository: LocalDataRepository
    let onComplete: () -> Void

    @State private var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    init(repository: LocalDataRepository, onComplete: @escaping () -> Void) {
        self.repository = repository
        self.onComplete = onComplete
        _viewModel = State(wrappedValue: OnboardingViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Main list
                List {
                    ForEach(viewModel.filteredCategories, id: \.0.id) { category, markers in
                        Section(category.name) {
                            ForEach(markers) { definition in
                                MarkerSelectionRow(
                                    definition: definition,
                                    isSelected: viewModel.isSelected(definition)
                                ) {
                                    viewModel.toggleSelection(definition)
                                }
                            }
                        }
                    }

                    // No results state
                    if viewModel.filteredCategories.isEmpty && !viewModel.searchQuery.isEmpty {
                        Section {
                            VStack(spacing: 12) {
                                Text("No markers found for \"\(viewModel.searchQuery)\"")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                Button("Add \"\(viewModel.searchQuery)\" as Custom Marker") {
                                    viewModel.customMarkerName = viewModel.searchQuery
                                    viewModel.isShowingCustomForm = true
                                }
                                .font(.body)
                            }
                            .padding(.vertical, 8)
                        }
                    }

                    // Add Custom Marker button at bottom of list
                    Section {
                        Button {
                            viewModel.isShowingCustomForm = true
                        } label: {
                            Label("Add Custom Marker", systemImage: "plus.circle")
                                .font(.body)
                        }
                    }

                    // Bottom padding for the Done button overlay
                    Color.clear.frame(height: 80)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.insetGrouped)
                .searchable(text: $viewModel.searchQuery, prompt: "Search markers")

                // Sticky Done button
                doneButton
            }
            .navigationTitle("Choose Your Markers")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        onComplete()
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingCustomForm) {
            CustomMarkerFormView(viewModel: viewModel)
        }
    }

    // MARK: - Done Button

    private var doneButton: some View {
        VStack(spacing: 0) {
            Divider()
            Button {
                viewModel.confirmSelection(completion: onComplete)
            } label: {
                Text(doneButtonLabel)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .disabled(viewModel.selectedCount == 0)
            .background(Color("CardBackground"))
        }
    }

    private var doneButtonLabel: String {
        if viewModel.selectedCount == 0 {
            return "Select Markers to Continue"
        }
        return "Done (\(viewModel.selectedCount) selected)"
    }
}

// MARK: - Marker Selection Row

private struct MarkerSelectionRow: View {
    let definition: MarkerDefinition
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(definition.displayName)
                    .font(.body)
                    .foregroundStyle(.primary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(definition.displayName)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Custom Marker Form

private struct CustomMarkerFormView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Marker Name") {
                    TextField("e.g., Cortisol", text: $viewModel.customMarkerName)
                }

                Section("Unit") {
                    TextField("e.g., µg/dL, nmol/L", text: $viewModel.customMarkerUnit)
                }

                Section("Reference Range (Optional)") {
                    HStack {
                        Text("Low")
                        Spacer()
                        TextField("Min", text: $viewModel.customMarkerLowText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                    HStack {
                        Text("High")
                        Spacer()
                        TextField("Max", text: $viewModel.customMarkerHighText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }
            }
            .navigationTitle("Custom Marker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        viewModel.addCustomMarker()
                    }
                    .disabled(!viewModel.canAddCustomMarker)
                }
            }
        }
    }
}

// MARK: - Previews

#Preview("Marker Selection — Default") {
    let data = PreviewData()
    MarkerSelectionView(repository: data.repository) { }
        .modelContainer(data.container)
}

#Preview("Marker Selection — Large Text") {
    let data = PreviewData()
    MarkerSelectionView(repository: data.repository) { }
        .modelContainer(data.container)
        .dynamicTypeSize(.accessibility2)
}

#Preview("Marker Selection — iPhone SE") {
    let data = PreviewData()
    MarkerSelectionView(repository: data.repository) { }
        .modelContainer(data.container)
        .previewDevice("iPhone SE (3rd generation)")
}
