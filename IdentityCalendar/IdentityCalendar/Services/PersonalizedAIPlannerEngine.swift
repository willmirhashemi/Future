import Foundation

// MARK: - Personalized AI Planner Engine
/// Elite goal-planning AI that transforms minimal input into comprehensive, executable plans
/// Follows Apple-like design: calm, precise, modern, empowering

final class PersonalizedAIPlannerEngine {
    static let shared = PersonalizedAIPlannerEngine()

    private let domainKnowledge = DomainKnowledgeBase.shared
    private let milestoneGenerator = MilestoneGenerator.shared
    private let weeklyPlanBuilder = WeeklyPlanBuilder.shared
    private let calendar = Calendar.current

    private init() {}

    // MARK: - Core Planning Function

    /// Transform user input into a complete, personalized plan
    func generateComprehensivePlan(
        userInput: String,
        timeHorizon: TimeHorizon,
        availability: Availability,
        intensity: Intensity,
        constraints: [UserConstraint] = []
    ) -> ComprehensivePlan {
        // Step 1: Parse and understand the goal
        let goalAnalysis = analyzeGoalInput(userInput)

        // Step 2: Get domain-specific knowledge
        let domainBlueprint = domainKnowledge.getBlueprint(for: goalAnalysis.primaryDomain)

        // Step 3: Define success criteria
        let successDefinition = defineSuccess(
            for: goalAnalysis,
            blueprint: domainBlueprint,
            timeHorizon: timeHorizon
        )

        // Step 4: Generate high-leverage activities
        let coreActivities = generateHighLeverageActivities(
            blueprint: domainBlueprint,
            availability: availability,
            intensity: intensity,
            constraints: constraints
        )

        // Step 5: Create milestone roadmap
        let milestones = milestoneGenerator.generateMilestones(
            for: goalAnalysis,
            blueprint: domainBlueprint,
            timeHorizon: timeHorizon,
            intensity: intensity
        )

        // Step 6: Build weekly execution plans
        let weeklyPlans = weeklyPlanBuilder.buildWeeklyPlans(
            activities: coreActivities,
            milestones: milestones,
            availability: availability,
            totalWeeks: timeHorizon.weeks
        )

        // Step 7: Generate plan blocks for calendar
        let planBlocks = generatePlanBlocks(
            from: weeklyPlans,
            startDate: Date(),
            totalWeeks: timeHorizon.weeks
        )

        // Step 8: Create weekly themes
        let weeklyThemes = generateWeeklyThemes(
            milestones: milestones,
            blueprint: domainBlueprint,
            totalWeeks: timeHorizon.weeks
        )

        return ComprehensivePlan(
            goalAnalysis: goalAnalysis,
            successDefinition: successDefinition,
            coreActivities: coreActivities,
            milestones: milestones,
            weeklyPlans: weeklyPlans,
            weeklyThemes: weeklyThemes,
            planBlocks: planBlocks,
            strategies: domainBlueprint.provenStrategies,
            psychologicalDesign: generatePsychologicalSupport(for: goalAnalysis)
        )
    }

    // MARK: - Goal Analysis

    private func analyzeGoalInput(_ input: String) -> GoalAnalysis {
        let lowercased = input.lowercased()

        // Detect primary domain
        let primaryDomain = detectPrimaryDomain(from: lowercased)

        // Extract specifics
        let specifics = extractGoalSpecifics(from: lowercased)

        // Detect urgency signals
        let urgencyLevel = detectUrgency(from: lowercased)

        // Detect experience level
        let experienceLevel = detectExperienceLevel(from: lowercased)

        return GoalAnalysis(
            originalInput: input,
            primaryDomain: primaryDomain,
            secondaryDomains: detectSecondaryDomains(from: lowercased, excluding: primaryDomain),
            specifics: specifics,
            urgencyLevel: urgencyLevel,
            experienceLevel: experienceLevel,
            assumptions: generateAssumptions(domain: primaryDomain, input: lowercased)
        )
    }

    private func detectPrimaryDomain(from input: String) -> GoalDomainType {
        let domainScores: [(GoalDomainType, Int)] = GoalDomainType.allCases.map { domain in
            let keywords = domainKnowledge.getKeywords(for: domain)
            let score = keywords.filter { input.contains($0.lowercased()) }.count
            return (domain, score)
        }

        // Return highest scoring domain, default to general
        return domainScores.max(by: { $0.1 < $1.1 })?.0 ?? .general
    }

