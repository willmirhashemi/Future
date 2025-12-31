import Foundation
import SwiftData
import SwiftUI

// MARK: - Achievement Types (must be defined before Achievement class)

enum AchievementType: String, Codable, CaseIterable {
    case firstStep = "first_step"
    case weekWarrior = "week_warrior"
    case twoWeekTitan = "two_week_titan"
    case monthlyMaster = "monthly_master"
    case quarterChampion = "quarter_champion"
    case tenBlocks = "ten_blocks"
    case fiftyBlocks = "fifty_blocks"
    case hundredBlocks = "hundred_blocks"
    case fiveHundredBlocks = "five_hundred_blocks"
    case earlyBird = "early_bird"
    case nightOwl = "night_owl"
    case weekendWarrior = "weekend_warrior"
    case firstMilestone = "first_milestone"
    case halfwayHero = "halfway_hero"
    case goalGetter = "goal_getter"
    case reflector = "reflector"
    case adapter = "adapter"
    case perfectWeek = "perfect_week"
    case newYearNewYou = "new_year_new_you"
    case comebackKid = "comeback_kid"

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
        case .firstStep, .tenBlocks, .firstMilestone, .halfwayHero, .adapter:
            return Color(hex: "00D9A5")
        case .weekWarrior, .fiftyBlocks, .earlyBird, .nightOwl:
            return Color(hex: "00B4D8")
        case .twoWeekTitan, .hundredBlocks, .weekendWarrior, .reflector:
            return Color(hex: "9B5DE5")
        case .monthlyMaster, .fiveHundredBlocks, .perfectWeek:
            return Color(hex: "FFB020")
        case .quarterChampion, .goalGetter, .newYearNewYou, .comebackKid:
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
        case .earlyBird, .nightOwl: return 5
        case .weekendWarrior, .reflector: return 4
        case .firstMilestone, .halfwayHero, .goalGetter, .perfectWeek, .newYearNewYou, .comebackKid: return 1
        case .adapter: return 10
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

// MARK: - Recurrence Pattern (must be defined before BlockTemplate class)

enum RecurrencePattern: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case weekdays = "weekdays"
    case weekends = "weekends"
    case biweekly = "biweekly"
    case monthly = "monthly"

    var displayName: String {
        switch self {
        case .daily: return "Every Day"
        case .weekly: return "Weekly"
        case .weekdays: return "Weekdays Only"
        case .weekends: return "Weekends Only"
        case .biweekly: return "Every 2 Weeks"
        case .monthly: return "Monthly"
        }
    }

    var icon: String {
        switch self {
        case .daily: return "arrow.clockwise"
        case .weekly: return "calendar.badge.clock"
        case .weekdays: return "briefcase"
        case .weekends: return "sun.max"
        case .biweekly: return "calendar.badge.plus"
        case .monthly: return "calendar"
        }
    }
}

// MARK: - Achievement Model

@Model
final class Achievement {
    var id: UUID
    var achievementType: AchievementType
    var unlockedAt: Date?
    var isUnlocked: Bool
    var progress: Int
    var notifiedUser: Bool

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

// MARK: - BlockTemplate Model

@Model
final class BlockTemplate {
    var id: UUID
    var createdAt: Date
    var title: String
    var intentShort: String
    var blockType: BlockType
    var durationMinutes: Int
    var location: String?
    var notes: String?
    var zoomLink: String?
    var youtubeLink: String?
    var category: String?
    var priority: BlockPriority?
    var energyLevel: EnergyLevel?
    var tips: [String]?
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var recurrenceDays: [Int]?
    var preferredTimeHour: Int?
    var preferredTimeMinute: Int?
    var timesUsed: Int
    var lastUsedAt: Date?
    var isFavorite: Bool

    @Relationship(inverse: \User.blockTemplates)
    var user: User?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String,
        intentShort: String,
        blockType: BlockType = .focus,
        durationMinutes: Int = 45,
        location: String? = nil,
        notes: String? = nil,
        zoomLink: String? = nil,
        youtubeLink: String? = nil,
        category: String? = nil,
        priority: BlockPriority? = nil,
        energyLevel: EnergyLevel? = nil,
        tips: [String]? = nil,
        isRecurring: Bool = false,
        recurrencePattern: RecurrencePattern? = nil,
        recurrenceDays: [Int]? = nil,
        preferredTimeHour: Int? = nil,
        preferredTimeMinute: Int? = nil,
        timesUsed: Int = 0,
        lastUsedAt: Date? = nil,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.intentShort = intentShort
        self.blockType = blockType
        self.durationMinutes = durationMinutes
        self.location = location
        self.notes = notes
        self.zoomLink = zoomLink
        self.youtubeLink = youtubeLink
        self.category = category
        self.priority = priority
        self.energyLevel = energyLevel
        self.tips = tips
        self.isRecurring = isRecurring
        self.recurrencePattern = recurrencePattern
        self.recurrenceDays = recurrenceDays
        self.preferredTimeHour = preferredTimeHour
        self.preferredTimeMinute = preferredTimeMinute
        self.timesUsed = timesUsed
        self.lastUsedAt = lastUsedAt
        self.isFavorite = isFavorite
    }

