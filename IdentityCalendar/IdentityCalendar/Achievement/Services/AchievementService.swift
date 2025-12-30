import Foundation
import SwiftData
import Combine

// MARK: - Achievement Unlock Event

/// Event fired when an achievement is unlocked
struct AchievementUnlockEvent: Sendable {
    let achievement: AchievementSnapshot
    let timestamp: Date

    init(achievement: AchievementSnapshot) {
        self.achievement = achievement
        self.timestamp = Date()
    }
}

// MARK: - Achievement Checking Context

/// Context data needed for checking achievement conditions
/// Designed to be passed safely between actors
struct AchievementCheckContext: Sendable {
    let totalBlocksCompleted: Int
    let currentStreak: Int
    let longestStreak: Int
    let earlyMorningBlocks: Int
    let nightBlocks: Int
    let weekendEngagementCount: Int
    let completedMilestoneCount: Int
    let progressPercentage: Double
    let goalsCompleted: Int
    let reflectionCount: Int
    let adaptationCount: Int
    let hasPerfectWeek: Bool
    let isJanuaryFirst: Bool
    let daysSinceLastEngagement: Int?

    init(
        totalBlocksCompleted: Int = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        earlyMorningBlocks: Int = 0,
        nightBlocks: Int = 0,
        weekendEngagementCount: Int = 0,
        completedMilestoneCount: Int = 0,
        progressPercentage: Double = 0,
        goalsCompleted: Int = 0,
        reflectionCount: Int = 0,
        adaptationCount: Int = 0,
        hasPerfectWeek: Bool = false,
        isJanuaryFirst: Bool = false,
        daysSinceLastEngagement: Int? = nil
    ) {
        self.totalBlocksCompleted = totalBlocksCompleted
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.earlyMorningBlocks = earlyMorningBlocks
        self.nightBlocks = nightBlocks
        self.weekendEngagementCount = weekendEngagementCount
        self.completedMilestoneCount = completedMilestoneCount
        self.progressPercentage = progressPercentage
        self.goalsCompleted = goalsCompleted
        self.reflectionCount = reflectionCount
        self.adaptationCount = adaptationCount
        self.hasPerfectWeek = hasPerfectWeek
        self.isJanuaryFirst = isJanuaryFirst
        self.daysSinceLastEngagement = daysSinceLastEngagement
    }
}

// MARK: - Achievement Service

/// Service responsible for all achievement-related logic
/// Uses @MainActor to ensure thread-safe access to SwiftData models
@MainActor
final class AchievementService: ObservableObject {

    // MARK: - Singleton

    static let shared = AchievementService()

    // MARK: - Published State

    @Published private(set) var recentUnlocks: [AchievementSnapshot] = []
    @Published private(set) var hasNewAchievements: Bool = false

    // MARK: - Event Publisher

    private let unlockSubject = PassthroughSubject<AchievementUnlockEvent, Never>()

