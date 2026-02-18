import SwiftUI

/// Welcome screen shown on first launch.
/// Leads into MarkerSelectionView where the user picks what to track.
struct OnboardingView: View {

    let repository: LocalDataRepository
    let onComplete: () -> Void

    @State private var showingSelection = false

    var body: some View {
        ZStack {
            Color("AppBackground").ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Logo / icon area
                Image(systemName: "stethoscope.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.accentColor)
                    .padding(.bottom, 32)

                // Headline
                Text("Glance")
                    .font(.largeTitle.weight(.bold))
                    .padding(.bottom, 8)

                // Tagline
                Text("Your health numbers,\nalways at a glance.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 48)

                // Feature highlights
                VStack(alignment: .leading, spacing: 16) {
                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Track your lab results over time")
                    FeatureRow(icon: "calendar", text: "Log doctor visits and notes")
                    FeatureRow(icon: "lock.shield", text: "Private — everything stays on your device")
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 48)

                Spacer()

                // CTA Button
                Button {
                    showingSelection = true
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showingSelection) {
            MarkerSelectionView(repository: repository, onComplete: onComplete)
        }
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
                .frame(width: 28)

            Text(text)
                .font(.body)
        }
    }
}

// MARK: - Previews

#Preview("Onboarding — Default") {
    let data = PreviewData()
    OnboardingView(repository: data.repository) { }
        .modelContainer(data.container)
}

#Preview("Onboarding — Large Text") {
    let data = PreviewData()
    OnboardingView(repository: data.repository) { }
        .modelContainer(data.container)
        .dynamicTypeSize(.accessibility2)
}

#Preview("Onboarding — iPhone SE") {
    let data = PreviewData()
    OnboardingView(repository: data.repository) { }
        .modelContainer(data.container)
        .previewDevice("iPhone SE (3rd generation)")
}
