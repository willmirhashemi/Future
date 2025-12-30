import SwiftUI

// MARK: - Achievement Detail Sheet

/// Full-screen achievement detail view
struct AchievementDetailSheet: View {
    let achievement: AchievementSnapshot
    let onDismiss: () -> Void
    let onMarkSeen: (() -> Void)?

    @Environment(\.appColorScheme) private var colorScheme

    private var metadata: AchievementMetadata {
        achievement.metadata
    }

    init(
        achievement: AchievementSnapshot,
        onDismiss: @escaping () -> Void,
        onMarkSeen: (() -> Void)? = nil
    ) {
        self.achievement = achievement
        self.onDismiss = onDismiss
        self.onMarkSeen = onMarkSeen
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                badgeSection
                titleSection
                statusSection
                Spacer()
                categoryInfo
            }
            .padding(24)
            .background(AppTheme.background(colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        if achievement.isNew {
                            onMarkSeen?()
                        }
                        onDismiss()
                    }
                    .foregroundColor(AppTheme.accent)
                }
            }
        }
        .onAppear {
            if achievement.isNew {
                Haptics.tap()
            }
        }
    }

    // MARK: - Badge Section

    private var badgeSection: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            metadata.color.opacity(0.4),
                            metadata.color.opacity(0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 80
                    )
                )
                .frame(width: 150, height: 150)

            // Inner circle
            Circle()
                .fill(
                    achievement.isUnlocked
                        ? metadata.color.opacity(0.2)
                        : AppTheme.secondaryBackground(colorScheme)
                )
                .frame(width: 100, height: 100)

            // Icon
            Image(systemName: metadata.icon)
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(
                    achievement.isUnlocked
                        ? metadata.color
                        : AppTheme.tertiaryText(colorScheme)
                )
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(spacing: 8) {
            Text(metadata.displayName)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primaryText(colorScheme))

            Text(metadata.description)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Status Section

    @ViewBuilder
    private var statusSection: some View {
        if achievement.isUnlocked {
            unlockedStatus
        } else {
            progressStatus
        }
    }

    private var unlockedStatus: some View {
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
    }

    private var progressStatus: some View {
        VStack(spacing: 8) {
            Text("Progress")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.secondaryText(colorScheme))

            ProgressView(
                value: Double(achievement.progress),
                total: Double(metadata.requirement)
            )
            .progressViewStyle(LinearProgressViewStyle(tint: metadata.color))
            .frame(width: 200)

            Text("\(achievement.progress) / \(metadata.requirement)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.primaryText(colorScheme))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(AppTheme.secondaryBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Category Info

    private var categoryInfo: some View {
        HStack {
            Image(systemName: metadata.category.icon)
                .foregroundColor(AppTheme.accent)
            Text(metadata.category.rawValue)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        }
    }
}

// MARK: - Achievement Detail Modifier

/// View modifier for presenting achievement detail sheet
struct AchievementDetailModifier: ViewModifier {
    @Binding var selectedAchievement: AchievementSnapshot?
    let onMarkSeen: ((AchievementSnapshot) -> Void)?

    func body(content: Content) -> some View {
        content
            .sheet(item: $selectedAchievement) { achievement in
                AchievementDetailSheet(
                    achievement: achievement,
                    onDismiss: {
                        selectedAchievement = nil
                    },
                    onMarkSeen: {
                        onMarkSeen?(achievement)
                    }
                )
                .presentationDetents([.medium])
            }
    }
}

extension View {
    /// Present achievement detail sheet when an achievement is selected
    func achievementDetail(
        selection: Binding<AchievementSnapshot?>,
        onMarkSeen: ((AchievementSnapshot) -> Void)? = nil
    ) -> some View {
        modifier(AchievementDetailModifier(
            selectedAchievement: selection,
            onMarkSeen: onMarkSeen
        ))
    }
}

// MARK: - Preview

#Preview("Achievement Detail") {
    AchievementDetailSheet(
        achievement: AchievementSnapshot(
            type: .weekWarrior,
            isUnlocked: true,
            progress: 7,
            unlockedAt: Date()
        ),
        onDismiss: {},
        onMarkSeen: nil
    )
    .themed()
}

#Preview("Achievement Detail - Locked") {
    AchievementDetailSheet(
        achievement: AchievementSnapshot(
            type: .monthlyMaster,
            isUnlocked: false,
            progress: 15
        ),
        onDismiss: {},
        onMarkSeen: nil
    )
    .themed()
}
