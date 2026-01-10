import Foundation
import SwiftUI

// MARK: - Achievement Model
struct Achievement: Identifiable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: AchievementRequirement
    let tier: AchievementTier
    var isUnlocked: Bool
    var unlockedAt: Date?
    var progress: Int

    init(
        id: String,
        title: String,
        description: String,
        icon: String,
        requirement: AchievementRequirement,
        tier: AchievementTier,
        isUnlocked: Bool = false,
        unlockedAt: Date? = nil,
        progress: Int = 0
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.requirement = requirement
        self.tier = tier
        self.isUnlocked = isUnlocked
        self.unlockedAt = unlockedAt
        self.progress = progress
    }

    var progressPercentage: Double {
        guard requirement.targetValue > 0 else { return 0 }
        return min(Double(progress) / Double(requirement.targetValue), 1.0)
    }

    var progressText: String {
        "\(progress)/\(requirement.targetValue)"
    }

    static func == (lhs: Achievement, rhs: Achievement) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Achievement Requirement
struct AchievementRequirement {
    let type: AchievementType
    let targetValue: Int

    static func journalStreak(_ days: Int) -> AchievementRequirement {
        AchievementRequirement(type: .journalStreak, targetValue: days)
    }

    static func manualEvents(_ count: Int) -> AchievementRequirement {
        AchievementRequirement(type: .manualEvents, targetValue: count)
    }

    static func completedTasks(_ count: Int) -> AchievementRequirement {
        AchievementRequirement(type: .completedTasks, targetValue: count)
    }

    static func appUsageStreak(_ days: Int) -> AchievementRequirement {
        AchievementRequirement(type: .appUsageStreak, targetValue: days)
    }

    static func weeklyReviews(_ count: Int) -> AchievementRequirement {
        AchievementRequirement(type: .weeklyReviews, targetValue: count)
    }
}

enum AchievementType: String, Codable {
    case journalStreak = "journal_streak"
    case manualEvents = "manual_events"
    case completedTasks = "completed_tasks"
    case appUsageStreak = "app_usage_streak"
    case weeklyReviews = "weekly_reviews"
}

// MARK: - Achievement Tier
enum AchievementTier: String, Codable, CaseIterable {
    case bronze = "bronze"
    case silver = "silver"
    case gold = "gold"
    case platinum = "platinum"

    var displayName: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .bronze: return Color(hex: "CD7F32")
        case .silver: return Color(hex: "C0C0C0")
        case .gold: return Color(hex: "FFD700")
        case .platinum: return Color(hex: "E5E4E2")
        }
    }
}

// MARK: - All Available Achievements
struct AchievementDefinitions {
    static let all: [Achievement] = [
        // Journal Streak Achievements
        Achievement(
            id: "journal_streak_7",
            title: "Week Warrior",
            description: "Journal for 7 days straight",
            icon: "book.fill",
            requirement: .journalStreak(7),
            tier: .bronze
        ),
        Achievement(
            id: "journal_streak_30",
            title: "Monthly Mindful",
            description: "Journal for 30 days straight",
            icon: "book.circle.fill",
            requirement: .journalStreak(30),
            tier: .silver
        ),
        Achievement(
            id: "journal_streak_100",
            title: "Century Scribe",
            description: "Journal for 100 days straight",
            icon: "books.vertical.fill",
            requirement: .journalStreak(100),
            tier: .gold
        ),

        // Manual Events Achievements
        Achievement(
            id: "manual_events_10",
            title: "Event Starter",
            description: "Add 10 of your own events",
            icon: "calendar.badge.plus",
            requirement: .manualEvents(10),
            tier: .bronze
        ),
        Achievement(
            id: "manual_events_50",
            title: "Event Enthusiast",
            description: "Add 50 of your own events",
            icon: "calendar",
            requirement: .manualEvents(50),
            tier: .silver
        ),
        Achievement(
            id: "manual_events_100",
            title: "Event Master",
            description: "Add over 100 of your own events",
            icon: "calendar.circle.fill",
            requirement: .manualEvents(100),
            tier: .gold
        ),

        // Completed Tasks Achievements
        Achievement(
            id: "completed_tasks_25",
            title: "Task Tackler",
            description: "Complete 25 tasks",
            icon: "checkmark.circle",
            requirement: .completedTasks(25),
            tier: .bronze
        ),
        Achievement(
            id: "completed_tasks_100",
            title: "Task Champion",
            description: "Complete 100 tasks",
            icon: "checkmark.circle.fill",
            requirement: .completedTasks(100),
            tier: .silver
        ),
        Achievement(
            id: "completed_tasks_500",
            title: "Productivity Legend",
            description: "Complete 500 tasks",
            icon: "checkmark.seal.fill",
            requirement: .completedTasks(500),
            tier: .gold
        ),

        // App Usage Streak Achievements
        Achievement(
            id: "app_usage_7",
            title: "Getting Started",
            description: "Use the app for 7 days straight",
            icon: "flame",
            requirement: .appUsageStreak(7),
            tier: .bronze
        ),
        Achievement(
            id: "app_usage_30",
            title: "Habit Forming",
            description: "Use the app for 30 days straight",
            icon: "flame.fill",
            requirement: .appUsageStreak(30),
            tier: .silver
        ),
        Achievement(
            id: "app_usage_365",
            title: "Year of Growth",
            description: "Use the app for a full year",
            icon: "flame.circle.fill",
            requirement: .appUsageStreak(365),
            tier: .platinum
        ),

        // Weekly Review Achievements
        Achievement(
            id: "weekly_review_4",
            title: "Reflective",
            description: "Complete 4 weekly reviews",
            icon: "arrow.triangle.2.circlepath",
            requirement: .weeklyReviews(4),
            tier: .bronze
        ),
        Achievement(
            id: "weekly_review_12",
            title: "Quarterly Thinker",
            description: "Complete 12 weekly reviews",
            icon: "arrow.triangle.2.circlepath.circle",
            requirement: .weeklyReviews(12),
            tier: .silver
        ),
        Achievement(
            id: "weekly_review_52",
            title: "Annual Analyzer",
            description: "Complete 52 weekly reviews",
            icon: "arrow.triangle.2.circlepath.circle.fill",
            requirement: .weeklyReviews(52),
            tier: .gold
        )
    ]

    static func achievement(for id: String) -> Achievement? {
        all.first { $0.id == id }
    }

    static func achievements(for type: AchievementType) -> [Achievement] {
        all.filter { $0.requirement.type == type }
    }
}
