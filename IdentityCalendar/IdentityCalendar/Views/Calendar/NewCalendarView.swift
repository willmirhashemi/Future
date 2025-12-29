import SwiftUI

/// Redesigned calendar view with cleaner UI
struct NewCalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @Environment(\.appColorScheme) private var colorScheme
    @State private var showBlockDetail = false
    @State private var selectedBlock: PlanBlock?
    @State private var showAddBlock = false
    @State private var appearAnimation = false

    var body: some View {
        ZStack {
            AppTheme.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Month header with add button
                CalendarHeaderView(
                    title: viewModel.selectedDate.monthYearString,
                    onPrevious: viewModel.goToPreviousPeriod,
                    onNext: viewModel.goToNextPeriod,
                    onToday: viewModel.goToToday,
                    onAddBlock: { showAddBlock = true },
                    colorScheme: colorScheme
                )

                // Calendar content
                ScrollView {
                    VStack(spacing: 20) {
                        // Monthly calendar grid
                        MonthGridView(
                            selectedDate: $viewModel.selectedDate,
                            blocks: viewModel.blocksForDisplay,
                            colorScheme: colorScheme,
                            onDateSelected: { date in
                                Haptics.select()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    viewModel.selectedDate = date
                                }
                                viewModel.loadBlocks()
                            }
                        )
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)

                        // Selected day schedule
                        SelectedDayScheduleView(
                            date: viewModel.selectedDate,
                            blocks: viewModel.blocksForDate(viewModel.selectedDate),
                            onBlockTap: { block in
                                selectedBlock = block
                                showBlockDetail = true
                            },
                            onAddBlock: { showAddBlock = true },
                            colorScheme: colorScheme
                        )
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 30)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 100) // Space for tab bar
                }
            }

            // Floating add button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showAddBlock = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(
                                LinearGradient(
                                    colors: [AppTheme.accent, AppTheme.accentLight],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 90)
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
        .sheet(isPresented: $showAddBlock) {
            AddBlockSheet(
                selectedDate: viewModel.selectedDate,
                colorScheme: colorScheme,
                onSave: { block in
                    viewModel.addBlock(block)
                    showAddBlock = false
                },
                onDismiss: { showAddBlock = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .onAppear {
            viewModel.refresh()
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) {
                appearAnimation = true
            }
        }
    }
}

// MARK: - Calendar Header

struct CalendarHeaderView: View {
    let title: String
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onToday: () -> Void
    let onAddBlock: () -> Void
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
    let onDateSelected: (Date) -> Void

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
                            blocksCount: blocksCount(on: date),
                            colorScheme: colorScheme,
                            onTap: {
                                onDateSelected(date)
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

    private func blocksCount(on date: Date) -> Int {
        blocks.filter { block in
            Calendar.current.isDate(block.startDateTime, inSameDayAs: date)
        }.count
    }
}

// MARK: - Day Cell

struct DayCell: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let blocksCount: Int
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 3) {
                Text(date.dayNumberString)
                    .font(.system(size: 16, weight: isToday ? .bold : .regular))
                    .foregroundColor(textColor)

                // Block indicators
                HStack(spacing: 2) {
                    if blocksCount > 0 {
                        ForEach(0..<min(blocksCount, 3), id: \.self) { _ in
                            Circle()
                                .fill(isToday ? .white.opacity(0.8) : AppTheme.accent)
                                .frame(width: 4, height: 4)
                        }
                        if blocksCount > 3 {
                            Text("+")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(isToday ? .white.opacity(0.8) : AppTheme.accent)
                        }
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 4, height: 4)
                    }
                }
                .frame(height: 6)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected && !isToday ? AppTheme.accent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
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
            return AppTheme.accent.opacity(0.12)
        } else {
            return Color.clear
        }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - Selected Day Schedule

