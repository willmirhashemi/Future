import Foundation

/// Deterministic mock AI planner for development and fallback
final class MockAIPlannerService: AIPlannerService {
    private let calendar = Calendar.current
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // Simulated delay for realistic UX
    private let simulatedDelay: TimeInterval

    init(simulatedDelay: TimeInterval = 1.5) {
        self.simulatedDelay = simulatedDelay
    }

    func generateInitialPlan(for goal: IdentityGoal) async throws -> AIPlanResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))

        let startDate = goal.createdAt
        let totalWeeks = goal.timeHorizon.weeks

        // Generate milestones
        let milestones = generateMilestones(for: goal, totalWeeks: totalWeeks)

        // Generate weekly themes
        let weeklyThemes = generateWeeklyThemes(for: goal, totalWeeks: totalWeeks)

        // Generate plan blocks (first 2 weeks for initial plan)
        let planBlocks = generatePlanBlocks(
            for: goal,
            startDate: startDate,
            weeksToGenerate: min(2, totalWeeks),
            isFirstWeek: goal.isFirstWeek
        )

        return AIPlanResponse(
            milestones: milestones,
            weeklyThemes: weeklyThemes,
            planBlocks: planBlocks
        )
    }

    func adaptWeeklyPlan(
        for goal: IdentityGoal,
        reflection: WeeklyReflection,
        currentBlocks: [PlanBlock]
    ) async throws -> AIAdaptationResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: UInt64(simulatedDelay * 1_000_000_000))

        // Calculate the start of next week
        let nextWeekStart = calendar.date(
            byAdding: .day,
            value: 1,
            to: reflection.weekEndDate
        ) ?? Date()

        // Adjust difficulty based on reflection
        var adjustedConfidence = goal.planConfidence
        var adjustmentType: AIAdaptationResponse.AdjustmentType = .maintained
        var summary: String

        switch reflection.weekFeeling {
        case .tooEasy:
            adjustedConfidence = increaseConfidence(goal.planConfidence)
            adjustmentType = .increased
            summary = "I've added more challenging blocks this week."
        case .justRight:
            adjustmentType = .maintained
            summary = "Your plan looks good. Keeping the same pace."
        case .tooHard:
            adjustedConfidence = decreaseConfidence(goal.planConfidence)
            adjustmentType = .lighter
            summary = "I've lightened next week to help you recover."
        }

        // Consider obstacles
        if let obstacle = reflection.obstacle {
            switch obstacle {
            case .time:
                summary = "I've adjusted next week with shorter, more focused blocks."
            case .energy:
                summary = "I've spread out activities and added lighter sessions."
            case .motivation:
                summary = "I've mixed things up to keep it engaging."
            case .life:
                summary = "I've added more flexibility for unexpected events."
            }
            adjustmentType = .restructured
        }

        // Generate adapted blocks for the next week
        let tempGoal = createTempGoal(from: goal, with: adjustedConfidence)
        let newBlocks = generatePlanBlocks(
            for: tempGoal,
            startDate: nextWeekStart,
            weeksToGenerate: 1,
            isFirstWeek: false
        )

        return AIAdaptationResponse(
            updatedBlocks: newBlocks,
            summary: summary,
            adjustmentType: adjustmentType
        )
    }

    func suggestReschedule(
        for block: PlanBlock,
        availableSlots: [DateInterval]
    ) async throws -> Date? {
        // Simulate delay
        try await Task.sleep(nanoseconds: UInt64(0.3 * 1_000_000_000))

        // Return first slot that can fit the block duration
        let blockDuration = block.duration
        for slot in availableSlots {
            if slot.duration >= blockDuration {
                return slot.start
            }
        }
        return nil
    }

    // MARK: - Private Generation Methods

    private func generateMilestones(for goal: IdentityGoal, totalWeeks: Int) -> [Milestone.MilestoneData] {
        let templates = milestonesForIdentity(goal.identityType)
        let milestoneCount = min(templates.count, max(3, totalWeeks / 4))

        var milestones: [Milestone.MilestoneData] = []
        let weekInterval = totalWeeks / milestoneCount

        for i in 0..<milestoneCount {
            let weekNumber = (i + 1) * weekInterval
            let template = templates[i % templates.count]

            milestones.append(Milestone.MilestoneData(
                title: template.title,
                description: template.description,
                weekNumber: weekNumber
            ))
        }

        return milestones
    }

    private func generateWeeklyThemes(for goal: IdentityGoal, totalWeeks: Int) -> [WeeklyTheme.WeeklyThemeData] {
        let themes = themesForIdentity(goal.identityType)
        var weeklyThemes: [WeeklyTheme.WeeklyThemeData] = []

        for week in 1...totalWeeks {
            let theme = themes[(week - 1) % themes.count]
            weeklyThemes.append(WeeklyTheme.WeeklyThemeData(
                weekNumber: week,
                title: theme.title,
                focus: theme.focus
            ))
        }

        return weeklyThemes
    }

    private func generatePlanBlocks(
        for goal: IdentityGoal,
        startDate: Date,
        weeksToGenerate: Int,
        isFirstWeek: Bool
    ) -> [PlanBlock.PlanBlockData] {
        var blocks: [PlanBlock.PlanBlockData] = []

        // Calculate base blocks per week based on settings
        let baseBlocksPerWeek = calculateBlocksPerWeek(goal: goal)
        let adjustedBlocks = isFirstWeek ? Int(Double(baseBlocksPerWeek) * 0.6) : baseBlocksPerWeek

        let activities = activitiesForIdentity(goal.identityType)

        for week in 0..<weeksToGenerate {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: week, to: startDate) ?? startDate
            let currentWeekNumber = (goal.planBlocks.count / baseBlocksPerWeek) + week + 1

            // Generate blocks for this week
            let weekBlocks = generateWeekBlocks(
                activities: activities,
                weekStart: weekStart,
                blockCount: adjustedBlocks,
                weekNumber: currentWeekNumber,
                goal: goal,
                isFirstWeek: isFirstWeek && week == 0
            )

            blocks.append(contentsOf: weekBlocks)
        }

        return blocks
    }

    private func generateWeekBlocks(
        activities: [ActivityTemplate],
        weekStart: Date,
        blockCount: Int,
        weekNumber: Int,
        goal: IdentityGoal,
        isFirstWeek: Bool
    ) -> [PlanBlock.PlanBlockData] {
        var blocks: [PlanBlock.PlanBlockData] = []

        // Distribute blocks across weekdays (Monday-Saturday, leaving Sunday light)
        let daysToUse = [1, 2, 3, 4, 5, 6] // Mon-Sat
        var dayIndex = 0

        for i in 0..<blockCount {
            let activity = activities[i % activities.count]
            let dayOffset = daysToUse[dayIndex % daysToUse.count]

            guard let blockDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }

            // Set appropriate time of day based on block type
            let (hour, minute) = timeForBlockType(activity.blockType, index: i)

            var components = calendar.dateComponents([.year, .month, .day], from: blockDate)
            components.hour = hour
            components.minute = minute

            guard let startTime = calendar.date(from: components) else { continue }

            // Calculate duration
            var durationMinutes = activity.blockType.defaultDurationMinutes
            durationMinutes = Int(Double(durationMinutes) * goal.planConfidence.blockDurationMultiplier)

            // First week has shorter blocks
            if isFirstWeek {
                durationMinutes = Int(Double(durationMinutes) * 0.75)
            }

            // Ensure reasonable bounds
            durationMinutes = max(20, min(90, durationMinutes))

            let endTime = startTime.addingTimeInterval(Double(durationMinutes * 60))

            blocks.append(PlanBlock.PlanBlockData(
                startDateTime: isoFormatter.string(from: startTime),
                endDateTime: isoFormatter.string(from: endTime),
                title: activity.title,
                blockType: activity.blockType.rawValue,
                intentShort: activity.intent,
                weekNumber: weekNumber
            ))

            dayIndex += 1
        }

        // Always add a review block on Sunday
        if let sunday = calendar.date(byAdding: .day, value: 7, to: weekStart) {
            var components = calendar.dateComponents([.year, .month, .day], from: sunday)
            components.hour = 18
            components.minute = 0

            if let reviewStart = calendar.date(from: components) {
                let reviewEnd = reviewStart.addingTimeInterval(30 * 60)

                blocks.append(PlanBlock.PlanBlockData(
                    startDateTime: isoFormatter.string(from: reviewStart),
                    endDateTime: isoFormatter.string(from: reviewEnd),
                    title: "Weekly Review",
                    blockType: BlockType.review.rawValue,
                    intentShort: "Reflect on progress and plan ahead",
                    weekNumber: weekNumber
                ))
            }
        }

        return blocks
    }

    private func calculateBlocksPerWeek(goal: IdentityGoal) -> Int {
        let baseBlocks: Int
        switch goal.availability {
        case .busy: baseBlocks = 4
        case .normal: baseBlocks = 6
        case .open: baseBlocks = 9
        }

        let adjusted = Double(baseBlocks) * goal.intensity.blockMultiplier * goal.planConfidence.blocksPerWeekMultiplier
        return max(3, min(14, Int(adjusted)))
    }

    private func timeForBlockType(_ type: BlockType, index: Int) -> (hour: Int, minute: Int) {
        switch type {
        case .focus:
            // Morning focus blocks
            return (9 + (index % 3), 0)
        case .light:
            // Afternoon light blocks
            return (14 + (index % 3), 30)
        case .habit:
            // Evening habit blocks
            return (18 + (index % 2), 0)
        case .review:
            // Evening review
            return (18, 0)
        }
    }

    private func increaseConfidence(_ current: PlanConfidence) -> PlanConfidence {
        switch current {
        case .conservative: return .balanced
        case .balanced: return .ambitious
        case .ambitious: return .ambitious
        }
    }

    private func decreaseConfidence(_ current: PlanConfidence) -> PlanConfidence {
        switch current {
        case .conservative: return .conservative
        case .balanced: return .conservative
        case .ambitious: return .balanced
        }
    }

    private func createTempGoal(from goal: IdentityGoal, with confidence: PlanConfidence) -> IdentityGoal {
        return IdentityGoal(
            identityType: goal.identityType,
            customIdentityName: goal.customIdentityName,
            timeHorizon: goal.timeHorizon,
            availability: goal.availability,
            intensity: goal.intensity,
            planConfidence: confidence
        )
    }
}