    /// Publisher for achievement unlock events
    var unlockPublisher: AnyPublisher<AchievementUnlockEvent, Never> {
        unlockSubject.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private var modelContext: ModelContext?

    // MARK: - Initialization

    private init() {}

    /// Configure the service with a model context
    func configure(with context: ModelContext) {
        self.modelContext = context
    }

    // MARK: - Achievement Initialization

    /// Initialize all achievements for a user
    func initializeAchievements(for user: User) {
        guard user.achievements.isEmpty else { return }

        for type in AchievementType.allCases {
            let achievement = Achievement(achievementType: type)
            achievement.user = user
            user.achievements.append(achievement)
            modelContext?.insert(achievement)
        }

        save()
    }

    // MARK: - Achievement Checking

    /// Check and update all achievements based on current context
    func checkAchievements(for user: User, context: AchievementCheckContext) {
        var newlyUnlocked: [AchievementSnapshot] = []

        for achievement in user.achievements where !achievement.isUnlocked {
            let (shouldUnlock, newProgress) = evaluateCondition(
                for: achievement.achievementType,
                context: context
            )

            // Update progress
            if newProgress != achievement.progress {
                achievement.progress = newProgress
            }

            // Unlock if condition met
            if shouldUnlock {
                achievement.unlock()
                let snapshot = achievement.snapshot()
                newlyUnlocked.append(snapshot)
                unlockSubject.send(AchievementUnlockEvent(achievement: snapshot))
            }
        }

        if !newlyUnlocked.isEmpty {
            recentUnlocks = newlyUnlocked
            hasNewAchievements = true
            save()
        }
    }

    /// Evaluate the condition for a specific achievement type
    private func evaluateCondition(
        for type: AchievementType,
        context: AchievementCheckContext
    ) -> (shouldUnlock: Bool, progress: Int) {

        switch type {
        // Streak Achievements
        case .firstStep:
            return (context.totalBlocksCompleted >= 1, min(context.totalBlocksCompleted, 1))

        case .weekWarrior:
            return (context.currentStreak >= 7, context.currentStreak)

        case .twoWeekTitan:
            return (context.currentStreak >= 14, context.currentStreak)

        case .monthlyMaster:
            return (context.currentStreak >= 30, context.currentStreak)

        case .quarterChampion:
            return (context.currentStreak >= 90, context.currentStreak)

        // Completion Achievements
        case .tenBlocks:
            return (context.totalBlocksCompleted >= 10, context.totalBlocksCompleted)

        case .fiftyBlocks:
            return (context.totalBlocksCompleted >= 50, context.totalBlocksCompleted)

        case .hundredBlocks:
            return (context.totalBlocksCompleted >= 100, context.totalBlocksCompleted)

        case .fiveHundredBlocks:
            return (context.totalBlocksCompleted >= 500, context.totalBlocksCompleted)

        // Consistency Achievements
        case .earlyBird:
            return (context.earlyMorningBlocks >= 5, context.earlyMorningBlocks)

        case .nightOwl:
            return (context.nightBlocks >= 5, context.nightBlocks)

        case .weekendWarrior:
            return (context.weekendEngagementCount >= 4, context.weekendEngagementCount)

        // Milestone Achievements
        case .firstMilestone:
            return (context.completedMilestoneCount >= 1, min(context.completedMilestoneCount, 1))

        case .halfwayHero:
            let progressInt = Int(context.progressPercentage * 100)
            return (context.progressPercentage >= 0.5, progressInt)

        case .goalGetter:
            return (context.goalsCompleted >= 1, min(context.goalsCompleted, 1))

        // Engagement Achievements
        case .reflector:
            return (context.reflectionCount >= 4, context.reflectionCount)

        case .adapter:
            return (context.adaptationCount >= 10, context.adaptationCount)

        case .perfectWeek:
            return (context.hasPerfectWeek, context.hasPerfectWeek ? 1 : 0)

        // Special Achievements
        case .newYearNewYou:
            let shouldUnlock = context.isJanuaryFirst && context.totalBlocksCompleted > 0
            return (shouldUnlock, shouldUnlock ? 1 : 0)

        case .comebackKid:
            let shouldUnlock = (context.daysSinceLastEngagement ?? 0) >= 7
            return (shouldUnlock, shouldUnlock ? 1 : 0)
        }
    }

    // MARK: - Data Queries

    /// Get all achievements for a user as snapshots
    func getAchievementSnapshots(for user: User) -> [AchievementSnapshot] {
        user.achievements.snapshots()
    }

    /// Get achievements grouped by category
    func getAchievementsByCategory(for user: User) -> [AchievementCategory: [AchievementSnapshot]] {
        var grouped: [AchievementCategory: [AchievementSnapshot]] = [:]

        for category in AchievementCategory.allCases {
            grouped[category] = user.achievements
                .filter { $0.metadata.category == category }
                .snapshots()
                .sorted { $0.metadata.tier < $1.metadata.tier }
        }

        return grouped
    }

    /// Get unlocked achievements sorted by unlock date
    func getUnlockedAchievements(for user: User) -> [AchievementSnapshot] {
        user.achievements
            .filter { $0.isUnlocked }
            .snapshots()
            .sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }
    }

    /// Get achievements that are new (unlocked but not yet seen)
    func getNewAchievements(for user: User) -> [AchievementSnapshot] {
        user.achievements
            .filter { $0.isNew }
            .snapshots()
    }

    /// Get a specific achievement by type
    func getAchievement(type: AchievementType, for user: User) -> Achievement? {
        user.achievements.first { $0.achievementType == type }
    }

    // MARK: - State Management

    /// Mark all new achievements as notified
    func markAllAsNotified(for user: User) {
        for achievement in user.achievements where achievement.isNew {
            achievement.markAsNotified()
        }
        hasNewAchievements = false
        save()
    }

    /// Mark a specific achievement as notified
    func markAsNotified(_ achievementId: UUID, for user: User) {
        if let achievement = user.achievements.first(where: { $0.id == achievementId }) {
            achievement.markAsNotified()
            hasNewAchievements = user.achievements.contains { $0.isNew }
            save()
        }
    }

    /// Clear recent unlocks
    func clearRecentUnlocks() {
        recentUnlocks = []
    }

    // MARK: - Statistics

    /// Get achievement statistics for a user
    func getStatistics(for user: User) -> AchievementStatistics {
        let achievements = user.achievements
        let unlocked = achievements.filter { $0.isUnlocked }

        var categoryProgress: [AchievementCategory: (unlocked: Int, total: Int)] = [:]
        for category in AchievementCategory.allCases {
            let categoryAchievements = achievements.filter { $0.metadata.category == category }
            let categoryUnlocked = categoryAchievements.filter { $0.isUnlocked }
            categoryProgress[category] = (categoryUnlocked.count, categoryAchievements.count)
        }

        return AchievementStatistics(
            totalAchievements: achievements.count,
            unlockedCount: unlocked.count,
            progressPercentage: achievements.isEmpty ? 0 : Double(unlocked.count) / Double(achievements.count),
            categoryProgress: categoryProgress,
            recentUnlock: unlocked.sorted { ($0.unlockedAt ?? .distantPast) > ($1.unlockedAt ?? .distantPast) }.first?.snapshot()
        )
    }

