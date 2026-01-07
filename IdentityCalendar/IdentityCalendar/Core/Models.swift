import Foundation
import SwiftData
import SwiftUI

// ============================================================================
// MARK: - USER MODEL
// ============================================================================

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

    // Stats
    var lastEngagementDate: Date?
    var totalBlocksEverCompleted: Int
    var totalGoalsCompleted: Int
    var appOpenCount: Int

    // Relationships
    @Relationship(deleteRule: .cascade) var goals: [IdentityGoal]
    @Relationship(deleteRule: .cascade) var achievements: [Achievement]
    @Relationship(deleteRule: .cascade) var blockTemplates: [BlockTemplate]
    @Relationship(deleteRule: .cascade) var dailyEngagements: [DailyEngagement]

    var activeGoal: IdentityGoal? { goals.first { $0.status == .active } }
    var unlockedAchievements: [Achievement] { achievements.filter { $0.isUnlocked } }
    var newAchievements: [Achievement] { achievements.filter { $0.isNew } }

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

// MARK: - UserDefaults Manager

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()
    private let defaults = UserDefaults.standard

    var hasLaunchedBefore: Bool {
        get { defaults.bool(forKey: "hasLaunchedBefore") }
        set { defaults.set(newValue, forKey: "hasLaunchedBefore") }
    }

    var currentUserId: String? {
        get { defaults.string(forKey: "currentUserId") }
        set { defaults.set(newValue, forKey: "currentUserId") }
    }
}

// ============================================================================
// MARK: - IDENTITY GOAL MODEL
// ============================================================================

@Model
final class IdentityGoal {
    var id: UUID
    var createdAt: Date

    var identityType: IdentityType
    var customIdentityName: String?
    var timeHorizon: TimeHorizon
    var availability: Availability
    var intensity: Intensity
    var planConfidence: PlanConfidence

    var status: GoalStatus
    var pausedAt: Date?
    var completedAt: Date?

    var progressPercentage: Double
    var currentStreak: Int
    var longestStreak: Int
    var totalBlocksCompleted: Int
    var totalBlocksScheduled: Int

    var isFirstWeek: Bool
    var firstWeekStartDate: Date?

    @Relationship(deleteRule: .cascade) var milestones: [Milestone]
    @Relationship(deleteRule: .cascade) var weeklyThemes: [WeeklyTheme]
    @Relationship(deleteRule: .cascade) var planBlocks: [PlanBlock]
    @Relationship(deleteRule: .cascade) var reflections: [WeeklyReflection]
    @Relationship(inverse: \User.goals) var user: User?

    var displayName: String {
        identityType == .custom ? (customIdentityName ?? "My Goal") : identityType.displayName
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        identityType: IdentityType,
        customIdentityName: String? = nil,
        timeHorizon: TimeHorizon,
        availability: Availability,
        intensity: Intensity,
        planConfidence: PlanConfidence,
        status: GoalStatus = .active,
        progressPercentage: Double = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalBlocksCompleted: Int = 0,
        totalBlocksScheduled: Int = 0,
        isFirstWeek: Bool = true,
        firstWeekStartDate: Date? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.identityType = identityType
        self.customIdentityName = customIdentityName
        self.timeHorizon = timeHorizon
        self.availability = availability
        self.intensity = intensity
        self.planConfidence = planConfidence
        self.status = status
        self.progressPercentage = progressPercentage
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalBlocksCompleted = totalBlocksCompleted
        self.totalBlocksScheduled = totalBlocksScheduled
        self.isFirstWeek = isFirstWeek
        self.firstWeekStartDate = firstWeekStartDate ?? createdAt
        self.milestones = []
        self.weeklyThemes = []
        self.planBlocks = []
        self.reflections = []
    }
}

// MARK: - Goal Enums

enum IdentityType: String, Codable, CaseIterable {
    case accountant, fitDisciplined = "fit_disciplined", structuredStudent = "structured_student", entrepreneur, custom

    var displayName: String {
        switch self {
        case .accountant: return "Accountant"
        case .fitDisciplined: return "Fit & Disciplined"
        case .structuredStudent: return "Structured Student"
        case .entrepreneur: return "Entrepreneur"
        case .custom: return "Custom"
        }
    }

