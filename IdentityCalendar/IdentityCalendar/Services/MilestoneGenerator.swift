import Foundation

// MARK: - Milestone Generator
/// Generates time-based milestone roadmaps for goal achievement

final class MilestoneGenerator {
    static let shared = MilestoneGenerator()

    private let knowledgeBase = DomainKnowledgeBase.shared
    private let calendar = Calendar.current

    private init() {}

    // MARK: - Generate Roadmap

    /// Generate a complete milestone roadmap for a goal
    func generateRoadmap(
        for analysis: GoalAnalysis,
        timeHorizon: TimeHorizon,
        intensity: Intensity,
        startDate: Date = Date()
    ) -> MilestoneRoadmap {
        let blueprint = knowledgeBase.getBlueprint(for: analysis.domain)
        let phases = blueprint.progressionPhases

        var milestones: [GeneratedMilestone] = []

        // Week 1: Orientation + Quick Wins
        milestones.append(generateWeek1Milestone(
            analysis: analysis,
            blueprint: blueprint,
            startDate: startDate,
            intensity: intensity
        ))

        // Week 2: First Measurable Progress
        milestones.append(generateWeek2Milestone(
            analysis: analysis,
            blueprint: blueprint,
            startDate: startDate,
            intensity: intensity
        ))

        // Week 4: Skill Validation
        milestones.append(generateWeek4Milestone(
            analysis: analysis,
            blueprint: blueprint,
            startDate: startDate,
            intensity: intensity
        ))

        // Week 8: Momentum Phase (if time horizon allows)
        if timeHorizon.weeks >= 8 {
            milestones.append(generateWeek8Milestone(
                analysis: analysis,
                blueprint: blueprint,
                startDate: startDate,
                intensity: intensity
            ))
        }

        // Week 12+: Scaling Phase (if time horizon allows)
        if timeHorizon.weeks >= 12 {
            milestones.append(generateWeek12Milestone(
                analysis: analysis,
                blueprint: blueprint,
                startDate: startDate,
                intensity: intensity
            ))
        }

        return MilestoneRoadmap(
            goalId: UUID(),
            domain: analysis.domain,
            milestones: milestones,
            estimatedCompletionDate: calendar.date(byAdding: .weekOfYear, value: timeHorizon.weeks, to: startDate) ?? startDate,
            adaptiveCheckpoints: generateAdaptiveCheckpoints(milestones: milestones)
        )
    }

    /// Generate milestones for PersonalizedAIPlannerEngine
    func generateMilestones(
        for analysis: GoalAnalysis,
        blueprint: DomainBlueprint,
        timeHorizon: TimeHorizon,
        intensity: Intensity
    ) -> [PlanMilestone] {
        var milestones: [PlanMilestone] = []
        let totalWeeks = timeHorizon.weeks

        // Week 1: Foundation
        milestones.append(PlanMilestone(
            title: "Foundation & First Wins",
            timeframe: "Week 1",
            weekNumber: 1
        ))

        // Week 2: Measurable Progress
        if totalWeeks >= 2 {
            milestones.append(PlanMilestone(
                title: "Measurable Progress",
                timeframe: "Week 2",
                weekNumber: 2
            ))
        }

        // Week 4: Skill Validation
        if totalWeeks >= 4 {
            milestones.append(PlanMilestone(
                title: "Skill Validation",
                timeframe: "Week 4",
                weekNumber: 4
            ))
        }

        // Week 8: Momentum Phase
        if totalWeeks >= 8 {
            milestones.append(PlanMilestone(
                title: "Momentum Phase",
                timeframe: "Week 8",
                weekNumber: 8
            ))
        }

        // Week 12: Scaling Phase
        if totalWeeks >= 12 {
            milestones.append(PlanMilestone(
                title: "Scaling & Mastery",
                timeframe: "Week 12",
                weekNumber: 12
            ))
        }

        return milestones
    }

    // MARK: - Week 1: Orientation + Quick Wins

