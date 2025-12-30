import Foundation
import SwiftData
import SwiftUI

/// Daily engagement record for detailed tracking and analytics
@Model
final class DailyEngagement {
    var id: UUID
    var date: Date // Start of day
    var blocksCompleted: Int
    var blocksScheduled: Int
    var blocksSkipped: Int
    var blocksMoved: Int
    var blocksReduced: Int
    var totalMinutesCompleted: Int
    var earliestBlockTime: Date?
    var latestBlockTime: Date?
    var engagedWithApp: Bool // Did user open the app?

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

        let blockHour = Calendar.current.component(.hour, from: block.startDateTime)

        if earliestBlockTime == nil || block.startDateTime < earliestBlockTime! {
            earliestBlockTime = block.startDateTime
        }
        if latestBlockTime == nil || block.startDateTime > latestBlockTime! {
            latestBlockTime = block.startDateTime
        }
    }
}

// MARK: - Analytics Helpers

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
    let weeklyComparison: [Double] // Completion rate for each week
}

// MARK: - Streak Calculator

struct StreakInfo {
    let currentStreak: Int
    let longestStreak: Int
    let lastActiveDate: Date?
    let streakStartDate: Date?
    let isActiveToday: Bool

    var streakAtRisk: Bool {
        guard let lastActive = lastActiveDate else { return false }
        let hoursSinceActive = Calendar.current.dateComponents(
            [.hour],
            from: lastActive,
            to: Date()
        ).hour ?? 0
        return hoursSinceActive > 20 && !isActiveToday
    }
}

// MARK: - Progress Ring Data

struct ProgressRingData {
    let progress: Double // 0.0 - 1.0
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

// MARK: - Time-of-Day Analytics

enum ProductivityTimeSlot: String, CaseIterable {
    case earlyMorning = "early_morning" // 5-8 AM
    case morning = "morning"             // 8-12 PM
    case afternoon = "afternoon"         // 12-5 PM
    case evening = "evening"             // 5-9 PM
    case night = "night"                 // 9 PM - 5 AM

    var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning"
        case .morning: return "Morning"
        case .afternoon: return "Afternoon"
        case .evening: return "Evening"
        case .night: return "Night"
        }
    }

    var hourRange: ClosedRange<Int> {
        switch self {
        case .earlyMorning: return 5...7
        case .morning: return 8...11
        case .afternoon: return 12...16
        case .evening: return 17...20
        case .night: return 21...23 // Also 0-4 but we'll handle that separately
        }
    }

    var icon: String {
        switch self {
        case .earlyMorning: return "sunrise"
        case .morning: return "sun.max"
        case .afternoon: return "sun.min"
        case .evening: return "sunset"
        case .night: return "moon"
        }
    }

    static func from(hour: Int) -> ProductivityTimeSlot {
        switch hour {
        case 5...7: return .earlyMorning
        case 8...11: return .morning
        case 12...16: return .afternoon
        case 17...20: return .evening
        default: return .night
        }
    }
}

struct TimeSlotStats {
    let slot: ProductivityTimeSlot
    let blocksCompleted: Int
    let totalBlocks: Int
    let completionRate: Double

    var isOptimal: Bool {
        completionRate >= 0.8 && blocksCompleted >= 3
    }
}
