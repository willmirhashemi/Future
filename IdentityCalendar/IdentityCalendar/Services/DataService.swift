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
                WeeklyReflection.self,
                Achievement.self,
                BlockTemplate.self,
                DailyEngagement.self
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
        // Track engagement and check achievements
        updateEngagementForBlockCompletion(block)

        // Feature 2: Track anchor completion for "day success"
        if block.isAnchor {
            handleAnchorCompletion(block)
        }
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

    // MARK: - Achievement Management

    func initializeAchievements(for user: User) {
        guard user.achievements.isEmpty else { return }

        for type in AchievementType.allCases {
            let achievement = Achievement(achievementType: type)
            achievement.user = user
            user.achievements.append(achievement)
            modelContext.insert(achievement)
        }
        saveContext()
    }

    func checkAndUnlockAchievements(for user: User) {
        guard let goal = user.activeGoal else { return }

        var unlockedNew = false

        for achievement in user.achievements where !achievement.isUnlocked {
            let shouldUnlock = checkAchievementCondition(achievement, user: user, goal: goal)
            if shouldUnlock {
                achievement.unlock()
                unlockedNew = true
            }
        }

        if unlockedNew {
            saveContext()
        }
    }

    private func checkAchievementCondition(_ achievement: Achievement, user: User, goal: IdentityGoal) -> Bool {
        let type = achievement.achievementType

        switch type {
        // Streak achievements
        case .firstStep:
            return goal.totalBlocksCompleted >= 1
        case .weekWarrior:
            return goal.currentStreak >= 7
        case .twoWeekTitan:
            return goal.currentStreak >= 14
        case .monthlyMaster:
            return goal.currentStreak >= 30
        case .quarterChampion:
            return goal.currentStreak >= 90

        // Completion achievements
        case .tenBlocks:
            return user.totalBlocksEverCompleted >= 10
        case .fiftyBlocks:
            return user.totalBlocksEverCompleted >= 50
        case .hundredBlocks:
            return user.totalBlocksEverCompleted >= 100
        case .fiveHundredBlocks:
            return user.totalBlocksEverCompleted >= 500

        // Time-based achievements
        case .earlyBird:
            let earlyBlocks = countEarlyMorningBlocks(for: goal)
            achievement.progress = earlyBlocks
            return earlyBlocks >= 5
        case .nightOwl:
            let nightBlocks = countNightBlocks(for: goal)
            achievement.progress = nightBlocks
            return nightBlocks >= 5
        case .weekendWarrior:
            let weekendCount = countWeekendEngagements(for: user)
            achievement.progress = weekendCount
            return weekendCount >= 4

        // Milestone achievements
        case .firstMilestone:
            return goal.milestones.contains { $0.isCompleted }
        case .halfwayHero:
            return calculateProgress(for: goal) >= 0.5
        case .goalGetter:
            return user.totalGoalsCompleted >= 1

        // Engagement achievements
        case .reflector:
            let reflectionCount = goal.reflections.count
            achievement.progress = reflectionCount
            return reflectionCount >= 4
        case .adapter:
            let adaptCount = countAdaptations(for: goal)
            achievement.progress = adaptCount
            return adaptCount >= 10
        case .perfectWeek:
            return hasPerfectWeek(for: goal)

        // Special achievements
        case .newYearNewYou:
            let calendar = Calendar.current
            let isJanFirst = calendar.component(.month, from: Date()) == 1 &&
                             calendar.component(.day, from: Date()) == 1
            return isJanFirst && goal.totalBlocksCompleted > 0
        case .comebackKid:
            return checkComebackKid(for: user)
        }
    }

    private func countEarlyMorningBlocks(for goal: IdentityGoal) -> Int {
        goal.planBlocks.filter { block in
            block.status == .completed &&
            Calendar.current.component(.hour, from: block.startDateTime) < 8
        }.count
    }

    private func countNightBlocks(for goal: IdentityGoal) -> Int {
        goal.planBlocks.filter { block in
            block.status == .completed &&
            Calendar.current.component(.hour, from: block.startDateTime) >= 20
        }.count
    }

    private func countWeekendEngagements(for user: User) -> Int {
        let weekendEngagements = user.dailyEngagements.filter { engagement in
            engagement.isWeekend && engagement.blocksCompleted > 0
        }
        // Count unique weekends
        var weekends = Set<String>()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-ww"
        for engagement in weekendEngagements {
            weekends.insert(formatter.string(from: engagement.date))
        }
        return weekends.count
    }

    private func countAdaptations(for goal: IdentityGoal) -> Int {
        goal.planBlocks.filter { $0.wasMoved || $0.wasReduced }.count
    }

    private func hasPerfectWeek(for goal: IdentityGoal) -> Bool {
        let calendar = Calendar.current
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return false
        }

        let weekBlocks = goal.planBlocks.filter { block in
            block.startDateTime >= weekStart && block.startDateTime < weekEnd
        }

        guard !weekBlocks.isEmpty else { return false }
        return weekBlocks.allSatisfy { $0.status == .completed }
    }

    private func checkComebackKid(for user: User) -> Bool {
        guard let lastEngagement = user.lastEngagementDate else { return false }
        let daysSinceEngagement = Calendar.current.dateComponents(
            [.day],
            from: lastEngagement,
            to: Date()
        ).day ?? 0
        return daysSinceEngagement >= 7
    }

    func getAchievement(type: AchievementType, for user: User) -> Achievement? {
        user.achievements.first { $0.achievementType == type }
    }

    // MARK: - Block Template Management

    func createTemplate(
        title: String,
        intentShort: String,
        blockType: BlockType,
        durationMinutes: Int,
        location: String? = nil,
        notes: String? = nil,
        isRecurring: Bool = false,
        recurrencePattern: RecurrencePattern? = nil,
        recurrenceDays: [Int]? = nil,
        preferredTimeHour: Int? = nil,
        preferredTimeMinute: Int? = nil
    ) -> BlockTemplate {
        let user = getOrCreateUser()

        let template = BlockTemplate(
            title: title,
            intentShort: intentShort,
            blockType: blockType,
            durationMinutes: durationMinutes,
            location: location,
            notes: notes,
            isRecurring: isRecurring,
            recurrencePattern: recurrencePattern,
            recurrenceDays: recurrenceDays,
            preferredTimeHour: preferredTimeHour,
            preferredTimeMinute: preferredTimeMinute
        )

        template.user = user
        user.blockTemplates.append(template)
        modelContext.insert(template)
        saveContext()

        return template
    }

    func createBlockFromTemplate(_ template: BlockTemplate, for date: Date, goal: IdentityGoal) -> PlanBlock {
        let block = template.createBlock(for: date, weekNumber: currentWeekNumber(for: goal))
        addBlocks([block], to: goal)
        return block
    }

    func toggleTemplateFavorite(_ template: BlockTemplate) {
        template.isFavorite.toggle()
        saveContext()
    }

    func deleteTemplate(_ template: BlockTemplate) {
        modelContext.delete(template)
        saveContext()
    }

    func updateTemplate(_ template: BlockTemplate) {
        saveContext()
    }

    private func currentWeekNumber(for goal: IdentityGoal) -> Int {
        let daysSinceStart = Calendar.current.dateComponents(
            [.day],
            from: goal.createdAt,
            to: Date()
        ).day ?? 0
        return (daysSinceStart / 7) + 1
    }

    // MARK: - Recurring Block Generation

    func generateRecurringBlocks(from template: BlockTemplate, for goal: IdentityGoal, weeks: Int = 4) {
        guard template.isRecurring else { return }

        let occurrences = template.nextOccurrences(from: Date(), count: weeks * 7)

        for date in occurrences {
            let weekNumber = currentWeekNumber(for: goal)
            let block = template.createBlock(for: date, weekNumber: weekNumber)
            block.goal = goal
            goal.planBlocks.append(block)
            modelContext.insert(block)
        }

        saveContext()
    }

    // MARK: - Daily Engagement Tracking

    func recordDailyEngagement() {
        guard let user = currentUser else { return }

        let today = Calendar.current.startOfDay(for: Date())

        // Check if we already have an engagement for today
        if let existing = user.dailyEngagements.first(where: {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }) {
            existing.engagedWithApp = true
            saveContext()
            return
        }

        // Create new engagement record
        let engagement = DailyEngagement(date: today)
        engagement.user = user
        user.dailyEngagements.append(engagement)
        modelContext.insert(engagement)

        // Update user stats
        user.appOpenCount += 1
        user.lastEngagementDate = Date()

        saveContext()

        // Check achievements
        checkAndUnlockAchievements(for: user)
    }

    func getTodayEngagement() -> DailyEngagement? {
        guard let user = currentUser else { return nil }
        let today = Calendar.current.startOfDay(for: Date())
        return user.dailyEngagements.first {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
    }

    func getOrCreateTodayEngagement() -> DailyEngagement {
        if let existing = getTodayEngagement() {
            return existing
        }

        let user = getOrCreateUser()
        let today = Calendar.current.startOfDay(for: Date())
        let engagement = DailyEngagement(date: today)
        engagement.user = user
        user.dailyEngagements.append(engagement)
        modelContext.insert(engagement)
        saveContext()
        return engagement
    }

    func updateEngagementForBlockCompletion(_ block: PlanBlock) {
        let engagement = getOrCreateTodayEngagement()
        engagement.recordBlockCompletion(block: block)

        if let user = currentUser {
            user.totalBlocksEverCompleted += 1
            checkAndUnlockAchievements(for: user)
        }

        saveContext()
    }

    // MARK: - Analytics

    func getWeeklyStats(for goal: IdentityGoal, weekOffset: Int = 0) -> WeeklyStats {
        let calendar = Calendar.current
        let today = Date()

        guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today),
              let adjustedWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: weekStart)),
              let weekEnd = calendar.date(byAdding: .day, value: 7, to: adjustedWeekStart) else {
            return WeeklyStats(weekStart: today, totalBlocks: 0, completedBlocks: 0,
                             skippedBlocks: 0, totalMinutes: 0, averageCompletionRate: 0,
                             bestDay: nil, mostProductiveHour: nil)
        }

        let weekBlocks = blocksForDateRange(start: adjustedWeekStart, end: weekEnd, goal: goal)
        let completedBlocks = weekBlocks.filter { $0.status == .completed }
        let skippedBlocks = weekBlocks.filter { $0.status == .skipped }

        let totalMinutes = completedBlocks.reduce(0) { $0 + $1.durationMinutes }

        // Find best day
        var dayCompletions: [Int: Int] = [:]
        for block in completedBlocks {
            let weekday = calendar.component(.weekday, from: block.startDateTime)
            dayCompletions[weekday, default: 0] += 1
        }
        let bestDayNumber = dayCompletions.max(by: { $0.value < $1.value })?.key
        let bestDay = bestDayNumber.map { calendar.weekdaySymbols[$0 - 1] }

        // Find most productive hour
        var hourCompletions: [Int: Int] = [:]
        for block in completedBlocks {
            let hour = calendar.component(.hour, from: block.startDateTime)
            hourCompletions[hour, default: 0] += 1
        }
        let mostProductiveHour = hourCompletions.max(by: { $0.value < $1.value })?.key

        let completionRate = weekBlocks.isEmpty ? 0.0 : Double(completedBlocks.count) / Double(weekBlocks.count)

        return WeeklyStats(
            weekStart: adjustedWeekStart,
            totalBlocks: weekBlocks.count,
            completedBlocks: completedBlocks.count,
            skippedBlocks: skippedBlocks.count,
            totalMinutes: totalMinutes,
            averageCompletionRate: completionRate,
            bestDay: bestDay,
            mostProductiveHour: mostProductiveHour
        )
    }

    func getStreakInfo(for goal: IdentityGoal) -> StreakInfo {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Check if engaged today
        let todayBlocks = blocksForDate(today, goal: goal)
        let isActiveToday = todayBlocks.contains { $0.status == .completed }

        // Find streak start date (simplified - in production you'd track this properly)
        var streakStartDate: Date? = nil
        if goal.currentStreak > 0 {
            streakStartDate = calendar.date(byAdding: .day, value: -(goal.currentStreak - 1), to: today)
        }

        // Find last active date
        let lastActive = goal.planBlocks
            .filter { $0.status == .completed }
            .max(by: { $0.completedAt ?? .distantPast < $1.completedAt ?? .distantPast })?
            .completedAt

        return StreakInfo(
            currentStreak: goal.currentStreak,
            longestStreak: goal.longestStreak,
            lastActiveDate: lastActive,
            streakStartDate: streakStartDate,
            isActiveToday: isActiveToday
        )
    }

    func getProgressRings(for goal: IdentityGoal) -> [ProgressRingData] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Today's progress
        let todayBlocks = blocksForDate(today, goal: goal)
        let todayCompleted = todayBlocks.filter { $0.status == .completed }.count
        let dailyRing = ProgressRingData.daily(completed: todayCompleted, scheduled: todayBlocks.count)

        // Weekly progress
        let weekStats = getWeeklyStats(for: goal)
        let weeklyRing = ProgressRingData.weekly(completed: weekStats.completedBlocks, scheduled: weekStats.totalBlocks)

        // Streak
        let streakRing = ProgressRingData.streak(current: goal.currentStreak)

        return [dailyRing, weeklyRing, streakRing]
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

