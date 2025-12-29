import Foundation
import SwiftData
import SwiftUI

/// A time block on the calendar representing a planned activity
@Model
final class PlanBlock {
    var id: UUID
    var createdAt: Date

    // Time
    var startDateTime: Date
    var endDateTime: Date
    var originalStartDateTime: Date
    var originalEndDateTime: Date

    // Content
    var title: String
    var intentShort: String
    var blockType: BlockType

    // Status
    var status: BlockStatus
    var completedAt: Date?
    var skippedAt: Date?
    var movedAt: Date?
    var reducedAt: Date?

    // Tracking
    var wasReduced: Bool
    var wasMoved: Bool
    var moveCount: Int

    // Week tracking
    var weekNumber: Int

    @Relationship(inverse: \IdentityGoal.planBlocks)
    var goal: IdentityGoal?

    var duration: TimeInterval {
        endDateTime.timeIntervalSince(startDateTime)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(startDateTime)
    }

    var isPast: Bool {
        endDateTime < Date()
    }

    var isFuture: Bool {
        startDateTime > Date()
    }

    var isActive: Bool {
        let now = Date()
        return startDateTime <= now && endDateTime >= now
    }

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        startDateTime: Date,
        endDateTime: Date,
        title: String,
        intentShort: String,
        blockType: BlockType,
        status: BlockStatus = .scheduled,
        weekNumber: Int = 1
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
        self.completedAt = nil
        self.skippedAt = nil
        self.movedAt = nil
        self.reducedAt = nil
        self.wasReduced = false
        self.wasMoved = false
        self.moveCount = 0
        self.weekNumber = weekNumber
    }

    // MARK: - Actions

    func markAsCompleted() {
        status = .completed
        completedAt = Date()
    }

    func markAsSkipped() {
        status = .skipped
        skippedAt = Date()
    }

    func markAsInProgress() {
        status = .inProgress
    }

    func move(to newStart: Date) {
        let duration = self.duration
        startDateTime = newStart
        endDateTime = newStart.addingTimeInterval(duration)
        movedAt = Date()
        wasMoved = true
        moveCount += 1
        status = .scheduled
    }

    func reduce() {
        // Cut duration by 50%
        let newDuration = duration / 2
        endDateTime = startDateTime.addingTimeInterval(newDuration)
        reducedAt = Date()
        wasReduced = true
        status = .scheduled
    }
}

// MARK: - Block Type

enum BlockType: String, Codable, CaseIterable {
    case focus = "focus"
    case light = "light"
    case habit = "habit"
    case review = "review"

    var displayName: String {
        switch self {
        case .focus: return "Focus"
        case .light: return "Light"
        case .habit: return "Habit"
        case .review: return "Review"
        }
    }

    var color: Color {
        switch self {
        case .focus: return Color(red: 0.2, green: 0.4, blue: 0.6) // Calm blue
        case .light: return Color(red: 0.5, green: 0.6, blue: 0.5) // Soft sage
        case .habit: return Color(red: 0.6, green: 0.5, blue: 0.4) // Warm taupe
        case .review: return Color(red: 0.4, green: 0.4, blue: 0.5) // Subtle purple
        }
    }

    var backgroundColor: Color {
        color.opacity(0.12)
    }

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

// MARK: - Block Status

enum BlockStatus: String, Codable {
    case scheduled = "scheduled"
    case inProgress = "in_progress"
    case completed = "completed"
    case skipped = "skipped"
    case missed = "missed" // Auto-set for past blocks never addressed

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

// MARK: - Plan Block Data for AI

extension PlanBlock {
    struct PlanBlockData: Codable {
        let startDateTime: String // ISO8601
        let endDateTime: String // ISO8601
        let title: String
        let blockType: String
        let intentShort: String
        let weekNumber: Int

        private static let isoFormatter: ISO8601DateFormatter = {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            return formatter
        }()

        func toPlanBlock() -> PlanBlock? {
            guard let start = Self.isoFormatter.date(from: startDateTime),
                  let end = Self.isoFormatter.date(from: endDateTime),
                  let type = BlockType(rawValue: blockType) else {
                return nil
            }

            return PlanBlock(
                startDateTime: start,
                endDateTime: end,
                title: title,
                intentShort: intentShort,
                blockType: type,
                weekNumber: weekNumber
            )
        }
    }
}