    private func generateWeek1Milestone(
        analysis: GoalAnalysis,
        blueprint: DomainBlueprint,
        startDate: Date,
        intensity: Intensity
    ) -> GeneratedMilestone {
        let quickWins = getQuickWins(for: analysis.domain, blueprint: blueprint)
        let setupTasks = getSetupTasks(for: analysis.domain)

        return GeneratedMilestone(
            weekNumber: 1,
            title: "Foundation & First Wins",
            description: "Set up your environment and achieve quick wins to build momentum",
            targetDate: calendar.date(byAdding: .weekOfYear, value: 1, to: startDate) ?? startDate,
            phase: .orientation,
            objectives: [
                MilestoneObjective(
                    title: "Complete setup",
                    description: setupTasks.first ?? "Prepare your workspace and tools",
                    isRequired: true,
                    verificationMethod: "Environment ready and tested"
                ),
                MilestoneObjective(
                    title: "First quick win",
                    description: quickWins.first ?? "Complete your first small achievement",
                    isRequired: true,
                    verificationMethod: "Tangible output produced"
                ),
                MilestoneObjective(
                    title: "Establish routine",
                    description: "Set consistent time blocks for this goal",
                    isRequired: false,
                    verificationMethod: "3+ sessions completed"
                )
            ],
            successMetrics: [
                "Setup 100% complete",
                "1 quick win achieved",
                "Daily routine established"
            ],
            estimatedHours: intensity.weeklyHours,
            blocksRequired: calculateBlocksRequired(hours: intensity.weeklyHours)
        )
    }

    // MARK: - Week 2: First Measurable Progress

    private func generateWeek2Milestone(
        analysis: GoalAnalysis,
        blueprint: DomainBlueprint,
        startDate: Date,
        intensity: Intensity
    ) -> GeneratedMilestone {
        let coreActivities = blueprint.highLeverageActivities.prefix(2)

        return GeneratedMilestone(
            weekNumber: 2,
            title: "Measurable Progress",
            description: "Demonstrate tangible progress with measurable outcomes",
            targetDate: calendar.date(byAdding: .weekOfYear, value: 2, to: startDate) ?? startDate,
            phase: .building,
            objectives: coreActivities.enumerated().map { index, activity in
                MilestoneObjective(
                    title: activity.name,
                    description: activity.description,
                    isRequired: index == 0,
                    verificationMethod: "Completed \(activity.weeklyFrequency)x this week"
                )
            } + [
                MilestoneObjective(
                    title: "Track progress",
                    description: "Log metrics and reflect on learnings",
                    isRequired: true,
                    verificationMethod: "Progress log updated"
                )
            ],
            successMetrics: getWeek2Metrics(for: analysis.domain),
            estimatedHours: intensity.weeklyHours,
            blocksRequired: calculateBlocksRequired(hours: intensity.weeklyHours)
        )
    }

    // MARK: - Week 4: Skill Validation

    private func generateWeek4Milestone(
        analysis: GoalAnalysis,
        blueprint: DomainBlueprint,
        startDate: Date,
        intensity: Intensity
    ) -> GeneratedMilestone {
        let validationTask = getValidationTask(for: analysis.domain)

        return GeneratedMilestone(
            weekNumber: 4,
            title: "Skill Validation",
            description: "Validate skills with a concrete output or assessment",
            targetDate: calendar.date(byAdding: .weekOfYear, value: 4, to: startDate) ?? startDate,
            phase: .validation,
            objectives: [
                MilestoneObjective(
                    title: validationTask.title,
                    description: validationTask.description,
                    isRequired: true,
                    verificationMethod: validationTask.verification
                ),
                MilestoneObjective(
                    title: "Identify gaps",
                    description: "Review progress and note areas for improvement",
                    isRequired: true,
                    verificationMethod: "Gap analysis documented"
                ),
                MilestoneObjective(
                    title: "Adjust approach",
                    description: "Refine strategy based on learnings",
                    isRequired: false,
                    verificationMethod: "Updated plan in place"
                )
            ],
            successMetrics: getWeek4Metrics(for: analysis.domain),
            estimatedHours: intensity.weeklyHours,
            blocksRequired: calculateBlocksRequired(hours: intensity.weeklyHours)
        )
    }

    // MARK: - Week 8: Momentum Phase

