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

    // Relationships
    @Relationship(deleteRule: .cascade)
    var goals: [IdentityGoal]

    var activeGoal: IdentityGoal? {
        goals.first { $0.status == .active }
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
        goals: [IdentityGoal] = []
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
        self.goals = goals
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
