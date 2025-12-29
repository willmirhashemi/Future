import Foundation
import SwiftData

/// Represents a significant checkpoint in the identity journey
@Model
final class Milestone {
    var id: UUID
    var createdAt: Date

    var title: String
    var description: String
    var targetDate: Date
    var weekNumber: Int
    var isCompleted: Bool
    var completedAt: Date?

    var sortOrder: Int

    @Relationship(inverse: \IdentityGoal.milestones)
    var goal: IdentityGoal?

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
        self.description = description
        self.targetDate = targetDate
        self.weekNumber = weekNumber
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.sortOrder = sortOrder
    }
}

// MARK: - Milestone Generation Helper
extension Milestone {
    /// Creates milestone data from AI response
    struct MilestoneData: Codable {
        let title: String
        let description: String
        let weekNumber: Int

        func toMilestone(startDate: Date) -> Milestone {
            let targetDate = Calendar.current.date(
                byAdding: .weekOfYear,
                value: weekNumber,
                to: startDate
            ) ?? startDate

            return Milestone(
                title: title,
                description: description,
                targetDate: targetDate,
                weekNumber: weekNumber,
                sortOrder: weekNumber
            )
        }
    }
}