    private func generateWeek8Milestone(
        analysis: GoalAnalysis,
        blueprint: DomainBlueprint,
        startDate: Date,
        intensity: Intensity
    ) -> GeneratedMilestone {
        return GeneratedMilestone(
            weekNumber: 8,
            title: "Momentum & Proof",
            description: "Demonstrate consistent capability and build momentum",
            targetDate: calendar.date(byAdding: .weekOfYear, value: 8, to: startDate) ?? startDate,
            phase: .momentum,
            objectives: [
                MilestoneObjective(
                    title: "Consistent execution",
                    description: "Maintain \(intensity.weeklyHours)+ hours/week for 4 consecutive weeks",
                    isRequired: true,
                    verificationMethod: "Time tracking confirms consistency"
                ),
                MilestoneObjective(
                    title: getMomentumProof(for: analysis.domain).title,
                    description: getMomentumProof(for: analysis.domain).description,
                    isRequired: true,
                    verificationMethod: getMomentumProof(for: analysis.domain).verification
                ),
                MilestoneObjective(
                    title: "Build portfolio/evidence",
                    description: "Compile proof of capability",
                    isRequired: false,
                    verificationMethod: "2+ examples documented"
                )
            ],
            successMetrics: getWeek8Metrics(for: analysis.domain),
            estimatedHours: intensity.weeklyHours,
            blocksRequired: calculateBlocksRequired(hours: intensity.weeklyHours)
        )
    }

    // MARK: - Week 12+: Scaling Phase

    private func generateWeek12Milestone(
        analysis: GoalAnalysis,
        blueprint: DomainBlueprint,
        startDate: Date,
        intensity: Intensity
    ) -> GeneratedMilestone {
        return GeneratedMilestone(
            weekNumber: 12,
            title: "Scale & Optimize",
            description: "Scale your capability and optimize for efficiency",
            targetDate: calendar.date(byAdding: .weekOfYear, value: 12, to: startDate) ?? startDate,
            phase: .scaling,
            objectives: [
                MilestoneObjective(
                    title: getScalingGoal(for: analysis.domain).title,
                    description: getScalingGoal(for: analysis.domain).description,
                    isRequired: true,
                    verificationMethod: getScalingGoal(for: analysis.domain).verification
                ),
                MilestoneObjective(
                    title: "Optimize workflow",
                    description: "Identify and eliminate inefficiencies",
                    isRequired: true,
                    verificationMethod: "20% efficiency gain documented"
                ),
                MilestoneObjective(
                    title: "Plan next phase",
                    description: "Set goals for continued growth",
                    isRequired: false,
                    verificationMethod: "Next quarter plan created"
                )
            ],
            successMetrics: getWeek12Metrics(for: analysis.domain),
            estimatedHours: intensity.weeklyHours,
            blocksRequired: calculateBlocksRequired(hours: intensity.weeklyHours)
        )
    }

    // MARK: - Domain-Specific Helpers

    private func getQuickWins(for domain: GoalDomainType, blueprint: DomainBlueprint) -> [String] {
        switch domain {
        case .softwareEngineering:
            return ["Complete first coding tutorial", "Set up development environment", "Build 'Hello World' project"]
        case .investmentBanking:
            return ["Complete first valuation model section", "Memorize 10 key formulas", "Read one industry report"]
        case .fitness:
            return ["Complete first full workout", "Hit protein target for one day", "Establish sleep schedule"]
        case .weightLoss:
            return ["Track meals for 3 days", "Complete first workout", "Remove one unhealthy habit"]
        case .business:
            return ["Validate one customer problem", "Create landing page", "Get first feedback"]
        case .incomeGeneration:
            return ["Identify monetizable skill", "Create first offering", "Reach out to 5 prospects"]
        case .contentCreation:
            return ["Publish first piece of content", "Set up platform profile", "Engage with 10 creators"]
        case .languageLearning:
            return ["Learn 50 common words", "Complete first lesson", "Have first basic conversation"]
        case .academicSuccess:
            return ["Create study schedule", "Complete first study session", "Review first chapter"]
        case .careerTransition:
            return ["Update resume", "Identify target roles", "Connect with 3 people in target field"]
        case .general:
            return ["Define clear outcome", "Complete first action", "Establish routine"]
        }
    }

