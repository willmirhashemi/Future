import SwiftUI

/// Future section - Progress tracking and pro features
struct FutureView: View {
    @StateObject private var progressViewModel = ProgressViewModel()
    @Environment(\.appColorScheme) private var colorScheme
    @ObservedObject private var subscriptionService = SubscriptionService.shared
    @State private var showPaywall = false
    @State private var showSettings = false

    var body: some View {
        ZStack {
            AppTheme.background(colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    FutureHeaderView(
                        goalName: progressViewModel.identityName,
                        progress: progressViewModel.progressPercentage,
                        colorScheme: colorScheme,
                        onSettingsTap: { showSettings = true }
                    )

                    // Quick stats
                    QuickStatsView(
                        streak: progressViewModel.currentStreak,
                        completed: progressViewModel.completedBlocks,
                        total: progressViewModel.totalBlocks,
                        colorScheme: colorScheme
                    )

                    // Milestones
                    if !progressViewModel.milestones.isEmpty {
                        MilestonesCardView(
                            milestones: progressViewModel.milestones,
                            colorScheme: colorScheme
                        )
                    }

                    // Pro features section
                    if !subscriptionService.isPremium {
                        ProFeaturesCard(
                            colorScheme: colorScheme,
                            onUpgrade: { showPaywall = true }
                        )
                    } else {
                        // Insights (Pro feature)
                        InsightsCardView(
                            weeklyStats: progressViewModel.weeklyStats,
                            colorScheme: colorScheme
                        )
                    }

                    // Weekly reflection prompt
                    if shouldShowReflection {
                        ReflectionPromptCard(
                            colorScheme: colorScheme,
                            onStartReflection: {
                                // Navigate to reflection
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(source: .featureGate) {
                showPaywall = false
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onAppear {
            progressViewModel.loadData()
        }
    }

    private var shouldShowReflection: Bool {
        Date().isSunday && subscriptionService.isPremium
    }
}

// MARK: - Future Header

struct FutureHeaderView: View {
    let goalName: String
    let progress: Double
    let colorScheme: ColorScheme
    let onSettingsTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Future")
                    .font(.title.weight(.bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text(goalName)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }

            Spacer()

            Button(action: onSettingsTap) {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .frame(width: 44, height: 44)
                    .background(AppTheme.secondaryBackground(colorScheme))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Quick Stats

struct QuickStatsView: View {
    let streak: Int
    let completed: Int
    let total: Int
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            QuickStatCard(
                icon: "flame.fill",
                iconColor: Color(hex: "FF6B35"),
                value: "\(streak)",
                label: "Day Streak",
                colorScheme: colorScheme
            )

            QuickStatCard(
                icon: "checkmark.circle.fill",
                iconColor: AppTheme.success,
                value: "\(completed)",
                label: "Completed",
                colorScheme: colorScheme
            )

            QuickStatCard(
                icon: "percent",
                iconColor: AppTheme.accent,
                value: total > 0 ? "\(Int((Double(completed) / Double(total)) * 100))%" : "0%",
                label: "Success Rate",
                colorScheme: colorScheme
            )
        }
    }
}

struct QuickStatCard: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)

            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.primaryText(colorScheme))

            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.tertiaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Milestones Card

struct MilestonesCardView: View {
    let milestones: [Milestone]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Milestones")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Spacer()

                Text("\(milestones.filter { $0.isCompleted }.count)/\(milestones.count)")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }

            VStack(spacing: 0) {
                ForEach(Array(milestones.prefix(4).enumerated()), id: \.element.id) { index, milestone in
                    MilestoneItemRow(
                        milestone: milestone,
                        isLast: index == min(3, milestones.count - 1),
                        colorScheme: colorScheme
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct MilestoneItemRow: View {
    let milestone: Milestone
    let isLast: Bool
    let colorScheme: ColorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(milestone.isCompleted ? AppTheme.success : AppTheme.secondaryBackground(colorScheme))
                    .frame(width: 24, height: 24)
                    .overlay(
                        milestone.isCompleted ?
                            Image(systemName: "checkmark")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.white)
                        : nil
                    )

                if !isLast {
                    Rectangle()
                        .fill(AppTheme.separator(colorScheme))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(milestone.isCompleted ? AppTheme.secondaryText(colorScheme) : AppTheme.primaryText(colorScheme))
                    .strikethrough(milestone.isCompleted)

                Text("Week \(milestone.weekNumber)")
                    .font(.caption)
                    .foregroundColor(AppTheme.tertiaryText(colorScheme))
            }
            .padding(.bottom, isLast ? 0 : 16)

            Spacer()
        }
    }
}

// MARK: - Pro Features Card

struct ProFeaturesCard: View {
    let colorScheme: ColorScheme
    let onUpgrade: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock Your Full Potential")
                        .font(.headline)
                        .foregroundColor(.white)

                    Text("Get AI-powered insights and adaptive planning")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Features list
            VStack(spacing: 8) {
                ProFeatureRow(icon: "brain.head.profile", text: "Weekly AI adaptation")
                ProFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Progress insights")
                ProFeatureRow(icon: "arrow.triangle.2.circlepath", text: "Smart rescheduling")
            }

            Button(action: onUpgrade) {
                Text("Upgrade to Pro")
                    .font(.headline)
                    .foregroundColor(Color(hex: "6366F1"))
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(20)
        .background(AppTheme.premiumGradient)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 20)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }
}

// MARK: - Insights Card (Pro)

struct InsightsCardView: View {
    let weeklyStats: [WeeklyStatData]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Insights")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Spacer()

                Image(systemName: "sparkles")
                    .foregroundColor(AppTheme.accent)
            }

            if weeklyStats.isEmpty {
                Text("Complete more blocks to see insights")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                // Simple bar chart
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(weeklyStats.suffix(6)) { stat in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(AppTheme.accent.opacity(0.3))
                                .frame(width: 32, height: 60)
                                .overlay(alignment: .bottom) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppTheme.accent)
                                        .frame(height: max(4, 60 * stat.barHeight))
                                }

                            Text(stat.weekLabel)
                                .font(.caption2)
                                .foregroundColor(AppTheme.tertiaryText(colorScheme))
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Reflection Prompt Card

struct ReflectionPromptCard: View {
    let colorScheme: ColorScheme
    let onStartReflection: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "bubble.left.and.text.bubble.right")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.accent)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Weekly Reflection")
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text("Take a moment to reflect on your week and adjust your plan")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button(action: onStartReflection) {
                Text("Start Reflection")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(AppTheme.accent.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    FutureView()
        .themed()
}