// MARK: - Template Data

private struct ActivityTemplate {
    let title: String
    let intent: String
    let blockType: BlockType
}

private struct MilestoneTemplate {
    let title: String
    let description: String
}

private struct ThemeTemplate {
    let title: String
    let focus: String
}

// MARK: - Identity-Specific Templates

private func activitiesForIdentity(_ identity: IdentityType) -> [ActivityTemplate] {
    switch identity {
    case .accountant:
        return [
            ActivityTemplate(title: "Study Session", intent: "Deep dive into accounting principles", blockType: .focus),
            ActivityTemplate(title: "Practice Problems", intent: "Work through practice exercises", blockType: .focus),
            ActivityTemplate(title: "Review Notes", intent: "Reinforce key concepts", blockType: .light),
            ActivityTemplate(title: "Industry Reading", intent: "Stay current with trends", blockType: .light),
            ActivityTemplate(title: "Excel Practice", intent: "Build spreadsheet skills", blockType: .habit),
            ActivityTemplate(title: "Mock Exam", intent: "Test your knowledge", blockType: .focus)
        ]
    case .fitDisciplined:
        return [
            ActivityTemplate(title: "Workout", intent: "Build strength and endurance", blockType: .focus),
            ActivityTemplate(title: "Active Recovery", intent: "Light movement and stretching", blockType: .light),
            ActivityTemplate(title: "Meal Prep", intent: "Prepare healthy meals", blockType: .habit),
            ActivityTemplate(title: "Morning Movement", intent: "Start the day right", blockType: .habit),
            ActivityTemplate(title: "Training Session", intent: "Push your limits", blockType: .focus),
            ActivityTemplate(title: "Mobility Work", intent: "Improve flexibility", blockType: .light)
        ]
    case .structuredStudent:
        return [
            ActivityTemplate(title: "Deep Study", intent: "Focused learning session", blockType: .focus),
            ActivityTemplate(title: "Note Review", intent: "Reinforce understanding", blockType: .light),
            ActivityTemplate(title: "Practice Problems", intent: "Apply what you learned", blockType: .focus),
            ActivityTemplate(title: "Reading Time", intent: "Cover assigned materials", blockType: .light),
            ActivityTemplate(title: "Study Group", intent: "Learn with others", blockType: .habit),
            ActivityTemplate(title: "Assignment Work", intent: "Complete coursework", blockType: .focus)
        ]
    case .entrepreneur:
        return [
            ActivityTemplate(title: "Deep Work", intent: "Build your core product", blockType: .focus),
            ActivityTemplate(title: "Learning Block", intent: "Develop key skills", blockType: .light),
            ActivityTemplate(title: "Networking", intent: "Build relationships", blockType: .habit),
            ActivityTemplate(title: "Strategy Session", intent: "Plan your next moves", blockType: .focus),
            ActivityTemplate(title: "Market Research", intent: "Understand your space", blockType: .light),
            ActivityTemplate(title: "Content Creation", intent: "Build your presence", blockType: .habit)
        ]
    case .custom:
        return [
            ActivityTemplate(title: "Focus Block", intent: "Deep work on your goal", blockType: .focus),
            ActivityTemplate(title: "Skill Building", intent: "Develop key abilities", blockType: .focus),
            ActivityTemplate(title: "Light Practice", intent: "Maintain momentum", blockType: .light),
            ActivityTemplate(title: "Learning Time", intent: "Expand your knowledge", blockType: .light),
            ActivityTemplate(title: "Daily Practice", intent: "Build consistency", blockType: .habit),
            ActivityTemplate(title: "Reflection", intent: "Review and adjust", blockType: .review)
        ]
    }
}