    private func getSetupTasks(for domain: GoalDomainType) -> [String] {
        switch domain {
        case .softwareEngineering:
            return ["Install IDE and tools", "Set up version control", "Configure development environment"]
        case .investmentBanking:
            return ["Set up Excel with shortcuts", "Organize study materials", "Create formula reference sheet"]
        case .fitness:
            return ["Join gym or set up home workout space", "Plan weekly workout schedule", "Prepare meal prep routine"]
        case .weightLoss:
            return ["Download calorie tracking app", "Clear kitchen of junk food", "Plan weekly meals"]
        case .business:
            return ["Register business entity", "Set up basic online presence", "Create customer tracking system"]
        case .incomeGeneration:
            return ["Set up payment processing", "Create portfolio or samples", "Set up tracking for leads"]
        case .contentCreation:
            return ["Set up equipment and software", "Create content calendar", "Establish posting schedule"]
        case .languageLearning:
            return ["Install language learning app", "Find language partner or tutor", "Set up daily practice reminders"]
        case .academicSuccess:
            return ["Organize study materials", "Set up distraction-free environment", "Create study calendar"]
        case .careerTransition:
            return ["Audit current skills", "Research target industry", "Set up professional profiles"]
        case .general:
            return ["Define success metrics", "Gather necessary resources", "Set up tracking system"]
        }
    }

    private func getValidationTask(for domain: GoalDomainType) -> (title: String, description: String, verification: String) {
        switch domain {
        case .softwareEngineering:
            return ("Complete mini-project", "Build a functional project that demonstrates core skills", "Working code deployed or shared")
        case .investmentBanking:
            return ("Complete practice case", "Finish a full valuation or modeling case study", "Case reviewed with 80%+ accuracy")
        case .fitness:
            return ("Hit strength benchmark", "Achieve measurable improvement in key lifts", "Logged improvement in tracking app")
        case .weightLoss:
            return ("Sustained loss verification", "Maintain consistent caloric deficit for 2+ weeks", "Scale confirms trend")
        case .business:
            return ("First revenue/engagement", "Get paying customer or significant user engagement", "Revenue or engagement documented")
        case .incomeGeneration:
            return ("First paid project", "Complete and get paid for first work", "Payment received")
        case .contentCreation:
            return ("Engagement milestone", "Achieve meaningful engagement on content", "Analytics show growth trend")
        case .languageLearning:
            return ("Conversation test", "Hold 5-minute conversation on basic topics", "Self-recorded or tutor verified")
        case .academicSuccess:
            return ("Practice test success", "Score 80%+ on practice assessment", "Test score documented")
        case .careerTransition:
            return ("First interview", "Secure interview at target company/role", "Interview scheduled")
        case .general:
            return ("Progress checkpoint", "Complete significant milestone toward goal", "Evidence documented")
        }
    }

    private func getMomentumProof(for domain: GoalDomainType) -> (title: String, description: String, verification: String) {
        switch domain {
        case .softwareEngineering:
            return ("Ship complete feature", "Build and deploy a complete feature or project", "Live and functional")
        case .investmentBanking:
            return ("Full model completion", "Complete end-to-end financial model", "Model reviewed and validated")
        case .fitness:
            return ("Intermediate benchmark", "Reach intermediate strength/fitness levels", "Benchmark achieved and logged")
        case .weightLoss:
            return ("Halfway to goal", "Reach 50% of weight loss target", "Weight log confirms")
        case .business:
            return ("Repeatable sales", "Achieve 3+ sales or consistent user growth", "Revenue/user data documented")
        case .incomeGeneration:
            return ("Recurring income", "Establish recurring revenue stream", "Income verified")
        case .contentCreation:
            return ("Audience growth", "Reach significant follower/subscriber milestone", "Analytics confirm")
        case .languageLearning:
            return ("Complex conversations", "Hold 15+ minute conversation on varied topics", "Recorded or tutor verified")
        case .academicSuccess:
            return ("Strong exam performance", "Score 85%+ on major assessment", "Grade confirmed")
        case .careerTransition:
            return ("Multiple interviews", "Complete 3+ interviews in target field", "Interviews logged")
        case .general:
            return ("Major milestone", "Complete significant deliverable", "Output documented")
        }
    }

    private func getScalingGoal(for domain: GoalDomainType) -> (title: String, description: String, verification: String) {
        switch domain {
        case .softwareEngineering:
            return ("Advanced project", "Build complex project or contribute to significant codebase", "Code reviewed and merged")
        case .investmentBanking:
            return ("Case ready", "Ready for live interview case studies", "Mock interviews passed")
        case .fitness:
            return ("Advanced fitness level", "Achieve advanced benchmarks", "Performance tests passed")
        case .weightLoss:
            return ("Goal weight achieved", "Reach target weight with maintenance plan", "Weight maintained 2+ weeks")
        case .business:
            return ("Scalable systems", "Implement systems for growth", "Growth metrics improving")
        case .incomeGeneration:
            return ("Income goal met", "Reach target income level", "Income documented")
        case .contentCreation:
            return ("Monetization active", "Generate revenue from content", "Revenue documented")
        case .languageLearning:
            return ("Fluent conversations", "Hold natural conversations with native speakers", "Conversation recorded")
        case .academicSuccess:
            return ("Top performance", "Achieve top 10% in class/exam", "Grades confirm")
        case .careerTransition:
            return ("Offer received", "Receive job offer in target field", "Offer letter received")
        case .general:
            return ("Goal achieved", "Complete primary objective", "Success criteria met")
        }
    }