    private func detectSecondaryDomains(from input: String, excluding primary: GoalDomainType) -> [GoalDomainType] {
        let domainScores: [(GoalDomainType, Int)] = GoalDomainType.allCases
            .filter { $0 != primary }
            .map { domain in
                let keywords = domainKnowledge.getKeywords(for: domain)
                let score = keywords.filter { input.contains($0.lowercased()) }.count
                return (domain, score)
            }

        return domainScores.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }.prefix(2).map { $0.0 }
    }

    private func extractGoalSpecifics(from input: String) -> GoalSpecifics {
        // Extract numeric targets
        var targetAmount: Double?
        var targetUnit: String?

        // Pattern: "$10,000" or "10000 dollars" or "10k"
        let moneyPatterns = [
            #"\$(\d+[,\d]*)"#,
            #"(\d+[,\d]*)\s*(?:dollars|usd)"#,
            #"(\d+)k\b"#
        ]

        for pattern in moneyPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
               let range = Range(match.range(at: 1), in: input) {
                var numStr = String(input[range]).replacingOccurrences(of: ",", with: "")
                if pattern.contains("k\\b") {
                    if let num = Double(numStr) {
                        targetAmount = num * 1000
                    }
                } else {
                    targetAmount = Double(numStr)
                }
                targetUnit = "dollars"
                break
            }
        }

        // Pattern: "15 pounds" or "20 lbs" or "10 kg"
        let weightPatterns = [
            #"(\d+)\s*(?:pounds?|lbs?)"#,
            #"(\d+)\s*(?:kg|kilograms?)"#
        ]

        for pattern in weightPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
               let range = Range(match.range(at: 1), in: input) {
                targetAmount = Double(input[range])
                targetUnit = pattern.contains("kg") ? "kg" : "pounds"
                break
            }
        }

        // Extract specific role/position
        let roleKeywords = ["engineer", "developer", "analyst", "manager", "designer", "founder", "creator", "coach", "consultant"]
        let targetRole = roleKeywords.first { input.contains($0) }

        // Extract specific skill
        let skillIndicators = ["learn", "master", "become fluent", "get good at"]
        var targetSkill: String?
        for indicator in skillIndicators {
            if let range = input.range(of: indicator) {
                let afterIndicator = String(input[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                let words = afterIndicator.components(separatedBy: .whitespaces).prefix(3)
                if !words.isEmpty {
                    targetSkill = words.joined(separator: " ")
                    break
                }
            }
        }

        return GoalSpecifics(
            targetAmount: targetAmount,
            targetUnit: targetUnit,
            targetRole: targetRole,
            targetSkill: targetSkill,
            isQuantifiable: targetAmount != nil
        )
    }

    private func detectUrgency(from input: String) -> UrgencyLevel {
        let urgentKeywords = ["asap", "urgent", "fast", "quickly", "immediately", "need to"]
        let relaxedKeywords = ["eventually", "someday", "when possible", "no rush", "casually"]

        if urgentKeywords.contains(where: { input.contains($0) }) {
            return .high
        } else if relaxedKeywords.contains(where: { input.contains($0) }) {
            return .low
        }
        return .moderate
    }

    private func detectExperienceLevel(from input: String) -> ExperienceLevel {
        let beginnerKeywords = ["beginner", "starting", "new to", "never", "first time", "from scratch", "zero experience"]
        let advancedKeywords = ["already", "experience", "background in", "worked as", "years of", "professional"]

        if beginnerKeywords.contains(where: { input.contains($0) }) {
            return .beginner
        } else if advancedKeywords.contains(where: { input.contains($0) }) {
            return .intermediate
        }
        return .beginner // Default assumption
    }

    private func generateAssumptions(domain: GoalDomainType, input: String) -> [String] {
        var assumptions: [String] = []

        // Add domain-specific assumptions
        switch domain {
        case .softwareEngineering:
            if !input.contains("job") && !input.contains("freelance") {
                assumptions.append("Goal is to get hired as a software engineer")
            }
        case .investmentBanking:
            if !input.contains("lateral") {
                assumptions.append("Targeting entry-level or internship positions")
            }
        case .fitness:
            if !input.contains("maintain") {
                assumptions.append("Goal is transformation, not maintenance")
            }
        case .business:
            if !input.contains("scale") {
                assumptions.append("Starting from idea/early stage")
            }
        case .incomeGeneration:
            if !input.contains("passive") {
                assumptions.append("Active income through skills or services")
            }
        default:
            break
        }

        return assumptions
    }

    // MARK: - Success Definition

    private func defineSuccess(
        for analysis: GoalAnalysis,
        blueprint: DomainBlueprint,
        timeHorizon: TimeHorizon
    ) -> SuccessDefinition {
        var outcomes: [MeasurableOutcome] = []
        var benchmarks: [PerformanceBenchmark] = []

        // Use specifics if available
        if let amount = analysis.specifics.targetAmount,
           let unit = analysis.specifics.targetUnit {
            outcomes.append(MeasurableOutcome(
                description: "Achieve \(Int(amount)) \(unit)",
                metric: unit,
                targetValue: amount,
                timeframe: timeHorizon.displayName
            ))
        }

        // Add domain-specific outcomes
        outcomes.append(contentsOf: blueprint.successOutcomes.map { outcome in
            MeasurableOutcome(
                description: outcome.description,
                metric: outcome.metric,
                targetValue: adjustTargetForTimeHorizon(outcome.targetValue, timeHorizon: timeHorizon),
                timeframe: timeHorizon.displayName
            )
        })

        // Add benchmarks
        benchmarks = blueprint.performanceBenchmarks

        return SuccessDefinition(
            summary: generateSuccessSummary(analysis: analysis, blueprint: blueprint),
            measurableOutcomes: outcomes,
            skillBenchmarks: benchmarks,
            timebound: timeHorizon.displayName
        )
    }

    private func generateSuccessSummary(analysis: GoalAnalysis, blueprint: DomainBlueprint) -> String {
        if let role = analysis.specifics.targetRole {
            return "Become a \(role) with demonstrated skills and opportunities"
        } else if let amount = analysis.specifics.targetAmount, let unit = analysis.specifics.targetUnit {
            return "Achieve \(Int(amount)) \(unit) through consistent execution"
        } else {
            return blueprint.defaultSuccessSummary
        }
    }

    private func adjustTargetForTimeHorizon(_ value: Double, timeHorizon: TimeHorizon) -> Double {
        switch timeHorizon {
        case .oneMonth: return value * 0.25
        case .threeMonths: return value * 0.5
        case .sixMonths: return value * 0.75
        case .oneYear: return value
        }
    }

    // MARK: - High-Leverage Activities

    private func generateHighLeverageActivities(
        blueprint: DomainBlueprint,
        availability: Availability,
        intensity: Intensity,
        constraints: [UserConstraint]
    ) -> [CoreActivity] {
        var activities = blueprint.highLeverageActivities

        // Adjust for availability
        let maxActivitiesPerWeek: Int
        switch availability {
        case .minimal: maxActivitiesPerWeek = 3
        case .partTime: maxActivitiesPerWeek = 5
        case .significant: maxActivitiesPerWeek = 7
        case .fullTime: maxActivitiesPerWeek = 10
        }

        // Prioritize and limit
        activities = Array(activities.sorted { $0.impactScore > $1.impactScore }.prefix(maxActivitiesPerWeek))

        // Adjust durations for intensity
        let durationMultiplier: Double
        switch intensity {
        case .light: durationMultiplier = 0.7
        case .balanced: durationMultiplier = 1.0
        case .aggressive: durationMultiplier = 1.3
        }

        activities = activities.map { activity in
            var modified = activity
            modified.durationMinutes = Int(Double(activity.durationMinutes) * durationMultiplier)
            return modified
        }

        // Apply constraints
        for constraint in constraints {
            switch constraint {
            case .limitedTime:
                activities = activities.map { activity in
                    var modified = activity
                    modified.durationMinutes = min(30, activity.durationMinutes)
                    return modified
                }
            case .beginner:
                // Prioritize foundational activities
                activities = activities.sorted { $0.difficultyLevel < $1.difficultyLevel }
            case .hasFullTimeJob:
                // Shift to morning/evening activities
                activities = activities.map { activity in
                    var modified = activity
                    modified.preferredTimeOfDay = [.earlyMorning, .evening]
                    return modified
                }
            case .isStudent:
                // Adjust for academic schedule
                activities = activities.map { activity in
                    var modified = activity
                    modified.preferredTimeOfDay = [.afternoon, .evening]
                    return modified
                }
            }
        }

        return activities
    }

    // MARK: - Plan Block Generation

    private func generatePlanBlocks(
        from weeklyPlans: [WeeklyExecutionPlan],
        startDate: Date,
        totalWeeks: Int
    ) -> [PlanBlock.PlanBlockData] {
        var blocks: [PlanBlock.PlanBlockData] = []
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime]

        for (weekIndex, weekPlan) in weeklyPlans.enumerated() {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: weekIndex, to: startDate) ?? startDate

            for task in weekPlan.tasks {
                // Distribute tasks across the week based on frequency
                let daysForTask = selectDaysForTask(task, in: weekStart)

                for day in daysForTask {
                    guard let blockStart = calendar.date(bySettingHour: task.preferredHour, minute: 0, second: 0, of: day),
                          let blockEnd = calendar.date(byAdding: .minute, value: task.durationMinutes, to: blockStart) else {
                        continue
                    }

                    blocks.append(PlanBlock.PlanBlockData(
                        startDateTime: isoFormatter.string(from: blockStart),
                        endDateTime: isoFormatter.string(from: blockEnd),
                        title: task.title,
                        blockType: task.blockType.rawValue,
                        intentShort: task.intent,
                        weekNumber: weekIndex + 1
                    ))
                }
            }
        }

        return blocks
    }

    private func selectDaysForTask(_ task: WeeklyTask, in weekStart: Date) -> [Date] {
        var days: [Date] = []

        switch task.frequency {
        case .daily:
            for dayOffset in 0..<7 {
                if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                    days.append(day)
                }
            }
        case .timesPerWeek(let count):
            // Distribute evenly across week
            let spacing = 7 / max(1, count)
            for i in 0..<count {
                if let day = calendar.date(byAdding: .day, value: i * spacing, to: weekStart) {
                    days.append(day)
                }
            }
        case .weekdays:
            for dayOffset in 0..<5 {
                if let day = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                    days.append(day)
                }
            }
        case .weekends:
            if let saturday = calendar.date(byAdding: .day, value: 5, to: weekStart) {
                days.append(saturday)
            }
            if let sunday = calendar.date(byAdding: .day, value: 6, to: weekStart) {
                days.append(sunday)
            }
        case .once:
            days.append(weekStart)
        }

        return days
    }

    // MARK: - Weekly Themes

    private func generateWeeklyThemes(
        milestones: [PlanMilestone],
        blueprint: DomainBlueprint,
        totalWeeks: Int
    ) -> [WeeklyTheme.WeeklyThemeData] {
        var themes: [WeeklyTheme.WeeklyThemeData] = []

        for week in 1...totalWeeks {
            let progressRatio = Double(week) / Double(totalWeeks)

            // Find relevant milestone for this week
            let relevantMilestone = milestones.first { $0.targetWeek >= week }

            let theme: (title: String, focus: String)
            if let milestone = relevantMilestone {
                theme = (milestone.title, milestone.focusArea)
            } else {
                theme = blueprint.getThemeForProgress(progressRatio)
            }

            themes.append(WeeklyTheme.WeeklyThemeData(
                weekNumber: week,
                title: theme.title,
                focus: theme.focus
            ))
        }

        return themes
    }

    // MARK: - Psychological Support

    private func generatePsychologicalSupport(for analysis: GoalAnalysis) -> PsychologicalDesign {
        return PsychologicalDesign(
            earlyWinStrategy: "Complete your first task within 24 hours to build momentum",
            motivationTriggers: [
                "Track visible progress daily",
                "Celebrate small wins weekly",
                "Connect with others on the same path"
            ],
            failureRecovery: "Missing a day doesn't reset progress. Adjust and continue.",
            streakPhilosophy: "Streaks bend — they don't break. One off day is a pause, not a restart.",
            reflectionPrompts: [
                "What worked well this week?",
                "What's one thing to improve?",
                "What are you proud of?"
            ]
        )
    }

    // MARK: - Plan Adaptation

    /// Adapt plan based on user feedback
    func adaptPlan(
        currentPlan: ComprehensivePlan,
        feedback: PlanFeedback
    ) -> ComprehensivePlan {
        var adapted = currentPlan

        switch feedback.type {
        case .tooHard:
            // Reduce intensity
            adapted.coreActivities = adapted.coreActivities.map { activity in
                var modified = activity
                modified.durationMinutes = Int(Double(activity.durationMinutes) * 0.7)
                return modified
            }
        case .tooEasy:
            // Increase intensity
            adapted.coreActivities = adapted.coreActivities.map { activity in
                var modified = activity
                modified.durationMinutes = Int(Double(activity.durationMinutes) * 1.2)
                return modified
            }
        case .missedWeek:
            // Provide recovery plan without shame
            adapted.psychologicalDesign.failureRecovery = "Welcome back. Let's pick up where you left off — no restart needed."
        case .wantsFaster:
            // Add optional stretch activities
            if let blueprint = domainKnowledge.getBlueprint(for: adapted.goalAnalysis.primaryDomain) as DomainBlueprint? {
                let stretchActivities = blueprint.highLeverageActivities.suffix(2)
                adapted.coreActivities.append(contentsOf: stretchActivities)
            }
        case .needsChange:
            // Offer alternative pathway
            break
        }

        return adapted
    }
}