private func milestonesForIdentity(_ identity: IdentityType) -> [MilestoneTemplate] {
    switch identity {
    case .accountant:
        return [
            MilestoneTemplate(title: "Foundation Set", description: "Core concepts mastered"),
            MilestoneTemplate(title: "Practice Ready", description: "Problem-solving confidence"),
            MilestoneTemplate(title: "Exam Prepared", description: "Ready for certification"),
            MilestoneTemplate(title: "Expert Level", description: "Advanced proficiency")
        ]
    case .fitDisciplined:
        return [
            MilestoneTemplate(title: "Habit Formed", description: "Consistent routine established"),
            MilestoneTemplate(title: "Visible Progress", description: "Noticeable improvements"),
            MilestoneTemplate(title: "New Standard", description: "Lifestyle transformation"),
            MilestoneTemplate(title: "Peak Performance", description: "Optimal health achieved")
        ]
    case .structuredStudent:
        return [
            MilestoneTemplate(title: "System Built", description: "Study routine established"),
            MilestoneTemplate(title: "Grades Improved", description: "Academic progress visible"),
            MilestoneTemplate(title: "Mastery Phase", description: "Deep understanding"),
            MilestoneTemplate(title: "Excellence", description: "Top performance achieved")
        ]
    case .entrepreneur:
        return [
            MilestoneTemplate(title: "Vision Clear", description: "Direction defined"),
            MilestoneTemplate(title: "MVP Ready", description: "First version complete"),
            MilestoneTemplate(title: "Market Entry", description: "Launch phase"),
            MilestoneTemplate(title: "Traction", description: "Growth momentum")
        ]
    case .custom:
        return [
            MilestoneTemplate(title: "Getting Started", description: "Foundation in place"),
            MilestoneTemplate(title: "Building Momentum", description: "Consistent progress"),
            MilestoneTemplate(title: "Real Progress", description: "Significant advancement"),
            MilestoneTemplate(title: "Transformation", description: "Goal realized")
        ]
    }
}