    // MARK: - Persistence

    private func save() {
        do {
            try modelContext?.save()
        } catch {
            print("[AchievementService] Failed to save: \(error)")
        }
    }
}

// MARK: - Achievement Statistics

/// Statistics about a user's achievement progress
struct AchievementStatistics: Sendable {
    let totalAchievements: Int
    let unlockedCount: Int
    let progressPercentage: Double
    let categoryProgress: [AchievementCategory: (unlocked: Int, total: Int)]
    let recentUnlock: AchievementSnapshot?

    var formattedProgress: String {
        "\(unlockedCount)/\(totalAchievements)"
    }

    var formattedPercentage: String {
        "\(Int(progressPercentage * 100))%"
    }
}

// MARK: - Achievement Context Builder

/// Helper to build AchievementCheckContext from app data
enum AchievementContextBuilder {

    /// Build context from user and goal data
    @MainActor
    static func build(user: User, goal: IdentityGoal?) -> AchievementCheckContext {
        let calendar = Calendar.current
        let today = Date()

        // Calculate early morning blocks (before 8 AM)
        let earlyBlocks = goal?.planBlocks.filter { block in
            block.status == .completed &&
            calendar.component(.hour, from: block.startDateTime) < 8
        }.count ?? 0

        // Calculate night blocks (after 8 PM)
        let nightBlocks = goal?.planBlocks.filter { block in
            block.status == .completed &&
            calendar.component(.hour, from: block.startDateTime) >= 20
        }.count ?? 0

        // Calculate weekend engagement count
        let weekendCount = countWeekendEngagements(for: user)

        // Calculate milestone count
        let milestoneCount = goal?.milestones.filter { $0.isCompleted }.count ?? 0

        // Calculate progress percentage
        let progressPercentage = calculateProgress(for: goal)

        // Calculate reflection count
        let reflectionCount = goal?.reflections.count ?? 0

        // Calculate adaptations
        let adaptationCount = goal?.planBlocks.filter { $0.wasMoved || $0.wasReduced }.count ?? 0

        // Check for perfect week
        let hasPerfectWeek = checkPerfectWeek(for: goal)

        // Check if January 1st
        let isJanFirst = calendar.component(.month, from: today) == 1 &&
                         calendar.component(.day, from: today) == 1

        // Days since last engagement
        var daysSinceEngagement: Int? = nil
        if let lastEngagement = user.lastEngagementDate {
            daysSinceEngagement = calendar.dateComponents([.day], from: lastEngagement, to: today).day
        }

        return AchievementCheckContext(
            totalBlocksCompleted: user.totalBlocksEverCompleted,
            currentStreak: goal?.currentStreak ?? 0,
            longestStreak: goal?.longestStreak ?? 0,
            earlyMorningBlocks: earlyBlocks,
            nightBlocks: nightBlocks,
            weekendEngagementCount: weekendCount,
            completedMilestoneCount: milestoneCount,
            progressPercentage: progressPercentage,
            goalsCompleted: user.totalGoalsCompleted,
            reflectionCount: reflectionCount,
            adaptationCount: adaptationCount,
            hasPerfectWeek: hasPerfectWeek,
            isJanuaryFirst: isJanFirst,
            daysSinceLastEngagement: daysSinceEngagement
        )
    }

    private static func countWeekendEngagements(for user: User) -> Int {
        let weekendEngagements = user.dailyEngagements.filter { engagement in
            engagement.isWeekend && engagement.blocksCompleted > 0
        }

        var weekends = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-ww"

        for engagement in weekendEngagements {
            weekends.insert(formatter.string(from: engagement.date))
        }

        return weekends.count
    }

    private static func calculateProgress(for goal: IdentityGoal?) -> Double {
        guard let goal = goal else { return 0 }

        let totalDays = goal.timeHorizon.days
        let daysPassed = Calendar.current.dateComponents(
            [.day],
            from: goal.createdAt,
            to: Date()
        ).day ?? 0

        let timeProgress = Double(daysPassed) / Double(totalDays)

        let completionRate: Double
        if goal.totalBlocksScheduled > 0 {
            completionRate = Double(goal.totalBlocksCompleted) / Double(goal.totalBlocksScheduled)
        } else {
            completionRate = 0
        }

        let progress = (timeProgress * 0.4) + (completionRate * 0.6)
        return min(1.0, max(0, progress))
    }

    private static func checkPerfectWeek(for goal: IdentityGoal?) -> Bool {
        guard let goal = goal else { return false }

        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return false
        }

        let weekBlocks = goal.planBlocks.filter { block in
            block.startDateTime >= weekStart && block.startDateTime < weekEnd
        }

        guard !weekBlocks.isEmpty else { return false }
        return weekBlocks.allSatisfy { $0.status == .completed }
    }
}