    var icon: String {
        switch self {
        case .accountant: return "chart.bar.doc.horizontal"
        case .fitDisciplined: return "figure.run"
        case .structuredStudent: return "book.closed"
        case .entrepreneur: return "lightbulb"
        case .custom: return "star"
        }
    }

    var description: String {
        switch self {
        case .accountant: return "Master financial expertise"
        case .fitDisciplined: return "Build lasting health habits"
        case .structuredStudent: return "Excel in your studies"
        case .entrepreneur: return "Build your vision"
        case .custom: return "Define your own path"
        }
    }
}

enum TimeHorizon: String, Codable, CaseIterable {
    case oneMonth = "1_month", threeMonths = "3_months", sixMonths = "6_months", oneYear = "1_year"

    var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        }
    }

    var days: Int {
        switch self {
        case .oneMonth: return 30
        case .threeMonths: return 90
        case .sixMonths: return 180
        case .oneYear: return 365
        }
    }

    var weeks: Int { days / 7 }
}

enum Availability: String, Codable, CaseIterable {
    case busy, normal, open

    var displayName: String {
        switch self {
        case .busy: return "Busy"
        case .normal: return "Normal"
        case .open: return "Open"
        }
    }

    var description: String {
        switch self {
        case .busy: return "Limited free time"
        case .normal: return "Typical schedule"
        case .open: return "Plenty of time"
        }
    }

    var hoursPerWeek: ClosedRange<Int> {
        switch self {
        case .busy: return 3...6
        case .normal: return 6...12
        case .open: return 12...20
        }
    }
}

enum Intensity: String, Codable, CaseIterable {
    case light, balanced, aggressive

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .balanced: return "Balanced"
        case .aggressive: return "Aggressive"
        }
    }

    var description: String {
        switch self {
        case .light: return "Gentle progress"
        case .balanced: return "Steady growth"
        case .aggressive: return "Push your limits"
        }
    }

    var blockMultiplier: Double {
        switch self {
        case .light: return 0.7
        case .balanced: return 1.0
        case .aggressive: return 1.4
        }
    }
}

enum PlanConfidence: String, Codable {
    case conservative, balanced, ambitious

    var displayName: String {
        switch self {
        case .conservative: return "Conservative"
        case .balanced: return "Balanced"
        case .ambitious: return "Ambitious"
        }
    }

    var value: Double {
        switch self {
        case .conservative: return 0.0
        case .balanced: return 0.5
        case .ambitious: return 1.0
        }
    }

    static func from(value: Double) -> PlanConfidence {
        if value < 0.33 { return .conservative }
        if value < 0.67 { return .balanced }
        return .ambitious
    }
}

enum GoalStatus: String, Codable {
    case active, paused, completed, abandoned
}

// ============================================================================
// MARK: - PLAN BLOCK MODEL
// ============================================================================

@Model
final class PlanBlock {
    var id: UUID
    var createdAt: Date

    var startDateTime: Date
    var endDateTime: Date
    var originalStartDateTime: Date
    var originalEndDateTime: Date

    var title: String
    var intentShort: String
    var blockType: BlockType

    // Rich content
    var location: String?
    var notes: String?
    var zoomLink: String?
    var youtubeLink: String?
    var resourceLinks: [String]?
    var reminder: Int?
    var category: String?
    var priority: BlockPriority?
    var energyLevel: EnergyLevel?
    var tips: [String]?

    // Feature 2: Daily Anchor - one non-negotiable task per day
    var isAnchor: Bool
    // Feature 3: Dopamine-aware classification for AI planning
    var taskClassification: TaskClassification?

    var status: BlockStatus
    var completedAt: Date?
    var skippedAt: Date?
    var movedAt: Date?
    var reducedAt: Date?

    var wasReduced: Bool
    var wasMoved: Bool
    var moveCount: Int
    var weekNumber: Int

    @Relationship(inverse: \IdentityGoal.planBlocks) var goal: IdentityGoal?