// MARK: - Supporting Types

struct ComprehensivePlan {
    let goalAnalysis: GoalAnalysis
    let successDefinition: SuccessDefinition
    var coreActivities: [CoreActivity]
    let milestones: [PlanMilestone]
    let weeklyPlans: [WeeklyExecutionPlan]
    let weeklyThemes: [WeeklyTheme.WeeklyThemeData]
    let planBlocks: [PlanBlock.PlanBlockData]
    let strategies: [ProvenStrategy]
    var psychologicalDesign: PsychologicalDesign
}

struct GoalAnalysis {
    let originalInput: String
    let primaryDomain: GoalDomainType
    let secondaryDomains: [GoalDomainType]
    let specifics: GoalSpecifics
    let urgencyLevel: UrgencyLevel
    let experienceLevel: ExperienceLevel
    let assumptions: [String]
}

struct GoalSpecifics {
    let targetAmount: Double?
    let targetUnit: String?
    let targetRole: String?
    let targetSkill: String?
    let isQuantifiable: Bool
}

enum UrgencyLevel {
    case low, moderate, high
}

enum ExperienceLevel {
    case beginner, intermediate, advanced
}

enum UserConstraint {
    case limitedTime
    case beginner
    case hasFullTimeJob
    case isStudent
}

struct SuccessDefinition {
    let summary: String
    let measurableOutcomes: [MeasurableOutcome]
    let skillBenchmarks: [PerformanceBenchmark]
    let timebound: String
}

