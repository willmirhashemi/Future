import Foundation
import SwiftUI

// MARK: - Achievement Category

/// Categories for grouping achievements
enum AchievementCategory: String, Codable, CaseIterable, Sendable {
    case streak = "Streaks"
    case completion = "Completion"
    case consistency = "Consistency"
    case milestone = "Milestones"
    case engagement = "Engagement"
    case special = "Special"

    var icon: String {
        switch self {
        case .streak: return "flame.fill"
        case .completion: return "checkmark.circle.fill"
        case .consistency: return "calendar"
        case .milestone: return "flag.fill"
        case .engagement: return "hand.raised.fill"
        case .special: return "sparkles"
        }
    }

    var sortOrder: Int {
        switch self {
        case .streak: return 0
        case .completion: return 1
        case .consistency: return 2
        case .milestone: return 3
        case .engagement: return 4
        case .special: return 5
        }
    }
}

// MARK: - Achievement Type

/// All available achievement types in the app
enum AchievementType: String, Codable, CaseIterable, Sendable {
    // Streak Achievements
    case firstStep = "first_step"
    case weekWarrior = "week_warrior"
    case twoWeekTitan = "two_week_titan"
    case monthlyMaster = "monthly_master"
    case quarterChampion = "quarter_champion"

    // Completion Achievements
    case tenBlocks = "ten_blocks"
    case fiftyBlocks = "fifty_blocks"
    case hundredBlocks = "hundred_blocks"
    case fiveHundredBlocks = "five_hundred_blocks"

    // Consistency Achievements
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case weekendWarrior = "weekend_warrior"

    // Milestone Achievements
    case firstMilestone = "first_milestone"
    case halfwayHero = "halfway_hero"
    case goalGetter = "goal_getter"

    // Engagement Achievements
    case reflector = "reflector"
    case adapter = "adapter"
    case perfectWeek = "perfect_week"

    // Special Achievements
    case newYearNewYou = "new_year_new_you"
    case comebackKid = "comeback_kid"
}

// MARK: - Achievement Metadata

/// Static metadata for achievement types - separated from @Model to avoid isolation issues
struct AchievementMetadata: Sendable {
    let type: AchievementType
    let displayName: String
    let description: String
    let icon: String
    let category: AchievementCategory
    let requirement: Int
    let colorHex: String

    var color: Color {
        Color(hex: colorHex)
    }

    /// Tier level for display purposes (1-4)
    var tier: Int {
        switch type {
        case .firstStep, .tenBlocks, .firstMilestone:
            return 1
        case .weekWarrior, .fiftyBlocks, .earlyBird, .nightOwl, .adapter:
            return 2
        case .twoWeekTitan, .hundredBlocks, .weekendWarrior, .reflector, .halfwayHero:
            return 3
        case .monthlyMaster, .fiveHundredBlocks, .perfectWeek, .goalGetter, .quarterChampion, .newYearNewYou, .comebackKid:
            return 4
        }
    }
}

// MARK: - Achievement Registry

/// Central registry of all achievement metadata - thread-safe and accessible from anywhere
enum AchievementRegistry {

