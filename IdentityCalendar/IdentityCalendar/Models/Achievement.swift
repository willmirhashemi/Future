import Foundation
import SwiftData
import SwiftUI

/// Represents an unlockable achievement/badge in the app
@Model
final class Achievement {
    var id: UUID
    var achievementType: AchievementType
    var unlockedAt: Date?
    var isUnlocked: Bool
    var progress: Int // Current progress toward unlocking
    var notifiedUser: Bool // Whether user has been notified of unlock

    @Relationship(inverse: \User.achievements)
    var user: User?

    var isNew: Bool {
        guard isUnlocked, let unlockedAt = unlockedAt else { return false }
        let daysSinceUnlock = Calendar.current.dateComponents([.day], from: unlockedAt, to: Date()).day ?? 0
        return daysSinceUnlock <= 3 && !notifiedUser
    }

    init(
        id: UUID = UUID(),
        achievementType: AchievementType,
        unlockedAt: Date? = nil,
        isUnlocked: Bool = false,
        progress: Int = 0,
        notifiedUser: Bool = false
    ) {
        self.id = id
        self.achievementType = achievementType
        self.unlockedAt = unlockedAt
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.notifiedUser = notifiedUser
    }

    func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedAt = Date()
        notifiedUser = false
    }

    func markAsNotified() {
        notifiedUser = true
    }
}

// MARK: - Achievement Types

enum AchievementType: String, Codable, CaseIterable {
    // Streak Achievements
    case firstStep = "first_step"           // Complete first block
    case weekWarrior = "week_warrior"       // 7-day streak
    case twoWeekTitan = "two_week_titan"    // 14-day streak
    case monthlyMaster = "monthly_master"   // 30-day streak
    case quarterChampion = "quarter_champion" // 90-day streak

    // Completion Achievements
    case tenBlocks = "ten_blocks"           // Complete 10 blocks
    case fiftyBlocks = "fifty_blocks"       // Complete 50 blocks
    case hundredBlocks = "hundred_blocks"   // Complete 100 blocks
    case fiveHundredBlocks = "five_hundred_blocks" // Complete 500 blocks

    // Consistency Achievements
    case earlyBird = "early_bird"           // Complete 5 blocks before 8 AM
    case nightOwl = "night_owl"             // Complete 5 blocks after 8 PM
    case weekendWarrior = "weekend_warrior" // Complete blocks on 4 weekends

    // Milestone Achievements
    case firstMilestone = "first_milestone" // Complete first milestone
    case halfwayHero = "halfway_hero"       // Reach 50% progress
    case goalGetter = "goal_getter"         // Complete a goal

    // Engagement Achievements
    case reflector = "reflector"            // Complete 4 weekly reflections
    case adapter = "adapter"                // Move/reduce blocks 10 times
    case perfectWeek = "perfect_week"       // Complete all blocks in a week

    // Special Achievements
    case newYearNewYou = "new_year_new_you" // Active on Jan 1
    case comebackKid = "comeback_kid"       // Return after 7+ days inactive

    var displayName: String {
        switch self {
        case .firstStep: return "First Step"
        case .weekWarrior: return "Week Warrior"
        case .twoWeekTitan: return "Two Week Titan"
        case .monthlyMaster: return "Monthly Master"
        case .quarterChampion: return "Quarter Champion"
        case .tenBlocks: return "Getting Started"
        case .fiftyBlocks: return "Making Progress"
        case .hundredBlocks: return "Century Club"
        case .fiveHundredBlocks: return "Legendary"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .weekendWarrior: return "Weekend Warrior"
        case .firstMilestone: return "Milestone Maker"
        case .halfwayHero: return "Halfway Hero"
        case .goalGetter: return "Goal Getter"
        case .reflector: return "Deep Thinker"
        case .adapter: return "Flexible Fighter"
        case .perfectWeek: return "Perfect Week"
        case .newYearNewYou: return "New Year, New You"
        case .comebackKid: return "Comeback Kid"
        }
    }

