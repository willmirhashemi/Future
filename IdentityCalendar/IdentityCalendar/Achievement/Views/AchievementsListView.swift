import SwiftUI

// MARK: - Achievements List View

/// Full-page view displaying all achievements organized by category
struct AchievementsListView: View {
    @StateObject private var viewModel = AchievementViewModel()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    headerStats
                    categoryList
                }
                .padding(.horizontal, Constants.Layout.screenPadding)
                .padding(.vertical, 16)
            }
            .background(AppTheme.background(colorScheme))
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .achievementDetail(
                selection: $viewModel.selectedAchievement,
                onMarkSeen: { achievement in
                    viewModel.markAsSeen(achievement)
                }
            )
        }
        .onAppear {
            viewModel.loadAchievements()
        }
    }

    // MARK: - Header Stats

    private var headerStats: some View {
        VStack(spacing: 16) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(
                        AppTheme.secondaryBackground(colorScheme),
                        lineWidth: 8
                    )
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: viewModel.statistics?.progressPercentage ?? 0)
                    .stroke(
                        AppTheme.accent,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text(viewModel.progressText)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryText(colorScheme))

                    Text("Unlocked")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
            }

            // Category breakdown
            if let statistics = viewModel.statistics {
                categoryBreakdown(statistics: statistics)
            }
        }
        .padding(20)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func categoryBreakdown(statistics: AchievementStatistics) -> some View {
        HStack(spacing: 12) {
            ForEach(viewModel.sortedCategories.prefix(4), id: \.self) { category in
                if let progress = statistics.categoryProgress[category] {
                    categoryMini(category: category, progress: progress)
                }
            }
        }
    }

    private func categoryMini(
        category: AchievementCategory,
        progress: (unlocked: Int, total: Int)
    ) -> some View {
        VStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.system(size: 14))
                .foregroundColor(AppTheme.accent)

            Text("\(progress.unlocked)/\(progress.total)")
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Category List

    private var categoryList: some View {
        ForEach(viewModel.sortedCategories, id: \.self) { category in
            let achievements = viewModel.achievements(for: category)
            if !achievements.isEmpty {
                AchievementCategorySection(
                    category: category,
                    achievements: achievements,
                    onSelect: { achievement in
                        viewModel.selectAchievement(achievement)
                    }
                )
            }
        }
    }
}

// MARK: - Compact Achievements View

/// Compact view for embedding achievements in other screens
struct CompactAchievementsView: View {
    @StateObject private var viewModel = AchievementViewModel()
    let onViewAll: () -> Void

    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .onAppear {
            viewModel.loadAchievements()
        }
        .achievementDetail(
            selection: $viewModel.selectedAchievement,
            onMarkSeen: { achievement in
                viewModel.markAsSeen(achievement)
            }
        )
    }

    private var header: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accent)

                Text("Achievements")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                if viewModel.hasNewAchievements {
                    Circle()
                        .fill(AppTheme.error)
                        .frame(width: 8, height: 8)
                }
            }

            Spacer()

            Button(action: onViewAll) {
                HStack(spacing: 4) {
                    Text("View All")
                        .font(.system(size: 13, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(AppTheme.accent)
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.recentlyUnlocked.isEmpty {
            emptyState
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.recentlyUnlocked) { achievement in
                        AchievementBadgeButton(
                            achievement: achievement,
                            size: .medium
                        ) {
                            viewModel.selectAchievement(achievement)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "star.circle")
                    .font(.system(size: 28))
                    .foregroundColor(AppTheme.tertiaryText(colorScheme))
                Text("Complete blocks to earn achievements")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
            Spacer()
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Preview

#Preview("Achievements List") {
    AchievementsListView()
        .themed()
}

#Preview("Compact Achievements") {
    CompactAchievementsView(onViewAll: {})
        .padding()
        .background(Color.black)
        .themed()
}
