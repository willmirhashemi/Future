import SwiftUI

/// Redesigned calendar view with cleaner UI
struct NewCalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @Environment(\.appColorScheme) private var colorScheme
    @State private var showBlockDetail = false
    @State private var selectedBlock: PlanBlock?

    var body: some View {
        ZStack {
            AppTheme.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Month header
                MonthHeaderView(
                    title: viewModel.selectedDate.monthYearString,
                    onPrevious: viewModel.goToPreviousPeriod,
                    onNext: viewModel.goToNextPeriod,
                    onToday: viewModel.goToToday,
                    colorScheme: colorScheme
                )

                // Calendar content
                ScrollView {
                    VStack(spacing: 20) {
                        // Monthly calendar grid
                        MonthGridView(
                            selectedDate: $viewModel.selectedDate,
                            blocks: viewModel.blocksForDisplay,
                            colorScheme: colorScheme
                        )

                        // Today's schedule
                        TodayScheduleView(
                            date: viewModel.selectedDate,
                            blocks: viewModel.blocksForDate(viewModel.selectedDate),
                            onBlockTap: { block in
                                selectedBlock = block
                                showBlockDetail = true
                            },
                            colorScheme: colorScheme
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }
        }
        .sheet(isPresented: $showBlockDetail) {
            if let block = selectedBlock {
                NewBlockDetailSheet(
                    block: block,
                    colorScheme: colorScheme,
                    onComplete: {
                        viewModel.completeBlock(block)
                        showBlockDetail = false
                    },
                    onSkip: {
                        viewModel.skipBlock(block)
                        showBlockDetail = false
                    },
                    onMove: { date in
                        viewModel.moveBlock(block, to: date)
                        showBlockDetail = false
                    },
                    onReduce: {
                        viewModel.reduceBlock(block)
                    },
                    onDismiss: {
                        showBlockDetail = false
                    }
                )
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            viewModel.refresh()
        }
    }
}

// MARK: - Month Header

struct MonthHeaderView: View {
    let title: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void
    let colorScheme: ColorScheme

    var body: some View {
        HStack {
            Text(title)
                .font(.title2.weight(.bold))
                .foregroundColor(AppTheme.primaryText(colorScheme))

            Spacer()

            HStack(spacing: 8) {
                Button(action: onPrevious) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                        .frame(width: 36, height: 36)
                        .background(AppTheme.secondaryBackground(colorScheme))
                        .clipShape(Circle())
                }

                Button(action: onToday) {
                    Text("Today")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.accent)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppTheme.accent.opacity(0.15))
                        .clipShape(Capsule())
                }

                Button(action: onNext) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                        .frame(width: 36, height: 36)
                        .background(AppTheme.secondaryBackground(colorScheme))
                        .clipShape(Circle())
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
}

// MARK: - Month Grid

struct MonthGridView: View {
    @Binding var selectedDate: Date
    let blocks: [PlanBlock]
    let colorScheme: ColorScheme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]

    var body: some View {
        VStack(spacing: 8) {
            // Weekday headers
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(weekdays, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.medium))
                        .foregroundColor(AppTheme.tertiaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                }
            }

            // Date grid
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(datesInMonth(), id: \.self) { date in
                    if let date = date {
                        DayCell(
                            date: date,
                            isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate),
                            isToday: date.isToday,
                            hasBlocks: hasBlocks(on: date),
                            colorScheme: colorScheme,
                            onTap: {
                                Haptics.select()
                                selectedDate = date
                            }
                        )
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func datesInMonth() -> [Date?] {
        let calendar = Calendar.current
        let startOfMonth = selectedDate.startOfMonth

        guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }

        let firstWeekday = calendar.component(.weekday, from: startOfMonth) - 1
        var dates: [Date?] = Array(repeating: nil, count: firstWeekday)

        for day in range {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) {
                dates.append(date)
            }
        }

        // Fill remaining cells
        while dates.count % 7 != 0 {
            dates.append(nil)
        }

        return dates
    }

    private func hasBlocks(on date: Date) -> Bool {
        blocks.contains { block in
            Calendar.current.isDate(block.startDateTime, inSameDayAs: date)
        }
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let hasBlocks: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(date.dayNumberString)
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)

                // Block indicator
                if hasBlocks {
                    Circle()
                        .fill(AppTheme.accent)
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var textColor: Color {
        if isToday {
            return .white
        } else if isSelected {
            return AppTheme.accent
        } else {
            return AppTheme.primaryText(colorScheme)
        }
    }

    private var backgroundColor: Color {
        if isToday {
            return AppTheme.accent
        } else if isSelected {
            return AppTheme.accent.opacity(0.15)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Today Schedule

struct TodayScheduleView: View {
    let date: Date
    let blocks: [PlanBlock]
    let onBlockTap: (PlanBlock) -> Void
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text(date.isToday ? "Today's Schedule" : date.relativeString)
                    .font(.headline)
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Spacer()

                if !blocks.isEmpty {
                    Text("\(blocks.count) block\(blocks.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
            }

            if blocks.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.checkmark")
                        .font(.system(size: 32))
                        .foregroundColor(AppTheme.tertiaryText(colorScheme))

                    Text("No blocks scheduled")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // Block list
                VStack(spacing: 8) {
                    ForEach(blocks.sorted { $0.startDateTime < $1.startDateTime }) { block in
                        ScheduleBlockRow(
                            block: block,
                            colorScheme: colorScheme,
                            onTap: { onBlockTap(block) }
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Schedule Block Row

struct ScheduleBlockRow: View {
    let block: PlanBlock
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time
                VStack(alignment: .trailing, spacing: 2) {
                    Text(block.startDateTime.shortTimeString)
                        .font(.caption.weight(.medium))
                        .foregroundColor(AppTheme.primaryText(colorScheme))

                    Text(block.endDateTime.shortTimeString)
                        .font(.caption2)
                        .foregroundColor(AppTheme.tertiaryText(colorScheme))
                }
                .frame(width: 50)

                // Color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blockColor(for: block.blockType, colorScheme: colorScheme))
                    .frame(width: 4)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(block.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                        .lineLimit(1)

                    Text(block.intentShort)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                        .lineLimit(1)
                }

                Spacer()

                // Status
                statusIcon
            }
            .padding(12)
            .background(Color.blockBackgroundColor(for: block.blockType, colorScheme: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch block.status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppTheme.success)
        case .inProgress:
            Image(systemName: "play.circle.fill")
                .foregroundColor(AppTheme.accent)
        case .skipped:
            Image(systemName: "forward.circle.fill")
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        default:
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppTheme.tertiaryText(colorScheme))
        }
    }
}

// MARK: - New Block Detail Sheet

struct NewBlockDetailSheet: View {
    let block: PlanBlock
    let colorScheme: ColorScheme
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onMove: (Date) -> Void
    let onReduce: () -> Void
    let onDismiss: () -> Void

    @State private var showDatePicker = false
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Block type badge and title
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: block.blockType.icon)
                                .font(.caption)
                            Text(block.blockType.displayName)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(Color.blockColor(for: block.blockType, colorScheme: colorScheme))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.blockBackgroundColor(for: block.blockType, colorScheme: colorScheme))
                        .clipShape(Capsule())

                        Text(block.title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                    }

                    // Intent
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intent")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        Text(block.intentShort)
                            .font(.body)
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                    }

                    // Time info
                    HStack(spacing: 16) {
                        InfoCard(
                            icon: "calendar",
                            title: "Date",
                            value: block.startDateTime.shortDateString,
                            colorScheme: colorScheme
                        )

                        InfoCard(
                            icon: "clock",
                            title: "Time",
                            value: block.startDateTime.shortTimeString,
                            colorScheme: colorScheme
                        )

                        InfoCard(
                            icon: "hourglass",
                            title: "Duration",
                            value: block.duration.minutesString,
                            colorScheme: colorScheme
                        )
                    }

                    Spacer(minLength: 20)

                    // Actions
                    if block.status == .scheduled || block.status == .inProgress {
                        VStack(spacing: 12) {
                            // Primary action
                            Button(action: onComplete) {
                                HStack {
                                    Image(systemName: "checkmark.circle")
                                    Text("Mark Complete")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 54)
                                .background(AppTheme.success)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }

                            // Secondary actions
                            HStack(spacing: 12) {
                                Button(action: { showDatePicker = true }) {
                                    HStack {
                                        Image(systemName: "arrow.right.circle")
                                        Text("Move")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(AppTheme.accent)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(AppTheme.accent.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }

                                Button(action: onSkip) {
                                    HStack {
                                        Image(systemName: "forward")
                                        Text("Skip")
                                    }
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(AppTheme.secondaryBackground(colorScheme))
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }

                            Button(action: onReduce) {
                                HStack {
                                    Image(systemName: "minus.circle")
                                    Text("Reduce to \(Int(block.duration / 120)) min")
                                }
                                .font(.subheadline)
                                .foregroundColor(AppTheme.tertiaryText(colorScheme))
                            }
                            .padding(.top, 8)
                        }
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background(colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done", action: onDismiss)
                        .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(
                    selectedDate: $selectedDate,
                    colorScheme: colorScheme,
                    onConfirm: {
                        showDatePicker = false
                        onMove(selectedDate)
                    },
                    onCancel: { showDatePicker = false }
                )
                .presentationDetents([.medium])
            }
        }
        .onAppear {
            selectedDate = block.startDateTime
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.accent)

            Text(title)
                .font(.caption2)
                .foregroundColor(AppTheme.tertiaryText(colorScheme))

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(AppTheme.primaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(AppTheme.secondaryBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    let colorScheme: ColorScheme
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            VStack {
                DatePicker(
                    "Select Date & Time",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(AppTheme.accent)
                .padding()

                Button(action: onConfirm) {
                    Text("Move Block")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .background(AppTheme.background(colorScheme))
            .navigationTitle("Move Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NewCalendarView()
        .themed()
}
