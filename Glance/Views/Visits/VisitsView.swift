import SwiftUI

// MARK: - Visit Type Enum

enum VisitType: String, CaseIterable {
    case physical
    case dental
    case vision
    case specialist
    case labWork
    case imaging
    case other

    var displayName: String {
        switch self {
        case .physical:   return "Physical"
        case .dental:     return "Dental"
        case .vision:     return "Vision"
        case .specialist: return "Specialist"
        case .labWork:    return "Lab Work"
        case .imaging:    return "Imaging"
        case .other:      return "Other"
        }
    }
}

// MARK: - VisitsView

struct VisitsView: View {

    let repository: LocalDataRepository
    @State private var viewModel: VisitsViewModel

    init(repository: LocalDataRepository) {
        self.repository = repository
        _viewModel = State(wrappedValue: VisitsViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            listContent
                .navigationTitle("Visits")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            viewModel.isShowingAddVisit = true
                        } label: {
                            Image(systemName: "plus")
                        }
                        .accessibilityLabel("Log visit")
                    }
                }
                .sheet(isPresented: $viewModel.isShowingAddVisit, onDismiss: { viewModel.load() }) {
                    AddVisitView(repository: repository, existingVisit: nil) {
                        viewModel.load()
                    }
                }
                .sheet(item: $viewModel.visitToEdit, onDismiss: { viewModel.load() }) { visit in
                    AddVisitView(repository: repository, existingVisit: visit) {
                        viewModel.load()
                    }
                }
                .confirmationDialog(
                    "Delete Visit",
                    isPresented: $viewModel.showDeleteConfirm,
                    titleVisibility: .visible
                ) {
                    if let v = viewModel.visitToDelete {
                        Button("Delete Visit", role: .destructive) {
                            viewModel.deleteVisit(v)
                        }
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This will permanently remove this visit record.")
                }
        }
    }

    // MARK: - List Content

    @ViewBuilder
    private var listContent: some View {
        if viewModel.visits.isEmpty && !viewModel.hasInsights {
            emptyState
        } else {
            List {
                // Next Visit Prep — only shown when insights exist (never an empty card)
                if viewModel.hasInsights {
                    Section("Next Visit Prep") {
                        ForEach(viewModel.insights) { insight in
                            NavigationLink {
                                MarkerDetailView(userMarker: insight.userMarker, repository: repository)
                                    .onDisappear { viewModel.load() }
                            } label: {
                                InsightCard(insight: insight)
                            }
                        }
                    }
                }

                // Visit list — newest first (repository returns sorted)
                if !viewModel.visits.isEmpty {
                    Section {
                        ForEach(viewModel.visits) { visit in
                            VisitCard(visit: visit) {
                                viewModel.visitToEdit = visit
                            } onDelete: {
                                viewModel.visitToDelete = visit
                                viewModel.showDeleteConfirm = true
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        ContentUnavailableView(
            "No Visits Yet",
            systemImage: "calendar.badge.plus",
            description: Text("Log your first visit after your next appointment.\nYou can also log past visits to build a richer history.")
        )
    }
}

// MARK: - Add/Edit Visit

private struct AddVisitView: View {

    let repository: LocalDataRepository
    let existingVisit: Visit?
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var date: Date
    @State private var doctorName: String
    @State private var visitType: VisitType
    @State private var visitTypeLabel: String
    @State private var notes: String

    init(repository: LocalDataRepository, existingVisit: Visit?, onSave: @escaping () -> Void) {
        self.repository = repository
        self.existingVisit = existingVisit
        self.onSave = onSave
        _date = State(initialValue: existingVisit?.date ?? Date())
        _doctorName = State(initialValue: existingVisit?.doctorName ?? "")
        _visitType = State(initialValue: VisitType(rawValue: existingVisit?.visitType ?? "") ?? .physical)
        _visitTypeLabel = State(initialValue: existingVisit?.visitTypeLabel ?? "")
        _notes = State(initialValue: existingVisit?.notes ?? "")
    }

    var isEditing: Bool { existingVisit != nil }
    var canSave: Bool { !doctorName.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // Visits CAN have future dates (unlike marker entries)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Doctor / Clinic Name", text: $doctorName)
                }

                Section("Visit Type") {
                    Picker("Type", selection: $visitType) {
                        ForEach(VisitType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.menu)

                    if visitType == .other {
                        TextField("Describe visit type", text: $visitTypeLabel)
                    }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                }
            }
            .navigationTitle(isEditing ? "Edit Visit" : "Log Visit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        if let existing = existingVisit {
            existing.date = date
            existing.doctorName = doctorName.trimmingCharacters(in: .whitespaces)
            existing.visitType = visitType.rawValue
            existing.visitTypeLabel = visitType == .other ? visitTypeLabel.trimmingCharacters(in: .whitespaces) : nil
            existing.notes = notes.isEmpty ? nil : notes
            repository.updateVisit(existing)
        } else {
            let visit = Visit(
                date: date,
                doctorName: doctorName.trimmingCharacters(in: .whitespaces),
                visitType: visitType.rawValue,
                visitTypeLabel: visitType == .other ? visitTypeLabel.trimmingCharacters(in: .whitespaces) : nil,
                notes: notes.isEmpty ? nil : notes
            )
            repository.addVisit(visit)
        }
        onSave()
        dismiss()
    }
}

// MARK: - Previews

#Preview("Visits — With Data") {
    let data = PreviewData()
    // Add sample visits to the preview repository
    let visit1 = Visit(
        date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!,
        doctorName: "Dr. Sarah Chen",
        visitType: "physical",
        notes: "Annual checkup. Blood panel ordered. Follow up in 3 months."
    )
    let visit2 = Visit(
        date: Calendar.current.date(byAdding: .day, value: -60, to: Date())!,
        doctorName: "Dr. James Park",
        visitType: "specialist",
        notes: "Cardiology consultation."
    )
    data.repository.addVisit(visit1)
    data.repository.addVisit(visit2)
    return VisitsView(repository: data.repository)
        .modelContainer(data.container)
}

#Preview("Visits — Empty") {
    let data = PreviewData()
    return VisitsView(repository: data.repository)
        .modelContainer(data.container)
}

#Preview("Visits — Large Text") {
    let data = PreviewData()
    let visit = Visit(
        date: Date(),
        doctorName: "Dr. Sarah Chen",
        visitType: "physical",
        notes: "Annual checkup. Blood panel ordered."
    )
    data.repository.addVisit(visit)
    return VisitsView(repository: data.repository)
        .modelContainer(data.container)
        .dynamicTypeSize(.accessibility2)
}