    var duration: TimeInterval { endDateTime.timeIntervalSince(startDateTime) }
    var durationMinutes: Int { Int(duration / 60) }
    var isToday: Bool { Calendar.current.isDateInToday(startDateTime) }
    var isPast: Bool { endDateTime < Date() }
    var isFuture: Bool { startDateTime > Date() }
    var isActive: Bool { startDateTime <= Date() && endDateTime >= Date() }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        startDateTime: Date,
        endDateTime: Date,
        title: String,
        intentShort: String,
        blockType: BlockType,
        status: BlockStatus = .scheduled,
        weekNumber: Int = 1,
        location: String? = nil,
        notes: String? = nil,
        zoomLink: String? = nil,
        youtubeLink: String? = nil,
        resourceLinks: [String]? = nil,
        reminder: Int? = nil,
        category: String? = nil,
        priority: BlockPriority? = nil,
        energyLevel: EnergyLevel? = nil,
        tips: [String]? = nil,
        isAnchor: Bool = false,
        taskClassification: TaskClassification? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.startDateTime = startDateTime
        self.endDateTime = endDateTime
        self.originalStartDateTime = startDateTime
        self.originalEndDateTime = endDateTime
        self.title = title
        self.intentShort = intentShort
        self.blockType = blockType
        self.status = status
        self.weekNumber = weekNumber
        self.location = location
        self.notes = notes
        self.zoomLink = zoomLink
        self.youtubeLink = youtubeLink
        self.resourceLinks = resourceLinks
        self.reminder = reminder
        self.category = category
        self.priority = priority
        self.energyLevel = energyLevel
        self.tips = tips
        self.isAnchor = isAnchor
        self.taskClassification = taskClassification
        self.wasReduced = false
        self.wasMoved = false
        self.moveCount = 0
    }

    func markAsCompleted() {
        status = .completed
        completedAt = Date()
    }

    func markAsInProgress() {
        status = .inProgress
    }

    func markAsSkipped() {
        status = .skipped
        skippedAt = Date()
    }

    func move(to newStart: Date) {
        let dur = duration
        startDateTime = newStart
        endDateTime = newStart.addingTimeInterval(dur)
        movedAt = Date()
        wasMoved = true
        moveCount += 1
        status = .scheduled
    }

    func reduce() {
        endDateTime = startDateTime.addingTimeInterval(duration / 2)
        reducedAt = Date()
        wasReduced = true
        status = .scheduled
    }
}

// MARK: - Block Enums

enum BlockType: String, Codable, CaseIterable {
    case focus, light, habit, review

    var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .light: return "Light"
        case .habit: return "Habit"
        case .review: return "Review"
        }
    }

    var color: Color { AppTheme.blockColor(for: self) }
    var backgroundColor: Color { color.opacity(0.15) }

    var icon: String {
        switch self {
        case .focus: return "target"
        case .light: return "leaf"
        case .habit: return "arrow.triangle.2.circlepath"
        case .review: return "text.badge.checkmark"
        }
    }

    var defaultDurationMinutes: Int {
        switch self {
        case .focus: return 60
        case .light: return 30
        case .habit: return 30
        case .review: return 45
        }
    }
}

enum BlockStatus: String, Codable {
    case scheduled, inProgress = "in_progress", completed, skipped, missed

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In Progress"
        case .completed: return "Done"
        case .skipped: return "Skipped"
        case .missed: return "Missed"
        }
    }

    var icon: String {
        switch self {
        case .scheduled: return "calendar"
        case .inProgress: return "play.fill"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "forward.fill"
        case .missed: return "minus.circle"
        }
    }
}

// MARK: - Dopamine-Aware Task Classification (Feature 3)
/// Internal classification for AI planning - not prominently shown to users
enum TaskClassification: String, Codable {
    case momentum    // Easy, quick wins - builds confidence
    case maintenance // Keep life stable - necessary but not growth
    case growth      // Meaningful but effortful - core progress

    /// Weight for daily balance calculations (AI internal use)
    var effortWeight: Double {
        switch self {
        case .momentum: return 0.3
        case .maintenance: return 0.5
        case .growth: return 1.0
        }
    }
}

enum BlockPriority: String, Codable, CaseIterable {
    case low, medium, high, critical

    var displayName: String { rawValue.capitalized }

    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return AppTheme.accentBlue
        case .high: return AppTheme.warning
        case .critical: return AppTheme.error
        }
    }
}

enum EnergyLevel: String, Codable, CaseIterable {
    case low, medium, high

    var displayName: String {
        switch self {
        case .low: return "Low Energy"
        case .medium: return "Medium Energy"
        case .high: return "High Energy"
        }
    }

