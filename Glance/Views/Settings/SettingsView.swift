import SwiftUI
import UIKit

/// Settings screen: manage tracked markers (reorder, remove, edit reference ranges),
/// toggle biometric lock, export health data, and view the privacy policy.
struct SettingsView: View {

    let repository: LocalDataRepository
    @State private var viewModel: SettingsViewModel

    init(repository: LocalDataRepository) {
        self.repository = repository
        _viewModel = State(wrappedValue: SettingsViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            List {
                markersSection
                securitySection
                dataSection
                aboutSection
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    EditButton()
                }
            }
            // Reference range editor sheet
            .sheet(item: $viewModel.markerToEditRange) { marker in
                ReferenceRangeEditorView(marker: marker, repository: repository) {
                    viewModel.load()
                }
            }
            // Delete marker confirmation
            .confirmationDialog(
                "Remove Marker",
                isPresented: $viewModel.showDeleteMarkerConfirm,
                titleVisibility: .visible
            ) {
                if let m = viewModel.deleteMarkerToConfirm {
                    Button(
                        "Remove \(m.markerDefinition?.displayName ?? "Marker")",
                        role: .destructive
                    ) {
                        viewModel.removeMarker(m)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete all readings for this marker. This action cannot be undone.")
            }
            // Export security notice
            .alert("Export Health Data", isPresented: $viewModel.showExportSecurityNotice) {
                Button("Export") { viewModel.confirmExport() }
                Button("Cancel", role: .cancel) { viewModel.pendingExportType = nil }
            } message: {
                Text("This file contains your health information. Store it securely and only share with trusted recipients.")
            }
            // Share sheet (JSON or CSV)
            .sheet(item: $viewModel.exportFile) { file in
                ShareSheet(url: file.url)
                    .ignoresSafeArea()
            }
        }
        .onAppear { viewModel.load() }
    }

    // MARK: - Sections

    private var markersSection: some View {
        Section("Markers") {
            ForEach(viewModel.trackedMarkers) { marker in
                Button {
                    viewModel.markerToEditRange = marker
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(marker.markerDefinition?.displayName ?? "—")
                                .font(.body)
                                .foregroundStyle(.primary)
                            Text(referenceRangeLabel(for: marker))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
            }
            .onMove { from, to in
                viewModel.moveMarker(from: from, to: to)
            }
            .onDelete { indices in
                if let idx = indices.first {
                    viewModel.deleteMarkerToConfirm = viewModel.trackedMarkers[idx]
                    viewModel.showDeleteMarkerConfirm = true
                }
            }
        }
    }

    private var securitySection: some View {
        Section("Security") {
            Toggle("Face ID / Touch ID", isOn: $viewModel.biometricLockEnabled)
                .frame(minHeight: 44)
                .onChange(of: viewModel.biometricLockEnabled) { _, enabled in
                    viewModel.updateBiometricLock(enabled)
                }
        }
    }

    private var dataSection: some View {
        Section("Data") {
            Button("Export as JSON") {
                viewModel.exportJSON()
            }
            .frame(minHeight: 44)

            Button("Export as CSV") {
                viewModel.exportCSV()
            }
            .frame(minHeight: 44)
        }
    }

    private var aboutSection: some View {
        Section("About") {
            NavigationLink("Privacy Policy") {
                PrivacyPolicyView()
            }
            .frame(minHeight: 44)
        }
    }

    // MARK: - Helpers

    private func referenceRangeLabel(for marker: UserMarker) -> String {
        let isCustom = marker.customReferenceLow != nil || marker.customReferenceHigh != nil
        let low = marker.customReferenceLow ?? marker.markerDefinition?.defaultReferenceLow
        let high = marker.customReferenceHigh ?? marker.markerDefinition?.defaultReferenceHigh
        let unit = marker.markerDefinition?.defaultUnit ?? ""

        let prefix = isCustom ? "Custom: " : ""

        switch (low, high) {
        case let (l?, h?):
            return "\(prefix)\(fmt(l))–\(fmt(h)) \(unit)"
        case (nil, let h?):
            return "\(prefix)Max \(fmt(h)) \(unit)"
        case (let l?, nil):
            return "\(prefix)Min \(fmt(l)) \(unit)"
        default:
            return "No range set"
        }
    }

    private func fmt(_ v: Double) -> String {
        v.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(v)) : String(format: "%.1f", v)
    }
}

// MARK: - Privacy Policy View

private struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Glance is designed with your privacy as the top priority.")
                    .font(.body)

                VStack(alignment: .leading, spacing: 10) {
                    BulletRow("We collect no personal data.")
                    BulletRow("We transmit no data to any server.")
                    BulletRow("Everything stays on your device.")
                    BulletRow("Your health information is stored locally in an encrypted iOS app container.")
                    BulletRow("You can export your data at any time using the Export feature in Settings.")
                    BulletRow("You can delete all data by deleting the app.")
                }

                Text("No third-party analytics, advertising, or tracking SDKs are used.")
                    .font(.body)

                Text("Last updated: February 2026")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct BulletRow: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•").font(.body)
            Text(text).font(.body)
        }
    }
}

// MARK: - Share Sheet

/// Thin wrapper around UIActivityViewController for sharing files.
struct ShareSheet: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}

// MARK: - Previews

#Preview("Settings — Default") {
    let data = PreviewData()
    SettingsView(repository: data.repository)
        .modelContainer(data.container)
}

#Preview("Settings — Large Text") {
    let data = PreviewData()
    SettingsView(repository: data.repository)
        .modelContainer(data.container)
        .dynamicTypeSize(.accessibility2)
}

#Preview("Settings — iPhone SE") {
    let data = PreviewData()
    SettingsView(repository: data.repository)
        .modelContainer(data.container)
        .previewDevice("iPhone SE (3rd generation)")
}
