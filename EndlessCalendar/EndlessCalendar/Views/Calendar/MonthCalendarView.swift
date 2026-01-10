import SwiftUI

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @Binding var currentMonth: Date
    let events: [Event]
    let onDateTap: (Date) -> Void

    private let calendar = Calendar.current
    private let daysOfWeek = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(spacing: Theme.Spacing.sm) {
            // Month Header
            monthHeader

            // Days of Week
            daysOfWeekHeader

            // Calendar Grid
            calendarGrid

            // Today Button
            todayButton
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.secondaryBackground)
    }

    // MARK: - Month Header
    private var monthHeader: some View {
        HStack {
            Button(action: previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Spacer()

            Text(monthYearString)
                .font(Theme.Fonts.title2())
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Button(action: nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.title3)
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
    }

    // MARK: - Days of Week Header
    private var daysOfWeekHeader: some View {
        HStack(spacing: 0) {
            ForEach(daysOfWeek, id: \.self) { day in
                Text(day)
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Calendar Grid
    private var calendarGrid: some View {
        let days = generateDaysInMonth()
        let rows = days.chunked(into: 7)

        return VStack(spacing: Theme.Spacing.xs) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                HStack(spacing: 0) {
                    ForEach(rows[rowIndex].indices, id: \.self) { dayIndex in
                        let day = rows[rowIndex][dayIndex]
                        CalendarDayCell(
                            day: day,
                            isSelected: day.date.map { calendar.isDate($0, inSameDayAs: selectedDate) } ?? false,
                            isToday: day.date.map { calendar.isDateInToday($0) } ?? false,
                            isCurrentMonth: day.isCurrentMonth,
                            events: eventsForDay(day.date)
                        ) {
                            if let date = day.date {
                                selectedDate = date
                                onDateTap(date)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Today Button
    private var todayButton: some View {
        HStack {
            Button(action: goToToday) {
                Text("Today")
                    .font(Theme.Fonts.subheadline())
                    .foregroundColor(Theme.Colors.accent)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Colors.tertiaryBackground)
                    .cornerRadius(Theme.CornerRadius.small)
            }

            Spacer()
        }
    }

    // MARK: - Computed Properties
    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }

    // MARK: - Methods
    private func generateDaysInMonth() -> [CalendarDay] {
        var days: [CalendarDay] = []

        let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)

        // Previous month days
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: firstDayOfMonth)!
        let daysInPreviousMonth = calendar.range(of: .day, in: .month, for: previousMonth)!.count

        for i in (0..<(firstWeekday - 1)).reversed() {
            let day = daysInPreviousMonth - i
            let date = calendar.date(byAdding: .day, value: day - daysInPreviousMonth, to: firstDayOfMonth)
            days.append(CalendarDay(day: day, date: date, isCurrentMonth: false))
        }

        // Current month days
        let daysInMonth = calendar.range(of: .day, in: .month, for: currentMonth)!.count
        for day in 1...daysInMonth {
            let date = calendar.date(byAdding: .day, value: day - 1, to: firstDayOfMonth)
            days.append(CalendarDay(day: day, date: date, isCurrentMonth: true))
        }

        // Next month days
        let remainingDays = 42 - days.count // 6 rows x 7 days
        let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: firstDayOfMonth)!

        for day in 1...remainingDays {
            let date = calendar.date(byAdding: .day, value: day - 1, to: nextMonthStart)
            days.append(CalendarDay(day: day, date: date, isCurrentMonth: false))
        }

        return days
    }

    private func eventsForDay(_ date: Date?) -> [Event] {
        guard let date = date else { return [] }
        return events.filter { event in
            calendar.isDate(event.startTime, inSameDayAs: date)
        }
    }

    private func previousMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth)!
        }
    }

    private func nextMonth() {
        withAnimation {
            currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth)!
        }
    }

    private func goToToday() {
        withAnimation {
            currentMonth = Date()
            selectedDate = Date()
        }
    }
}

// MARK: - Calendar Day Model
struct CalendarDay {
    let day: Int
    let date: Date?
    let isCurrentMonth: Bool
}

// MARK: - Calendar Day Cell
struct CalendarDayCell: View {
    let day: CalendarDay
    let isSelected: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
    let events: [Event]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Day number
                Text("\(day.day)")
                    .font(Theme.Fonts.subheadline())
                    .foregroundColor(dayTextColor)
                    .frame(width: 32, height: 32)
                    .background(dayBackground)
                    .cornerRadius(16)

                // Event indicators
                if !events.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(events.prefix(3).indices, id: \.self) { index in
                            Circle()
                                .fill(events[index].displayColor)
                                .frame(width: 4, height: 4)
                        }
                        if events.count > 3 {
                            Text("+\(events.count - 3)")
                                .font(.system(size: 8))
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    }
                    .frame(height: 8)
                } else {
                    Spacer()
                        .frame(height: 8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .disabled(!isCurrentMonth)
    }

    private var dayTextColor: Color {
        if isToday {
            return .white
        } else if isSelected {
            return Theme.Colors.accent
        } else if isCurrentMonth {
            return Theme.Colors.textPrimary
        } else {
            return Theme.Colors.textTertiary
        }
    }

    private var dayBackground: Color {
        if isToday {
            return Theme.Colors.accent
        } else if isSelected {
            return Theme.Colors.accent.opacity(0.2)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Array Extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    MonthCalendarView(
        selectedDate: .constant(Date()),
        currentMonth: .constant(Date()),
        events: [],
        onDateTap: { _ in }
    )
}
