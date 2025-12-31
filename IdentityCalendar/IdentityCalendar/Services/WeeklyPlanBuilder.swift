import Foundation

// MARK: - Weekly Plan Builder
/// Transforms milestones and activities into executable weekly plans with calendar blocks

final class WeeklyPlanBuilder {
    static let shared = WeeklyPlanBuilder()

    private let knowledgeBase = DomainKnowledgeBase.shared
    private let calendar = Calendar.current

    private init() {}

    // MARK: - Build Weekly Plan

    /// Build a complete weekly execution plan
    func buildWeeklyPlan(
        for milestone: Milestone,
        domain: GoalDomainType,
        availability: Availability,
        userPatterns: UserPatterns,
        weekNumber: Int
    ) -> WeeklyExecutionPlan {
        let blueprint = knowledgeBase.getBlueprint(for: domain)
        let activities = selectActivitiesForPhase(
            phase: milestone.phase,
            blueprint: blueprint,
            availability: availability
        )

        let blocks = generateBlocks(
            from: activities,
            availability: availability,
            userPatterns: userPatterns,
            weekNumber: weekNumber
        )

        let dailyDistribution = distributeToDays(
            blocks: blocks,
            preferredDays: userPatterns.preferredDays,
            availability: availability
        )

        return WeeklyExecutionPlan(
            weekNumber: weekNumber,
            milestone: milestone,
            blocks: blocks,
            dailyDistribution: dailyDistribution,
            focusAreas: extractFocusAreas(from: activities),
            weeklyQuickWin: getQuickWin(for: milestone.phase, domain: domain),
            reflectionPrompts: getReflectionPrompts(for: milestone.phase),
            adjustmentTriggers: getAdjustmentTriggers(for: milestone.phase)
        )
    }

    // MARK: - Activity Selection

    private func selectActivitiesForPhase(
        phase: MilestonePhase,
        blueprint: DomainBlueprint,
        availability: Availability
    ) -> [DomainActivity] {
        let allActivities = blueprint.highLeverageActivities

        // Filter by phase appropriateness and availability
        let phaseActivities: [DomainActivity]

        switch phase {
        case .orientation:
            // Focus on setup and low-difficulty activities
            phaseActivities = allActivities.filter { $0.difficulty <= 3 }
        case .building:
            // Mix of activities, prefer high-impact ones
            phaseActivities = allActivities.sorted { $0.impactScore > $1.impactScore }
        case .validation:
            // Focus on practice and assessment activities
            phaseActivities = allActivities.filter { $0.impactScore >= 7 }
        case .momentum:
            // Consistent execution of core activities
            phaseActivities = allActivities.filter { $0.weeklyFrequency >= 3 }
        case .scaling:
            // Advanced and optimization activities
            phaseActivities = allActivities.filter { $0.difficulty >= 6 }
        }

        // Limit based on available hours
        let maxActivities = min(phaseActivities.count, availability.weeklyHours / 3)
        return Array(phaseActivities.prefix(max(2, maxActivities)))
    }

    // MARK: - Block Generation

    private func generateBlocks(
        from activities: [DomainActivity],
        availability: Availability,
        userPatterns: UserPatterns,
        weekNumber: Int
    ) -> [PlannedBlock] {
        var blocks: [PlannedBlock] = []
        var remainingHours = availability.weeklyHours

        for activity in activities {
            guard remainingHours > 0 else { break }

            let blocksForActivity = min(
                activity.weeklyFrequency,
                remainingHours / max(1, activity.typicalDuration / 60)
            )

            for i in 0..<blocksForActivity {
                let duration = min(activity.typicalDuration, userPatterns.preferredBlockDuration)
                let preferredTime = determineOptimalTime(
                    for: activity,
                    userPeakHour: userPatterns.peakProductivityHour,
                    sessionIndex: i
                )

                blocks.append(PlannedBlock(
                    activityName: activity.name,
                    description: activity.description,
                    duration: duration,
                    blockType: mapToBlockType(activity: activity),
                    preferredTimeOfDay: preferredTime,
                    energyLevel: mapToEnergyLevel(difficulty: activity.difficulty),
                    weekNumber: weekNumber,
                    isFlexible: activity.difficulty <= 5,
                    priority: activity.impactScore >= 8 ? .high : (activity.impactScore >= 5 ? .medium : .low)
                ))

                remainingHours -= duration / 60
            }
        }

        return blocks
    }