    var description: String {
        switch self {
        case .firstStep: return "Complete your first block"
        case .weekWarrior: return "Maintain a 7-day streak"
        case .twoWeekTitan: return "Maintain a 14-day streak"
        case .monthlyMaster: return "Maintain a 30-day streak"
        case .quarterChampion: return "Maintain a 90-day streak"
        case .tenBlocks: return "Complete 10 blocks"
        case .fiftyBlocks: return "Complete 50 blocks"
        case .hundredBlocks: return "Complete 100 blocks"
        case .fiveHundredBlocks: return "Complete 500 blocks"
        case .earlyBird: return "Complete 5 blocks before 8 AM"
        case .nightOwl: return "Complete 5 blocks after 8 PM"
        case .weekendWarrior: return "Work on 4 different weekends"
        case .firstMilestone: return "Complete your first milestone"
        case .halfwayHero: return "Reach 50% of your goal"
        case .goalGetter: return "Complete an entire goal"
        case .reflector: return "Complete 4 weekly reflections"
        case .adapter: return "Adapt your schedule 10 times"
        case .perfectWeek: return "Complete every block in a week"
        case .newYearNewYou: return "Be active on January 1st"
        case .comebackKid: return "Return after a break"
        }
    }

    var icon: String {
        switch self {
        case .firstStep: return "figure.walk"
        case .weekWarrior: return "flame"
        case .twoWeekTitan: return "flame.fill"
        case .monthlyMaster: return "crown"
        case .quarterChampion: return "crown.fill"
        case .tenBlocks: return "square.stack"
        case .fiftyBlocks: return "square.stack.fill"
        case .hundredBlocks: return "star"
        case .fiveHundredBlocks: return "star.fill"
        case .earlyBird: return "sunrise"
        case .nightOwl: return "moon.stars"
        case .weekendWarrior: return "calendar.badge.clock"
        case .firstMilestone: return "flag"
        case .halfwayHero: return "chart.pie"
        case .goalGetter: return "trophy"
        case .reflector: return "brain.head.profile"
        case .adapter: return "arrow.triangle.2.circlepath"
        case .perfectWeek: return "checkmark.seal"
        case .newYearNewYou: return "sparkles"
        case .comebackKid: return "arrow.uturn.backward"
        }
    }

    var color: Color {
        switch self {
        case .firstStep, .tenBlocks:
            return Color(hex: "00D9A5") // Green - starter
        case .weekWarrior, .fiftyBlocks, .earlyBird, .nightOwl:
            return Color(hex: "00B4D8") // Blue - intermediate
        case .twoWeekTitan, .hundredBlocks, .weekendWarrior, .reflector:
            return Color(hex: "9B5DE5") // Purple - advanced
        case .monthlyMaster, .fiveHundredBlocks, .perfectWeek:
            return Color(hex: "FFB020") // Gold - elite
        case .quarterChampion, .goalGetter:
            return Color(hex: "FF6B6B") // Red - legendary
        case .firstMilestone, .halfwayHero, .adapter:
            return Color(hex: "00D9A5")
        case .newYearNewYou, .comebackKid:
            return Color(hex: "FF6B6B")
        }
    }

    var requirement: Int {
        switch self {
        case .firstStep: return 1
        case .weekWarrior: return 7
        case .twoWeekTitan: return 14
        case .monthlyMaster: return 30
        case .quarterChampion: return 90
        case .tenBlocks: return 10
        case .fiftyBlocks: return 50
        case .hundredBlocks: return 100
        case .fiveHundredBlocks: return 500
        case .earlyBird: return 5
        case .nightOwl: return 5
        case .weekendWarrior: return 4
        case .firstMilestone: return 1
        case .halfwayHero: return 50
        case .goalGetter: return 1
        case .reflector: return 4
        case .adapter: return 10
        case .perfectWeek: return 1
        case .newYearNewYou: return 1
        case .comebackKid: return 1
        }
    }

    var category: AchievementCategory {
        switch self {
        case .firstStep, .weekWarrior, .twoWeekTitan, .monthlyMaster, .quarterChampion:
            return .streak
        case .tenBlocks, .fiftyBlocks, .hundredBlocks, .fiveHundredBlocks:
            return .completion
        case .earlyBird, .nightOwl, .weekendWarrior, .perfectWeek:
            return .consistency
        case .firstMilestone, .halfwayHero, .goalGetter:
            return .milestone
        case .reflector, .adapter:
            return .engagement
        case .newYearNewYou, .comebackKid:
            return .special
        }
    }
}

enum AchievementCategory: String, CaseIterable {
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
}
