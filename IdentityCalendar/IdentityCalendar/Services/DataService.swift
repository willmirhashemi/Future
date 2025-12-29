import Foundation
import SwiftData

/// Manages all SwiftData operations
@MainActor
final class DataService: ObservableObject {
    static let shared = DataService()

    let modelContainer: ModelContainer
    let modelContext: ModelContext

    @Published private(set) var currentUser: User?
    @Published private(set) var activeGoal: IdentityGoal?

    private init() {
        do {
            let schema = Schema([
                User.self,
                IdentityGoal.self,
                Milestone.self,
                WeeklyTheme.self,
                PlanBlock.self,
                WeeklyReflection.self
            ])

            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )

            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext

            loadCurrentUser()
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    // MARK: - User Management

    func loadCurrentUser() {
        let descriptor = FetchDescriptor<User>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])

        do {
            let users = try modelContext.fetch(descriptor)
            currentUser = users.first
            activeGoal = currentUser?.activeGoal
        } catch {
            print("Failed to fetch user: \(error)")
        }
    }

    func createUser() -> User {
        let user = User()
        modelContext.insert(user)
        saveContext()
        currentUser = user
        return user
    }

    func getOrCreateUser() -> User {
        if let user = currentUser {
            return user
        }
        return createUser()
    }

    // MARK: - Goal Management

    func createGoal(
        identityType: IdentityType,
        customName: String?,
        timeHorizon: TimeHorizon,
        availability: Availability,
        intensity: Intensity,
        planConfidence: PlanConfidence
    ) -> IdentityGoal {
        let user = getOrCreateUser()

        // Deactivate existing goals for free users
        for goal in user.goals where goal.status == .active {
            goal.status = .paused
        }

        let goal = IdentityGoal(
            identityType: identityType,
            customIdentityName: identityType == .custom ? customName : nil,
            timeHorizon: timeHorizon,
            availability: availability,
            intensity: intensity,
            planConfidence: planConfidence
        )

        goal.user = user
        user.goals.append(goal)

        modelContext.insert(goal)
        saveContext()

        activeGoal = goal
        return goal
    }

    func updateGoal(_ goal: IdentityGoal) {
        saveContext()
        if goal.id == activeGoal?.id {
            activeGoal = goal
        }
    }

    func pauseGoal(_ goal: IdentityGoal) {
        goal.status = .paused
        goal.pausedAt = Date()
        saveContext()
        if goal.id == activeGoal?.id {
            activeGoal = nil
        }
    }

    func resumeGoal(_ goal: IdentityGoal) {
        // Pause any other active goals
        if let user = currentUser {
            for g in user.goals where g.status == .active && g.id != goal.id {
                g.status = .paused
            }
        }

        goal.status = .active
        goal.pausedAt = nil
        saveContext()
        activeGoal = goal
    }

    func deleteGoal(_ goal: IdentityGoal) {
        modelContext.delete(goal)
        saveContext()
        if goal.id == activeGoal?.id {
            activeGoal = currentUser?.activeGoal
        }
    }

    // MARK: - Block Management

    func addBlocks(_ blocks: [PlanBlock], to goal: IdentityGoal) {
        for block in blocks {
            block.goal = goal
            goal.planBlocks.append(block)
            modelContext.insert(block)
        }
        goal.totalBlocksScheduled += blocks.count
        saveContext()
    }

    func updateBlock(_ block: PlanBlock) {
        saveContext()
    }

    func completeBlock(_ block: PlanBlock) {
        block.markAsCompleted()
        if let goal = block.goal {
            goal.totalBlocksCompleted += 1
            updateStreak(for: goal, engaged: true)
        }
        saveContext()
    }

    func skipBlock(_ block: PlanBlock) {
        block.markAsSkipped()
        // Skipping is neutral - doesn't affect streak
        saveContext()
    }

    func moveBlock(_ block: PlanBlock, to newDate: Date) {
        block.move(to: newDate)
        if let goal = block.goal {
            updateStreak(for: goal, engaged: true) // Moving counts as engagement
        }
        saveContext()
    }

    func reduceBlock(_ block: PlanBlock) {
        block.reduce()
        if let goal = block.goal {
            updateStreak(for: goal, engaged: true) // Reducing counts as engagement
        }
        saveContext()
    }

    func blocksForDateRange(start: Date, end: Date, goal: IdentityGoal) -> [PlanBlock] {
        goal.planBlocks.filter { block in
            block.startDateTime >= start && block.startDateTime < end
        }.sorted { $0.startDateTime < $1.startDateTime }
    }

    func blocksForDate(_ date: Date, goal: IdentityGoal) -> [PlanBlock] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        return blocksForDateRange(start: startOfDay, end: endOfDay, goal: goal)
    }

    func blocksForWeek(containing date: Date, goal: IdentityGoal) -> [PlanBlock] {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return []
        }
        return blocksForDateRange(start: weekStart, end: weekEnd, goal: goal)
    }

    // MARK: - Milestone Management

    func addMilestones(_ milestones: [Milestone], to goal: IdentityGoal) {
        for milestone in milestones {
            milestone.goal = goal
            goal.milestones.append(milestone)
            modelContext.insert(milestone)
        }
        saveContext()
    }

    func completeMilestone(_ milestone: Milestone) {
        milestone.isCompleted = true
        milestone.completedAt = Date()
        saveContext()
    }

    // MARK: - Weekly Theme Management

    func addWeeklyThemes(_ themes: [WeeklyTheme], to goal: IdentityGoal) {
        for theme in themes {
            theme.goal = goal
            goal.weeklyThemes.append(theme)
            modelContext.insert(theme)
        }
        saveContext()
    }

    func currentWeekTheme(for goal: IdentityGoal) -> WeeklyTheme? {
        goal.weeklyThemes.first { $0.isCurrentWeek }
    }

    // MARK: - Reflection Management

    func createReflection(
        for goal: IdentityGoal,
        weekNumber: Int,
        weekStart: Date,
        weekEnd: Date,
        feeling: WeekFeeling,
        obstacle: WeekObstacle?,
        note: String?
    ) -> WeeklyReflection {
        let blocks = blocksForDateRange(start: weekStart, end: weekEnd, goal: goal)

        let reflection = WeeklyReflection(
            weekNumber: weekNumber,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            weekFeeling: feeling,
            obstacle: obstacle,
            note: note,
            blocksCompleted: blocks.filter { $0.status == .completed }.count,
            blocksSkipped: blocks.filter { $0.status == .skipped }.count,
            blocksMoved: blocks.filter { $0.wasMoved }.count,
            blocksReduced: blocks.filter { $0.wasReduced }.count,
            totalBlocks: blocks.count
        )

        reflection.goal = goal
        goal.reflections.append(reflection)
        modelContext.insert(reflection)
        saveContext()

        return reflection
    }

    func latestReflection(for goal: IdentityGoal) -> WeeklyReflection? {
        goal.reflections.sorted { $0.weekNumber > $1.weekNumber }.first
    }

    func needsReflection(for goal: IdentityGoal) -> Bool {
        let calendar = Calendar.current
        let today = Date()

        // Check if it's Sunday
        guard calendar.component(.weekday, from: today) == 1 else { return false }

        // Check if we already have a reflection for this week
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else {
            return false
        }

        let hasReflection = goal.reflections.contains { reflection in
            calendar.isDate(reflection.weekStartDate, inSameDayAs: weekStart)
        }

        return !hasReflection
    }

    // MARK: - Streak Management

    private func updateStreak(for goal: IdentityGoal, engaged: Bool) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Soft streak logic - streaks don't break, they just bend
        if engaged {
            goal.currentStreak += 1
            if goal.currentStreak > goal.longestStreak {
                goal.longestStreak = goal.currentStreak
            }
        }
        // Not engaging doesn't break the streak - it's a "soft" streak

        saveContext()
    }

    // MARK: - Progress Calculation

    func calculateProgress(for goal: IdentityGoal) -> Double {
        let totalDays = goal.timeHorizon.days
        let daysPassed = Calendar.current.dateComponents(
            [.day],
            from: goal.createdAt,
            to: Date()
        ).day ?? 0

        let timeProgress = Double(daysPassed) / Double(totalDays)

        // Weight completion rate
        let completionRate: Double
        if goal.totalBlocksScheduled > 0 {
            completionRate = Double(goal.totalBlocksCompleted) / Double(goal.totalBlocksScheduled)
        } else {
            completionRate = 0
        }

        // Blend time progress with completion rate
        let progress = (timeProgress * 0.4) + (completionRate * 0.6)
        return min(1.0, max(0, progress))
    }

    // MARK: - First Week Check

    func checkAndUpdateFirstWeek(for goal: IdentityGoal) {
        guard goal.isFirstWeek else { return }

        if let startDate = goal.firstWeekStartDate {
            let daysSinceStart = Calendar.current.dateComponents(
                [.day],
                from: startDate,
                to: Date()
            ).day ?? 0

            if daysSinceStart >= 7 {
                goal.isFirstWeek = false
                saveContext()
            }
        }
    }

    // MARK: - Onboarding

    func completeOnboarding() {
        guard let user = currentUser else { return }
        user.hasCompletedOnboarding = true
        saveContext()
    }

    // MARK: - Persistence

    func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    // MARK: - Debug/Reset

    #if DEBUG
    func resetAllData() {
        let userDescriptor = FetchDescriptor<User>()
        if let users = try? modelContext.fetch(userDescriptor) {
            for user in users {
                modelContext.delete(user)
            }
        }
        saveContext()
        currentUser = nil
        activeGoal = nil
    }
    #endif
}

// MARK: - Preview Support

extension DataService {
    static var preview: DataService {
        let service = DataService.shared
        return service
    }

    func createSampleData() {
        let user = getOrCreateUser()
        user.hasCompletedOnboarding = true

        let goal = createGoal(
            identityType: .fitDisciplined,
            customName: nil,
            timeHorizon: .threeMonths,
            availability: .normal,
            intensity: .balanced,
            planConfidence: .balanced
        )

        // Add sample blocks for the current week
        let calendar = Calendar.current
        let today = Date()

        for i in 0..<5 {
            guard let blockDate = calendar.date(byAdding: .day, value: i, to: today) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: blockDate)
            components.hour = 9
            components.minute = 0

            guard let startTime = calendar.date(from: components) else { continue }
            let endTime = startTime.addingTimeInterval(45 * 60)

            let block = PlanBlock(
                startDateTime: startTime,
                endDateTime: endTime,
                title: "Morning Workout",
                intentShort: "Build strength and start the day right",
                blockType: .focus,
                weekNumber: 1
            )

            addBlocks([block], to: goal)
        }

        saveContext()
    }
}