    private func determineOptimalTime(
        for activity: DomainActivity,
        userPeakHour: Int,
        sessionIndex: Int
    ) -> TimeOfDay {
        // Use activity's preferred time if specified
        if let preferred = activity.preferredTime {
            return preferred
        }

        // High-impact activities during peak hours
        if activity.impactScore >= 8 {
            if userPeakHour < 12 {
                return .morning
            } else if userPeakHour < 17 {
                return .afternoon
            } else {
                return .evening
            }
        }

        // Distribute other activities throughout day
        switch sessionIndex % 3 {
        case 0: return .morning
        case 1: return .afternoon
        default: return .evening
        }
    }

    private func mapToBlockType(activity: DomainActivity) -> BlockType {
        // Map based on activity characteristics
        if activity.impactScore >= 8 && activity.difficulty >= 6 {
            return .focus
        } else if activity.name.lowercased().contains("exercise") ||
                  activity.name.lowercased().contains("workout") ||
                  activity.name.lowercased().contains("training") {
            return .energy
        } else if activity.name.lowercased().contains("review") ||
                  activity.name.lowercased().contains("reflect") {
            return .review
        } else {
            return .focus
        }
    }

    private func mapToEnergyLevel(difficulty: Int) -> EnergyLevel {
        if difficulty >= 7 { return .high }
        if difficulty >= 4 { return .medium }
        return .low
    }

    // MARK: - Daily Distribution

    private func distributeToDays(
        blocks: [PlannedBlock],
        preferredDays: [Int],
        availability: Availability
    ) -> [Int: [PlannedBlock]] {
        var distribution: [Int: [PlannedBlock]] = [:]
        var blockIndex = 0

        // Initialize preferred days
        for day in preferredDays {
            distribution[day] = []
        }

        // Distribute blocks across preferred days
        for block in blocks {
            let targetDay = preferredDays[blockIndex % preferredDays.count]
            distribution[targetDay, default: []].append(block)
            blockIndex += 1
        }

        // Balance load across days
        return balanceDistribution(distribution, maxBlocksPerDay: availability.maxBlocksPerDay)
    }

    private func balanceDistribution(
        _ distribution: [Int: [PlannedBlock]],
        maxBlocksPerDay: Int
    ) -> [Int: [PlannedBlock]] {
        var balanced = distribution
        var overflow: [PlannedBlock] = []

        // Collect overflow from days with too many blocks
        for (day, blocks) in balanced {
            if blocks.count > maxBlocksPerDay {
                overflow.append(contentsOf: Array(blocks.dropFirst(maxBlocksPerDay)))
                balanced[day] = Array(blocks.prefix(maxBlocksPerDay))
            }
        }

        // Redistribute overflow to days with capacity
        for block in overflow {
            for day in balanced.keys.sorted() {
                if (balanced[day]?.count ?? 0) < maxBlocksPerDay {
                    balanced[day, default: []].append(block)
                    break
                }
            }
        }

        return balanced
    }

    // MARK: - Focus Areas

    private func extractFocusAreas(from activities: [DomainActivity]) -> [String] {
        // Extract unique focus areas from activity names/descriptions
        var areas: Set<String> = []

        for activity in activities {
            let words = activity.name.components(separatedBy: " ")
            if let mainFocus = words.first {
                areas.insert(mainFocus)
            }
        }

        return Array(areas).sorted()
    }

    // MARK: - Quick Wins

