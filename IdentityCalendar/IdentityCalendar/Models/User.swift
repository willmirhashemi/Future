import Foundation
import SwiftData

/// Represents the app user and their preferences
@Model
final class User {
    var id: UUID
    var createdAt: Date
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var premiumExpiresAt: Date?

    // Notification preferences
    var blockRemindersEnabled: Bool
    var reflectionRemindersEnabled: Bool
    var quietHoursStart: Date?
    var quietHoursEnd: Date?

    // Streak tracking (global across all goals)
    var lastEngagementDate: Date?
    var totalBlocksEverCompleted: Int
    var totalGoalsCompleted: Int
    var appOpenCount: Int

    // Relationships
    @Relationship(deleteRule: .cascade)
    var goals: [IdentityGoal]

    @Relationship(deleteRule: .cascade)
    var achievements: [Achievement]

    @Relationship(deleteRule: .cascade)
    var blockTemplates: [BlockTemplate]

    @Relationship(deleteRule: .cascade)
    var dailyEngagements: [DailyEngagement]

    var activeGoal: IdentityGoal? {
        goals.first { $0.status == .active }
    }

    var unlockedAchievements: [Achievement] {
        achievements.filter { $0.isUnlocked }
    }

    var newAchievements: [Achievement] {
        achievements.filter { $0.isNew }
    }

    var favoriteTemplates: [BlockTemplate] {
        blockTemplates.filter { $0.isFavorite }.sorted { $0.timesUsed > $1.timesUsed }
    }

    var recentTemplates: [BlockTemplate] {
        blockTemplates
            .filter { $0.lastUsedAt != nil }
            .sorted { ($0.lastUsedAt ?? .distantPast) > ($1.lastUsedAt ?? .distantPast) }
            .prefix(5)
            .map { $0 }
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        hasCompletedOnboarding: Bool = false,
        isPremium: Bool = false,
        premiumExpiresAt: Date? = nil,
        blockRemindersEnabled: Bool = true,
        reflectionRemindersEnabled: Bool = true,
        quietHoursStart: Date? = nil,
        quietHoursEnd: Date? = nil,
        lastEngagementDate: Date? = nil,
        totalBlocksEverCompleted: Int = 0,
        totalGoalsCompleted: Int = 0,
        appOpenCount: Int = 0,
        goals: [IdentityGoal] = [],
        achievements: [Achievement] = [],
        blockTemplates: [BlockTemplate] = [],
        dailyEngagements: [DailyEngagement] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.isPremium = isPremium
        self.premiumExpiresAt = premiumExpiresAt
        self.blockRemindersEnabled = blockRemindersEnabled
        self.reflectionRemindersEnabled = reflectionRemindersEnabled
        self.quietHoursStart = quietHoursStart
        self.quietHoursEnd = quietHoursEnd
        self.lastEngagementDate = lastEngagementDate
        self.totalBlocksEverCompleted = totalBlocksEverCompleted
        self.totalGoalsCompleted = totalGoalsCompleted
        self.appOpenCount = appOpenCount
        self.goals = goals
        self.achievements = achievements
        self.blockTemplates = blockTemplates
        self.dailyEngagements = dailyEngagements
    }
}

// MARK: - User Defaults Wrapper for Quick Access
final class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let hasLaunchedBefore = "hasLaunchedBefore"
        static let currentUserId = "currentUserId"
    }

    var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: Keys.hasLaunchedBefore) }
        set { defaults.set(newValue, forKey: Keys.hasLaunchedBefore) }
    }

    var currentUserId: String? {
        get { defaults.string(forKey: Keys.currentUserId) }
        set { defaults.set(newValue, forKey: Keys.currentUserId) }
    }
}