private func themesForIdentity(_ identity: IdentityType) -> [ThemeTemplate] {
    switch identity {
    case .accountant:
        return [
            ThemeTemplate(title: "Foundation", focus: "Build core knowledge"),
            ThemeTemplate(title: "Practice", focus: "Apply concepts"),
            ThemeTemplate(title: "Deepening", focus: "Advanced topics"),
            ThemeTemplate(title: "Mastery", focus: "Expert application")
        ]
    case .fitDisciplined:
        return [
            ThemeTemplate(title: "Activation", focus: "Start moving"),
            ThemeTemplate(title: "Building", focus: "Increase capacity"),
            ThemeTemplate(title: "Strengthening", focus: "Push boundaries"),
            ThemeTemplate(title: "Optimization", focus: "Peak performance")
        ]
    case .structuredStudent:
        return [
            ThemeTemplate(title: "Organization", focus: "Build systems"),
            ThemeTemplate(title: "Absorption", focus: "Intake knowledge"),
            ThemeTemplate(title: "Application", focus: "Use what you learned"),
            ThemeTemplate(title: "Excellence", focus: "Master material")
        ]
    case .entrepreneur:
        return [
            ThemeTemplate(title: "Discovery", focus: "Find your path"),
            ThemeTemplate(title: "Creation", focus: "Build core offering"),
            ThemeTemplate(title: "Launch", focus: "Go to market"),
            ThemeTemplate(title: "Growth", focus: "Scale what works")
        ]
    case .custom:
        return [
            ThemeTemplate(title: "Beginning", focus: "Start your journey"),
            ThemeTemplate(title: "Building", focus: "Develop skills"),
            ThemeTemplate(title: "Advancing", focus: "Make progress"),
            ThemeTemplate(title: "Mastering", focus: "Achieve your goal")
        ]
    }
}