    private func getQuickWin(for phase: MilestonePhase, domain: GoalDomainType) -> String {
        switch (phase, domain) {
        case (.orientation, .softwareEngineering):
            return "Complete one coding challenge"
        case (.orientation, .fitness):
            return "Hit your step goal today"
        case (.orientation, .business):
            return "Talk to one potential customer"
        case (.orientation, _):
            return "Complete your first focused session"

        case (.building, .softwareEngineering):
            return "Finish one feature or module"
        case (.building, .fitness):
            return "Set a new personal record"
        case (.building, .business):
            return "Get one piece of positive feedback"
        case (.building, _):
            return "Complete all scheduled blocks this week"

        case (.validation, .softwareEngineering):
            return "Get code reviewed by someone experienced"
        case (.validation, .fitness):
            return "Complete a fitness assessment"
        case (.validation, .business):
            return "Close your first sale or conversion"
        case (.validation, _):
            return "Test yourself and document results"

        case (.momentum, .softwareEngineering):
            return "Ship something to production"
        case (.momentum, .fitness):
            return "Complete all workouts this week"
        case (.momentum, .business):
            return "Achieve your weekly revenue target"
        case (.momentum, _):
            return "Maintain your streak all week"

        case (.scaling, .softwareEngineering):
            return "Mentor someone or share your learning"
        case (.scaling, .fitness):
            return "Try an advanced variation"
        case (.scaling, .business):
            return "Automate one repetitive task"
        case (.scaling, _):
            return "Optimize your highest-impact activity"
        }
    }

    // MARK: - Reflection Prompts

    private func getReflectionPrompts(for phase: MilestonePhase) -> [String] {
        switch phase {
        case .orientation:
            return [
                "What felt most natural this week?",
                "What was harder than expected?",
                "What time of day worked best for you?"
            ]
        case .building:
            return [
                "What progress are you most proud of?",
                "Where did you struggle most?",
                "What would you do differently next week?"
            ]
        case .validation:
            return [
                "Did you meet your validation criteria?",
                "What gaps in your skills did you identify?",
                "What's your confidence level on a scale of 1-10?"
            ]
        case .momentum:
            return [
                "Are you maintaining consistency?",
                "What's fueling your motivation?",
                "What could derail you, and how will you prevent it?"
            ]
        case .scaling:
            return [
                "What can you delegate or automate?",
                "Where are your biggest efficiency gains?",
                "What's your next growth opportunity?"
            ]
        }
    }

    // MARK: - Adjustment Triggers

    private func getAdjustmentTriggers(for phase: MilestonePhase) -> [AdjustmentTrigger] {
        var triggers: [AdjustmentTrigger] = []

        // Universal triggers
        triggers.append(AdjustmentTrigger(
            condition: "Completion rate < 50%",
            suggestedAction: "Reduce weekly hours or block duration",
            priority: .high
        ))

        triggers.append(AdjustmentTrigger(
            condition: "3+ consecutive skipped blocks",
            suggestedAction: "Review scheduling conflicts and adjust times",
            priority: .medium
        ))

        // Phase-specific triggers
        switch phase {
        case .orientation:
            triggers.append(AdjustmentTrigger(
                condition: "Feeling overwhelmed",
                suggestedAction: "Focus on just one core activity this week",
                priority: .high
            ))
        case .building:
            triggers.append(AdjustmentTrigger(
                condition: "Plateauing progress",
                suggestedAction: "Increase difficulty or add variety",
                priority: .medium
            ))
        case .validation:
            triggers.append(AdjustmentTrigger(
                condition: "Failed validation",
                suggestedAction: "Identify specific gaps and add targeted practice",
                priority: .high
            ))
        case .momentum:
            triggers.append(AdjustmentTrigger(
                condition: "Losing motivation",
                suggestedAction: "Reconnect with your 'why' and add accountability",
                priority: .medium
            ))
        case .scaling:
            triggers.append(AdjustmentTrigger(
                condition: "Diminishing returns",
                suggestedAction: "Consider if goal is complete or needs redefinition",
                priority: .low
            ))
        }

        return triggers
    }

    // MARK: - Create Calendar Blocks