struct MeasurableOutcome {
    let description: String
    let metric: String
    let targetValue: Double
    let timeframe: String
}

struct PerformanceBenchmark {
    let skill: String
    let beginnerLevel: String
    let targetLevel: String
}

struct CoreActivity {
    var title: String
    var description: String
    var durationMinutes: Int
    var frequency: ActivityFrequency
    var blockType: BlockType
    var impactScore: Double // 0-1, how much this moves the needle
    var difficultyLevel: Int // 1-5
    var preferredTimeOfDay: [TimeOfDay]
}

// ActivityFrequency and TimeOfDay are defined in Models.swift

struct ProvenStrategy {
    let title: String
    let description: String
    let tactics: [String]
    let resources: [String]
}

struct PsychologicalDesign {
    let earlyWinStrategy: String
    let motivationTriggers: [String]
    var failureRecovery: String
    let streakPhilosophy: String
    let reflectionPrompts: [String]
}

struct PlanFeedback {
    let type: FeedbackType
    let details: String?

    enum FeedbackType {
        case tooHard
        case tooEasy
        case missedWeek
        case wantsFaster
        case needsChange
    }
}

enum GoalDomainType: String, CaseIterable {
    case softwareEngineering = "software_engineering"
    case investmentBanking = "investment_banking"
    case fitness = "fitness"
    case weightLoss = "weight_loss"
    case business = "business"
    case incomeGeneration = "income_generation"
    case contentCreation = "content_creation"
    case languageLearning = "language_learning"
    case academicSuccess = "academic_success"
    case careerTransition = "career_transition"
    case general = "general"
}
