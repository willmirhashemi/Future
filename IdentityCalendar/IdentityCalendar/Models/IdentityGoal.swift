import Foundation
import SwiftData

/// The core identity goal that the user is working towards
@Model
final class IdentityGoal {
    var id: UUID
    var createdAt: Date

    // Identity configuration
    var identityType: IdentityType
    var customIdentityName: String?
    var timeHorizon: TimeHorizon
    var availability: Availability
    var intensity: Intensity
    var planConfidence: PlanConfidence

    // Status tracking
    var status: GoalStatus
    var pausedAt: Date?
    var completedAt: Date?

    // Progress
    var progressPercentage: Double
    var currentStreak: Int
    var longestStreak: Int
    var totalBlocksCompleted: Int
    var totalBlocksScheduled: Int

    // First week tracking for delight experience
    var isFirstWeek: Bool
    var firstWeekStartDate: Date?

    // Relationships
    @Relationship(deleteRule: .cascade)
    var milestones: [Milestone]

    @Relationship(deleteRule: .cascade)
    var weeklyThemes: [WeeklyTheme]

    @Relationship(deleteRule: .cascade)
    var planBlocks: [PlanBlock]

    @Relationship(deleteRule: .cascade)
    var reflections: [WeeklyReflection]

    @Relationship(inverse: \User.goals)
    var user: User?

    var displayName: String {
        switch identityType {
        case .custom:
            return customIdentityName ?? "My Goal"
        default:
            return identityType.displayName
        }
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
        pausedAt: Date? = nil,
        completedAt: Date? = nil,
        progressPercentage: Double = 0,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        totalBlocksCompleted: Int = 0,
        totalBlocksScheduled: Int = 0,
        isFirstWeek: Bool = true,
        firstWeekStartDate: Date? = nil,
        milestones: [Milestone] = [],
        weeklyThemes: [WeeklyTheme] = [],
        planBlocks: [PlanBlock] = [],
        reflections: [WeeklyReflection] = []
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
        self.pausedAt = pausedAt
        self.completedAt = completedAt
        self.progressPercentage = progressPercentage
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.totalBlocksCompleted = totalBlocksCompleted
        self.totalBlocksScheduled = totalBlocksScheduled
        self.isFirstWeek = isFirstWeek
        self.firstWeekStartDate = firstWeekStartDate ?? createdAt
        self.milestones = milestones
        self.weeklyThemes = weeklyThemes
        self.planBlocks = planBlocks
        self.reflections = reflections
    }
}

// MARK: - Supporting Enums

enum IdentityType: String, Codable, CaseIterable {
    case accountant = "accountant"
    case fitDisciplined = "fit_disciplined"
    case structuredStudent = "structured_student"
    case entrepreneur = "entrepreneur"
    case custom = "custom"

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
    case oneMonth = "1_month"
    case threeMonths = "3_months"
    case sixMonths = "6_months"
    case oneYear = "1_year"

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

    var weeks: Int {
        days / 7
    }
}

enum Availability: String, Codable, CaseIterable {
    case busy = "busy"
    case normal = "normal"
    case open = "open"

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
    case light = "light"
    case balanced = "balanced"
    case aggressive = "aggressive"

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
    case conservative = "conservative"
    case balanced = "balanced"
    case ambitious = "ambitious"

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

    var blocksPerWeekMultiplier: Double {
        switch self {
        case .conservative: return 0.6
        case .balanced: return 1.0
        case .ambitious: return 1.5
        }
    }

    var blockDurationMultiplier: Double {
        switch self {
        case .conservative: return 0.8
        case .balanced: return 1.0
        case .ambitious: return 1.2
        }
    }
}

enum GoalStatus: String, Codable {
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case abandoned = "abandoned"
}
