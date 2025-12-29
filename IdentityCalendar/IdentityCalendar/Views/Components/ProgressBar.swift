import SwiftUI

/// Onboarding progress bar
struct OnboardingProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appSecondaryBackground)

                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.appAccent)
                    .frame(width: geometry.size.width * CGFloat(min(1, max(0, progress))))
                    .animation(.easeInOut(duration: 0.3), value: progress)
            }
        }
        .frame(height: Constants.Onboarding.progressBarHeight)
    }
}

/// Identity progress bar with percentage
struct IdentityProgressBar: View {
    let progress: Double
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appPrimaryText)

                Spacer()

                Text("\(Int(progress * 100))%")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appAccent)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appSecondaryBackground)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appAccent)
                        .frame(width: geometry.size.width * CGFloat(min(1, max(0, progress))))
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)
                }
            }
            .frame(height: 8)
        }
    }
}

/// Circular progress indicator
struct CircularProgressView: View {
    let progress: Double
    var lineWidth: CGFloat = 8
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.appSecondaryBackground, lineWidth: lineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(1, max(0, progress))))
                .stroke(
                    Color.appAccent,
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progress)

            Text("\(Int(progress * 100))%")
                .font(.system(size: size * 0.25, weight: .semibold, design: .rounded))
                .foregroundColor(.appPrimaryText)
        }
        .frame(width: size, height: size)
    }
}

/// Weekly stats bar chart
struct WeeklyStatsChart: View {
    let data: [WeeklyStatData]
    var barWidth: CGFloat = 24
    var maxHeight: CGFloat = 100

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data) { stat in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.appAccent.opacity(0.2))
                        .frame(width: barWidth, height: maxHeight)
                        .overlay(alignment: .bottom) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.appAccent)
                                .frame(height: max(4, maxHeight * stat.barHeight))
                        }

                    Text(stat.weekLabel)
                        .font(.caption2)
                        .foregroundColor(.appTertiaryText)
                }
            }
        }
    }
}

/// Plan confidence slider
struct ConfidenceSlider: View {
    @Binding var value: Double

    var body: some View {
        VStack(spacing: 16) {
            // Labels
            HStack {
                Text("Conservative")
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)

                Spacer()

                Text("Balanced")
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)

                Spacer()

                Text("Ambitious")
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
            }

            // Slider
            Slider(value: $value, in: 0...1, step: 0.01)
                .tint(.appAccent)
                .onChange(of: value) { _, _ in
                    Haptics.selection()
                }

            // Current value indicator
            HStack {
                Spacer()
                Text(confidenceLabel)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appAccent)
                    .animation(.none, value: value)
                Spacer()
            }
        }
        .padding(.vertical, 8)
    }

    private var confidenceLabel: String {
        PlanConfidence.from(value: value).displayName
    }
}

// MARK: - Previews

#Preview("Onboarding Progress") {
    VStack(spacing: 20) {
        OnboardingProgressBar(progress: 0.3)
        OnboardingProgressBar(progress: 0.6)
        OnboardingProgressBar(progress: 1.0)
    }
    .padding()
}

#Preview("Identity Progress") {
    IdentityProgressBar(progress: 0.45, label: "Fit & Disciplined Path")
        .padding()
}

#Preview("Circular Progress") {
    HStack(spacing: 20) {
        CircularProgressView(progress: 0.25)
        CircularProgressView(progress: 0.65)
        CircularProgressView(progress: 1.0)
    }
}

#Preview("Confidence Slider") {
    ConfidenceSlider(value: .constant(0.5))
        .padding()
}