// ============================================================================
// MARK: - NEW FEATURES SUPPORT
// ============================================================================

extension DataService {
    // MARK: - Feature 1: Soft Recovery Mode Support

    /// Get recent engagements for momentum calculation
    func getRecentEngagements(days: Int = 7) -> [DailyEngagement] {
        guard let user = currentUser else { return [] }
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()

        return user.dailyEngagements
            .filter { $0.date >= cutoff }
            .sorted { $0.date < $1.date }
    }

    /// Get momentum state for planning adjustments (Feature 1)
    func getMomentumState() -> MomentumState {
        let engagements = getRecentEngagements(days: 7)
        return AIService.shared.calculateMomentumState(from: engagements)
    }

    // MARK: - Feature 2: Daily Anchor Task

    /// Ensure each day has exactly one anchor task
    func ensureAnchorForDay(_ date: Date, goal: IdentityGoal) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let dayBlocks = goal.planBlocks.filter {
            $0.startDateTime >= dayStart && $0.startDateTime < dayEnd
        }

        // Check if anchor already exists
        let hasAnchor = dayBlocks.contains { $0.isAnchor }
        guard !hasAnchor, !dayBlocks.isEmpty else { return }

        // Select best anchor using AI logic
        if let anchor = AIService.shared.selectAnchorTask(from: dayBlocks, goal: goal) {
            anchor.isAnchor = true
            saveContext()
        }
    }

    /// Update anchor completion status when block is completed
    func handleAnchorCompletion(_ block: PlanBlock) {
        guard block.isAnchor else { return }

        let engagement = getOrCreateTodayEngagement()
        engagement.anchorCompleted = true
        saveContext()
    }

    /// Get today's anchor task
    func getTodayAnchor(goal: IdentityGoal) -> PlanBlock? {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        return goal.planBlocks.first {
            $0.startDateTime >= today &&
            $0.startDateTime < tomorrow &&
            $0.isAnchor
        }
    }

    // MARK: - Feature 3: Dopamine-Aware Classification

    /// Classify all blocks for a day and ensure balance
    func classifyAndBalanceDay(_ date: Date, goal: IdentityGoal) {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let dayBlocks = goal.planBlocks.filter {
            $0.startDateTime >= dayStart && $0.startDateTime < dayEnd
        }

        // Classify unclassified blocks
        for block in dayBlocks where block.taskClassification == nil {
            block.taskClassification = AIService.shared.classifyTask(block, goal: goal)
        }

        saveContext()
    }

    // MARK: - Feature 4: End-of-Day Reflection

    /// Check if daily reflection prompt should be shown
    func shouldShowDailyReflection() -> Bool {
        guard let engagement = getTodayEngagement() else { return false }

        // Don't show if already shown today
        if engagement.reflectionPromptShown { return false }

        // Show after 7pm if there was any activity
        let hour = Calendar.current.component(.hour, from: Date())
        return hour >= 19 && engagement.blocksScheduled > 0
    }

    /// Record daily reflection response
    func recordDailyReflection(note: String?, skipped: Bool) {
        let engagement = getOrCreateTodayEngagement()
        engagement.reflectionPromptShown = true
        engagement.reflectionSkipped = skipped

        if let note = note, !note.isEmpty {
            engagement.reflectionNote = note
        }

        saveContext()
    }

    /// Get appropriate reflection prompt for today
    func getDailyReflectionPrompt() -> DailyReflectionPrompt {
        let engagement = getTodayEngagement()
        let anchorCompleted = engagement?.anchorCompleted ?? false
        let completionRate = engagement?.completionRate ?? 0

        return DailyReflectionPrompt.selectPrompt(
            anchorCompleted: anchorCompleted,
            completionRate: completionRate
        )
    }

    // MARK: - Feature 5: Trust Indicator

    /// Get current trust indicator
    func getTrustIndicator() -> TrustIndicator {
        guard let user = currentUser else {
            return TrustIndicator(successfulDays: 0, totalTrackedDays: 0, longestConsistentRun: 0)
        }

        return AIService.shared.calculateTrustIndicator(from: user.dailyEngagements)
    }
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
