import Foundation
import FirebaseFirestore
import SwiftUI

// MARK: - Event Model
struct Event: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    var userId: String
    var title: String
    var description: String?
    var startTime: Date
    var endTime: Date
    var isAllDay: Bool
    var eventType: EventType
    var category: GoalCategory?
    var isCompleted: Bool
    var isAIGenerated: Bool
    var color: String
    var reminder: EventReminder?
    var recurrence: EventRecurrence?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        userId: String,
        title: String,
        description: String? = nil,
        startTime: Date,
        endTime: Date,
        isAllDay: Bool = false,
        eventType: EventType = .task,
        category: GoalCategory? = nil,
        isCompleted: Bool = false,
        isAIGenerated: Bool = false,
        color: String = "4ECDC4",
        reminder: EventReminder? = nil,
        recurrence: EventRecurrence? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.title = title
        self.description = description
        self.startTime = startTime
        self.endTime = endTime
        self.isAllDay = isAllDay
        self.eventType = eventType
        self.category = category
        self.isCompleted = isCompleted
        self.isAIGenerated = isAIGenerated
        self.color = color
        self.reminder = reminder
        self.recurrence = recurrence
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var displayColor: Color {
        Color(hex: color)
    }

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationInMinutes: Int {
        Int(duration / 60)
    }

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }

    static func == (lhs: Event, rhs: Event) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Event Type
enum EventType: String, Codable, CaseIterable {
    case task = "task"
    case meeting = "meeting"
    case reminder = "reminder"
    case study = "study"
    case workout = "workout"
    case meditation = "meditation"
    case reading = "reading"
    case practice = "practice"
    case networking = "networking"
    case financial = "financial"
    case creative = "creative"
    case selfCare = "self_care"
    case milestone = "milestone"

    var displayName: String {
        switch self {
        case .task: return "Task"
        case .meeting: return "Meeting"
        case .reminder: return "Reminder"
        case .study: return "Study Session"
        case .workout: return "Workout"
        case .meditation: return "Meditation"
        case .reading: return "Reading"
        case .practice: return "Practice"
        case .networking: return "Networking"
        case .financial: return "Financial"
        case .creative: return "Creative"
        case .selfCare: return "Self Care"
        case .milestone: return "Milestone"
        }
    }

    var icon: String {
        switch self {
        case .task: return "checkmark.circle"
        case .meeting: return "person.2"
        case .reminder: return "bell"
        case .study: return "book"
        case .workout: return "figure.run"
        case .meditation: return "brain.head.profile"
        case .reading: return "book.pages"
        case .practice: return "pencil.and.outline"
        case .networking: return "link"
        case .financial: return "dollarsign.circle"
        case .creative: return "paintbrush"
        case .selfCare: return "heart"
        case .milestone: return "flag.fill"
        }
    }

    var defaultColor: String {
        switch self {
        case .task: return "4ECDC4"
        case .meeting: return "FF8C42"
        case .reminder: return "FFD93D"
        case .study: return "4D96FF"
        case .workout: return "6BCB77"
        case .meditation: return "A8E6CF"
        case .reading: return "9B59B6"
        case .practice: return "FF6B9D"
        case .networking: return "FF8C42"
        case .financial: return "4D96FF"
        case .creative: return "9B59B6"
        case .selfCare: return "A8E6CF"
        case .milestone: return "FFD93D"
        }
    }
}

// MARK: - Event Reminder
struct EventReminder: Codable, Equatable {
    var minutesBefore: Int
    var isEnabled: Bool

    init(minutesBefore: Int = 15, isEnabled: Bool = true) {
        self.minutesBefore = minutesBefore
        self.isEnabled = isEnabled
    }

    var displayText: String {
        if minutesBefore < 60 {
            return "\(minutesBefore) minutes before"
        } else if minutesBefore == 60 {
            return "1 hour before"
        } else if minutesBefore < 1440 {
            return "\(minutesBefore / 60) hours before"
        } else {
            return "\(minutesBefore / 1440) day(s) before"
        }
    }
}

// MARK: - Event Recurrence
struct EventRecurrence: Codable, Equatable {
    var type: RecurrenceType
    var interval: Int
    var endDate: Date?
    var daysOfWeek: [Int]? // 1 = Sunday, 7 = Saturday

    init(type: RecurrenceType, interval: Int = 1, endDate: Date? = nil, daysOfWeek: [Int]? = nil) {
        self.type = type
        self.interval = interval
        self.endDate = endDate
        self.daysOfWeek = daysOfWeek
    }
}

enum RecurrenceType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case biweekly = "biweekly"
    case monthly = "monthly"
    case yearly = "yearly"
    case custom = "custom"

    var displayName: String {
        switch self {
        case .daily: return "Daily"
        case .weekly: return "Weekly"
        case .biweekly: return "Bi-weekly"
        case .monthly: return "Monthly"
        case .yearly: return "Yearly"
        case .custom: return "Custom"
        }
    }
}

// MARK: - AI Generated Plan
struct AIGeneratedPlan: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var category: GoalCategory
    var specificGoal: String
    var events: [Event]
    var createdAt: Date
    var isActive: Bool
    var summary: String

    init(
        id: String? = nil,
        userId: String,
        category: GoalCategory,
        specificGoal: String,
        events: [Event] = [],
        createdAt: Date = Date(),
        isActive: Bool = true,
        summary: String = ""
    ) {
        self.id = id
        self.userId = userId
        self.category = category
        self.specificGoal = specificGoal
        self.events = events
        self.createdAt = createdAt
        self.isActive = isActive
        self.summary = summary
    }
}