    var icon: String {
        switch self {
        case .low: return "battery.25"
        case .medium: return "battery.50"
        case .high: return "battery.100"
        }
    }

    var color: Color {
        switch self {
        case .low: return AppTheme.accentPurple
        case .medium: return AppTheme.accentBlue
        case .high: return AppTheme.accent
        }
    }
}

// MARK: - PlanBlock Data (for AI)

extension PlanBlock {
    struct PlanBlockData: Codable {
        let startDateTime: String
        let endDateTime: String
        let title: String
        let blockType: String
        let intentShort: String
        let weekNumber: Int

        func toPlanBlock() -> PlanBlock? {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            guard let start = formatter.date(from: startDateTime),
                  let end = formatter.date(from: endDateTime),
                  let type = BlockType(rawValue: blockType) else { return nil }
            return PlanBlock(startDateTime: start, endDateTime: end, title: title, intentShort: intentShort, blockType: type, weekNumber: weekNumber)
        }
    }
}

// ============================================================================
// MARK: - MILESTONE MODEL
// ============================================================================

@Model
final class Milestone {
    var id: UUID
    var createdAt: Date
    var title: String
    var milestoneDescription: String
    var targetDate: Date
    var weekNumber: Int
    var isCompleted: Bool
    var completedAt: Date?
    var sortOrder: Int

    @Relationship(inverse: \IdentityGoal.milestones) var goal: IdentityGoal?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String,
        description: String,
        targetDate: Date,
        weekNumber: Int,
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.createdAt = createdAt
        self.title = title
        self.milestoneDescription = description
        self.targetDate = targetDate
        self.weekNumber = weekNumber
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.sortOrder = sortOrder
    }

    struct MilestoneData: Codable {
        let title: String
        let description: String
        let weekNumber: Int

        func toMilestone(startDate: Date) -> Milestone {
            let targetDate = Calendar.current.date(byAdding: .weekOfYear, value: weekNumber, to: startDate) ?? startDate
            return Milestone(title: title, description: description, targetDate: targetDate, weekNumber: weekNumber, sortOrder: weekNumber)
        }
    }
}

// ============================================================================
// MARK: - WEEKLY THEME MODEL
// ============================================================================

@Model
final class WeeklyTheme {
    var id: UUID
    var createdAt: Date
    var weekNumber: Int
    var weekStartDate: Date
    var title: String
    var focus: String

    @Relationship(inverse: \IdentityGoal.weeklyThemes) var goal: IdentityGoal?

    var isCurrentWeek: Bool {
        let today = Date()
        let weekEnd = Calendar.current.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate
        return today >= weekStartDate && today < weekEnd
    }

    init(id: UUID = UUID(), createdAt: Date = Date(), weekNumber: Int, weekStartDate: Date, title: String, focus: String) {
        self.id = id
        self.createdAt = createdAt
        self.weekNumber = weekNumber
        self.weekStartDate = weekStartDate
        self.title = title
        self.focus = focus
    }

    struct WeeklyThemeData: Codable {
        let weekNumber: Int
        let title: String
        let focus: String

        func toWeeklyTheme(startDate: Date) -> WeeklyTheme {
            let weekStartDate = Calendar.current.date(byAdding: .weekOfYear, value: weekNumber - 1, to: startDate) ?? startDate
            return WeeklyTheme(weekNumber: weekNumber, weekStartDate: weekStartDate, title: title, focus: focus)
        }
    }
}

// ============================================================================
// MARK: - WEEKLY REFLECTION MODEL
// ============================================================================

@Model
final class WeeklyReflection {
    var id: UUID
    var createdAt: Date
    var weekNumber: Int
    var weekStartDate: Date
    var weekEndDate: Date
    var weekFeeling: WeekFeeling
    var obstacle: WeekObstacle?
    var note: String?
    var blocksCompleted: Int
    var blocksSkipped: Int
    var blocksMoved: Int
    var blocksReduced: Int
    var totalBlocks: Int
    var aiAdjustmentSummary: String?
    var wasProcessed: Bool

    @Relationship(inverse: \IdentityGoal.reflections) var goal: IdentityGoal?

