import SwiftUI

/// Week view showing 7 days with time slots
struct WeekView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let dates: [Date]

    var body: some View {
        VStack(spacing: 0) {
            // Day headers
            DayHeadersView(
                dates: dates,
                selectedDate: viewModel.selectedDate,
                onDateSelect: viewModel.selectDate
            )

            // Time grid
            ScrollView {
                ScrollViewReader { proxy in
                    TimeGridView(
                        dates: dates,
                        blocks: viewModel.blocksForDisplay,
                        onBlockTap: viewModel.selectBlock
                    )
                    .onAppear {
                        // Scroll to current time on appear
                        let currentHour = Calendar.current.component(.hour, from: Date())
                        if currentHour >= Constants.Calendar.startHour {
                            proxy.scrollTo("hour-\(max(Constants.Calendar.startHour, currentHour - 1))", anchor: .top)
                        }
                    }
                }
            }
        }
    }
}

/// Day column headers
struct DayHeadersView: View {
    let dates: [Date]
    let selectedDate: Date
    let onDateSelect: (Date) -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Time column spacer
            Color.clear
                .frame(width: Constants.Calendar.timeColumnWidth)

            // Day headers
            ForEach(dates, id: \.self) { date in
                DayHeaderCell(
                    date: date,
                    isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                    isToday: date.isToday,
                    onTap: { onDateSelect(date) }
                )
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(Color.appBackground)
    }
}

/// Individual day header cell
struct DayHeaderCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(date.shortDayOfWeekString.uppercased())
                    .font(.caption2.weight(.medium))
                    .foregroundColor(textColor)

                Text(date.dayNumberString)
                    .font(.system(size: 18, weight: isToday ? .bold : .medium))
                    .foregroundColor(isToday ? .white : textColor)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isToday ? Color.appAccent : Color.clear)
                    )
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected && !isToday ? Color.calendarSelected : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        if isSelected {
            return .appAccent
        } else if date.isWeekend {
            return .appTertiaryText
        } else {
            return .appSecondaryText
        }
    }
}

/// Time grid with hour rows
struct TimeGridView: View {
    let dates: [Date]
    let blocks: [PlanBlock]
    let onBlockTap: (PlanBlock) -> Void

    private let startHour = Constants.Calendar.startHour
    private let endHour = Constants.Calendar.endHour

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Hour lines and labels
            VStack(spacing: 0) {
                ForEach(startHour..<endHour, id: \.self) { hour in
                    HStack(alignment: .top, spacing: 0) {
                        // Time label
                        Text(hourLabel(hour))
                            .font(.caption2)
                            .foregroundColor(.appTertiaryText)
                            .frame(width: Constants.Calendar.timeColumnWidth, alignment: .trailing)
                            .padding(.trailing, 8)

                        // Hour line
                        Rectangle()
                            .fill(Color.appSeparator.opacity(0.5))
                            .frame(height: 0.5)
                    }
                    .frame(height: Constants.Calendar.hourHeight)
                    .id("hour-\(hour)")
                }
            }

            // Current time indicator
            CurrentTimeIndicator(
                startHour: startHour,
                hourHeight: Constants.Calendar.hourHeight,
                timeColumnWidth: Constants.Calendar.timeColumnWidth
            )

            // Blocks overlay
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: Constants.Calendar.timeColumnWidth)

                ForEach(dates, id: \.self) { date in
                    DayColumnView(
                        date: date,
                        blocks: blocksForDate(date),
                        hourHeight: Constants.Calendar.hourHeight,
                        startHour: startHour,
                        endHour: endHour,
                        onBlockTap: onBlockTap
                    )
                }
            }
        }
        .padding(.horizontal, 8)
    }

    private func hourLabel(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour)"
    }

    private func blocksForDate(_ date: Date) -> [PlanBlock] {
        blocks.filter { block in
            Calendar.current.isDate(block.startDateTime, inSameDayAs: date)
        }
    }
}

/// Column for a single day's blocks
struct DayColumnView: View {
    let date: Date
    let blocks: [PlanBlock]
    let hourHeight: CGFloat
    let startHour: Int
    let endHour: Int
    let onBlockTap: (PlanBlock) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .topLeading) {
                // Today highlight
                if date.isToday {
                    Rectangle()
                        .fill(Color.calendarToday)
                }

                // Blocks
                ForEach(blocks) { block in
                    let position = calculatePosition(for: block, in: geometry.size.height)

                    BlockView(block: block)
                        .frame(height: position.height)
                        .offset(y: position.top)
                        .padding(.horizontal, 2)
                        .onTapGesture {
                            onBlockTap(block)
                        }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func calculatePosition(for block: PlanBlock, in totalHeight: CGFloat) -> (top: CGFloat, height: CGFloat) {
        let totalMinutes = CGFloat((endHour - startHour) * 60)
        let minuteHeight = totalHeight / totalMinutes

        let startMinutes = CGFloat(block.startDateTime.hour * 60 + block.startDateTime.minute)
        let startOffset = startMinutes - CGFloat(startHour * 60)
        let top = startOffset * minuteHeight

        let durationMinutes = CGFloat(block.durationMinutes)
        let height = max(Constants.Calendar.blockMinHeight, durationMinutes * minuteHeight)

        return (max(0, top), height)
    }
}

/// Current time indicator line
struct CurrentTimeIndicator: View {
    let startHour: Int
    let hourHeight: CGFloat
    let timeColumnWidth: CGFloat

    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

    var body: some View {
        if isVisible {
            HStack(spacing: 0) {
                Color.clear
                    .frame(width: timeColumnWidth - 8)

                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)

                Rectangle()
                    .fill(Color.red)
                    .frame(height: 1)
            }
            .offset(y: offsetY)
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }

    private var isVisible: Bool {
        currentTime.isToday &&
        currentTime.hour >= startHour &&
        currentTime.hour < Constants.Calendar.endHour
    }

    private var offsetY: CGFloat {
        let minutes = CGFloat(currentTime.hour * 60 + currentTime.minute)
        let startMinutes = CGFloat(startHour * 60)
        return ((minutes - startMinutes) / 60) * hourHeight
    }
}

// MARK: - Preview

#Preview {
    WeekView(
        viewModel: CalendarViewModel(),
        dates: Date().daysOfWeek()
    )
}