    private func getWeek2Metrics(for domain: GoalDomainType) -> [String] {
        switch domain {
        case .softwareEngineering:
            return ["100+ lines of code written", "1 tutorial completed", "Consistent daily practice"]
        case .investmentBanking:
            return ["5 valuation concepts mastered", "50+ formulas memorized", "2 practice problems completed"]
        case .fitness:
            return ["4 workouts completed", "Protein target hit 5/7 days", "Progressive overload applied"]
        case .weightLoss:
            return ["Caloric deficit maintained 6/7 days", "3+ workouts completed", "1-2 lbs lost"]
        case .business:
            return ["10 customer conversations", "MVP feature defined", "First landing page live"]
        case .incomeGeneration:
            return ["10 outreach messages sent", "1 potential client engaged", "Pricing established"]
        case .contentCreation:
            return ["3+ pieces published", "Engagement baseline established", "Posting rhythm set"]
        case .languageLearning:
            return ["100+ words learned", "Daily practice streak", "First conversation attempted"]
        case .academicSuccess:
            return ["All scheduled sessions completed", "Notes for 2+ chapters", "No missed deadlines"]
        case .careerTransition:
            return ["Resume tailored to 3 roles", "5 networking messages sent", "1 informational interview done"]
        case .general:
            return ["Consistent daily action", "First mini-goal achieved", "Tracking system active"]
        }
    }

    private func getWeek4Metrics(for domain: GoalDomainType) -> [String] {
        switch domain {
        case .softwareEngineering:
            return ["1 project completed", "Core concepts understood", "Problem-solving improved"]
        case .investmentBanking:
            return ["Full case study completed", "All core formulas memorized", "Speed improving"]
        case .fitness:
            return ["10% strength increase", "All workouts completed", "Recovery optimized"]
        case .weightLoss:
            return ["4+ lbs lost", "Habits becoming automatic", "Energy levels improved"]
        case .business:
            return ["First revenue or strong interest", "Clear value proposition", "Customer feedback incorporated"]
        case .incomeGeneration:
            return ["First paid work completed", "Pipeline of prospects", "Process documented"]
        case .contentCreation:
            return ["12+ pieces published", "Growing engagement", "Voice/style emerging"]
        case .languageLearning:
            return ["300+ words known", "Basic conversations possible", "Listening comprehension improved"]
        case .academicSuccess:
            return ["Practice test taken", "Weak areas identified", "Study method refined"]
        case .careerTransition:
            return ["3+ applications submitted", "Interview skills practiced", "1+ interviews scheduled"]
        case .general:
            return ["Validation checkpoint passed", "Clear progress visible", "Refined approach"]
        }
    }

    private func getWeek8Metrics(for domain: GoalDomainType) -> [String] {
        switch domain {
        case .softwareEngineering:
            return ["2+ projects in portfolio", "Intermediate skills proven", "Can build independently"]
        case .investmentBanking:
            return ["Multiple case types mastered", "Speed at target level", "Interview ready"]
        case .fitness:
            return ["Intermediate benchmarks hit", "Consistent 8-week streak", "Body composition improved"]
        case .weightLoss:
            return ["50%+ toward goal", "Lifestyle changes embedded", "No major setbacks"]
        case .business:
            return ["Repeatable sales process", "Growing customer base", "Unit economics positive"]
        case .incomeGeneration:
            return ["Recurring clients/income", "Referral pipeline active", "Efficient delivery"]
        case .contentCreation:
            return ["Significant audience growth", "Engagement increasing", "Format optimized"]
        case .languageLearning:
            return ["500+ words known", "15+ min conversations", "Cultural context understood"]
        case .academicSuccess:
            return ["Strong exam performance", "Top third of class", "Study efficiency high"]
        case .careerTransition:
            return ["Multiple interviews completed", "Strong interview performance", "Close to offer stage"]
        case .general:
            return ["Major milestone achieved", "Momentum sustained", "Confidence high"]
        }
    }

