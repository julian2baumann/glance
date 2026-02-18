import Foundation

/// Drives the batch entry form. Holds one row per tracked marker, runs
/// the same per-field validation chain as EntryViewModel (plausible range →
/// 10x outlier → duplicate), presenting alerts sequentially.
@Observable
@MainActor
final class BatchEntryViewModel {

    // MARK: - Row State

    struct MarkerRow: Identifiable {
        var id: UUID { userMarker.id }
        let userMarker: UserMarker
        var valueText: String = ""
        var unit: String
    }

    // MARK: - Form State

    var rows: [MarkerRow] = []
    var dateOfService: Date = Date()
    var batchSaved: Bool = false

    // MARK: - Alert State (one alert shown at a time)

    var showPlausibleRangeAlert: Bool = false
    var plausibleRangeMessage: String = ""

    var showOutlierAlert: Bool = false
    var outlierSuggestion: Double? = nil

    var showDuplicateAlert: Bool = false
    var duplicateMessage: String = ""

    // Index of the row whose alert is currently displayed
    private(set) var alertRowIndex: Int = 0

    // MARK: - Queue

    private var pendingIndices: [Int] = []
    private var confirmedIndices: [Int] = []

    // MARK: - Computed

    var hasAnyValue: Bool {
        rows.contains { Double($0.valueText) != nil }
    }

    var outlierAlertTitle: String {
        if let s = outlierSuggestion {
            return "Did you mean \(formatValue(s))?"
        }
        return "Unusual Value"
    }

    // MARK: - Dependencies

    private let repository: LocalDataRepository

    // MARK: - Init

    init(repository: LocalDataRepository) {
        self.repository = repository
        loadRows()
    }

    private func loadRows() {
        let markers = repository.getTrackedMarkers()
        rows = markers.map { marker in
            MarkerRow(
                userMarker: marker,
                unit: marker.markerDefinition?.defaultUnit ?? ""
            )
        }
    }

    // MARK: - Save Flow

    /// Entry point: build the validation queue from all rows with parseable values.
    func save() {
        let valuedIndices = rows.indices.filter { Double(rows[$0].valueText) != nil }
        guard !valuedIndices.isEmpty else { return }
        pendingIndices = Array(valuedIndices)
        confirmedIndices = []
        processNextInQueue()
    }

    /// Called when user confirms "Save Anyway" on any alert for the current row.
    func confirmCurrent() {
        confirmedIndices.append(alertRowIndex)
        processNextInQueue()
    }

    /// Called when user taps "Skip This Marker" on any alert — row is not saved.
    func skipCurrent() {
        processNextInQueue()
    }

    /// Applies the outlier suggestion value to the current row's text field.
    func useOutlierSuggestion() {
        if let s = outlierSuggestion {
            rows[alertRowIndex].valueText = formatValue(s)
        }
    }

    // MARK: - Private

    private func processNextInQueue() {
        guard !pendingIndices.isEmpty else {
            performBatchSave()
            return
        }
        let idx = pendingIndices.removeFirst()
        validateRow(at: idx)
    }

    private func validateRow(at idx: Int) {
        let row = rows[idx]
        guard let value = Double(row.valueText) else {
            processNextInQueue()
            return
        }

        alertRowIndex = idx
        let marker = row.userMarker
        let definition = marker.markerDefinition

        // 1. Plausible range check (system-defined markers only)
        if definition?.isSystemDefined == true,
           let plausibleMin = definition?.plausibleMin,
           let plausibleMax = definition?.plausibleMax {
            if value < plausibleMin || value > plausibleMax {
                let name = definition?.displayName ?? "this marker"
                let unit = row.unit
                let formatted = formatValue(value)
                if value < plausibleMin {
                    plausibleRangeMessage = "You entered \(name) of \(formatted) \(unit). This seems unusually low — would you like to double-check?"
                } else {
                    plausibleRangeMessage = "You entered \(name) of \(formatted) \(unit). This seems unusually high — would you like to double-check?"
                }
                showPlausibleRangeAlert = true
                return
            }
        }

        // 2. 10x outlier check (only if ≥3 existing entries)
        let existingEntries = repository.getEntries(for: marker, in: nil)
        if existingEntries.count >= 3 {
            let avgValue = existingEntries.map(\.value).reduce(0, +) / Double(existingEntries.count)
            if avgValue > 0 {
                let ratio = value / avgValue
                if ratio > 8 || ratio < 0.12 {
                    outlierSuggestion = avgValue
                    showOutlierAlert = true
                    return
                }
            }
        }

        // 3. Duplicate check (same value + same date)
        let dateStart = Calendar.current.startOfDay(for: dateOfService)
        let hasDuplicate = existingEntries.contains { entry in
            let entryDay = Calendar.current.startOfDay(for: entry.dateOfService)
            return abs(entry.value - value) < 0.001 && entryDay == dateStart
        }
        if hasDuplicate {
            let name = definition?.displayName ?? "this marker"
            let formatted = formatValue(value)
            duplicateMessage = "You already have a \(name) entry of \(formatted) for this date."
            showDuplicateAlert = true
            return
        }

        // All checks passed
        confirmedIndices.append(idx)
        processNextInQueue()
    }

    private func performBatchSave() {
        for idx in confirmedIndices {
            let row = rows[idx]
            guard let value = Double(row.valueText) else { continue }
            let entry = MarkerEntry(
                userMarker: row.userMarker,
                value: value,
                unit: row.unit,
                dateOfService: dateOfService,
                note: nil,
                sourceType: "batchEntry"
            )
            repository.addEntry(entry)
        }
        if !confirmedIndices.isEmpty {
            batchSaved = true
        }
    }

    private func formatValue(_ value: Double) -> String {
        value.truncatingRemainder(dividingBy: 1) == 0
            ? String(Int(value))
            : String(format: "%.1f", value)
    }
}