struct SelectedDayScheduleView: View {
    let date: Date
    let blocks: [PlanBlock]
    let onBlockTap: (PlanBlock) -> Void
    let onAddBlock: () -> Void
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(date.isToday ? "Today" : date.weekdayString)
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText(colorScheme))

                    Text(date.fullDateString)
                        .font(.caption)
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }

                Spacer()

                if !blocks.isEmpty {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(AppTheme.accent)
                            .frame(width: 8, height: 8)
                        Text("\(blocks.count) block\(blocks.count == 1 ? "" : "s")")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.accent)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.accent.opacity(0.12))
                    .clipShape(Capsule())
                }
            }

            if blocks.isEmpty {
                // Improved empty state
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.1))
                            .frame(width: 80, height: 80)

                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.accent)
                    }

                    VStack(spacing: 6) {
                        Text("No blocks scheduled")
                            .font(.headline)
                            .foregroundColor(AppTheme.primaryText(colorScheme))

                        Text("Add a block to start planning your day")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .multilineTextAlignment(.center)
                    }

                    Button(action: onAddBlock) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Block")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.accent)
                        .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            } else {
                // Block list with timeline
                VStack(spacing: 0) {
                    ForEach(Array(blocks.sorted { $0.startDateTime < $1.startDateTime }.enumerated()), id: \.element.id) { index, block in
                        ScheduleBlockRow(
                            block: block,
                            isFirst: index == 0,
                            isLast: index == blocks.count - 1,
                            colorScheme: colorScheme,
                            onTap: { onBlockTap(block) }
                        )
                    }
                }

                // Add more blocks button
                Button(action: onAddBlock) {
                    HStack {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add another block")
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(AppTheme.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(AppTheme.accent.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .padding(.top, 12)
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
    var isFirst: Bool = true
    var isLast: Bool = true
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Time column with connector line
                VStack(spacing: 0) {
                    if !isFirst {
                        Rectangle()
                            .fill(AppTheme.separator(colorScheme))
                            .frame(width: 2, height: 8)
                    }

                    VStack(spacing: 2) {
                        Text(block.startDateTime.shortTimeString)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))

                        Text(block.endDateTime.shortTimeString)
                            .font(.caption2)
                            .foregroundColor(AppTheme.tertiaryText(colorScheme))
                    }
                    .padding(.vertical, 4)

                    if !isLast {
                        Rectangle()
                            .fill(AppTheme.separator(colorScheme))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 50)

                // Block card
                HStack(spacing: 0) {
                    // Color bar
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.blockColor(for: block.blockType, colorScheme: colorScheme))
                        .frame(width: 4)

                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(block.title)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(AppTheme.primaryText(colorScheme))
                                .lineLimit(1)

                            Spacer()

                            // Status icon
                            statusIcon
                        }

                        HStack(spacing: 8) {
                            // Block type badge
                            HStack(spacing: 4) {
                                Image(systemName: block.blockType.icon)
                                    .font(.system(size: 10))
                                Text(block.blockType.displayName)
                                    .font(.caption2.weight(.medium))
                            }
                            .foregroundColor(Color.blockColor(for: block.blockType, colorScheme: colorScheme))

                            // Duration
                            Text("• \(block.durationMinutes) min")
                                .font(.caption2)
                                .foregroundColor(AppTheme.tertiaryText(colorScheme))
                        }

                        if !block.intentShort.isEmpty {
                            Text(block.intentShort)
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText(colorScheme))
                                .lineLimit(2)
                        }
                    }
                    .padding(.leading, 12)
                    .padding(.vertical, 12)
                    .padding(.trailing, 12)
                }
                .background(Color.blockBackgroundColor(for: block.blockType, colorScheme: colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch block.status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.success)
        case .inProgress:
            Image(systemName: "play.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.accent)
        case .skipped:
            Image(systemName: "forward.circle.fill")
                .font(.system(size: 18))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        default:
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
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

// MARK: - Add Block Sheet

struct AddBlockSheet: View {
    let selectedDate: Date
    let colorScheme: ColorScheme
    let onSave: (PlanBlock) -> Void
    let onDismiss: () -> Void

    @State private var title = ""
    @State private var intent = ""
    @State private var blockType: BlockType = .focus
    @State private var startTime: Date
    @State private var duration: Int = 45

    private let durations = [15, 30, 45, 60, 90, 120]

    init(selectedDate: Date, colorScheme: ColorScheme, onSave: @escaping (PlanBlock) -> Void, onDismiss: @escaping () -> Void) {
        self.selectedDate = selectedDate
        self.colorScheme = colorScheme
        self.onSave = onSave
        self.onDismiss = onDismiss

        // Default to next hour
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: selectedDate)
        components.hour = (components.hour ?? 9) + 1
        components.minute = 0
        _startTime = State(initialValue: calendar.date(from: components) ?? selectedDate)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What are you working on?")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        TextField("e.g., Deep work session", text: $title)
                            .font(.body)
                            .padding(16)
                            .background(AppTheme.secondaryBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Intent input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's your intention?")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        TextField("e.g., Complete chapter 5 review", text: $intent)
                            .font(.body)
                            .padding(16)
                            .background(AppTheme.secondaryBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Block type selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Block Type")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        HStack(spacing: 8) {
                            ForEach(BlockType.allCases, id: \.rawValue) { type in
                                BlockTypeButton(
                                    type: type,
                                    isSelected: blockType == type,
                                    colorScheme: colorScheme,
                                    onTap: { blockType = type }
                                )
                            }
                        }
                    }

                    // Time selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Start Time")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        DatePicker(
                            "Start Time",
                            selection: $startTime,
                            displayedComponents: [.hourAndMinute]
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(height: 100)
                        .padding(.horizontal)
                        .background(AppTheme.secondaryBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Duration selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Duration")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                            ForEach(durations, id: \.self) { minutes in
                                DurationButton(
                                    minutes: minutes,
                                    isSelected: duration == minutes,
                                    colorScheme: colorScheme,
                                    onTap: { duration = minutes }
                                )
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Save button
                    Button(action: saveBlock) {
                        Text("Add Block")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(title.isEmpty ? AppTheme.accent.opacity(0.5) : AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(title.isEmpty)
                }
                .padding(20)
            }
            .background(AppTheme.background(colorScheme))
            .navigationTitle("New Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onDismiss)
                }
            }
        }
    }

    private func saveBlock() {
        Haptics.success()

        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        components.hour = timeComponents.hour
        components.minute = timeComponents.minute

        guard let startDateTime = calendar.date(from: components) else { return }
        let endDateTime = startDateTime.addingTimeInterval(Double(duration * 60))

        let block = PlanBlock(
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            title: title,
            intentShort: intent.isEmpty ? "Stay focused and present" : intent,
            blockType: blockType,
            weekNumber: 1
        )

        onSave(block)
    }
}

struct BlockTypeButton: View {
    let type: BlockType
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.select()
            onTap()
        }) {
            VStack(spacing: 6) {
                Image(systemName: type.icon)
                    .font(.system(size: 18))
                Text(type.displayName)
                    .font(.caption.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : Color.blockColor(for: type, colorScheme: colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blockColor(for: type, colorScheme: colorScheme) : Color.blockBackgroundColor(for: type, colorScheme: colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.clear : Color.blockColor(for: type, colorScheme: colorScheme).opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

struct DurationButton: View {
    let minutes: Int
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.select()
            onTap()
        }) {
            Text("\(minutes) min")
                .font(.subheadline.weight(.medium))
                .foregroundColor(isSelected ? .white : AppTheme.primaryText(colorScheme))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(isSelected ? AppTheme.accent : AppTheme.secondaryBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    NewCalendarView()
        .themed()
}