    var completionRate: Double { totalBlocks > 0 ? Double(blocksCompleted) / Double(totalBlocks) : 0 }
    var engagementRate: Double {
        guard totalBlocks > 0 else { return 0 }
        return Double(blocksCompleted + blocksMoved + blocksReduced) / Double(totalBlocks)
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        weekNumber: Int,
        weekStartDate: Date,
        weekEndDate: Date,
        weekFeeling: WeekFeeling,
        obstacle: WeekObstacle? = nil,
        note: String? = nil,
        blocksCompleted: Int = 0,
        blocksSkipped: Int = 0,
        blocksMoved: Int = 0,
        blocksReduced: Int = 0,
        totalBlocks: Int = 0,
        aiAdjustmentSummary: String? = nil,
        wasProcessed: Bool = false
    ) {
        self.id = id
        self.createdAt = createdAt
        self.weekNumber = weekNumber
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.weekFeeling = weekFeeling
        self.obstacle = obstacle
        self.note = note
        self.blocksCompleted = blocksCompleted
        self.blocksSkipped = blocksSkipped
        self.blocksMoved = blocksMoved
        self.blocksReduced = blocksReduced
        self.totalBlocks = totalBlocks
        self.aiAdjustmentSummary = aiAdjustmentSummary
        self.wasProcessed = wasProcessed
    }
}

enum WeekFeeling: String, Codable, CaseIterable {
    case tooEasy = "too_easy", justRight = "just_right", tooHard = "too_hard"

    var displayName: String {
        switch self {
        case .tooEasy: return "Too easy"
        case .justRight: return "Just right"
        case .tooHard: return "Too hard"
        }
    }

    var icon: String {
        switch self {
        case .tooEasy: return "hare"
        case .justRight: return "checkmark.circle"
        case .tooHard: return "tortoise"
        }
    }
}

enum WeekObstacle: String, Codable, CaseIterable {
    case time, energy, motivation, life

    var displayName: String { rawValue.capitalized }

    var icon: String {
        switch self {
        case .time: return "clock"
        case .energy: return "bolt"
        case .motivation: return "heart"
        case .life: return "person.2"
        }
    }
}

// ============================================================================
// MARK: - ACHIEVEMENT MODEL
// ============================================================================

@Model
final class Achievement {
    var id: UUID
    var achievementType: AchievementType
    var unlockedAt: Date?
    var isUnlocked: Bool
    var progress: Int
    var notifiedUser: Bool

    @Relationship(inverse: \User.achievements) var user: User?

    var isNew: Bool {
        guard isUnlocked, let unlockedAt = unlockedAt else { return false }
        let daysSinceUnlock = Calendar.current.dateComponents([.day], from: unlockedAt, to: Date()).day ?? 0
        return daysSinceUnlock <= 3 && !notifiedUser
    }

    init(id: UUID = UUID(), achievementType: AchievementType, isUnlocked: Bool = false, progress: Int = 0) {
        self.id = id
        self.achievementType = achievementType
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.notifiedUser = false
    }

    func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedAt = Date()
        notifiedUser = false
    }
}

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
        case .fiveHundredBlocks: return "Block Master"
        case .earlyBird: return "Early Bird"
        case .nightOwl: return "Night Owl"
        case .weekendWarrior: return "Weekend Warrior"
        case .firstMilestone: return "Milestone Maker"
        case .halfwayHero: return "Halfway Hero"
        case .goalGetter: return "Goal Getter"
        case .reflector: return "Deep Thinker"
        case .adapter: return "Flexible Mind"
        case .perfectWeek: return "Perfect Week"
        case .newYearNewYou: return "Fresh Start"
        case .comebackKid: return "Comeback"
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
        case .weekendWarrior: return "Stay active on 4 weekends"
        case .firstMilestone: return "Complete your first milestone"
        case .halfwayHero: return "Reach 50% of your goal"
        case .goalGetter: return "Complete an entire goal"
        case .reflector: return "Complete 4 weekly reflections"
        case .adapter: return "Reschedule or reduce 10 blocks"
        case .perfectWeek: return "Complete every block in a week"
        case .newYearNewYou: return "Complete a block on New Year's Day"
        case .comebackKid: return "Return after 7 days away"
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
        case .weekendWarrior: return "sun.max"
        case .firstMilestone: return "flag"
        case .halfwayHero: return "chart.pie"
        case .goalGetter: return "trophy"
        case .reflector: return "brain.head.profile"
        case .adapter: return "arrow.triangle.2.circlepath"
        case .perfectWeek: return "checkmark.seal"
        case .newYearNewYou: return "sparkles"
        case .comebackKid: return "arrow.uturn.up"
        }
    }

    var color: Color {
        switch self {
        case .firstStep, .tenBlocks: return AppTheme.accent
        case .weekWarrior, .fiftyBlocks, .earlyBird, .nightOwl, .weekendWarrior: return AppTheme.accentBlue
        case .twoWeekTitan, .hundredBlocks, .reflector, .adapter: return AppTheme.accentPurple
        case .monthlyMaster, .perfectWeek, .quarterChampion, .fiveHundredBlocks: return AppTheme.accentAmber
        case .firstMilestone, .halfwayHero, .comebackKid: return AppTheme.accent
        case .goalGetter, .newYearNewYou: return AppTheme.error
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
        case .weekendWarrior: return 4
        case .firstMilestone, .goalGetter, .perfectWeek, .newYearNewYou, .comebackKid: return 1
        case .halfwayHero: return 50
        case .reflector: return 4
        case .adapter: return 10
        }
    }
}