    /// Convert planned blocks to actual PlanBlocks for the calendar
    func createCalendarBlocks(
        from weeklyPlan: WeeklyExecutionPlan,
        startOfWeek: Date,
        goalId: UUID
    ) -> [PlanBlock] {
        var calendarBlocks: [PlanBlock] = []

        for (dayOfWeek, plannedBlocks) in weeklyPlan.dailyDistribution {
            guard let targetDate = calendar.date(
                byAdding: .day,
                value: dayOfWeek - 1, // Calendar weekdays are 1-indexed (Sunday = 1)
                to: startOfWeek
            ) else { continue }

            var hourOffset = 9 // Start scheduling from 9 AM

            for planned in plannedBlocks {
                // Adjust start time based on preferred time of day
                let startHour: Int
                switch planned.preferredTimeOfDay {
                case .morning: startHour = min(hourOffset, 11)
                case .afternoon: startHour = max(13, min(hourOffset, 16))
                case .evening: startHour = max(17, min(hourOffset, 20))
                }

                guard let startDateTime = calendar.date(
                    bySettingHour: startHour,
                    minute: 0,
                    second: 0,
                    of: targetDate
                ) else { continue }

                let endDateTime = calendar.date(
                    byAdding: .minute,
                    value: planned.duration,
                    to: startDateTime
                ) ?? startDateTime

                let block = PlanBlock(
                    startDateTime: startDateTime,
                    endDateTime: endDateTime,
                    title: planned.activityName,
                    intentShort: planned.description,
                    blockType: planned.blockType,
                    energyLevel: planned.energyLevel,
                    weekNumber: planned.weekNumber
                )

                calendarBlocks.append(block)
                hourOffset = startHour + (planned.duration / 60) + 1 // Add 1 hour buffer
            }
        }

        return calendarBlocks
    }
}

// MARK: - Supporting Types

struct WeeklyExecutionPlan {
    let weekNumber: Int
    let milestone: Milestone
    let blocks: [PlannedBlock]
    let dailyDistribution: [Int: [PlannedBlock]]
    let focusAreas: [String]
    let weeklyQuickWin: String
    let reflectionPrompts: [String]
    let adjustmentTriggers: [AdjustmentTrigger]

    var totalHours: Double {
        Double(blocks.reduce(0) { $0 + $1.duration }) / 60.0
    }

    var blockCount: Int {
        blocks.count
    }
}

struct PlannedBlock: Identifiable {
    let id = UUID()
    let activityName: String
    let description: String
    let duration: Int // in minutes
    let blockType: BlockType
    let preferredTimeOfDay: TimeOfDay
    let energyLevel: EnergyLevel
    let weekNumber: Int
    let isFlexible: Bool
    let priority: BlockPriority
}

enum TimeOfDay: String, CaseIterable {
    case morning = "Morning"
    case afternoon = "Afternoon"
    case evening = "Evening"

    var hourRange: ClosedRange<Int> {
        switch self {
        case .morning: return 6...11
        case .afternoon: return 12...16
        case .evening: return 17...21
        }
    }
}

enum BlockPriority: Int, Comparable {
    case low = 1
    case medium = 2
    case high = 3

    static func < (lhs: BlockPriority, rhs: BlockPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct AdjustmentTrigger {
    let condition: String
    let suggestedAction: String
    let priority: TriggerPriority

    enum TriggerPriority {
        case low, medium, high
    }
}

struct Availability {
    let weeklyHours: Int
    let preferredDays: [Int] // 1 = Sunday, 7 = Saturday
    let maxBlocksPerDay: Int
    let blackoutTimes: [DateInterval]

    static let standard = Availability(
        weeklyHours: 10,
        preferredDays: [2, 3, 4, 5, 6], // Mon-Fri
        maxBlocksPerDay: 3,
        blackoutTimes: []
    )

    static let intensive = Availability(
        weeklyHours: 20,
        preferredDays: [1, 2, 3, 4, 5, 6, 7], // All days
        maxBlocksPerDay: 4,
        blackoutTimes: []
    )

    static let minimal = Availability(
        weeklyHours: 5,
        preferredDays: [2, 4, 6], // Mon, Wed, Fri
        maxBlocksPerDay: 2,
        blackoutTimes: []
    )
}
