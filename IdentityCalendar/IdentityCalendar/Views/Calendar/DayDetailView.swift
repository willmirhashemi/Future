import SwiftUI

// MARK: - Day Detail View

/// Full-screen view for viewing and managing a specific day's schedule and tasks
struct DayDetailView: View {
    let date: Date
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColorScheme) private var colorScheme
    @StateObject private var viewModel = CalendarViewModel()

    @State private var selectedSegment: DaySegment = .schedule
    @State private var showAddBlock = false
    @State private var showAddTask = false
    @State private var selectedBlock: PlanBlock?
    @State private var showBlockDetail = false
    @State private var tasks: [Task] = []

    enum DaySegment: String, CaseIterable {
        case schedule = "Schedule"
        case tasks = "Tasks"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background(colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Date header
                    dateHeader
                        .padding(.horizontal, 20)
                        .padding(.top, 8)

                    // Segment picker
                    segmentPicker
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedSegment {
                            case .schedule:
                                scheduleSection
                            case .tasks:
                                tasksSection
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .padding(.bottom, 80)
                    }
                }

                // Floating add button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        floatingAddButton
                    }
                    .padding(.trailing, 20)
                    .padding(.bottom, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .frame(width: 32, height: 32)
                            .background(AppTheme.secondaryBackground(colorScheme))
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showAddBlock) {
                AddBlockSheet(
                    selectedDate: date,
                    colorScheme: colorScheme,
                    onSave: { block in
                        viewModel.addBlock(block)
                        showAddBlock = false
                    },
                    onDismiss: { showAddBlock = false }
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskSheet(
                    selectedDate: date,
                    colorScheme: colorScheme,
                    onSave: { task in
                        tasks.append(task)
                        showAddTask = false
                    },
                    onDismiss: { showAddTask = false }
                )
                .presentationDetents([.medium])
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
                        onMove: { newDate in
                            viewModel.moveBlock(block, to: newDate)
                            showBlockDetail = false
                        },
                        onReduce: {
                            viewModel.reduceBlock(block)
                        },
                        onDismiss: { showBlockDetail = false }
                    )
                    .presentationDetents([.medium, .large])
                }
            }
            .onAppear {
                viewModel.selectedDate = date
                viewModel.refresh()
                loadTasks()
            }
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(date.isToday ? "Today" : date.weekdayString)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primaryText(colorScheme))

            Text(date.formatted(.dateTime.month(.wide).day().year()))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            ForEach(DaySegment.allCases, id: \.rawValue) { segment in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedSegment = segment
                    }
                    Haptics.select()
                }) {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: segment == .schedule ? "calendar" : "checklist")
                                .font(.system(size: 14, weight: .medium))
                            Text(segment.rawValue)
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(selectedSegment == segment ? AppTheme.accent : AppTheme.secondaryText(colorScheme))

                        // Indicator
                        Rectangle()
                            .fill(selectedSegment == segment ? AppTheme.accent : Color.clear)
                            .frame(height: 3)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 4)
    }

    // MARK: - Schedule Section

    private var scheduleSection: some View {
        VStack(spacing: 16) {
            let blocks = viewModel.blocksForDate(date)

            if blocks.isEmpty {
                emptyScheduleState
            } else {
                // Summary card
                scheduleSummary(blocks: blocks)

                // Block list
                ForEach(blocks.sorted { $0.startDateTime < $1.startDateTime }) { block in
                    ModernBlockCard(
                        block: block,
                        colorScheme: colorScheme,
                        onTap: {
                            selectedBlock = block
                            showBlockDetail = true
                        },
                        onComplete: {
                            viewModel.completeBlock(block)
                        }
                    )
                }
            }
        }
    }

    private var emptyScheduleState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 44))
                    .foregroundColor(AppTheme.accent)
            }

            VStack(spacing: 8) {
                Text("No blocks scheduled")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text("Plan your day by adding time blocks")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button(action: { showAddBlock = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Block")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(AppTheme.accent)
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func scheduleSummary(blocks: [PlanBlock]) -> some View {
        let completed = blocks.filter { $0.status == .completed }.count
        let total = blocks.count
        let totalMinutes = blocks.reduce(0) { $0 + $1.durationMinutes }

        return HStack(spacing: 16) {
            SummaryItem(
                icon: "square.stack.fill",
                value: "\(total)",
                label: "Blocks",
                color: AppTheme.accent,
                colorScheme: colorScheme
            )

            SummaryItem(
                icon: "checkmark.circle.fill",
                value: "\(completed)/\(total)",
                label: "Done",
                color: AppTheme.success,
                colorScheme: colorScheme
            )

            SummaryItem(
                icon: "clock.fill",
                value: "\(totalMinutes)",
                label: "Minutes",
                color: Color(hex: "FF9500"),
                colorScheme: colorScheme
            )
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(spacing: 16) {
            if tasks.isEmpty {
                emptyTasksState
            } else {
                // Task summary
                tasksSummary

                // Task list grouped by category
                ForEach(TaskCategory.allCases, id: \.rawValue) { category in
                    let categoryTasks = tasks.filter { $0.category == category }
                    if !categoryTasks.isEmpty {
                        TaskCategorySection(
                            category: category,
                            tasks: categoryTasks,
                            colorScheme: colorScheme,
                            onToggle: { task in
                                toggleTask(task)
                            },
                            onDelete: { task in
                                deleteTask(task)
                            }
                        )
                    }
                }
            }
        }
    }

    private var emptyTasksState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color(hex: "4CAF50").opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checklist")
                    .font(.system(size: 44))
                    .foregroundColor(Color(hex: "4CAF50"))
            }

            VStack(spacing: 8) {
                Text("No tasks for today")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text("Add tasks like homework, groceries, or errands")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
            }

            Button(action: { showAddTask = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Task")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(Color(hex: "4CAF50"))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var tasksSummary: some View {
        let completed = tasks.filter { $0.isCompleted }.count
        let total = tasks.count
        let progress = total > 0 ? Double(completed) / Double(total) : 0

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(completed) of \(total) completed")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryText(colorScheme))

                    Text(progress == 1 ? "All done! Great work!" : "Keep going!")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(AppTheme.secondaryBackground(colorScheme), lineWidth: 6)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AppTheme.success, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Floating Add Button

    private var floatingAddButton: some View {
        Button(action: {
            if selectedSegment == .schedule {
                showAddBlock = true
            } else {
                showAddTask = true
            }
        }) {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: selectedSegment == .schedule
                            ? [AppTheme.accent, AppTheme.accentLight]
                            : [Color(hex: "4CAF50"), Color(hex: "81C784")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(
                    color: (selectedSegment == .schedule ? AppTheme.accent : Color(hex: "4CAF50")).opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        }
    }

    // MARK: - Actions

    private func loadTasks() {
        tasks = DataService.shared.tasksForDate(date)
    }

    private func toggleTask(_ task: Task) {
        DataService.shared.toggleTaskComplete(task)
        Haptics.success()
        loadTasks()
    }

    private func deleteTask(_ task: Task) {
        DataService.shared.deleteTask(task)
        loadTasks()
    }
}

// MARK: - Summary Item

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primaryText(colorScheme))

            Text(label)
                .font(.caption2)
                .foregroundColor(AppTheme.tertiaryText(colorScheme))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Modern Block Card

struct ModernBlockCard: View {
    let block: PlanBlock
    let colorScheme: ColorScheme
    let onTap: () -> Void
    let onComplete: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Color accent bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.blockColor(for: block.blockType, colorScheme: colorScheme))
                    .frame(width: 4)

                // Content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(block.title)
                                .font(.headline)
                                .foregroundColor(AppTheme.primaryText(colorScheme))
                                .strikethrough(block.status == .completed)

                            Text("\(block.startDateTime.shortTimeString) - \(block.endDateTime.shortTimeString)")
                                .font(.caption)
                                .foregroundColor(AppTheme.secondaryText(colorScheme))
                        }

                        Spacer()

                        // Complete button
                        Button(action: onComplete) {
                            Image(systemName: block.status == .completed ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 26))
                                .foregroundColor(block.status == .completed ? AppTheme.success : AppTheme.tertiaryText(colorScheme))
                        }
                        .buttonStyle(.plain)
                    }

                    // Block type and duration
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: block.blockType.icon)
                                .font(.system(size: 11))
                            Text(block.blockType.displayName)
                                .font(.caption.weight(.medium))
                        }
                        .foregroundColor(Color.blockColor(for: block.blockType, colorScheme: colorScheme))

                        Text("•")
                            .foregroundColor(AppTheme.tertiaryText(colorScheme))

                        Text("\(block.durationMinutes) min")
                            .font(.caption)
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                    }
                }
                .padding(16)
            }
            .background(AppTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Task Category Section

struct TaskCategorySection: View {
    let category: TaskCategory
    let tasks: [Task]
    let colorScheme: ColorScheme
    let onToggle: (Task) -> Void
    let onDelete: (Task) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(category.color)

                Text(category.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Spacer()

                Text("\(tasks.filter { $0.isCompleted }.count)/\(tasks.count)")
                    .font(.caption.weight(.medium))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
            }

            // Tasks
            VStack(spacing: 8) {
                ForEach(tasks.sorted { first, second in
                    if first.isCompleted != second.isCompleted {
                        return !first.isCompleted
                    }
                    return first.priority.rawValue > second.priority.rawValue
                }) { task in
                    TaskRow(
                        task: task,
                        colorScheme: colorScheme,
                        onToggle: { onToggle(task) },
                        onDelete: { onDelete(task) }
                    )
                }
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Task Row

struct TaskRow: View {
    let task: Task
    let colorScheme: ColorScheme
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(
                            task.isCompleted ? AppTheme.success : task.priority.color,
                            lineWidth: 2
                        )
                        .frame(width: 28, height: 28)

                    if task.isCompleted {
                        Circle()
                            .fill(AppTheme.success)
                            .frame(width: 28, height: 28)

                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            // Task info
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(task.isCompleted ? AppTheme.tertiaryText(colorScheme) : AppTheme.primaryText(colorScheme))
                    .strikethrough(task.isCompleted)
                    .lineLimit(1)

                if let notes = task.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(AppTheme.tertiaryText(colorScheme))
                        .lineLimit(1)
                }
            }

            Spacer()

            // Priority indicator
            if !task.isCompleted {
                Image(systemName: task.priority.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(task.priority.color)
                    .frame(width: 24, height: 24)
                    .background(task.priority.color.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onDelete) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

// MARK: - Add Task Sheet

struct AddTaskSheet: View {
    let selectedDate: Date
    let colorScheme: ColorScheme
    let onSave: (Task) -> Void
    let onDismiss: () -> Void

    @State private var title = ""
    @State private var notes = ""
    @State private var category: TaskCategory = .other
    @State private var priority: TaskPriority = .medium

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Title input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        TextField("What needs to be done?", text: $title)
                            .font(.body)
                            .padding(16)
                            .background(AppTheme.secondaryBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Notes input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes (optional)")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        TextField("Add details...", text: $notes)
                            .font(.body)
                            .padding(16)
                            .background(AppTheme.secondaryBackground(colorScheme))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }

                    // Category selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Category")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                            ForEach(TaskCategory.allCases, id: \.rawValue) { cat in
                                CategoryButton(
                                    category: cat,
                                    isSelected: category == cat,
                                    colorScheme: colorScheme,
                                    onTap: { category = cat }
                                )
                            }
                        }
                    }

                    // Priority selector
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Priority")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        HStack(spacing: 8) {
                            ForEach(TaskPriority.allCases, id: \.rawValue) { prio in
                                PriorityButton(
                                    priority: prio,
                                    isSelected: priority == prio,
                                    colorScheme: colorScheme,
                                    onTap: { priority = prio }
                                )
                            }
                        }
                    }

                    Spacer(minLength: 20)

                    // Save button
                    Button(action: saveTask) {
                        Text("Add Task")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(title.isEmpty ? Color.gray : Color(hex: "4CAF50"))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .disabled(title.isEmpty)
                }
                .padding(20)
            }
            .background(AppTheme.background(colorScheme))
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onDismiss)
                }
            }
        }
    }

    private func saveTask() {
        Haptics.success()
        let task = DataService.shared.createTask(
            title: title,
            notes: notes.isEmpty ? nil : notes,
            category: category,
            priority: priority,
            dueDate: selectedDate
        )
        onSave(task)
    }
}

// MARK: - Category Button

struct CategoryButton: View {
    let category: TaskCategory
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.select()
            onTap()
        }) {
            VStack(spacing: 6) {
                Image(systemName: category.icon)
                    .font(.system(size: 18))
                Text(category.displayName)
                    .font(.caption2.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : category.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? category.color : category.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Priority Button

struct PriorityButton: View {
    let priority: TaskPriority
    let isSelected: Bool
    let colorScheme: ColorScheme
    let onTap: () -> Void

    var body: some View {
        Button(action: {
            Haptics.select()
            onTap()
        }) {
            HStack(spacing: 6) {
                Image(systemName: priority.icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(priority.displayName)
                    .font(.subheadline.weight(.medium))
            }
            .foregroundColor(isSelected ? .white : priority.color)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? priority.color : priority.color.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    DayDetailView(date: Date())
        .themed()
}