enum AchievementCategory: String, CaseIterable {
    case streak = "Streaks"
    case completion = "Completion"
    case consistency = "Consistency"
    case milestone = "Milestones"
}

// ============================================================================
// MARK: - BLOCK TEMPLATE MODEL
// ============================================================================

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
    var category: String?
    var priority: BlockPriority?
    var energyLevel: EnergyLevel?
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var recurrenceDays: [Int]?
    var preferredTimeHour: Int?
    var preferredTimeMinute: Int?
    var timesUsed: Int
    var lastUsedAt: Date?
    var isFavorite: Bool

    @Relationship(inverse: \User.blockTemplates) var user: User?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        title: String,
        intentShort: String,
        blockType: BlockType = .focus,
        durationMinutes: Int = 45,
        location: String? = nil,
        notes: String? = nil,
        category: String? = nil,
        priority: BlockPriority? = nil,
        energyLevel: EnergyLevel? = nil,
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
        self.category = category
        self.priority = priority
        self.energyLevel = energyLevel
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
        return PlanBlock(startDateTime: startTime, endDateTime: endTime, title: title, intentShort: intentShort, blockType: blockType, weekNumber: weekNumber, location: location, notes: notes, category: category, priority: priority, energyLevel: energyLevel)
    }
}

enum RecurrencePattern: String, Codable, CaseIterable {
    case daily, weekly, weekdays, weekends, biweekly, monthly

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
}

// ============================================================================
// MARK: - DAILY ENGAGEMENT MODEL
// ============================================================================

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

    // Feature 2: Track if anchor task was completed
    var anchorCompleted: Bool

    // Feature 4: End-of-day micro reflection (10 seconds max)
    var reflectionNote: String?
    var reflectionPromptShown: Bool
    var reflectionSkipped: Bool

    @Relationship(inverse: \User.dailyEngagements) var user: User?

    var completionRate: Double {
        blocksScheduled > 0 ? Double(blocksCompleted) / Double(blocksScheduled) : 0
    }

    /// Day is considered "successful" if anchor was completed (Feature 2)
    var isDaySuccessful: Bool { anchorCompleted }

    /// Check if this is a weekend day
    var isWeekend: Bool { Calendar.current.isDateInWeekend(date) }

    /// Record block completion - updates engagement metrics
    func recordBlockCompletion(block: PlanBlock) {
        blocksCompleted += 1
        totalMinutesCompleted += block.durationMinutes

        // Track time bounds
        if earliestBlockTime == nil || block.startDateTime < (earliestBlockTime ?? .distantFuture) {
            earliestBlockTime = block.startDateTime
        }
        if latestBlockTime == nil || block.endDateTime > (latestBlockTime ?? .distantPast) {
            latestBlockTime = block.endDateTime
        }
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
        engagedWithApp: Bool = true,
        anchorCompleted: Bool = false,
        reflectionNote: String? = nil,
        reflectionPromptShown: Bool = false,
        reflectionSkipped: Bool = false
    ) {
        self.id = id
        self.date = date
        self.blocksCompleted = blocksCompleted
        self.blocksScheduled = blocksScheduled
        self.blocksSkipped = blocksSkipped
        self.blocksMoved = blocksMoved
        self.blocksReduced = blocksReduced
        self.totalMinutesCompleted = totalMinutesCompleted
        self.engagedWithApp = engagedWithApp
        self.anchorCompleted = anchorCompleted
        self.reflectionNote = reflectionNote
        self.reflectionPromptShown = reflectionPromptShown
        self.reflectionSkipped = reflectionSkipped
    }
}