    private static let metadataMap: [AchievementType: AchievementMetadata] = {
        var map: [AchievementType: AchievementMetadata] = [:]

        // Streak Achievements
        map[.firstStep] = AchievementMetadata(
            type: .firstStep,
            displayName: "First Step",
            description: "Complete your first block",
            icon: "figure.walk",
            category: .streak,
            requirement: 1,
            colorHex: "00D9A5"
        )
        map[.weekWarrior] = AchievementMetadata(
            type: .weekWarrior,
            displayName: "Week Warrior",
            description: "Maintain a 7-day streak",
            icon: "flame",
            category: .streak,
            requirement: 7,
            colorHex: "00B4D8"
        )
        map[.twoWeekTitan] = AchievementMetadata(
            type: .twoWeekTitan,
            displayName: "Two Week Titan",
            description: "Maintain a 14-day streak",
            icon: "flame.fill",
            category: .streak,
            requirement: 14,
            colorHex: "9B5DE5"
        )
        map[.monthlyMaster] = AchievementMetadata(
            type: .monthlyMaster,
            displayName: "Monthly Master",
            description: "Maintain a 30-day streak",
            icon: "crown",
            category: .streak,
            requirement: 30,
            colorHex: "FFB020"
        )
        map[.quarterChampion] = AchievementMetadata(
            type: .quarterChampion,
            displayName: "Quarter Champion",
            description: "Maintain a 90-day streak",
            icon: "crown.fill",
            category: .streak,
            requirement: 90,
            colorHex: "FF6B6B"
        )

        // Completion Achievements
        map[.tenBlocks] = AchievementMetadata(
            type: .tenBlocks,
            displayName: "Getting Started",
            description: "Complete 10 blocks",
            icon: "square.stack",
            category: .completion,
            requirement: 10,
            colorHex: "00D9A5"
        )
        map[.fiftyBlocks] = AchievementMetadata(
            type: .fiftyBlocks,
            displayName: "Making Progress",
            description: "Complete 50 blocks",
            icon: "square.stack.fill",
            category: .completion,
            requirement: 50,
            colorHex: "00B4D8"
        )
        map[.hundredBlocks] = AchievementMetadata(
            type: .hundredBlocks,
            displayName: "Century Club",
            description: "Complete 100 blocks",
            icon: "star",
            category: .completion,
            requirement: 100,
            colorHex: "9B5DE5"
        )
        map[.fiveHundredBlocks] = AchievementMetadata(
            type: .fiveHundredBlocks,
            displayName: "Legendary",
            description: "Complete 500 blocks",
            icon: "star.fill",
            category: .completion,
            requirement: 500,
            colorHex: "FFB020"
        )

        // Consistency Achievements
        map[.earlyBird] = AchievementMetadata(
            type: .earlyBird,
            displayName: "Early Bird",
            description: "Complete 5 blocks before 8 AM",
            icon: "sunrise",
            category: .consistency,
            requirement: 5,
            colorHex: "00B4D8"
        )
        map[.nightOwl] = AchievementMetadata(
            type: .nightOwl,
            displayName: "Night Owl",
            description: "Complete 5 blocks after 8 PM",
            icon: "moon.stars",
            category: .consistency,
            requirement: 5,
            colorHex: "00B4D8"
        )
        map[.weekendWarrior] = AchievementMetadata(
            type: .weekendWarrior,
            displayName: "Weekend Warrior",
            description: "Work on 4 different weekends",
            icon: "calendar.badge.clock",
            category: .consistency,
            requirement: 4,
            colorHex: "9B5DE5"
        )

        // Milestone Achievements
        map[.firstMilestone] = AchievementMetadata(
            type: .firstMilestone,
            displayName: "Milestone Maker",
            description: "Complete your first milestone",
            icon: "flag",
            category: .milestone,
            requirement: 1,
            colorHex: "00D9A5"
        )
        map[.halfwayHero] = AchievementMetadata(
            type: .halfwayHero,
            displayName: "Halfway Hero",
            description: "Reach 50% of your goal",
            icon: "chart.pie",
            category: .milestone,
            requirement: 50,
            colorHex: "00D9A5"
        )
        map[.goalGetter] = AchievementMetadata(
            type: .goalGetter,
            displayName: "Goal Getter",
            description: "Complete an entire goal",
            icon: "trophy",
            category: .milestone,
            requirement: 1,
            colorHex: "FF6B6B"
        )

        // Engagement Achievements
        map[.reflector] = AchievementMetadata(
            type: .reflector,
            displayName: "Deep Thinker",
            description: "Complete 4 weekly reflections",
            icon: "brain.head.profile",
            category: .engagement,
            requirement: 4,
            colorHex: "9B5DE5"
        )
        map[.adapter] = AchievementMetadata(
            type: .adapter,
            displayName: "Flexible Fighter",
            description: "Adapt your schedule 10 times",
            icon: "arrow.triangle.2.circlepath",
            category: .engagement,
            requirement: 10,
            colorHex: "00D9A5"
        )
        map[.perfectWeek] = AchievementMetadata(
            type: .perfectWeek,
            displayName: "Perfect Week",
            description: "Complete every block in a week",
            icon: "checkmark.seal",
            category: .engagement,
            requirement: 1,
            colorHex: "FFB020"
        )

        // Special Achievements
        map[.newYearNewYou] = AchievementMetadata(
            type: .newYearNewYou,
            displayName: "New Year, New You",
            description: "Be active on January 1st",
            icon: "sparkles",
            category: .special,
            requirement: 1,
            colorHex: "FF6B6B"
        )
        map[.comebackKid] = AchievementMetadata(
            type: .comebackKid,
            displayName: "Comeback Kid",
            description: "Return after a break",
            icon: "arrow.uturn.backward",
            category: .special,
            requirement: 1,
            colorHex: "FF6B6B"
        )

        return map
    }()

    /// Get metadata for a specific achievement type
    static func metadata(for type: AchievementType) -> AchievementMetadata {
        guard let meta = metadataMap[type] else {
            fatalError("Missing metadata for achievement type: \(type)")
        }
        return meta
    }

    /// Get all achievements grouped by category
    static func achievementsByCategory() -> [AchievementCategory: [AchievementMetadata]] {
        var grouped: [AchievementCategory: [AchievementMetadata]] = [:]

        for category in AchievementCategory.allCases {
            grouped[category] = AchievementType.allCases
                .map { metadata(for: $0) }
                .filter { $0.category == category }
        }

        return grouped
    }

    /// Get all achievement metadata sorted by category and tier
    static var allMetadata: [AchievementMetadata] {
        AchievementType.allCases
            .map { metadata(for: $0) }
            .sorted { first, second in
                if first.category.sortOrder != second.category.sortOrder {
                    return first.category.sortOrder < second.category.sortOrder
                }
                return first.tier < second.tier
            }
    }
}
