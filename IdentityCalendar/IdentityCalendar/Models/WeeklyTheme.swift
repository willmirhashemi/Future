import Foundation
import SwiftData

/// Represents the theme and focus for a specific week
@Model
final class WeeklyTheme {
    var id: UUID
    var createdAt: Date

    var weekNumber: Int
    var weekStartDate: Date
    var title: String
    var focus: String

    var isCurrentWeek: Bool {
        let calendar = Calendar.current
        let today = Date()
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStartDate) ?? weekStartDate
        return today >= weekStartDate && today < weekEnd
    }

    @Relationship(inverse: \IdentityGoal.weeklyThemes)
    var goal: IdentityGoal?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        weekNumber: Int,
        weekStartDate: Date,
        title: String,
        focus: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.weekNumber = weekNumber
        self.weekStartDate = weekStartDate
        self.title = title
        self.focus = focus
    }
}

// MARK: - Weekly Theme Data for AI
extension WeeklyTheme {
    struct WeeklyThemeData: Codable {
        let weekNumber: Int
        let title: String
        let focus: String

        func toWeeklyTheme(startDate: Date) -> WeeklyTheme {
            let weekStartDate = Calendar.current.date(
                byAdding: .weekOfYear,
                value: weekNumber - 1,
                to: startDate
            ) ?? startDate

            return WeeklyTheme(
                weekNumber: weekNumber,
                weekStartDate: weekStartDate,
                title: title,
                focus: focus
            )
        }
    }
}