// ============================================================================
// MARK: - SUBSCRIPTION MODEL
// ============================================================================

struct Subscription {
    let tier: SubscriptionTier
    let status: SubscriptionStatus
    let expiresAt: Date?
    let startedAt: Date?

    var isActive: Bool {
        switch status {
        case .active, .trial:
            if let expiresAt = expiresAt { return Date() < expiresAt }
            return true
        default: return false
        }
    }

    var isPremium: Bool { isActive && tier == .pro }

    static let free = Subscription(tier: .free, status: .active, expiresAt: nil, startedAt: nil)
}

enum SubscriptionTier: String, Codable {
    case free, pro

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }

    var maxGoals: Int { self == .free ? 1 : .max }
}

enum SubscriptionStatus: String, Codable {
    case active, trial, expired, cancelled, none
}

enum SubscriptionProduct: String, CaseIterable {
    case monthlyPro = "com.endlessfuture.pro.monthly"
    case yearlyPro = "com.endlessfuture.pro.yearly"

    var displayName: String { self == .monthlyPro ? "Monthly" : "Yearly" }
    var price: String { self == .monthlyPro ? "$9.99" : "$59.99" }
    var pricePerMonth: String { self == .monthlyPro ? "$9.99/mo" : "$4.99/mo" }
    var savings: String? { self == .yearlyPro ? "Save 50%" : nil }
}

// ============================================================================
// MARK: - ANALYTICS HELPERS
// ============================================================================

struct WeeklyStats {
    let weekStart: Date
    let totalBlocks: Int
    let completedBlocks: Int
    let skippedBlocks: Int
    let totalMinutes: Int
    let averageCompletionRate: Double
    let bestDay: String?
    let mostProductiveHour: Int?

    var completionRate: Double { totalBlocks > 0 ? Double(completedBlocks) / Double(totalBlocks) : 0 }
    var hoursCompleted: Double { Double(totalMinutes) / 60.0 }
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
        let color = progress >= 0.8 ? AppTheme.accent : (progress >= 0.5 ? AppTheme.accentBlue : AppTheme.accentPurple)
        return ProgressRingData(progress: progress, label: "\(completed)/\(scheduled)", sublabel: "Today", color: color)
    }

    static func streak(current: Int, target: Int = 7) -> ProgressRingData {
        let progress = min(1.0, Double(current) / Double(target))
        return ProgressRingData(progress: progress, label: "\(current)", sublabel: "Day Streak", color: current >= 7 ? AppTheme.accentAmber : AppTheme.accent)
    }
}

// ============================================================================
// MARK: - FEATURE 1: SOFT RECOVERY MODE (Invisible Reset System)
// ============================================================================

/// Represents the user's current momentum state - used internally by AI
/// Never exposed to users as "failure" or "recovery"
struct MomentumState {
    let recentCompletionRate: Double  // Last 3-7 days
    let missedDaysInWindow: Int       // Days with 0 completions
    let averageBlocksPerDay: Double   // Baseline

    /// Determines load adjustment factor (0.5 = lighter, 1.0 = normal, 1.2 = increased)
    var loadFactor: Double {
        // Soft recovery: reduce load if struggling
        if missedDaysInWindow >= 2 || recentCompletionRate < 0.3 {
            return 0.5  // Significant reduction
        } else if missedDaysInWindow >= 1 || recentCompletionRate < 0.5 {
            return 0.7  // Moderate reduction
        } else if recentCompletionRate > 0.85 {
            return 1.1  // Slight increase if doing well
        }
        return 1.0  // Normal
    }

    /// Recovery-aware AI messages (reframing, not failure language)
    var aiTone: RecoveryTone {
        if loadFactor < 0.8 {
            return .rebuilding
        } else if loadFactor > 1.0 {
            return .expanding
        }
        return .steady
    }

