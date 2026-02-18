import Foundation
import SwiftData

@Observable
@MainActor
final class EntryViewModel {

    // MARK: - Form State

    var selectedMarker: UserMarker?
    var valueText: String = ""
    var dateOfService: Date = Date()
    var note: String = ""
    var entrySaved: Bool = false

    // MARK: - Validation Alerts

    var showPlausibleRangeAlert: Bool = false
    var plausibleRangeMessage: String = ""
    var showOutlierAlert: Bool = false
    var outlierSuggestion: Double? = nil
    var outlierOriginalValue: Double? = nil
    var showDuplicateAlert: Bool = false

    // MARK: - Derived

    var parsedValue: Double? { Double(valueText) }

    var canSave: Bool {
        selectedMarker != nil && parsedValue != nil
    }

    // MARK: - Dependencies

    private let repository: LocalDataRepository

    init(repository: LocalDataRepository, preselectedMarker: UserMarker? = nil) {
        self.repository = repository
        self.selectedMarker = preselectedMarker
    }

    // MARK: - Available Markers

    var availableMarkers: [UserMarker] {
        repository.getTrackedMarkers()
    }

    // MARK: - Save Flow

    func save() {
        guard let marker = selectedMarker, let value = parsedValue else { return }

        // 1. Plausible range check (system-defined markers only)
        if let def = marker.markerDefinition, def.isSystemDefined {
            if let min = def.plausibleMin, value < min {
                plausibleRangeMessage = "You entered \(def.displayName) of \(formatValue(value)) \(def.defaultUnit). This seems unusually low — would you like to double-check?"
                showPlausibleRangeAlert = true
                return
            }
            if let max = def.plausibleMax, value > max {
                plausibleRangeMessage = "You entered \(def.displayName) of \(formatValue(value)) \(def.defaultUnit). This seems unusually high — would you like to double-check?"
                showPlausibleRangeAlert = true
                return
            }
        }

        // 2. 10x outlier check (only if 3+ existing entries for this marker)
        let existingEntries = repository.getEntries(for: marker, in: nil)
        if existingEntries.count >= 3 {
            let values = existingEntries.map(\.value)
            let avgValue = values.reduce(0, +) / Double(values.count)
            if avgValue > 0 {
                let ratio = value / avgValue
                if ratio > 8 || ratio < 0.12 {
                    let suggested = avgValue
                    outlierSuggestion = suggested
                    outlierOriginalValue = value
                    showOutlierAlert = true
                    return
                }
            }
        }

        // 3. Duplicate check
        let sameDate = Calendar.current.startOfDay(for: dateOfService)
        let hasDuplicate = existingEntries.contains { entry in
            entry.value == value &&
            Calendar.current.startOfDay(for: entry.dateOfService) == sameDate
        }
        if hasDuplicate {
            showDuplicateAlert = true
            return
        }

        performSave()
    }

    func confirmSave() {
        performSave()
    }

    private func performSave() {
        guard let marker = selectedMarker, let value = parsedValue else { return }
        let unit = marker.markerDefinition?.defaultUnit ?? ""
        let entry = MarkerEntry(
            userMarker: marker,
            value: value,
            unit: unit,
            dateOfService: dateOfService,
            note: note.isEmpty ? nil : note,
            sourceType: "quickAdd"
        )
        repository.addEntry(entry)
        entrySaved = true
    }

    // MARK: - Formatting

    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
