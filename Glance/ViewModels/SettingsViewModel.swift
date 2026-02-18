import Foundation

/// Wraps a URL for presentation via .sheet(item:), which requires Identifiable.
struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

/// Drives the Settings screen: marker management, reference range saves,
/// biometric lock toggle, and data export.
@Observable
@MainActor
final class SettingsViewModel {

    // MARK: - Marker Management

    var trackedMarkers: [UserMarker] = []
    var markerToEditRange: UserMarker? = nil
    var deleteMarkerToConfirm: UserMarker? = nil
    var showDeleteMarkerConfirm: Bool = false

    // MARK: - Security

    var biometricLockEnabled: Bool = false

    // MARK: - Export

    enum ExportType { case json, csv }
    var showExportSecurityNotice: Bool = false
    var pendingExportType: ExportType? = nil
    var exportFile: ExportFile? = nil

    // MARK: - Dependencies

    private let repository: LocalDataRepository

    // MARK: - Init

    init(repository: LocalDataRepository) {
        self.repository = repository
        load()
    }

    // MARK: - Data

    func load() {
        trackedMarkers = repository.getTrackedMarkers()
        biometricLockEnabled = repository.getBiometricLockEnabled()
    }

    // MARK: - Marker Management

    func removeMarker(_ marker: UserMarker) {
        repository.removeTrackedMarker(marker)
        load()
    }

    func moveMarker(from source: IndexSet, to destination: Int) {
        var reordered = trackedMarkers
        reordered.move(fromOffsets: source, toOffset: destination)
        repository.updateMarkerOrder(reordered)
        trackedMarkers = reordered
    }

    // MARK: - Biometric Lock

    func updateBiometricLock(_ enabled: Bool) {
        repository.setBiometricLock(enabled)
    }

    // MARK: - Export

    func exportJSON() {
        pendingExportType = .json
        showExportSecurityNotice = true
    }

    func exportCSV() {
        pendingExportType = .csv
        showExportSecurityNotice = true
    }

    func confirmExport() {
        guard let type = pendingExportType else { return }
        let data: Data
        let filename: String
        switch type {
        case .json:
            data = repository.exportAllData()
            filename = "glance-export.json"
        case .csv:
            data = repository.exportAsCSV()
            filename = "glance-export.csv"
        }
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(filename)
        try? data.write(to: tmpURL)
        exportFile = ExportFile(url: tmpURL)
        pendingExportType = nil
    }
}