    private func getWeek12Metrics(for domain: GoalDomainType) -> [String] {
        switch domain {
        case .softwareEngineering:
            return ["Advanced project completed", "Job-ready skills", "Can mentor beginners"]
        case .investmentBanking:
            return ["Interview process navigated", "Technical skills proven", "Ready for role"]
        case .fitness:
            return ["Advanced benchmarks achieved", "Sustainable routine", "Teaching others"]
        case .weightLoss:
            return ["Goal weight achieved or near", "Maintenance plan active", "Identity shift complete"]
        case .business:
            return ["Scalable systems in place", "Consistent growth", "Profitable operations"]
        case .incomeGeneration:
            return ["Target income achieved", "Multiple revenue streams", "Time freedom increased"]
        case .contentCreation:
            return ["Monetization active", "Strong community", "Content flywheel working"]
        case .languageLearning:
            return ["Conversational fluency", "Cultural fluency", "Can consume native content"]
        case .academicSuccess:
            return ["Top 10% performance", "Deep subject mastery", "Teaching ability"]
        case .careerTransition:
            return ["Offer received/accepted", "Successful transition", "Thriving in new role"]
        case .general:
            return ["Primary goal achieved", "New baseline established", "Ready for next level"]
        }
    }

    // MARK: - Helpers

    private func calculateBlocksRequired(hours: Int) -> Int {
        // Assuming average block is 45 minutes
        return Int(ceil(Double(hours * 60) / 45.0))
    }

    private func generateAdaptiveCheckpoints(milestones: [GeneratedMilestone]) -> [AdaptiveCheckpoint] {
        milestones.enumerated().map { index, milestone in
            AdaptiveCheckpoint(
                weekNumber: milestone.weekNumber,
                checkType: index == 0 ? .initial : (index == milestones.count - 1 ? .final : .progress),
                questions: [
                    "Are you on track with \(milestone.title)?",
                    "What's been your biggest challenge?",
                    "What adjustment would help most?"
                ],
                possibleAdaptations: [
                    .adjustIntensity,
                    .modifyApproach,
                    .extendTimeline
                ]
            )
        }
    }
}

// MARK: - Supporting Types

struct MilestoneRoadmap {
    let goalId: UUID
    let domain: GoalDomainType
    let milestones: [GeneratedMilestone]
    let estimatedCompletionDate: Date
    let adaptiveCheckpoints: [AdaptiveCheckpoint]

    var currentMilestone: GeneratedMilestone? {
        let now = Date()
        return milestones.first { $0.targetDate > now }
    }

    var progress: Double {
        let completed = milestones.filter { $0.isCompleted }.count
        return Double(completed) / Double(max(1, milestones.count))
    }
}

struct GeneratedMilestone: Identifiable {
    let id = UUID()
    let weekNumber: Int
    let title: String
    let description: String
    let targetDate: Date
    let phase: MilestonePhase
    let objectives: [MilestoneObjective]
    let successMetrics: [String]
    let estimatedHours: Int
    let blocksRequired: Int

    var isCompleted: Bool = false
    var completedDate: Date?
    var notes: String?
}

struct MilestoneObjective: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let isRequired: Bool
    let verificationMethod: String

    var isCompleted: Bool = false
}

enum MilestonePhase: String, CaseIterable {
    case orientation = "Orientation"
    case building = "Building"
    case validation = "Validation"
    case momentum = "Momentum"
    case scaling = "Scaling"

    var icon: String {
        switch self {
        case .orientation: return "flag.fill"
        case .building: return "hammer.fill"
        case .validation: return "checkmark.seal.fill"
        case .momentum: return "flame.fill"
        case .scaling: return "chart.line.uptrend.xyaxis"
        }
    }

    var color: String {
        switch self {
        case .orientation: return "blue"
        case .building: return "orange"
        case .validation: return "green"
        case .momentum: return "red"
        case .scaling: return "purple"
        }
    }
}

struct AdaptiveCheckpoint {
    let weekNumber: Int
    let checkType: CheckpointType
    let questions: [String]
    let possibleAdaptations: [AdaptationType]
}

enum CheckpointType {
    case initial
    case progress
    case final
}

enum AdaptationType {
    case adjustIntensity
    case modifyApproach
    case extendTimeline
    case addSupport
    case simplifyGoal
}
