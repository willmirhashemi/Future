import SwiftUI

// MARK: - Badge Size

enum AchievementBadgeSize {
    case small
    case medium
    case large

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

    var fontSize: CGFloat {
        switch self {
        case .small: return 9
        case .medium: return 11
        case .large: return 13
        }
    }

    var showsLabel: Bool {
        self != .small
    }
}

// MARK: - Achievement Badge View

/// Individual achievement badge display component
struct AchievementBadgeView: View {
    let achievement: AchievementSnapshot
    let size: AchievementBadgeSize

    @Environment(\.appColorScheme) private var colorScheme

    private var metadata: AchievementMetadata {
        achievement.metadata
    }

    var body: some View {
        VStack(spacing: 8) {
            badgeCircle

            if size.showsLabel {
                Text(metadata.displayName)
                    .font(.system(size: size.fontSize, weight: .medium))
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

    @ViewBuilder
    private var badgeCircle: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(
                    achievement.isUnlocked
                        ? metadata.color.opacity(0.2)
                        : AppTheme.secondaryBackground(colorScheme)
                )
                .frame(width: size.frameSize, height: size.frameSize)

            // Icon
            Image(systemName: metadata.icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundColor(
                    achievement.isUnlocked
                        ? metadata.color
                        : AppTheme.tertiaryText(colorScheme)
                )

            // Lock overlay for locked achievements
            if !achievement.isUnlocked {
                lockOverlay
            }

            // New badge indicator
            if achievement.isNew {
                newIndicator
            }
        }
    }

    @ViewBuilder
    private var lockOverlay: some View {
        Circle()
            .fill(AppTheme.background(colorScheme).opacity(0.5))
            .frame(width: size.frameSize, height: size.frameSize)

        Image(systemName: "lock.fill")
            .font(.system(size: size.iconSize * 0.4, weight: .medium))
            .foregroundColor(AppTheme.tertiaryText(colorScheme))
    }

    private var newIndicator: some View {
        Circle()
            .fill(AppTheme.error)
            .frame(width: 12, height: 12)
            .offset(x: size.frameSize * 0.35, y: -size.frameSize * 0.35)
    }
}

// MARK: - Achievement Badge Button

/// Achievement badge wrapped in a tappable button
struct AchievementBadgeButton: View {
    let achievement: AchievementSnapshot
    let size: AchievementBadgeSize
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            AchievementBadgeView(achievement: achievement, size: size)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress Badge View

/// Achievement badge with progress indicator
struct AchievementProgressBadgeView: View {
    let achievement: AchievementSnapshot
    let size: AchievementBadgeSize

    @Environment(\.appColorScheme) private var colorScheme

    private var metadata: AchievementMetadata {
        achievement.metadata
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Progress ring background
                Circle()
                    .stroke(
                        AppTheme.secondaryBackground(colorScheme),
                        lineWidth: 3
                    )
                    .frame(width: size.frameSize + 6, height: size.frameSize + 6)

                // Progress ring
                if !achievement.isUnlocked {
                    Circle()
                        .trim(from: 0, to: achievement.progressPercentage)
                        .stroke(
                            metadata.color,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: size.frameSize + 6, height: size.frameSize + 6)
                        .rotationEffect(.degrees(-90))
                }

                // Badge
                AchievementBadgeView(achievement: achievement, size: size)
            }

            // Progress text
            if !achievement.isUnlocked && size.showsLabel {
                Text("\(achievement.progress)/\(metadata.requirement)")
                    .font(.system(size: size.fontSize - 2, weight: .medium))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
        }
    }
}

// MARK: - Preview

#Preview("Achievement Badges") {
    VStack(spacing: 32) {
        HStack(spacing: 24) {
            AchievementBadgeView(
                achievement: AchievementSnapshot(
                    type: .weekWarrior,
                    isUnlocked: true,
                    progress: 7,
                    unlockedAt: Date()
                ),
                size: .large
            )

            AchievementBadgeView(
                achievement: AchievementSnapshot(
                    type: .monthlyMaster,
                    isUnlocked: false,
                    progress: 15
                ),
                size: .large
            )
        }

        HStack(spacing: 16) {
            AchievementProgressBadgeView(
                achievement: AchievementSnapshot(
                    type: .fiftyBlocks,
                    isUnlocked: false,
                    progress: 35
                ),
                size: .medium
            )

            AchievementProgressBadgeView(
                achievement: AchievementSnapshot(
                    type: .tenBlocks,
                    isUnlocked: true,
                    progress: 10,
                    unlockedAt: Date()
                ),
                size: .medium
            )
        }
    }
    .padding()
    .background(Color.black)
    .themed()
}