    func createBlock(for date: Date, weekNumber: Int = 1) -> PlanBlock {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = preferredTimeHour ?? 9
        components.minute = preferredTimeMinute ?? 0

        let startTime = calendar.date(from: components) ?? date
        let endTime = startTime.addingTimeInterval(Double(durationMinutes * 60))

        timesUsed += 1
        lastUsedAt = Date()

        return PlanBlock(
            startDateTime: startTime,
            endDateTime: endTime,
            title: title,
            intentShort: intentShort,
            blockType: blockType,
            weekNumber: weekNumber,
            location: location,
            notes: notes,
            zoomLink: zoomLink,
            youtubeLink: youtubeLink,
            category: category,
            priority: priority,
            energyLevel: energyLevel,
            tips: tips
        )
    }

    func nextOccurrences(from startDate: Date, count: Int = 7) -> [Date] {
        guard isRecurring, let pattern = recurrencePattern else { return [] }

        var dates: [Date] = []
        let calendar = Calendar.current
        var currentDate = startDate

        while dates.count < count {
            switch pattern {
            case .daily:
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate

            case .weekly:
                if let days = recurrenceDays {
                    let weekday = calendar.component(.weekday, from: currentDate)
                    if days.contains(weekday) {
                        dates.append(currentDate)
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate

            case .weekdays:
                let weekday = calendar.component(.weekday, from: currentDate)
                if weekday >= 2 && weekday <= 6 {
                    dates.append(currentDate)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate

            case .weekends:
                let weekday = calendar.component(.weekday, from: currentDate)
                if weekday == 1 || weekday == 7 {
                    dates.append(currentDate)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate

            case .biweekly:
                let weekNumber = calendar.component(.weekOfYear, from: currentDate)
                if let days = recurrenceDays {
                    let weekday = calendar.component(.weekday, from: currentDate)
                    if weekNumber % 2 == 0 && days.contains(weekday) {
                        dates.append(currentDate)
                    }
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate

            case .monthly:
                dates.append(currentDate)
                currentDate = calendar.date(byAdding: .month, value: 1, to: currentDate) ?? currentDate
            }
        }

        return dates
    }

    var displayTime: String? {
        guard let hour = preferredTimeHour, let minute = preferredTimeMinute else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return nil
    }

    var recurrenceDescription: String? {
        guard isRecurring, let pattern = recurrencePattern else { return nil }
        switch pattern {
        case .daily: return "Every day"
        case .weekly:
            if let days = recurrenceDays, !days.isEmpty {
                let dayNames = days.compactMap { dayNumber -> String? in
                    let symbols = Calendar.current.shortWeekdaySymbols
                    let index = dayNumber - 1
                    return index >= 0 && index < symbols.count ? symbols[index] : nil
                }
                return dayNames.joined(separator: ", ")
            }
            return "Weekly"
        case .weekdays: return "Weekdays"
        case .weekends: return "Weekends"
        case .biweekly: return "Every 2 weeks"
        case .monthly: return "Monthly"
        }
    }

    static let defaultTemplates: [(title: String, intent: String, type: BlockType, duration: Int, category: String)] = [
        ("Morning Workout", "Start the day with energy", .focus, 45, "Fitness"),
        ("Deep Work Session", "Focused, uninterrupted work", .focus, 90, "Work"),
        ("Study Block", "Active learning and review", .focus, 60, "Education"),
        ("Meditation", "Calm the mind", .habit, 15, "Wellness"),
        ("Journaling", "Reflect and plan", .light, 20, "Wellness"),
        ("Reading Time", "Learn something new", .light, 30, "Learning"),
        ("Meal Prep", "Prepare healthy meals", .habit, 60, "Health"),
        ("Weekly Review", "Assess progress", .review, 45, "Planning"),
        ("Networking", "Connect with others", .light, 30, "Career"),
        ("Creative Practice", "Work on creative skills", .focus, 60, "Creative")
    ]
}

// MARK: - DailyEngagement Model

@Model
final class DailyEngagement {
    var id: UUID
    var date: Date
    var blocksCompleted: Int
    var blocksScheduled: Int
    var blocksSkipped: Int
    var blocksMoved: Int
    var blocksReduced: Int
    var totalMinutesCompleted: Int
    var earliestBlockTime: Date?
    var latestBlockTime: Date?
    var engagedWithApp: Bool

    @Relationship(inverse: \User.dailyEngagements)
    var user: User?

    var completionRate: Double {
        guard blocksScheduled > 0 else { return 0 }
        return Double(blocksCompleted) / Double(blocksScheduled)
    }

    var isWeekend: Bool {
        let weekday = Calendar.current.component(.weekday, from: date)
        return weekday == 1 || weekday == 7
    }

    init(
        id: UUID = UUID(),
        date: Date = Calendar.current.startOfDay(for: Date()),
        blocksCompleted: Int = 0,
        blocksScheduled: Int = 0,
        blocksSkipped: Int = 0,
        blocksMoved: Int = 0,
        blocksReduced: Int = 0,
        totalMinutesCompleted: Int = 0,
        earliestBlockTime: Date? = nil,
        latestBlockTime: Date? = nil,
        engagedWithApp: Bool = true
    ) {
        self.id = id
        self.date = date
        self.blocksCompleted = blocksCompleted
        self.blocksScheduled = blocksScheduled
        self.blocksSkipped = blocksSkipped
        self.blocksMoved = blocksMoved
        self.blocksReduced = blocksReduced
        self.totalMinutesCompleted = totalMinutesCompleted
        self.earliestBlockTime = earliestBlockTime
        self.latestBlockTime = latestBlockTime
        self.engagedWithApp = engagedWithApp
    }

    func recordBlockCompletion(block: PlanBlock) {
        blocksCompleted += 1
        totalMinutesCompleted += block.durationMinutes
        if earliestBlockTime == nil || block.startDateTime < earliestBlockTime! {
            earliestBlockTime = block.startDateTime
        }
        if latestBlockTime == nil || block.startDateTime > latestBlockTime! {
            latestBlockTime = block.startDateTime
        }
    }
}

// MARK: - User Model

@Model
final class User {
    var id: UUID
    var createdAt: Date
    var hasCompletedOnboarding: Bool
    var isPremium: Bool
    var premiumExpiresAt: Date?
    var blockRemindersEnabled: Bool
    var reflectionRemindersEnabled: Bool
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
    var lastEngagementDate: Date?
    var totalBlocksEverCompleted: Int
    var totalGoalsCompleted: Int
    var appOpenCount: Int

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

// MARK: - Analytics Helper Structs

struct WeeklyStats {
    let weekStart: Date
    let totalBlocks: Int
    let completedBlocks: Int
    let skippedBlocks: Int
    let totalMinutes: Int
    let averageCompletionRate: Double
    let bestDay: String?
    let mostProductiveHour: Int?

    var completionRate: Double {
        guard totalBlocks > 0 else { return 0 }
        return Double(completedBlocks) / Double(totalBlocks)
    }

    var hoursCompleted: Double {
        Double(totalMinutes) / 60.0
    }
}

struct MonthlyStats {
    let month: Date
    let totalBlocks: Int
    let completedBlocks: Int
    let streakDays: Int
    let averageBlocksPerDay: Double
    let weeklyComparison: [Double]
}

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let lastActiveDate: Date?
    let streakStartDate: Date?
    let isActiveToday: Bool

    var streakAtRisk: Bool {
        guard let lastActive = lastActiveDate else { return false }
        let hoursSinceActive = Calendar.current.dateComponents([.hour], from: lastActive, to: Date()).hour ?? 0
        return hoursSinceActive > 20 && !isActiveToday
    }
}

struct ProgressRingData {
    let progress: Double
    let label: String
    let sublabel: String
    let color: Color

    static func daily(completed: Int, scheduled: Int) -> ProgressRingData {
        let progress = scheduled > 0 ? Double(completed) / Double(scheduled) : 0
        return ProgressRingData(
            progress: progress,
            label: "\(completed)/\(scheduled)",
            sublabel: "Today's Blocks",
            color: progress >= 0.8 ? Color(hex: "00D9A5") : (progress >= 0.5 ? Color(hex: "00B4D8") : Color(hex: "9B5DE5"))
        )
    }

    static func weekly(completed: Int, scheduled: Int) -> ProgressRingData {
        let progress = scheduled > 0 ? Double(completed) / Double(scheduled) : 0
        return ProgressRingData(
            progress: progress,
            label: "\(Int(progress * 100))%",
            sublabel: "This Week",
            color: progress >= 0.8 ? Color(hex: "00D9A5") : (progress >= 0.5 ? Color(hex: "00B4D8") : Color(hex: "9B5DE5"))
        )
    }

    static func streak(current: Int, target: Int = 7) -> ProgressRingData {
        let progress = min(1.0, Double(current) / Double(target))
        return ProgressRingData(
            progress: progress,
            label: "\(current)",
            sublabel: "Day Streak",
            color: current >= 7 ? Color(hex: "FFB020") : Color(hex: "00D9A5")
        )
    }
}

// MARK: - User Defaults Wrapper

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
