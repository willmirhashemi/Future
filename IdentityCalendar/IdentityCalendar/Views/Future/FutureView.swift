import SwiftUI

/// Future section - Progress tracking, achievements, and analytics
struct FutureView: View {
    @StateObject private var progressViewModel = ProgressViewModel()
    @ObservedObject private var dataService = DataService.shared
    @Environment(\.appColorScheme) private var colorScheme
    @State private var showSettings = false
    @State private var showAllAchievements = false
    @State private var selectedSection: FutureSection = .overview

    enum FutureSection: String, CaseIterable {
        case overview = "Overview"
        case achievements = "Achievements"
        case analytics = "Analytics"
    }

    var body: some View {
        ZStack {
            AppTheme.background(colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header with settings
                    EnhancedFutureHeaderView(
                        goalName: progressViewModel.identityName,
                        colorScheme: colorScheme,
                        onSettingsTap: { showSettings = true }
                    )

                    // Section Picker
                    sectionPicker

                    // Content based on selected section
                    switch selectedSection {
                    case .overview:
                        overviewSection
                    case .achievements:
                        achievementsSection
                    case .analytics:
                        analyticsSection
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showAllAchievements) {
            AllAchievementsView(achievements: dataService.currentUser?.achievements ?? [])
        }
        .onAppear {
            progressViewModel.loadData()
            dataService.recordDailyEngagement()
            initializeAchievementsIfNeeded()
        }
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 8) {
            ForEach(FutureSection.allCases, id: \.self) { section in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedSection = section
                    }
                    Haptics.tap()
                } label: {
                    Text(section.rawValue)
                        .font(.system(size: 14, weight: selectedSection == section ? .semibold : .medium))
                        .foregroundColor(
                            selectedSection == section
                                ? AppTheme.primaryText(colorScheme)
                                : AppTheme.secondaryText(colorScheme)
                        )
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            selectedSection == section
                                ? AppTheme.accent.opacity(0.15)
                                : Color.clear
                        )
                        .clipShape(Capsule())
                }
            }
        }
        .padding(4)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(Capsule())
    }

    // MARK: - Overview Section

    private var overviewSection: some View {
        VStack(spacing: 20) {
            // Hero Progress Ring
            if let goal = dataService.activeGoal {
                let streakInfo = dataService.getStreakInfo(for: goal)
                HeroProgressRing(streakInfo: streakInfo)
                    .padding(.vertical, 8)
            }

            // Progress Rings Row
            if let goal = dataService.activeGoal {
                let rings = dataService.getProgressRings(for: goal)
                ProgressRingsRow(rings: rings)
            }

            // Quick stats (legacy, enhanced)
            QuickStatsView(
                streak: progressViewModel.currentStreak,
                completed: progressViewModel.completedBlocks,
                total: progressViewModel.totalBlocks,
                colorScheme: colorScheme
            )

            // Recent Achievements
            if let achievements = dataService.currentUser?.achievements {
                RecentAchievementsCard(achievements: achievements)
                    .onTapGesture {
                        showAllAchievements = true
                    }
            }

            // Milestones
            if !progressViewModel.milestones.isEmpty {
                MilestonesCardView(
                    milestones: progressViewModel.milestones,
                    colorScheme: colorScheme
                )
            }

            // Insights - now available to all users
            InsightsCardView(
                weeklyStats: progressViewModel.weeklyStats,
                colorScheme: colorScheme
            )

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
    }

    // MARK: - Achievements Section

    private var achievementsSection: some View {
        VStack(spacing: 20) {
            if let user = dataService.currentUser {
                // Summary
                AchievementsSummaryCard(
                    unlocked: user.unlockedAchievements.count,
                    total: user.achievements.count,
                    colorScheme: colorScheme
                )

                // By Category
                ForEach(AchievementCategory.allCases, id: \.self) { category in
                    let categoryAchievements = user.achievements.filter {
                        $0.achievementType.category == category
                    }

                    if !categoryAchievements.isEmpty {
                        AchievementCategorySection(
                            category: category,
                            achievements: categoryAchievements,
                            colorScheme: colorScheme
                        )
                    }
                }
            }
        }
    }

    // MARK: - Analytics Section

    private var analyticsSection: some View {
        VStack(spacing: 20) {
            if let goal = dataService.activeGoal {
                // Weekly Stats Card
                let weekStats = dataService.getWeeklyStats(for: goal)
                WeeklyAnalyticsCard(stats: weekStats, colorScheme: colorScheme)

                // Best Day & Time
                BestPerformanceCard(stats: weekStats, colorScheme: colorScheme)

                // Weekly Comparison
                WeeklyComparisonChart(
                    goal: goal,
                    dataService: dataService,
                    colorScheme: colorScheme
                )

                // Insights - now available to all users
                InsightsCardView(
                    weeklyStats: progressViewModel.weeklyStats,
                    colorScheme: colorScheme
                )
            }
        }
    }

    private var shouldShowReflection: Bool {
        // Reflection available to all users on Sundays
        Date().isSunday
    }

    private func initializeAchievementsIfNeeded() {
        if let user = dataService.currentUser {
            dataService.initializeAchievements(for: user)
        }
    }
}

