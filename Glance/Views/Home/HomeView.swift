import SwiftUI
import SwiftData

/// Markers tab root — shows all tracked markers as compact rows.
struct HomeView: View {

    let repository: LocalDataRepository
    @State private var viewModel: HomeViewModel

    init(repository: LocalDataRepository) {
        self.repository = repository
        _viewModel = State(wrappedValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                listContent
                quickAddButton
            }
            .navigationTitle("My Markers")
            .searchable(text: $viewModel.searchQuery, prompt: "Search markers")
            .onChange(of: viewModel.searchQuery) { _, _ in
                viewModel.updateSearch()
            }
            .sheet(isPresented: $viewModel.isShowingQuickAdd, onDismiss: {
                viewModel.refresh()
            }) {
                QuickAddView(repository: repository) {
                    viewModel.refresh()
                }
            }
            .sheet(isPresented: $viewModel.isShowingBatchEntry, onDismiss: {
                viewModel.refresh()
            }) {
                BatchEntryView(repository: repository) {
                    viewModel.refresh()
                }
            }
        }
    }

    // MARK: - List

    @ViewBuilder
    private var listContent: some View {
        if viewModel.isSearching {
            searchResultsList
        } else if viewModel.trackedMarkers.isEmpty {
            emptyState
        } else {
            trackedMarkersList
        }
    }

    private var trackedMarkersList: some View {
        List {
            ForEach(viewModel.trackedMarkers) { userMarker in
                NavigationLink {
                    MarkerDetailView(userMarker: userMarker, repository: repository)
                        .onDisappear { viewModel.refresh() }
                } label: {
                    MarkerRow(
                        userMarker: userMarker,
                        status: viewModel.status(for: userMarker),
                        trend: viewModel.trend(for: userMarker),
                        latestEntry: viewModel.latestEntry(for: userMarker),
                        higherIsBetter: userMarker.markerDefinition?.higherIsBetter ?? false
                    )
                }
            }
        }
        .listStyle(.plain)
    }

    private var searchResultsList: some View {
        List {
            // Tracked markers matching search
            if !viewModel.searchResults.trackedMarkers.isEmpty {
                Section("Tracked") {
                    ForEach(viewModel.searchResults.trackedMarkers) { userMarker in
                        NavigationLink {
                            MarkerDetailView(userMarker: userMarker, repository: repository)
                                .onDisappear { viewModel.refresh() }
                        } label: {
                            MarkerRow(
                                userMarker: userMarker,
                                status: viewModel.status(for: userMarker),
                                trend: viewModel.trend(for: userMarker),
                                latestEntry: viewModel.latestEntry(for: userMarker),
                                higherIsBetter: userMarker.markerDefinition?.higherIsBetter ?? false
                            )
                        }
                    }
                }
            }

            // Untracked library markers matching search
            if !viewModel.searchResults.untrackedDefinitions.isEmpty {
                Section("Add to Tracking") {
                    ForEach(viewModel.searchResults.untrackedDefinitions) { definition in
                        UntrackedDefinitionRow(definition: definition) {
                            let _ = repository.addTrackedMarker(definition)
                            viewModel.searchQuery = ""
                            viewModel.refresh()
                        }
                    }
                }
            }

            // No results
            if viewModel.searchResults.trackedMarkers.isEmpty &&
               viewModel.searchResults.untrackedDefinitions.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchQuery)
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Markers Yet",
            systemImage: "heart.text.square",
            description: Text("Add the health markers you want to track.")
        )
    }

    // MARK: - Quick Add / Batch Entry FAB (Menu)

    private var quickAddButton: some View {
        Menu {
            Button {
                viewModel.isShowingQuickAdd = true
            } label: {
                Label("Quick Add", systemImage: "plus.circle")
            }

            Button {
                viewModel.isShowingBatchEntry = true
            } label: {
                Label("Add Lab Panel", systemImage: "list.bullet.clipboard")
            }
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.accentColor, in: Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
        }
        .padding(.trailing, 20)
        .padding(.bottom, 20)
        .accessibilityLabel("Add reading")
    }
}

// MARK: - Untracked Definition Row

private struct UntrackedDefinitionRow: View {
    let definition: MarkerDefinition
    let onAdd: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(definition.displayName)
                    .font(.body)
                if let cat = definition.category?.name {
                    Text(cat)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Button("Add", action: onAdd)
                .font(.subheadline.weight(.medium))
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityLabel("Add \(definition.displayName)")
        }
        .frame(minHeight: 44)
    }
}

// MARK: - Previews

#Preview("Home — With Markers") {
    let data = PreviewData()
    HomeView(repository: data.repository)
        .modelContainer(data.container)
}

#Preview("Home — Empty State") {
    let schema = Schema([
        Profile.self, MarkerCategory.self, MarkerDefinition.self,
        UserMarker.self, MarkerEntry.self, Visit.self
    ])
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: schema, configurations: config)
    let repo = LocalDataRepository(context: container.mainContext)
    HomeView(repository: repo)
        .modelContainer(container)
}

#Preview("Home — Large Text") {
    let data = PreviewData()
    HomeView(repository: data.repository)
        .modelContainer(data.container)
        .dynamicTypeSize(.accessibility2)
}
