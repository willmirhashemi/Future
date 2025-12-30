import SwiftUI

// MARK: - Achievements Grid View

/// Grid display of achievement badges
struct AchievementsGridView: View {
    let achievements: [AchievementSnapshot]
    let columns: Int
    let onSelect: (AchievementSnapshot) -> Void

    @Environment(\.appColorScheme) private var colorScheme

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: columns)
    }

    var body: some View {
        LazyVGrid(columns: gridColumns, spacing: 16) {
            ForEach(achievements) { achievement in
                AchievementBadgeButton(
                    achievement: achievement,
                    size: .medium
                ) {
                    onSelect(achievement)
                }
            }
        }
    }
}

// MARK: - Recent Achievements Card

/// Card showing recent achievements
struct RecentAchievementsCard: View {
    let achievements: [AchievementSnapshot]
    let onTap: ((AchievementSnapshot) -> Void)?

    @Environment(\.appColorScheme) private var colorScheme

    private var unlockedAchievements: [AchievementSnapshot] {
        achievements
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            content
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var header: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.accent)

            Text("ACHIEVEMENTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
                .tracking(1)

            Spacer()

            Text("\(achievements.filter { $0.isUnlocked }.count)/\(achievements.count)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        }
    }

    @ViewBuilder
    private var content: some View {
        if unlockedAchievements.isEmpty {
            emptyState
        } else {
            achievementsList
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "star.circle")
                    .font(.system(size: 32))
                    .foregroundColor(AppTheme.tertiaryText(colorScheme))
                Text("Complete blocks to earn achievements")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
            Spacer()
        }
        .padding(.vertical, 16)
    }

    private var achievementsList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(unlockedAchievements) { achievement in
                    if let onTap = onTap {
                        AchievementBadgeButton(
                            achievement: achievement,
                            size: .small
                        ) {
                            onTap(achievement)
                        }
                    } else {
                        AchievementBadgeView(achievement: achievement, size: .small)
                    }
                }
            }
        }
    }
}

// MARK: - Category Section View

/// Section showing achievements for a specific category
struct AchievementCategorySection: View {
    let category: AchievementCategory
    let achievements: [AchievementSnapshot]
    let onSelect: (AchievementSnapshot) -> Void

    @Environment(\.appColorScheme) private var colorScheme

    private var progress: (unlocked: Int, total: Int) {
        let unlocked = achievements.filter { $0.isUnlocked }.count
        return (unlocked, achievements.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            AchievementsGridView(
                achievements: achievements,
                columns: 4,
                onSelect: onSelect
            )
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var header: some View {
        HStack {
            Image(systemName: category.icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.accent)

            Text(category.rawValue.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
                .tracking(1)

            Spacer()

            Text("\(progress.unlocked)/\(progress.total)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        }
    }
}

// MARK: - Preview

#Preview("Achievement Grid") {
    let sampleAchievements: [AchievementSnapshot] = [
        AchievementSnapshot(type: .firstStep, isUnlocked: true, progress: 1, unlockedAt: Date()),
        AchievementSnapshot(type: .weekWarrior, isUnlocked: true, progress: 7, unlockedAt: Date().addingTimeInterval(-86400)),
        AchievementSnapshot(type: .twoWeekTitan, isUnlocked: false, progress: 10),
        AchievementSnapshot(type: .monthlyMaster, isUnlocked: false, progress: 5),
    ]

    ScrollView {
        VStack(spacing: 16) {
            RecentAchievementsCard(achievements: sampleAchievements, onTap: nil)

            AchievementCategorySection(
                category: .streak,
                achievements: sampleAchievements,
                onSelect: { _ in }
            )
        }
        .padding()
    }
    .background(Color.black)
    .themed()
}