// MARK: - Enhanced Future Header

struct EnhancedFutureHeaderView: View {
    let goalName: String
    let colorScheme: ColorScheme
    let onSettingsTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Future")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text(goalName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }

            Spacer()

            Button(action: onSettingsTap) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .frame(width: 44, height: 44)
                    .background(AppTheme.cardBackground(colorScheme))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Achievements Summary Card

struct AchievementsSummaryCard: View {
    let unlocked: Int
    let total: Int
    let colorScheme: ColorScheme

    var progress: Double {
        total > 0 ? Double(unlocked) / Double(total) : 0
    }

    var body: some View {
        HStack(spacing: 20) {
            ProgressRingView(
                progress: progress,
                label: "\(unlocked)",
                sublabel: "of \(total)",
                color: AppTheme.accent,
                size: 80,
                lineWidth: 8
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Achievements Unlocked")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text("\(Int(progress * 100))% Complete")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))

                if unlocked < total {
                    Text("\(total - unlocked) more to unlock")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppTheme.tertiaryText(colorScheme))
                }
            }

            Spacer()
        }
        .padding(20)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Achievement Category Section

struct AchievementCategorySection: View {
    let category: AchievementCategory
    let achievements: [Achievement]
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                Text(category.rawValue.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .tracking(1)
            }

            AchievementsGridView(
                achievements: achievements.sorted { $0.isUnlocked && !$1.isUnlocked },
                columns: 4
            )
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Weekly Analytics Card

struct WeeklyAnalyticsCard: View {
    let stats: WeeklyStats
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                Text("THIS WEEK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .tracking(1)
            }

            HStack(spacing: 16) {
                AnalyticStatBox(
                    value: "\(stats.completedBlocks)",
                    label: "Completed",
                    icon: "checkmark.circle.fill",
                    color: AppTheme.success,
                    colorScheme: colorScheme
                )

                AnalyticStatBox(
                    value: "\(Int(stats.hoursCompleted * 10) / 10)h",
                    label: "Hours",
                    icon: "clock.fill",
                    color: AppTheme.accent,
                    colorScheme: colorScheme
                )

                AnalyticStatBox(
                    value: "\(Int(stats.completionRate * 100))%",
                    label: "Rate",
                    icon: "percent",
                    color: Color(hex: "9B5DE5"),
                    colorScheme: colorScheme
                )
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct AnalyticStatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primaryText(colorScheme))

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppTheme.tertiaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Best Performance Card

struct BestPerformanceCard: View {
    let stats: WeeklyStats
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.warning)
                Text("BEST PERFORMANCE")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .tracking(1)
            }

            HStack(spacing: 20) {
                if let bestDay = stats.bestDay {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Best Day")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                        Text(bestDay)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                    }
                }

                Divider()
                    .frame(height: 40)

                if let hour = stats.mostProductiveHour {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Peak Hour")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                        Text(formatHour(hour))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                    }
                }

                Spacer()
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour):00"
    }
}

// MARK: - Weekly Comparison Chart

struct WeeklyComparisonChart: View {
    let goal: IdentityGoal
    @ObservedObject var dataService: DataService
    let colorScheme: ColorScheme

    var weeklyData: [(week: String, rate: Double)] {
        (0..<4).reversed().map { offset in
            let stats = dataService.getWeeklyStats(for: goal, weekOffset: offset)
            let weekLabel = offset == 0 ? "This Week" : (offset == 1 ? "Last Week" : "\(offset)w ago")
            return (weekLabel, stats.completionRate)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                Text("WEEKLY TREND")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .tracking(1)
            }

            HStack(alignment: .bottom, spacing: 12) {
                ForEach(weeklyData, id: \.week) { data in
                    VStack(spacing: 6) {
                        Text("\(Int(data.rate * 100))%")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))

                        RoundedRectangle(cornerRadius: 6)
                            .fill(data.week == "This Week" ? AppTheme.accent : AppTheme.accent.opacity(0.4))
                            .frame(width: 50, height: max(20, 80 * data.rate))

                        Text(data.week)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(AppTheme.tertiaryText(colorScheme))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - All Achievements View

struct AllAchievementsView: View {
    let achievements: [Achievement]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(AchievementCategory.allCases, id: \.self) { category in
                        let categoryAchievements = achievements.filter {
                            $0.achievementType.category == category
                        }

                        if !categoryAchievements.isEmpty {
                            AchievementCategorySection(
                                category: category,
                                achievements: categoryAchievements,
                                colorScheme: colorScheme
                            )
                        }
                    }
                }
                .padding(16)
            }
            .background(AppTheme.background(colorScheme))
            .navigationTitle("All Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Legacy Components (kept for compatibility)

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
