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

    // Rich Content (Optional)
    var location: String?
    var notes: String?
    var zoomLink: String?
    var youtubeLink: String?
    var resourceLinks: [String]?
    var reminder: Int? // Minutes before to remind
    var category: String? // Optional category tag
    var priority: BlockPriority?
    var energyLevel: EnergyLevel?
    var tips: [String]? // AI-generated tips for this activity

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
        tips: [String]? = nil
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
        // Rich content
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

// MARK: - Block Priority

enum BlockPriority: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .critical: return "Critical"
        }
    }

    var icon: String {
        switch self {
        case .low: return "flag"
        case .medium: return "flag.fill"
        case .high: return "exclamationmark.triangle"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }

    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .critical: return .red
        }
    }
}

// MARK: - Energy Level

enum EnergyLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"

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
        case .low: return Color(hex: "9B5DE5") // Purple for rest
        case .medium: return Color(hex: "00B4D8") // Blue for moderate
        case .high: return Color(hex: "00D9A5") // Green for high
        }
    }

    var description: String {
        switch self {
        case .low: return "Good for when you're tired"
        case .medium: return "Moderate focus required"
        case .high: return "Peak energy recommended"
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
