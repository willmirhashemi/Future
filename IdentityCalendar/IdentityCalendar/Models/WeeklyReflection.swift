import Foundation
import SwiftData

/// Captures weekly reflection data for AI adaptation
@Model
final class WeeklyReflection {
    var id: UUID
    var createdAt: Date

    var weekNumber: Int
    var weekStartDate: Date
    var weekEndDate: Date

    // Reflection responses
    var weekFeeling: WeekFeeling
    var obstacle: WeekObstacle?
    var note: String?

    // Stats for the week
    var blocksCompleted: Int
    var blocksSkipped: Int
    var blocksMoved: Int
    var blocksReduced: Int
    var totalBlocks: Int

    // AI response
    var aiAdjustmentSummary: String?
    var wasProcessed: Bool

    @Relationship(inverse: \IdentityGoal.reflections)
    var goal: IdentityGoal?

    var completionRate: Double {
        guard totalBlocks > 0 else { return 0 }
        return Double(blocksCompleted) / Double(totalBlocks)
    }

    var engagementRate: Double {
        guard totalBlocks > 0 else { return 0 }
        let engaged = blocksCompleted + blocksMoved + blocksReduced
        return Double(engaged) / Double(totalBlocks)
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

// MARK: - Supporting Enums

enum WeekFeeling: String, Codable, CaseIterable {
    case tooEasy = "too_easy"
    case justRight = "just_right"
    case tooHard = "too_hard"

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

    var aiAdjustment: String {
        switch self {
        case .tooEasy: return "increase_difficulty"
        case .justRight: return "maintain"
        case .tooHard: return "decrease_difficulty"
        }
    }
}

enum WeekObstacle: String, Codable, CaseIterable {
    case time = "time"
    case energy = "energy"
    case motivation = "motivation"
    case life = "life"

    var displayName: String {
        switch self {
        case .time: return "Time"
        case .energy: return "Energy"
        case .motivation: return "Motivation"
        case .life: return "Life"
        }
    }

    var icon: String {
        switch self {
        case .time: return "clock"
        case .energy: return "bolt"
        case .motivation: return "heart"
        case .life: return "person.2"
        }
    }

    var aiContext: String {
        switch self {
        case .time: return "User lacked time - suggest shorter, more efficient blocks"
        case .energy: return "User lacked energy - suggest lighter activities and better spacing"
        case .motivation: return "User lacked motivation - suggest more engaging or varied activities"
        case .life: return "Life got in the way - suggest more flexibility and buffer time"
        }
    }
}
