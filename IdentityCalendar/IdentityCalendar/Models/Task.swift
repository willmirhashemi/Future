import Foundation
import SwiftData
import SwiftUI

// MARK: - Task Category

/// Categories for organizing tasks
enum TaskCategory: String, Codable, CaseIterable, Sendable {
    case homework = "homework"
    case groceries = "groceries"
    case errands = "errands"
    case health = "health"
    case work = "work"
    case personal = "personal"
    case other = "other"

    var displayName: String {
        switch self {
        case .homework: return "Homework"
        case .groceries: return "Groceries"
        case .errands: return "Errands"
        case .health: return "Health"
        case .work: return "Work"
        case .personal: return "Personal"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .homework: return "book.fill"
        case .groceries: return "cart.fill"
        case .errands: return "figure.walk"
        case .health: return "heart.fill"
        case .work: return "briefcase.fill"
        case .personal: return "person.fill"
        case .other: return "square.grid.2x2.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .homework: return "5B8DEF"
        case .groceries: return "4CAF50"
        case .errands: return "FF9800"
        case .health: return "E91E63"
        case .work: return "9C27B0"
        case .personal: return "00BCD4"
        case .other: return "607D8B"
        }
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Task Priority

enum TaskPriority: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"

    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }

    var icon: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "exclamationmark"
        }
    }

    var color: Color {
        switch self {
        case .low: return Color(hex: "4CAF50")
        case .medium: return Color(hex: "FF9800")
        case .high: return Color(hex: "F44336")
        }
    }
}

// MARK: - Task Model

/// Represents a task item (homework, groceries, errands, etc.)
@Model
final class Task {
    var id: UUID
    var title: String
    var notes: String?
    private var categoryRawValue: String
    private var priorityRawValue: String
    var dueDate: Date
    var isCompleted: Bool
    var completedAt: Date?
    var createdAt: Date
    var reminderTime: Date?
    var isRecurring: Bool
    private var recurrencePatternRawValue: String?

    @Relationship(inverse: \User.tasks)
    var user: User?

    // MARK: - Computed Properties

    nonisolated var category: TaskCategory {
        TaskCategory(rawValue: categoryRawValue) ?? .other
    }

    nonisolated var priority: TaskPriority {
        TaskPriority(rawValue: priorityRawValue) ?? .medium
    }

    var recurrencePattern: RecurrencePattern? {
        guard let raw = recurrencePatternRawValue else { return nil }
        return RecurrencePattern(rawValue: raw)
    }

    var isOverdue: Bool {
        !isCompleted && dueDate < Date()
    }

    var isDueToday: Bool {
        Calendar.current.isDateInToday(dueDate)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        category: TaskCategory = .other,
        priority: TaskPriority = .medium,
        dueDate: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        reminderTime: Date? = nil,
        isRecurring: Bool = false,
        recurrencePattern: RecurrencePattern? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.categoryRawValue = category.rawValue
        self.priorityRawValue = priority.rawValue
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.reminderTime = reminderTime
        self.isRecurring = isRecurring
        self.recurrencePatternRawValue = recurrencePattern?.rawValue
    }

    // MARK: - Methods

    func markComplete() {
        isCompleted = true
        completedAt = Date()
    }

    func markIncomplete() {
        isCompleted = false
        completedAt = nil
    }

    func toggleComplete() {
        if isCompleted {
            markIncomplete()
        } else {
            markComplete()
        }
    }

    func setCategory(_ category: TaskCategory) {
        categoryRawValue = category.rawValue
    }

    func setPriority(_ priority: TaskPriority) {
        priorityRawValue = priority.rawValue
    }

    func setRecurrencePattern(_ pattern: RecurrencePattern?) {
        recurrencePatternRawValue = pattern?.rawValue
        isRecurring = pattern != nil
    }
}

// MARK: - Task Snapshot

/// Thread-safe snapshot of a task for use in views
struct TaskSnapshot: Identifiable, Sendable, Hashable {
    let id: UUID
    let title: String
    let notes: String?
    let category: TaskCategory
    let priority: TaskPriority
    let dueDate: Date
    let isCompleted: Bool
    let completedAt: Date?
    let isOverdue: Bool
    let isDueToday: Bool

    init(from task: Task) {
        self.id = task.id
        self.title = task.title
        self.notes = task.notes
        self.category = task.category
        self.priority = task.priority
        self.dueDate = task.dueDate
        self.isCompleted = task.isCompleted
        self.completedAt = task.completedAt
        self.isOverdue = task.isOverdue
        self.isDueToday = task.isDueToday
    }

    init(
        id: UUID = UUID(),
        title: String,
        notes: String? = nil,
        category: TaskCategory = .other,
        priority: TaskPriority = .medium,
        dueDate: Date = Date(),
        isCompleted: Bool = false,
        completedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.category = category
        self.priority = priority
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.isOverdue = !isCompleted && dueDate < Date()
        self.isDueToday = Calendar.current.isDateInToday(dueDate)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: TaskSnapshot, rhs: TaskSnapshot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Task Extensions

extension Task {
    func snapshot() -> TaskSnapshot {
        TaskSnapshot(from: self)
    }
}

extension Array where Element == Task {
    func snapshots() -> [TaskSnapshot] {
        map { $0.snapshot() }
    }
}
