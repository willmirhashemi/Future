import SwiftUI

/// Progress tracking and insights view
struct ProgressTrackingView: View {
    @StateObject private var viewModel = ProgressViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Identity progress card
                    ProgressHeaderCard(
                        identityName: viewModel.identityName,
                        progress: viewModel.progressPercentage,
                        timeRemaining: viewModel.timeRemaining
                    )

                    // Streak card
                    StreakCard(
                        currentStreak: viewModel.currentStreak,
                        longestStreak: viewModel.longestStreak,
                        message: viewModel.streakMessage
                    )

                    // Feature 5: Trust indicator (subtle, no streaks/numbers)
                    TrustIndicatorView()

                    // Weekly stats chart
                    if !viewModel.weeklyStats.isEmpty {
                        WeeklyProgressSection(stats: viewModel.weeklyStats)
                    }

                    // Milestones timeline
                    if !viewModel.milestones.isEmpty {
                        MilestonesSection(
                            milestones: viewModel.milestones,
                            onComplete: viewModel.markMilestoneComplete
                        )
                    }

                    // Stats overview
                    StatsOverviewSection(
                        totalBlocks: viewModel.totalBlocks,
                        completedBlocks: viewModel.completedBlocks,
                        engagementRate: viewModel.engagementRate
                    )
                }
                .padding(.horizontal, Constants.Layout.screenPadding)
                .padding(.vertical, 16)
            }
            .background(Color.appBackground)
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

/// Main progress header with circular indicator
struct ProgressHeaderCard: View {
    let identityName: String
    let progress: Double
    let timeRemaining: String

    var body: some View {
        VStack(spacing: 20) {
            CircularProgressView(progress: progress, size: 100)

            VStack(spacing: 6) {
                Text("\(identityName) Path")
                    .font(.headline)
                    .foregroundColor(.appPrimaryText)

                Text(timeRemaining)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Streak display card
struct StreakCard: View {
    let currentStreak: Int
    let longestStreak: Int
    let message: String

    var body: some View {
        HStack(spacing: 20) {
            // Current streak
            VStack(spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.appAccent)

                Text("Day streak")
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
            }
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 50)

            // Longest streak
            VStack(spacing: 4) {
                Text("\(longestStreak)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.appPrimaryText)

                Text("Best streak")
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Weekly progress chart section
struct WeeklyProgressSection: View {
    let stats: [WeeklyStatData]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weekly Progress")
                .font(.headline)
                .foregroundColor(.appPrimaryText)

            WeeklyStatsChart(data: stats, maxHeight: 80)
                .padding(.vertical, 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Milestones timeline section
struct MilestonesSection: View {
    let milestones: [Milestone]
    let onComplete: (Milestone) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Milestones")
                .font(.headline)
                .foregroundColor(.appPrimaryText)

            VStack(spacing: 0) {
                ForEach(milestones) { milestone in
                    MilestoneRow(
                        milestone: milestone,
                        isLast: milestone.id == milestones.last?.id,
                        onComplete: { onComplete(milestone) }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Individual milestone row
struct MilestoneRow: View {
    let milestone: Milestone
    let isLast: Bool
    let onComplete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack(spacing: 0) {
                Circle()
                    .fill(milestone.isCompleted ? Color.appSuccess : Color.appSecondaryText.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .overlay(
                        milestone.isCompleted ?
                            Image(systemName: "checkmark")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.white)
                        : nil
                    )

                if !isLast {
                    Rectangle()
                        .fill(Color.appSecondaryText.opacity(0.2))
                        .frame(width: 2)
                        .padding(.top, 4)
                }
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(milestone.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(milestone.isCompleted ? .appSecondaryText : .appPrimaryText)
                        .strikethrough(milestone.isCompleted)

                    Spacer()

                    Text("Week \(milestone.weekNumber)")
                        .font(.caption)
                        .foregroundColor(.appTertiaryText)
                }

                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)

                if !milestone.isCompleted && milestone.targetDate <= Date() {
                    Button(action: onComplete) {
                        Text("Mark complete")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.appAccent)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.bottom, isLast ? 0 : 20)
        }
    }
}

/// Stats overview section
struct StatsOverviewSection: View {
    let totalBlocks: Int
    let completedBlocks: Int
    let engagementRate: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Stats Overview")
                .font(.headline)
                .foregroundColor(.appPrimaryText)

            HStack(spacing: 16) {
                StatCard(
                    value: "\(completedBlocks)",
                    label: "Completed",
                    icon: "checkmark.circle"
                )

                StatCard(
                    value: "\(totalBlocks)",
                    label: "Scheduled",
                    icon: "calendar"
                )

                StatCard(
                    value: "\(Int(engagementRate * 100))%",
                    label: "Engagement",
                    icon: "chart.line.uptrend.xyaxis"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Individual stat card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appAccent)

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.appPrimaryText)

            Text(label)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.appBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// ============================================================================
// MARK: - Feature 5: Trust Indicator View
// ============================================================================

/// Subtle trust indicator - no numbers, no pressure, just calm progress language
/// Never resets to zero, focuses on long-term pattern, not daily pressure
struct TrustIndicatorView: View {
    private let dataService = DataService.shared
    private var trustIndicator: TrustIndicator {
        dataService.getTrustIndicator()
    }

    var body: some View {
        HStack(spacing: 12) {
            // Subtle progress bar (not front-and-center)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.appSecondaryBackground)
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(trustIndicator.indicatorColor)
                        .frame(width: geo.size.width * trustIndicator.trustLevel, height: 6)
                }
            }
            .frame(height: 6)

            // Status message - calm, non-judgmental
            Text(trustIndicator.statusMessage)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSecondaryBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    ProgressTrackingView()
}

#Preview("Trust Indicator") {
    VStack {
        TrustIndicatorView()
    }
    .padding()
}
