import Foundation
import SwiftData
import SwiftUI

/// A reusable template for creating blocks quickly
@Model
final class BlockTemplate {
    var id: UUID
    var createdAt: Date

    // Template content
    var title: String
    var intentShort: String
    var blockType: BlockType
    var durationMinutes: Int

    // Optional rich content
    var location: String?
    var notes: String?
    var zoomLink: String?
    var youtubeLink: String?
    var category: String?
    var priority: BlockPriority?
    var energyLevel: EnergyLevel?
    var tips: [String]?

    // Recurrence settings
    var isRecurring: Bool
    var recurrencePattern: RecurrencePattern?
    var recurrenceDays: [Int]? // 1 = Sunday, 7 = Saturday
    var preferredTimeHour: Int?
    var preferredTimeMinute: Int?

    // Usage tracking
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

    /// Create a PlanBlock from this template for a specific date
    func createBlock(for date: Date, weekNumber: Int = 1) -> PlanBlock {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = preferredTimeHour ?? 9
        components.minute = preferredTimeMinute ?? 0

        let startTime = calendar.date(from: components) ?? date
        let endTime = startTime.addingTimeInterval(Double(durationMinutes * 60))

        // Track usage
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

    /// Get the next occurrence dates for recurring templates
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
                if weekday >= 2 && weekday <= 6 { // Mon-Fri
                    dates.append(currentDate)
                }
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate

            case .weekends:
                let weekday = calendar.component(.weekday, from: currentDate)
                if weekday == 1 || weekday == 7 { // Sun or Sat
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
        case .daily:
            return "Every day"
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
        case .weekdays:
            return "Weekdays"
        case .weekends:
            return "Weekends"
        case .biweekly:
            return "Every 2 weeks"
        case .monthly:
            return "Monthly"
        }
    }
}

// MARK: - Recurrence Pattern

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

// MARK: - Default Templates

extension BlockTemplate {
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
