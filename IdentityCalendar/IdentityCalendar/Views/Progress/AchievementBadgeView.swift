import SwiftUI

/// Individual achievement badge display
struct AchievementBadgeView: View {
    let achievement: Achievement
    let size: BadgeSize
    @Environment(\.appColorScheme) private var colorScheme

    enum BadgeSize {
        case small, medium, large

        var iconSize: CGFloat {
            switch self {
            case .small: return 24
            case .medium: return 36
            case .large: return 48
            }
        }

        var frameSize: CGFloat {
            switch self {
            case .small: return 50
            case .medium: return 70
            case .large: return 90
            }
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        achievement.isUnlocked
                            ? achievement.achievementType.color.opacity(0.2)
                            : AppTheme.secondaryBackground(colorScheme)
                    )
                    .frame(width: size.frameSize, height: size.frameSize)

                // Icon
                Image(systemName: achievement.achievementType.icon)
                    .font(.system(size: size.iconSize, weight: .medium))
                    .foregroundColor(
                        achievement.isUnlocked
                            ? achievement.achievementType.color
                            : AppTheme.tertiaryText(colorScheme)
                    )

                // Lock overlay for locked achievements
                if !achievement.isUnlocked {
                    Circle()
                        .fill(AppTheme.background(colorScheme).opacity(0.5))
                        .frame(width: size.frameSize, height: size.frameSize)

                    Image(systemName: "lock.fill")
                        .font(.system(size: size.iconSize * 0.4, weight: .medium))
                        .foregroundColor(AppTheme.tertiaryText(colorScheme))
                }

                // New badge indicator
                if achievement.isNew {
                    Circle()
                        .fill(AppTheme.error)
                        .frame(width: 12, height: 12)
                        .offset(x: size.frameSize * 0.35, y: -size.frameSize * 0.35)
                }
            }

            if size != .small {
                Text(achievement.achievementType.displayName)
                    .font(.system(size: size == .large ? 13 : 11, weight: .medium))
                    .foregroundColor(
                        achievement.isUnlocked
                            ? AppTheme.primaryText(colorScheme)
                            : AppTheme.tertiaryText(colorScheme)
                    )
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: size.frameSize + 10)
            }
        }
    }
}

/// Grid of achievement badges
struct AchievementsGridView: View {
    let achievements: [Achievement]
    let columns: Int
    @Environment(\.appColorScheme) private var colorScheme
    @State private var selectedAchievement: Achievement?

    var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: columns),
            spacing: 16
        ) {
            ForEach(achievements, id: \.id) { achievement in
                Button {
                    selectedAchievement = achievement
                    Haptics.tap()
                } label: {
                    AchievementBadgeView(achievement: achievement, size: .medium)
                }
                .buttonStyle(.plain)
            }
        }
        .sheet(item: $selectedAchievement) { achievement in
            AchievementDetailSheet(achievement: achievement)
                .presentationDetents([.medium])
        }
    }
}

/// Card showing recent achievements
struct RecentAchievementsCard: View {
    let achievements: [Achievement]
    @Environment(\.appColorScheme) private var colorScheme

    var unlockedAchievements: [Achievement] {
        achievements
            .filter { $0.isUnlocked }
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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

            if unlockedAchievements.isEmpty {
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
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(unlockedAchievements, id: \.id) { achievement in
                            AchievementBadgeView(achievement: achievement, size: .small)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

/// Full-screen achievement detail
struct AchievementDetailSheet: View {
    let achievement: Achievement
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Badge
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    achievement.achievementType.color.opacity(0.4),
                                    achievement.achievementType.color.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 80
                            )
                        )
                        .frame(width: 150, height: 150)

                    Circle()
                        .fill(
                            achievement.isUnlocked
                                ? achievement.achievementType.color.opacity(0.2)
                                : AppTheme.secondaryBackground(colorScheme)
                        )
                        .frame(width: 100, height: 100)

                    Image(systemName: achievement.achievementType.icon)
                        .font(.system(size: 48, weight: .medium))
                        .foregroundColor(
                            achievement.isUnlocked
                                ? achievement.achievementType.color
                                : AppTheme.tertiaryText(colorScheme)
                        )
                }

                // Title
                VStack(spacing: 8) {
                    Text(achievement.achievementType.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryText(colorScheme))

                    Text(achievement.achievementType.description)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                        .multilineTextAlignment(.center)
                }

                // Status
                if achievement.isUnlocked {
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.success)
                            Text("Unlocked")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.success)
                        }

                        if let unlockedAt = achievement.unlockedAt {
                            Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText(colorScheme))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(AppTheme.success.opacity(0.1))
                    .clipShape(Capsule())
                } else {
                    // Progress bar
                    VStack(spacing: 8) {
                        Text("Progress")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        ProgressView(
                            value: Double(achievement.progress),
                            total: Double(achievement.achievementType.requirement)
                        )
                        .progressViewStyle(LinearProgressViewStyle(tint: achievement.achievementType.color))
                        .frame(width: 200)

                        Text("\(achievement.progress) / \(achievement.achievementType.requirement)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(AppTheme.secondaryBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Spacer()

                // Category info
                HStack {
                    Image(systemName: achievement.achievementType.category.icon)
                        .foregroundColor(AppTheme.accent)
                    Text(achievement.achievementType.category.rawValue)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
            }
            .padding(24)
            .background(AppTheme.background(colorScheme))
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