    /// Duration of adjusted state (in days)
    var adjustmentDuration: Int {
        if loadFactor < 0.6 { return 3 }
        if loadFactor < 0.8 { return 2 }
        return 1
    }
}

enum RecoveryTone {
    case rebuilding  // "Let's reset and rebuild momentum"
    case steady      // Normal operation
    case expanding   // "You're ready for more"

    var aiPhrases: [String] {
        switch self {
        case .rebuilding:
            return [
                "Let's ease back in.",
                "We'll rebuild momentum together.",
                "Starting fresh with a lighter load.",
                "One step at a time."
            ]
        case .steady:
            return [
                "Keeping the rhythm going.",
                "Steady progress today.",
                "You've got this."
            ]
        case .expanding:
            return [
                "Ready for a bit more challenge.",
                "Building on your momentum.",
                "Let's push a little further."
            ]
        }
    }

    var randomPhrase: String {
        aiPhrases.randomElement() ?? aiPhrases[0]
    }
}

// ============================================================================
// MARK: - FEATURE 4: END-OF-DAY REFLECTION PROMPTS
// ============================================================================

/// Simple reflection prompts - one question, 10 seconds max, always skippable
enum DailyReflectionPrompt: CaseIterable {
    case whatWentWell
    case whatWasHard
    case energyLevel
    case oneWin
    case obstacle

    var question: String {
        switch self {
        case .whatWentWell: return "What went well today?"
        case .whatWasHard: return "What made today harder than expected?"
        case .energyLevel: return "How was your energy today?"
        case .oneWin: return "What's one small win from today?"
        case .obstacle: return "Anything get in your way?"
        }
    }

    var placeholder: String {
        switch self {
        case .whatWentWell: return "Something positive..."
        case .whatWasHard: return "A challenge or obstacle..."
        case .energyLevel: return "High, medium, low..."
        case .oneWin: return "Even something small..."
        case .obstacle: return "Or nothing, that's fine too..."
        }
    }

    /// Select prompt based on day's outcome for more relevant questions
    static func selectPrompt(anchorCompleted: Bool, completionRate: Double) -> DailyReflectionPrompt {
        if anchorCompleted && completionRate > 0.7 {
            // Good day - ask about wins
            return [.whatWentWell, .oneWin].randomElement()!
        } else if completionRate < 0.3 {
            // Tough day - ask gently about obstacles
            return [.whatWasHard, .obstacle, .energyLevel].randomElement()!
        }
        // Average day - mix of prompts
        return allCases.randomElement()!
    }
}

// ============================================================================
// MARK: - FEATURE 5: TIME-TO-TRUST INDICATOR
// ============================================================================

/// Represents consistency confidence - never resets to zero, no streaks
/// Focuses on long-term pattern rather than daily pressure
struct TrustIndicator {
    let successfulDays: Int       // Days where anchor was completed
    let totalTrackedDays: Int     // Total days in system
    let longestConsistentRun: Int // Best streak (internal use only)

    /// Trust level as a smooth progression (0.0 to 1.0)
    var trustLevel: Double {
        guard totalTrackedDays > 0 else { return 0 }
        // Weighted: recent success matters more but never goes to zero
        let baseLevel = Double(successfulDays) / Double(max(totalTrackedDays, 7))
        // Minimum 10% if they've had any success - never feels like starting over
        let minimum = successfulDays > 0 ? 0.1 : 0
        return max(minimum, min(1.0, baseLevel))
    }

    /// Human-readable status - calm, non-judgmental language
    var statusMessage: String {
        switch trustLevel {
        case 0..<0.2:
            return "Getting started"
        case 0.2..<0.4:
            return "Building foundation"
        case 0.4..<0.6:
            return "Consistency emerging"
        case 0.6..<0.8:
            return "Routine stabilizing"
        case 0.8...1.0:
            return "Momentum established"
        default:
            return "In progress"
        }
    }

    /// Subtle color for UI (muted, not attention-grabbing)
    var indicatorColor: Color {
        switch trustLevel {
        case 0..<0.3:
            return AppTheme.secondaryText
        case 0.3..<0.6:
            return AppTheme.accentBlue.opacity(0.7)
        case 0.6..<0.85:
            return AppTheme.accent.opacity(0.7)
        default:
            return AppTheme.accent
        }
    }
}
