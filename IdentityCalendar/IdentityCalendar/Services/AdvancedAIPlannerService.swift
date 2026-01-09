import Foundation

// MARK: - Advanced AI Planning Engine
/// A sophisticated AI-powered planning system that uses NLP parsing,
/// evidence-based scheduling algorithms, and domain-specific intelligence
/// to create highly personalized and effective plans.

@MainActor
final class AdvancedAIPlannerService: AIPlannerService {

    // MARK: - Core Components

    private let nlpParser = GoalNLPParser()
    private let scheduleOptimizer = ScheduleOptimizer()
    private let domainIntelligence = DomainIntelligence()
    private let adaptiveEngine = AdaptiveLearningEngine()
    private let calendar = Calendar.current

    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    // MARK: - AIPlannerService Protocol

    func generateInitialPlan(for goal: IdentityGoal) async throws -> AIPlanResponse {
        // Step 1: Parse and understand the goal deeply
        let parsedGoal = nlpParser.parseGoal(goal)

        // Step 2: Get domain-specific knowledge
        let domainPlan = domainIntelligence.generateDomainPlan(for: parsedGoal)

        // Step 3: Create optimized schedule
        let optimizedBlocks = scheduleOptimizer.createOptimalSchedule(
            domainPlan: domainPlan,
            parsedGoal: parsedGoal,
            goal: goal
        )

        // Step 4: Generate intelligent milestones
        let milestones = generateIntelligentMilestones(
            parsedGoal: parsedGoal,
            domainPlan: domainPlan,
            totalWeeks: goal.timeHorizon.weeks
        )

        // Step 5: Create progressive weekly themes
        let weeklyThemes = generateProgressiveThemes(
            parsedGoal: parsedGoal,
            domainPlan: domainPlan,
            totalWeeks: goal.timeHorizon.weeks
        )

        return AIPlanResponse(
            milestones: milestones,
            weeklyThemes: weeklyThemes,
            planBlocks: optimizedBlocks
        )
    }

    /// Protocol-compliant method for weekly plan adaptation
    func adaptWeeklyPlan(for goal: IdentityGoal, weekNumber: Int, feedback: WeeklyReflection?) async throws -> AIPlanResponse {
        // If no feedback, just regenerate the plan
        guard let reflection = feedback else {
            return try await generateInitialPlan(for: goal)
        }

        // Get current blocks for the goal
        let currentBlocks = goal.planBlocks.filter { $0.weekNumber == weekNumber }

        // Use the detailed adaptation method
        let adaptationResponse = try await adaptWeeklyPlanDetailed(
            for: goal,
            reflection: reflection,
            currentBlocks: Array(currentBlocks)
        )

        // Convert AIAdaptationResponse to AIPlanResponse
        return AIPlanResponse(
            milestones: [],  // Keep existing milestones
            weeklyThemes: [], // Keep existing themes
            planBlocks: adaptationResponse.updatedBlocks
        )
    }

    /// Detailed adaptation with full context
    func adaptWeeklyPlanDetailed(
        for goal: IdentityGoal,
        reflection: WeeklyReflection,
        currentBlocks: [PlanBlock]
    ) async throws -> AIAdaptationResponse {
        // Analyze user patterns
        let userPatterns = adaptiveEngine.analyzeUserPatterns(
            reflection: reflection,
            blocks: currentBlocks
        )

        // Calculate adaptation strategy
        let strategy = adaptiveEngine.determineAdaptationStrategy(
            patterns: userPatterns,
            reflection: reflection
        )

        // Generate adapted blocks
        let nextWeekStart = calendar.date(byAdding: .day, value: 1, to: reflection.weekEndDate) ?? Date()
        let adaptedBlocks = generateAdaptedBlocks(
            strategy: strategy,
            goal: goal,
            startDate: nextWeekStart,
            weekNumber: reflection.weekNumber + 1
        )

        return AIAdaptationResponse(
            updatedBlocks: adaptedBlocks,
            summary: strategy.summary,
            adjustmentType: strategy.adjustmentType
        )
    }

    func suggestReschedule(
        for block: PlanBlock,
        availableSlots: [DateInterval]
    ) async throws -> Date? {
        return scheduleOptimizer.findOptimalRescheduleSlot(
            for: block,
            availableSlots: availableSlots
        )
    }

    // MARK: - Milestone Generation

    private func generateIntelligentMilestones(
        parsedGoal: ParsedGoalAnalysis,
        domainPlan: DomainPlan,
        totalWeeks: Int
    ) -> [Milestone.MilestoneData] {
        var milestones: [Milestone.MilestoneData] = []

        // Create milestones based on domain knowledge
        let domainMilestones = domainPlan.keyMilestones
        let milestoneCount = min(domainMilestones.count, max(4, totalWeeks / 3))

        for i in 0..<milestoneCount {
            let weekNumber = ((i + 1) * totalWeeks) / (milestoneCount + 1)
            let milestone = domainMilestones[i % domainMilestones.count]

            milestones.append(Milestone.MilestoneData(
                title: milestone.title,
                description: milestone.description,
                weekNumber: max(1, weekNumber)
            ))
        }

        return milestones
    }

    // MARK: - Theme Generation

    private func generateProgressiveThemes(
        parsedGoal: ParsedGoalAnalysis,
        domainPlan: DomainPlan,
        totalWeeks: Int
    ) -> [WeeklyTheme.WeeklyThemeData] {
        var themes: [WeeklyTheme.WeeklyThemeData] = []
        let domainThemes = domainPlan.weeklyThemes

        for week in 1...totalWeeks {
            // Progressive difficulty curve
            let progressRatio = Double(week) / Double(totalWeeks)
            let phaseIndex = min(Int(progressRatio * Double(domainThemes.count)), domainThemes.count - 1)
            let theme = domainThemes[phaseIndex]

            themes.append(WeeklyTheme.WeeklyThemeData(
                weekNumber: week,
                title: theme.title,
                focus: theme.focus
            ))
        }

        return themes
    }

    // MARK: - Adaptive Block Generation

    private func generateAdaptedBlocks(
        strategy: AdaptationStrategy,
        goal: IdentityGoal,
        startDate: Date,
        weekNumber: Int
    ) -> [PlanBlock.PlanBlockData] {
        let parsedGoal = nlpParser.parseGoal(goal)
        let domainPlan = domainIntelligence.generateDomainPlan(for: parsedGoal)

        // Apply strategy modifications
        var modifiedBlockCount = domainPlan.baseBlocksPerWeek
        var durationMultiplier: Double = 1.0

        switch strategy.adjustmentType {
        case .lighter:
            modifiedBlockCount = max(3, modifiedBlockCount - 2)
            durationMultiplier = 0.8
        case .increased:
            modifiedBlockCount = min(14, modifiedBlockCount + 2)
            durationMultiplier = 1.15
        case .restructured:
            // Keep same volume but change distribution
            durationMultiplier = 1.0
        case .maintained:
            break
        }

        // Feature 1: Apply soft recovery mode adjustments
        // This happens invisibly - user never knows they're in "recovery"
        let momentum = DataService.shared.getMomentumState()
        modifiedBlockCount = AIService.shared.adjustBlockCount(baseCount: modifiedBlockCount, momentum: momentum)

        // Adjust duration if in recovery
        if momentum.loadFactor < 1.0 {
            durationMultiplier *= momentum.loadFactor
        }

        return scheduleOptimizer.generateWeekBlocks(
            domainPlan: domainPlan,
            weekStart: startDate,
            blockCount: modifiedBlockCount,
            weekNumber: weekNumber,
            durationMultiplier: durationMultiplier,
            energyPattern: strategy.preferredEnergyPattern
        )
    }
}

// MARK: - NLP Goal Parser

/// Advanced natural language processing for goal understanding
final class GoalNLPParser {

    // Domain keyword dictionaries
    private let domainKeywords: [GoalDomain: Set<String>] = [
        .finance: Set(["investment banking", "finance", "trading", "analyst", "banking", "wall street", "private equity", "hedge fund", "m&a", "ib", "valuation", "financial modeling", "dcf", "lbo"]),
        .technology: Set(["software", "developer", "programming", "coding", "engineer", "tech", "computer science", "app", "web", "mobile", "ai", "machine learning", "data science", "startup"]),
        .academia: Set(["study", "student", "exam", "degree", "university", "college", "gpa", "research", "thesis", "graduate", "phd", "masters", "professor", "academic"]),
        .fitness: Set(["fitness", "workout", "gym", "muscle", "training", "exercise", "run", "marathon", "athletic", "sport", "strength", "lift", "crossfit", "hiit"]),
        .business: Set(["entrepreneur", "business", "startup", "founder", "company", "revenue", "sales", "marketing", "growth", "customers", "product", "market", "launch"]),
        .creative: Set(["art", "music", "writing", "design", "creative", "portfolio", "artist", "musician", "writer", "content", "youtube", "social media", "brand"]),
        .language: Set(["language", "spanish", "french", "chinese", "japanese", "fluent", "speak", "learn language", "bilingual", "conversation"]),
        .career: Set(["job", "career", "internship", "interview", "resume", "networking", "promotion", "salary", "offer", "hire", "recruit", "linkedin"]),
        .income: Set(["make money", "earn", "income", "side hustle", "freelance", "passive income", "$", "dollar", "thousand", "profit", "monetize", "gig", "extra income", "financial goal", "savings goal", "10000", "5000", "1000", "rich", "wealth"]),
        .weightLoss: Set(["lose weight", "weight loss", "fat loss", "slim", "diet", "calories", "pounds", "kg", "bmi", "lean", "cut", "shred", "body fat", "obesity", "overweight", "belly fat", "waist"]),
        .health: Set(["health", "healthy", "wellness", "longevity", "nutrition", "sleep", "energy", "vitality", "immune", "doctor", "medical", "lifestyle", "wellbeing", "recovery", "heal"]),
        .productivity: Set(["productivity", "productive", "time management", "efficiency", "organize", "focus", "discipline", "routine", "habit", "procrastination", "morning routine", "schedule", "optimize"]),
        .relationship: Set(["relationship", "dating", "social", "friends", "communication", "confidence", "charisma", "networking", "connection", "people skills", "public speaking"]),
        .mindfulness: Set(["meditation", "mindfulness", "mental health", "anxiety", "stress", "calm", "peace", "therapy", "self-care", "journal", "gratitude", "awareness", "breathing", "yoga"])
    ]

    // Intensity signal words
    private let intensitySignals: [Intensity: Set<String>] = [
        .aggressive: Set(["aggressive", "intense", "hardcore", "serious", "committed", "all-in", "maximum", "fast-track", "accelerate", "ambitious"]),
        .balanced: Set(["balanced", "steady", "sustainable", "consistent", "moderate", "reasonable"]),
        .light: Set(["gentle", "light", "easy", "relaxed", "flexible", "casual", "minimal"])
    ]

    // Timeline extraction patterns
    private let timelinePatterns: [(pattern: String, weeks: Int)] = [
        ("4 year", 208), ("four year", 208), ("3 year", 156), ("three year", 156),
        ("2 year", 104), ("two year", 104), ("1 year", 52), ("one year", 52),
        ("12 month", 52), ("6 month", 26), ("six month", 26), ("3 month", 13),
        ("three month", 13), ("1 month", 4), ("one month", 4), ("semester", 16),
        ("quarter", 13), ("summer", 12), ("week", 1)
    ]

    func parseGoal(_ goal: IdentityGoal) -> ParsedGoalAnalysis {
        let text = (goal.customIdentityName ?? goal.identityType.displayName).lowercased()

        // Detect domain
        let domain = detectDomain(from: text)

        // Extract specific targets
        let targets = extractTargets(from: text)

        // Detect intensity from text
        let detectedIntensity = detectIntensity(from: text) ?? goal.intensity

        // Parse constraints
        let constraints = parseConstraints(from: text)

        // Detect timeline if mentioned
        let detectedWeeks = detectTimeline(from: text)

        // Calculate urgency score (0-1)
        let urgency = calculateUrgency(
            timeHorizon: goal.timeHorizon,
            intensity: detectedIntensity,
            targets: targets
        )

        return ParsedGoalAnalysis(
            originalGoal: goal,
            domain: domain,
            subDomains: detectSubDomains(from: text, primaryDomain: domain),
            targets: targets,
            constraints: constraints,
            detectedIntensity: detectedIntensity,
            detectedTimelineWeeks: detectedWeeks,
            urgencyScore: urgency,
            keywords: extractKeywords(from: text)
        )
    }

    private func detectDomain(from text: String) -> GoalDomain {
        var bestMatch: GoalDomain = .general
        var highestScore = 0

        for (domain, keywords) in domainKeywords {
            let score = keywords.filter { text.contains($0) }.count
            if score > highestScore {
                highestScore = score
                bestMatch = domain
            }
        }

        return bestMatch
    }

    private func detectSubDomains(from text: String, primaryDomain: GoalDomain) -> [GoalDomain] {
        var subDomains: [GoalDomain] = []

        for (domain, keywords) in domainKeywords where domain != primaryDomain {
            let score = keywords.filter { text.contains($0) }.count
            if score > 0 {
                subDomains.append(domain)
            }
        }

        return subDomains
    }

    private func detectIntensity(from text: String) -> Intensity? {
        for (intensity, signals) in intensitySignals {
            if signals.contains(where: { text.contains($0) }) {
                return intensity
            }
        }
        return nil
    }

    private func detectTimeline(from text: String) -> Int? {
        for (pattern, weeks) in timelinePatterns {
            if text.contains(pattern) {
                return weeks
            }
        }
        return nil
    }

    private func extractTargets(from text: String) -> [GoalTarget] {
        var targets: [GoalTarget] = []

        // Extract numeric targets
        let numberPattern = #"(\d+)\s+(internship|job|offer|interview|project|client|pound|kg|mile|hour)"#
        if let regex = try? NSRegularExpression(pattern: numberPattern, options: .caseInsensitive) {
            let range = NSRange(text.startIndex..., in: text)
            let matches = regex.matches(in: text, options: [], range: range)

            for match in matches {
                if let numRange = Range(match.range(at: 1), in: text),
                   let typeRange = Range(match.range(at: 2), in: text),
                   let number = Int(text[numRange]) {
                    targets.append(GoalTarget(
                        type: String(text[typeRange]),
                        quantity: number,
                        timeframe: nil
                    ))
                }
            }
        }

        // Add qualitative targets
        if text.contains("secure") || text.contains("land") || text.contains("get") {
            if text.contains("internship") {
                targets.append(GoalTarget(type: "internship", quantity: 1, timeframe: nil))
            }
            if text.contains("job") || text.contains("offer") {
                targets.append(GoalTarget(type: "job_offer", quantity: 1, timeframe: nil))
            }
        }

        return targets
    }

    private func parseConstraints(from text: String) -> [PlanConstraint] {
        var constraints: [PlanConstraint] = []

        if text.contains("busy") || text.contains("limited time") {
            constraints.append(.limitedTime)
        }
        if text.contains("beginner") || text.contains("starting from scratch") || text.contains("new to") {
            constraints.append(.beginner)
        }
        if text.contains("working") || text.contains("full-time job") {
            constraints.append(.hasFullTimeJob)
        }
        if text.contains("student") || text.contains("classes") {
            constraints.append(.isStudent)
        }

        return constraints
    }

    private func calculateUrgency(
        timeHorizon: TimeHorizon,
        intensity: Intensity,
        targets: [GoalTarget]
    ) -> Double {
        var urgency = 0.5

        // Shorter timeline = more urgent
        switch timeHorizon {
        case .oneMonth: urgency += 0.3
        case .threeMonths: urgency += 0.2
        case .sixMonths: urgency += 0.1
        case .oneYear: break
        }

        // Higher intensity = more urgent
        switch intensity {
        case .aggressive: urgency += 0.2
        case .balanced: break
        case .light: urgency -= 0.1
        }

        // More targets = more urgent
        if targets.count > 2 { urgency += 0.1 }

        return min(1.0, max(0.0, urgency))
    }

    private func extractKeywords(from text: String) -> [String] {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { $0.count > 3 }
            .filter { !["want", "need", "will", "would", "could", "should", "have", "that", "this", "with", "from", "they", "been", "were", "being"].contains($0) }
        return Array(Set(words))
    }
}

// MARK: - Domain Intelligence

/// Provides domain-specific knowledge and planning strategies
final class DomainIntelligence {

    func generateDomainPlan(for parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        switch parsedGoal.domain {
        case .finance:
            return generateFinancePlan(parsedGoal)
        case .technology:
            return generateTechPlan(parsedGoal)
        case .academia:
            return generateAcademiaPlan(parsedGoal)
        case .fitness:
            return generateFitnessPlan(parsedGoal)
        case .business:
            return generateBusinessPlan(parsedGoal)
        case .creative:
            return generateCreativePlan(parsedGoal)
        case .language:
            return generateLanguagePlan(parsedGoal)
        case .career:
            return generateCareerPlan(parsedGoal)
        case .income:
            return generateIncomePlan(parsedGoal)
        case .weightLoss:
            return generateWeightLossPlan(parsedGoal)
        case .health:
            return generateHealthPlan(parsedGoal)
        case .productivity:
            return generateProductivityPlan(parsedGoal)
        case .relationship:
            return generateRelationshipPlan(parsedGoal)
        case .mindfulness:
            return generateMindfulnessPlan(parsedGoal)
        case .general:
            return generateGeneralPlan(parsedGoal)
        }
    }

    // MARK: - Finance/Banking Plan

    private func generateFinancePlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            // Technical Skills
            DomainActivity(
                title: "Financial Modeling",
                intent: "Build Excel/modeling proficiency",
                blockType: .focus,
                duration: 60,
                frequency: .timesPerWeek(3),
                phase: .early,
                skillCategory: "Technical"
            ),
            DomainActivity(
                title: "Valuation Practice",
                intent: "Master DCF, comps, and precedents",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(2),
                phase: .middle,
                skillCategory: "Technical"
            ),
            DomainActivity(
                title: "Accounting Review",
                intent: "Strengthen financial statement analysis",
                blockType: .focus,
                duration: 40,
                frequency: .timesPerWeek(2),
                phase: .early,
                skillCategory: "Technical"
            ),

            // Behavioral Prep
            DomainActivity(
                title: "Behavioral Prep",
                intent: "Craft and refine your story",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(2),
                phase: .middle,
                skillCategory: "Interview"
            ),
            DomainActivity(
                title: "Mock Interviews",
                intent: "Practice with pressure",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(1),
                phase: .late,
                skillCategory: "Interview"
            ),

            // Networking
            DomainActivity(
                title: "Networking Outreach",
                intent: "Connect with professionals",
                blockType: .habit,
                duration: 25,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Networking"
            ),
            DomainActivity(
                title: "Coffee Chat Prep",
                intent: "Research contacts and prepare questions",
                blockType: .light,
                duration: 20,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Networking"
            ),

            // Industry Knowledge
            DomainActivity(
                title: "Market News Review",
                intent: "Stay current on deals and markets",
                blockType: .habit,
                duration: 15,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Knowledge"
            ),
            DomainActivity(
                title: "Deal Analysis",
                intent: "Study recent M&A transactions",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(1),
                phase: .middle,
                skillCategory: "Knowledge"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Technical Foundation", description: "Core modeling skills in place", weekRatio: 0.15),
            DomainMilestone(title: "Network Building", description: "10+ meaningful connections", weekRatio: 0.3),
            DomainMilestone(title: "Interview Ready", description: "Story polished, technicals solid", weekRatio: 0.6),
            DomainMilestone(title: "Application Sprint", description: "Active recruiting cycle", weekRatio: 0.8),
            DomainMilestone(title: "Offer Secured", description: "Goal achieved", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Foundation Building", focus: "Core skills and knowledge", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Technical Deep Dive", focus: "Modeling and valuation mastery", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Network Expansion", focus: "Building relationships", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Interview Prep", focus: "Story and technicals", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Execution Mode", focus: "Active recruiting", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .morningHeavy,
            restDays: [.sunday],
            specialConsiderations: ["Recruiting cycles are seasonal", "Networking is critical"]
        )
    }

    // MARK: - Technology Plan

    private func generateTechPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Coding Practice",
                intent: "Solve algorithmic problems",
                blockType: .focus,
                duration: 60,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Technical"
            ),
            DomainActivity(
                title: "Project Work",
                intent: "Build portfolio projects",
                blockType: .focus,
                duration: 90,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Portfolio"
            ),
            DomainActivity(
                title: "System Design Study",
                intent: "Learn architecture patterns",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(2),
                phase: .middle,
                skillCategory: "Technical"
            ),
            DomainActivity(
                title: "Technical Reading",
                intent: "Stay current with tech trends",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Knowledge"
            ),
            DomainActivity(
                title: "Open Source Contribution",
                intent: "Build real-world experience",
                blockType: .habit,
                duration: 45,
                frequency: .timesPerWeek(1),
                phase: .middle,
                skillCategory: "Portfolio"
            ),
            DomainActivity(
                title: "Mock Technical Interview",
                intent: "Practice coding under pressure",
                blockType: .focus,
                duration: 60,
                frequency: .timesPerWeek(1),
                phase: .late,
                skillCategory: "Interview"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Fundamentals Solid", description: "Core concepts mastered", weekRatio: 0.2),
            DomainMilestone(title: "First Project Complete", description: "Portfolio started", weekRatio: 0.35),
            DomainMilestone(title: "Algorithm Proficiency", description: "Consistent problem solving", weekRatio: 0.5),
            DomainMilestone(title: "System Design Ready", description: "Can discuss architecture", weekRatio: 0.7),
            DomainMilestone(title: "Interview Ready", description: "Full preparation complete", weekRatio: 0.9)
        ]

        let themes = [
            DomainTheme(title: "Foundation", focus: "Core programming skills", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Building", focus: "Project development", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Deepening", focus: "Advanced concepts", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Polishing", focus: "Portfolio and prep", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Executing", focus: "Interview mode", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .flexible,
            restDays: [.sunday],
            specialConsiderations: ["Consistent daily practice is key", "Build in public"]
        )
    }

    // MARK: - Academia Plan

    private func generateAcademiaPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Deep Study Session",
                intent: "Focused learning on core material",
                blockType: .focus,
                duration: 50,
                frequency: .timesPerWeek(5),
                phase: .ongoing,
                skillCategory: "Learning"
            ),
            DomainActivity(
                title: "Active Recall Practice",
                intent: "Test yourself on material",
                blockType: .focus,
                duration: 30,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Retention"
            ),
            DomainActivity(
                title: "Spaced Repetition Review",
                intent: "Review with optimal spacing",
                blockType: .light,
                duration: 20,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Retention"
            ),
            DomainActivity(
                title: "Problem Set Work",
                intent: "Apply concepts to problems",
                blockType: .focus,
                duration: 60,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Application"
            ),
            DomainActivity(
                title: "Reading Assignment",
                intent: "Complete required readings",
                blockType: .light,
                duration: 45,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Learning"
            ),
            DomainActivity(
                title: "Study Group",
                intent: "Collaborative learning",
                blockType: .habit,
                duration: 60,
                frequency: .timesPerWeek(1),
                phase: .ongoing,
                skillCategory: "Social Learning"
            )
        ]

        let milestones = [
            DomainMilestone(title: "System Established", description: "Study routine in place", weekRatio: 0.1),
            DomainMilestone(title: "Midterm Ready", description: "First major assessment", weekRatio: 0.4),
            DomainMilestone(title: "Deep Understanding", description: "Concepts click", weekRatio: 0.6),
            DomainMilestone(title: "Final Prep", description: "Comprehensive review", weekRatio: 0.85),
            DomainMilestone(title: "Academic Success", description: "Goals achieved", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Setup", focus: "Build study systems", phaseRatio: 0.0...0.15),
            DomainTheme(title: "Absorption", focus: "Intake new material", phaseRatio: 0.15...0.4),
            DomainTheme(title: "Integration", focus: "Connect concepts", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Application", focus: "Practice problems", phaseRatio: 0.6...0.85),
            DomainTheme(title: "Mastery", focus: "Final preparation", phaseRatio: 0.85...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .morningHeavy,
            restDays: [.saturday],
            specialConsiderations: ["Use spaced repetition", "Active recall beats passive review"]
        )
    }

    // MARK: - Fitness Plan

    private func generateFitnessPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Strength Training",
                intent: "Progressive overload workout",
                blockType: .focus,
                duration: 60,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Training"
            ),
            DomainActivity(
                title: "Cardio Session",
                intent: "Cardiovascular conditioning",
                blockType: .focus,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Training"
            ),
            DomainActivity(
                title: "Mobility Work",
                intent: "Flexibility and recovery",
                blockType: .light,
                duration: 20,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Recovery"
            ),
            DomainActivity(
                title: "Meal Prep",
                intent: "Prepare healthy meals",
                blockType: .habit,
                duration: 45,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Nutrition"
            ),
            DomainActivity(
                title: "Progress Check",
                intent: "Track measurements and progress",
                blockType: .habit,
                duration: 15,
                frequency: .timesPerWeek(1),
                phase: .ongoing,
                skillCategory: "Tracking"
            ),
            DomainActivity(
                title: "Active Recovery",
                intent: "Light movement and stretching",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Recovery"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Habit Formed", description: "Consistent routine established", weekRatio: 0.15),
            DomainMilestone(title: "First Results", description: "Visible progress", weekRatio: 0.3),
            DomainMilestone(title: "Strength Gains", description: "Measurable improvements", weekRatio: 0.5),
            DomainMilestone(title: "Lifestyle Shift", description: "New normal", weekRatio: 0.75),
            DomainMilestone(title: "Transformation", description: "Goal achieved", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Foundation", focus: "Build the habit", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Building", focus: "Progressive overload", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Pushing", focus: "Increase intensity", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Refining", focus: "Optimize routine", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Maintaining", focus: "Sustain results", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .flexible,
            restDays: [.sunday],
            specialConsiderations: ["Rest is part of training", "Progressive overload is key"]
        )
    }

    // MARK: - Business/Entrepreneur Plan

    private func generateBusinessPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Product Development",
                intent: "Build your core offering",
                blockType: .focus,
                duration: 90,
                frequency: .timesPerWeek(4),
                phase: .early,
                skillCategory: "Product"
            ),
            DomainActivity(
                title: "Customer Discovery",
                intent: "Talk to potential customers",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(3),
                phase: .early,
                skillCategory: "Market"
            ),
            DomainActivity(
                title: "Market Research",
                intent: "Understand your space",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Market"
            ),
            DomainActivity(
                title: "Sales Outreach",
                intent: "Find and close customers",
                blockType: .focus,
                duration: 60,
                frequency: .daily,
                phase: .middle,
                skillCategory: "Sales"
            ),
            DomainActivity(
                title: "Content Creation",
                intent: "Build your brand",
                blockType: .habit,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Marketing"
            ),
            DomainActivity(
                title: "Networking",
                intent: "Build relationships",
                blockType: .habit,
                duration: 30,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Relationships"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Problem Validated", description: "Clear customer pain point", weekRatio: 0.15),
            DomainMilestone(title: "MVP Ready", description: "First version complete", weekRatio: 0.35),
            DomainMilestone(title: "First Customers", description: "People paying", weekRatio: 0.5),
            DomainMilestone(title: "Product-Market Fit", description: "Strong retention", weekRatio: 0.75),
            DomainMilestone(title: "Growth Mode", description: "Scaling up", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Discovery", focus: "Find the problem", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Building", focus: "Create the solution", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Launching", focus: "Get to market", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Iterating", focus: "Improve based on feedback", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Scaling", focus: "Grow what works", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .flexible,
            restDays: [],
            specialConsiderations: ["Talk to customers early and often", "Ship fast, iterate faster"]
        )
    }

    // MARK: - Creative Plan

    private func generateCreativePlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Creative Practice",
                intent: "Dedicated creation time",
                blockType: .focus,
                duration: 60,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Core"
            ),
            DomainActivity(
                title: "Skill Study",
                intent: "Learn new techniques",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Learning"
            ),
            DomainActivity(
                title: "Portfolio Work",
                intent: "Build showcase pieces",
                blockType: .focus,
                duration: 90,
                frequency: .timesPerWeek(2),
                phase: .middle,
                skillCategory: "Portfolio"
            ),
            DomainActivity(
                title: "Inspiration Gathering",
                intent: "Study great work",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Learning"
            ),
            DomainActivity(
                title: "Share Work",
                intent: "Post and get feedback",
                blockType: .habit,
                duration: 20,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Marketing"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Daily Practice", description: "Consistent habit formed", weekRatio: 0.15),
            DomainMilestone(title: "Skill Jump", description: "Noticeable improvement", weekRatio: 0.35),
            DomainMilestone(title: "Portfolio Pieces", description: "Work to show", weekRatio: 0.55),
            DomainMilestone(title: "Recognition", description: "External validation", weekRatio: 0.75),
            DomainMilestone(title: "Professional Level", description: "Goal achieved", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Beginning", focus: "Start creating daily", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Learning", focus: "Study the craft", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Creating", focus: "Make more work", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Refining", focus: "Develop your style", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Sharing", focus: "Build an audience", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .flexible,
            restDays: [.sunday],
            specialConsiderations: ["Show up daily", "Share work regularly"]
        )
    }

    // MARK: - Language Plan

    private func generateLanguagePlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Active Study",
                intent: "Learn new vocabulary and grammar",
                blockType: .focus,
                duration: 30,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Learning"
            ),
            DomainActivity(
                title: "Listening Practice",
                intent: "Immersive listening",
                blockType: .light,
                duration: 25,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Comprehension"
            ),
            DomainActivity(
                title: "Speaking Practice",
                intent: "Conversation practice",
                blockType: .focus,
                duration: 30,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Speaking"
            ),
            DomainActivity(
                title: "Flashcard Review",
                intent: "Spaced repetition vocab",
                blockType: .habit,
                duration: 15,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Retention"
            ),
            DomainActivity(
                title: "Native Content",
                intent: "Watch/read native material",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .middle,
                skillCategory: "Immersion"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Basic Foundation", description: "Core vocabulary and grammar", weekRatio: 0.15),
            DomainMilestone(title: "Simple Conversations", description: "Basic exchanges", weekRatio: 0.35),
            DomainMilestone(title: "Intermediate Level", description: "Express opinions", weekRatio: 0.55),
            DomainMilestone(title: "Fluent Discussions", description: "Complex topics", weekRatio: 0.8),
            DomainMilestone(title: "Fluency", description: "Goal achieved", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Foundation", focus: "Basic building blocks", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Expansion", focus: "Growing vocabulary", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Conversation", focus: "Speaking practice", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Immersion", focus: "Native content", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Fluency", focus: "Natural usage", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .morningHeavy,
            restDays: [],
            specialConsiderations: ["Daily practice is essential", "Speak from day one"]
        )
    }

    // MARK: - Career Plan

    private func generateCareerPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Skill Development",
                intent: "Build relevant skills",
                blockType: .focus,
                duration: 60,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Skills"
            ),
            DomainActivity(
                title: "Networking",
                intent: "Build professional relationships",
                blockType: .habit,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Network"
            ),
            DomainActivity(
                title: "Application Work",
                intent: "Customize applications",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(3),
                phase: .middle,
                skillCategory: "Applications"
            ),
            DomainActivity(
                title: "Interview Prep",
                intent: "Practice interviews",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(2),
                phase: .late,
                skillCategory: "Interview"
            ),
            DomainActivity(
                title: "Industry Research",
                intent: "Understand the market",
                blockType: .light,
                duration: 25,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Knowledge"
            ),
            DomainActivity(
                title: "Personal Brand",
                intent: "Build online presence",
                blockType: .habit,
                duration: 20,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Branding"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Resume Ready", description: "Polished materials", weekRatio: 0.15),
            DomainMilestone(title: "Network Growing", description: "Key connections made", weekRatio: 0.3),
            DomainMilestone(title: "Applications Sent", description: "Active pipeline", weekRatio: 0.5),
            DomainMilestone(title: "Interviews Scheduled", description: "In the process", weekRatio: 0.7),
            DomainMilestone(title: "Offer Received", description: "Goal achieved", weekRatio: 0.9)
        ]

        let themes = [
            DomainTheme(title: "Preparation", focus: "Materials and skills", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Outreach", focus: "Building network", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Application", focus: "Active job search", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Interview", focus: "Preparation and practice", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Closing", focus: "Negotiation and decision", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .morningHeavy,
            restDays: [.sunday],
            specialConsiderations: ["Networking is #1", "Customize every application"]
        )
    }

    // MARK: - General Plan

    private func generateGeneralPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Deep Focus Block",
                intent: "Concentrated work on your goal",
                blockType: .focus,
                duration: 60,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Core"
            ),
            DomainActivity(
                title: "Skill Building",
                intent: "Develop key abilities",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Skills"
            ),
            DomainActivity(
                title: "Learning Session",
                intent: "Expand knowledge",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Learning"
            ),
            DomainActivity(
                title: "Practice",
                intent: "Apply what you learned",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Application"
            ),
            DomainActivity(
                title: "Daily Habit",
                intent: "Build consistency",
                blockType: .habit,
                duration: 20,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Consistency"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Started", description: "Foundation in place", weekRatio: 0.15),
            DomainMilestone(title: "Momentum", description: "Consistent progress", weekRatio: 0.35),
            DomainMilestone(title: "Progress", description: "Visible improvement", weekRatio: 0.55),
            DomainMilestone(title: "Advancement", description: "Significant gains", weekRatio: 0.75),
            DomainMilestone(title: "Achievement", description: "Goal reached", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Beginning", focus: "Start your journey", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Building", focus: "Develop habits", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Growing", focus: "Expand capabilities", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Advancing", focus: "Push further", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Achieving", focus: "Reach your goal", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .flexible,
            restDays: [.sunday],
            specialConsiderations: ["Consistency beats intensity", "Track your progress"]
        )
    }

    // MARK: - Income/Money Making Plan

    private func generateIncomePlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Income Strategy Session",
                intent: "Plan and review income streams",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(2),
                phase: .early,
                skillCategory: "Strategy"
            ),
            DomainActivity(
                title: "Skill Building",
                intent: "Develop marketable skills",
                blockType: .focus,
                duration: 60,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Skills"
            ),
            DomainActivity(
                title: "Client Outreach",
                intent: "Find and connect with potential clients",
                blockType: .focus,
                duration: 45,
                frequency: .daily,
                phase: .middle,
                skillCategory: "Sales"
            ),
            DomainActivity(
                title: "Financial Tracking",
                intent: "Track income, expenses, progress",
                blockType: .habit,
                duration: 15,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Finance"
            ),
            DomainActivity(
                title: "Project Work",
                intent: "Execute income-generating work",
                blockType: .focus,
                duration: 90,
                frequency: .timesPerWeek(5),
                phase: .ongoing,
                skillCategory: "Execution"
            ),
            DomainActivity(
                title: "Market Research",
                intent: "Find opportunities and trends",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Research"
            ),
            DomainActivity(
                title: "Network Building",
                intent: "Connect with potential partners",
                blockType: .habit,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Networking"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Strategy Clear", description: "Income plan defined", weekRatio: 0.1),
            DomainMilestone(title: "First Revenue", description: "Initial income generated", weekRatio: 0.25),
            DomainMilestone(title: "Momentum Building", description: "Consistent income flow", weekRatio: 0.5),
            DomainMilestone(title: "Scaling Up", description: "Growing income streams", weekRatio: 0.75),
            DomainMilestone(title: "Goal Achieved", description: "Target income reached", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Foundation", focus: "Strategy and skills", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Activation", focus: "Start earning", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Optimization", focus: "Improve efficiency", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Scaling", focus: "Grow income", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Sustaining", focus: "Maintain momentum", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .flexible,
            restDays: [.sunday],
            specialConsiderations: ["Focus on high-value activities", "Track every dollar", "Iterate quickly"]
        )
    }

    // MARK: - Weight Loss Plan

    private func generateWeightLossPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Workout Session",
                intent: "Burn calories and build muscle",
                blockType: .focus,
                duration: 45,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Exercise"
            ),
            DomainActivity(
                title: "Cardio Training",
                intent: "Cardiovascular exercise for fat loss",
                blockType: .focus,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Exercise"
            ),
            DomainActivity(
                title: "Meal Prep",
                intent: "Prepare healthy meals for the week",
                blockType: .habit,
                duration: 60,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Nutrition"
            ),
            DomainActivity(
                title: "Food Logging",
                intent: "Track calories and macros",
                blockType: .habit,
                duration: 10,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Tracking"
            ),
            DomainActivity(
                title: "Weigh-In & Measurements",
                intent: "Track body composition progress",
                blockType: .habit,
                duration: 10,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Tracking"
            ),
            DomainActivity(
                title: "Walk/Light Activity",
                intent: "Increase daily movement",
                blockType: .light,
                duration: 30,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Movement"
            ),
            DomainActivity(
                title: "Nutrition Education",
                intent: "Learn about healthy eating",
                blockType: .light,
                duration: 20,
                frequency: .timesPerWeek(2),
                phase: .early,
                skillCategory: "Knowledge"
            ),
            DomainActivity(
                title: "Recovery & Sleep",
                intent: "Prioritize rest for results",
                blockType: .habit,
                duration: 15,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Recovery"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Habits Established", description: "Routine in place", weekRatio: 0.15),
            DomainMilestone(title: "First Results", description: "Scale moving in right direction", weekRatio: 0.3),
            DomainMilestone(title: "Halfway Point", description: "Significant progress visible", weekRatio: 0.5),
            DomainMilestone(title: "Lifestyle Change", description: "New habits feel natural", weekRatio: 0.75),
            DomainMilestone(title: "Goal Weight", description: "Target achieved", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Getting Started", focus: "Build foundation habits", phaseRatio: 0.0...0.15),
            DomainTheme(title: "Building Momentum", focus: "Consistency is key", phaseRatio: 0.15...0.35),
            DomainTheme(title: "Pushing Through", focus: "Break through plateaus", phaseRatio: 0.35...0.55),
            DomainTheme(title: "Accelerating", focus: "Optimize your approach", phaseRatio: 0.55...0.8),
            DomainTheme(title: "Finishing Strong", focus: "Reach your goal", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .morningHeavy,
            restDays: [.sunday],
            specialConsiderations: ["Calories matter most", "Rest is essential", "Consistency beats perfection"]
        )
    }

    // MARK: - Health/Wellness Plan

    private func generateHealthPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Movement Practice",
                intent: "Daily physical activity",
                blockType: .focus,
                duration: 30,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Movement"
            ),
            DomainActivity(
                title: "Healthy Cooking",
                intent: "Prepare nutritious meals",
                blockType: .habit,
                duration: 45,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Nutrition"
            ),
            DomainActivity(
                title: "Sleep Optimization",
                intent: "Wind-down routine for better sleep",
                blockType: .habit,
                duration: 30,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Sleep"
            ),
            DomainActivity(
                title: "Hydration Check",
                intent: "Track and maintain water intake",
                blockType: .habit,
                duration: 5,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Hydration"
            ),
            DomainActivity(
                title: "Stress Management",
                intent: "Practice relaxation techniques",
                blockType: .light,
                duration: 20,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Mental Health"
            ),
            DomainActivity(
                title: "Health Education",
                intent: "Learn about wellness practices",
                blockType: .light,
                duration: 20,
                frequency: .timesPerWeek(2),
                phase: .early,
                skillCategory: "Knowledge"
            ),
            DomainActivity(
                title: "Outdoor Time",
                intent: "Fresh air and nature exposure",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(4),
                phase: .ongoing,
                skillCategory: "Wellbeing"
            ),
            DomainActivity(
                title: "Health Tracking",
                intent: "Monitor vitals and progress",
                blockType: .habit,
                duration: 10,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Tracking"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Foundation Set", description: "Basic habits in place", weekRatio: 0.15),
            DomainMilestone(title: "Energy Improving", description: "Feeling more vital", weekRatio: 0.3),
            DomainMilestone(title: "Routine Solid", description: "Habits feel automatic", weekRatio: 0.5),
            DomainMilestone(title: "Health Transformed", description: "Major improvements noticed", weekRatio: 0.75),
            DomainMilestone(title: "Optimal Health", description: "Living your best life", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Awareness", focus: "Understand your baseline", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Building", focus: "Establish healthy habits", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Deepening", focus: "Refine your approach", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Optimizing", focus: "Fine-tune for results", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Thriving", focus: "Maintain excellence", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .morningHeavy,
            restDays: [],
            specialConsiderations: ["Small habits compound", "Sleep is foundational", "Listen to your body"]
        )
    }

    // MARK: - Productivity Plan

    private func generateProductivityPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Morning Planning",
                intent: "Set daily priorities",
                blockType: .habit,
                duration: 15,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Planning"
            ),
            DomainActivity(
                title: "Deep Work Block",
                intent: "Focused, distraction-free work",
                blockType: .focus,
                duration: 90,
                frequency: .timesPerWeek(5),
                phase: .ongoing,
                skillCategory: "Focus"
            ),
            DomainActivity(
                title: "Weekly Review",
                intent: "Assess progress and adjust",
                blockType: .review,
                duration: 45,
                frequency: .timesPerWeek(1),
                phase: .ongoing,
                skillCategory: "Reflection"
            ),
            DomainActivity(
                title: "Habit Stacking",
                intent: "Build productive routines",
                blockType: .habit,
                duration: 20,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Habits"
            ),
            DomainActivity(
                title: "Environment Optimization",
                intent: "Organize workspace for productivity",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(1),
                phase: .ongoing,
                skillCategory: "Environment"
            ),
            DomainActivity(
                title: "Productivity Learning",
                intent: "Study productivity techniques",
                blockType: .light,
                duration: 25,
                frequency: .timesPerWeek(2),
                phase: .early,
                skillCategory: "Knowledge"
            ),
            DomainActivity(
                title: "Energy Management",
                intent: "Match tasks to energy levels",
                blockType: .habit,
                duration: 10,
                frequency: .daily,
                phase: .middle,
                skillCategory: "Energy"
            )
        ]

        let milestones = [
            DomainMilestone(title: "System Designed", description: "Productivity system in place", weekRatio: 0.15),
            DomainMilestone(title: "Habits Forming", description: "Routines taking hold", weekRatio: 0.3),
            DomainMilestone(title: "Flow State", description: "Regular deep work achieved", weekRatio: 0.5),
            DomainMilestone(title: "High Performance", description: "Consistently productive", weekRatio: 0.75),
            DomainMilestone(title: "Mastery", description: "Peak productivity achieved", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Setup", focus: "Design your system", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Training", focus: "Build focus muscles", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Executing", focus: "Practice deep work", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Optimizing", focus: "Refine your approach", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Mastering", focus: "Sustainable high performance", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .morningHeavy,
            restDays: [.sunday],
            specialConsiderations: ["Start with your most important task", "Protect deep work time", "Rest enables productivity"]
        )
    }

    // MARK: - Relationship/Social Plan

    private func generateRelationshipPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Social Practice",
                intent: "Put yourself in social situations",
                blockType: .focus,
                duration: 60,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Social"
            ),
            DomainActivity(
                title: "Communication Skills",
                intent: "Study and practice conversation",
                blockType: .focus,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .early,
                skillCategory: "Skills"
            ),
            DomainActivity(
                title: "Reach Out",
                intent: "Contact friends and new connections",
                blockType: .habit,
                duration: 15,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Outreach"
            ),
            DomainActivity(
                title: "Self-Improvement",
                intent: "Work on confidence and presence",
                blockType: .light,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Self"
            ),
            DomainActivity(
                title: "Event Attendance",
                intent: "Attend social gatherings",
                blockType: .focus,
                duration: 120,
                frequency: .timesPerWeek(2),
                phase: .middle,
                skillCategory: "Social"
            ),
            DomainActivity(
                title: "Reflection Journal",
                intent: "Reflect on social interactions",
                blockType: .habit,
                duration: 15,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Reflection"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Comfort Building", description: "Less anxiety in social situations", weekRatio: 0.15),
            DomainMilestone(title: "Connections Made", description: "New relationships forming", weekRatio: 0.35),
            DomainMilestone(title: "Confidence Growing", description: "Natural in conversations", weekRatio: 0.55),
            DomainMilestone(title: "Network Expanding", description: "Strong social circle", weekRatio: 0.75),
            DomainMilestone(title: "Social Success", description: "Thriving relationships", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Foundation", focus: "Build confidence", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Practice", focus: "Get comfortable", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Connection", focus: "Deepen relationships", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Expansion", focus: "Grow your network", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Thriving", focus: "Enjoy social life", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .eveningHeavy,
            restDays: [],
            specialConsiderations: ["Quality over quantity", "Be genuinely curious", "Show up consistently"]
        )
    }

    // MARK: - Mindfulness/Mental Health Plan

    private func generateMindfulnessPlan(_ parsedGoal: ParsedGoalAnalysis) -> DomainPlan {
        let activities: [DomainActivity] = [
            DomainActivity(
                title: "Meditation",
                intent: "Daily mindfulness practice",
                blockType: .focus,
                duration: 20,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Meditation"
            ),
            DomainActivity(
                title: "Journaling",
                intent: "Process thoughts and emotions",
                blockType: .habit,
                duration: 15,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Reflection"
            ),
            DomainActivity(
                title: "Breathing Exercises",
                intent: "Calm the nervous system",
                blockType: .light,
                duration: 10,
                frequency: .timesPerWeek(5),
                phase: .ongoing,
                skillCategory: "Breathing"
            ),
            DomainActivity(
                title: "Gratitude Practice",
                intent: "Cultivate positive mindset",
                blockType: .habit,
                duration: 10,
                frequency: .daily,
                phase: .ongoing,
                skillCategory: "Gratitude"
            ),
            DomainActivity(
                title: "Mindful Movement",
                intent: "Yoga or gentle exercise",
                blockType: .focus,
                duration: 30,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Movement"
            ),
            DomainActivity(
                title: "Digital Detox",
                intent: "Unplug and be present",
                blockType: .light,
                duration: 60,
                frequency: .timesPerWeek(2),
                phase: .ongoing,
                skillCategory: "Presence"
            ),
            DomainActivity(
                title: "Self-Care Time",
                intent: "Activities that nurture you",
                blockType: .light,
                duration: 45,
                frequency: .timesPerWeek(3),
                phase: .ongoing,
                skillCategory: "Self-Care"
            ),
            DomainActivity(
                title: "Learning Session",
                intent: "Study mindfulness techniques",
                blockType: .light,
                duration: 25,
                frequency: .timesPerWeek(2),
                phase: .early,
                skillCategory: "Knowledge"
            )
        ]

        let milestones = [
            DomainMilestone(title: "Practice Started", description: "Daily habit established", weekRatio: 0.15),
            DomainMilestone(title: "Awareness Growing", description: "More present moments", weekRatio: 0.3),
            DomainMilestone(title: "Calm Increasing", description: "Stress levels dropping", weekRatio: 0.5),
            DomainMilestone(title: "Transformation", description: "New mental patterns", weekRatio: 0.75),
            DomainMilestone(title: "Inner Peace", description: "Sustainable calm achieved", weekRatio: 1.0)
        ]

        let themes = [
            DomainTheme(title: "Beginning", focus: "Start your practice", phaseRatio: 0.0...0.2),
            DomainTheme(title: "Developing", focus: "Build consistency", phaseRatio: 0.2...0.4),
            DomainTheme(title: "Deepening", focus: "Go deeper", phaseRatio: 0.4...0.6),
            DomainTheme(title: "Integrating", focus: "Apply to daily life", phaseRatio: 0.6...0.8),
            DomainTheme(title: "Embodying", focus: "Living mindfully", phaseRatio: 0.8...1.0)
        ]

        return DomainPlan(
            activities: activities,
            keyMilestones: milestones,
            weeklyThemes: themes,
            baseBlocksPerWeek: calculateBaseBlocks(parsedGoal),
            energyDistribution: .morningHeavy,
            restDays: [],
            specialConsiderations: ["Start small", "Consistency matters more than duration", "Be gentle with yourself"]
        )
    }

    // MARK: - Helper Methods

    private func calculateBaseBlocks(_ parsedGoal: ParsedGoalAnalysis) -> Int {
        let goal = parsedGoal.originalGoal

        var baseBlocks: Int
        switch goal.availability {
        case .busy: baseBlocks = 5
        case .normal: baseBlocks = 7
        case .open: baseBlocks = 10
        }

        // Adjust for intensity
        let intensityMultiplier: Double
        switch parsedGoal.detectedIntensity {
        case .light: intensityMultiplier = 0.7
        case .balanced: intensityMultiplier = 1.0
        case .aggressive: intensityMultiplier = 1.3
        }

        // Adjust for urgency
        let urgencyBonus = parsedGoal.urgencyScore > 0.7 ? 2 : 0

        return min(14, max(4, Int(Double(baseBlocks) * intensityMultiplier) + urgencyBonus))
    }
}

// MARK: - Schedule Optimizer

/// Optimizes block scheduling using evidence-based techniques
final class ScheduleOptimizer {

    private let calendar = Calendar.current
    private let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    func createOptimalSchedule(
        domainPlan: DomainPlan,
        parsedGoal: ParsedGoalAnalysis,
        goal: IdentityGoal
    ) -> [PlanBlock.PlanBlockData] {
        var allBlocks: [PlanBlock.PlanBlockData] = []

        let totalWeeks = goal.timeHorizon.weeks
        let daysToGenerate = min(21, totalWeeks * 7) // Generate first 3 weeks worth of days

        // CRITICAL: Start from TODAY, not from goal.createdAt or week start
        let today = calendar.startOfDay(for: Date())

        // Get activities for the current phase
        let activitiesPool = selectActivitiesForWeek(
            domainPlan: domainPlan,
            weekNumber: 1,
            totalActivitiesNeeded: domainPlan.baseBlocksPerWeek * 3
        )

        var activityIndex = 0
        var currentWeek = 1
        var blocksThisWeek = 0
        let maxBlocksPerDay = 3

        // Generate blocks for each day starting from today
        for dayOffset in 0..<daysToGenerate {
            guard let blockDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else {
                continue
            }

            // Check if it's a rest day (Sunday by default)
            let weekday = calendar.component(.weekday, from: blockDate)
            let dayOfWeek = DayOfWeek.from(weekday: weekday)
            if domainPlan.restDays.contains(dayOfWeek) {
                continue
            }

            // Calculate week number
            let daysFromStart = dayOffset
            let newWeek = (daysFromStart / 7) + 1
            if newWeek != currentWeek {
                currentWeek = newWeek
                blocksThisWeek = 0
            }

            // First week is lighter (onboarding)
            let isFirstWeek = currentWeek == 1
            let maxBlocksThisWeek = isFirstWeek
                ? Int(Double(domainPlan.baseBlocksPerWeek) * 0.7)
                : domainPlan.baseBlocksPerWeek

            if blocksThisWeek >= maxBlocksThisWeek {
                continue
            }

            // Determine how many blocks for this day
            let blocksForToday = min(maxBlocksPerDay, maxBlocksThisWeek - blocksThisWeek, max(1, (maxBlocksThisWeek / 5)))

            // Time slots for the day
            let timeSlots = generateTimeSlots(for: domainPlan.energyDistribution)

            for blockIndex in 0..<blocksForToday {
                guard activityIndex < activitiesPool.count else {
                    activityIndex = 0 // Cycle through activities
                }

                let activity = activitiesPool[activityIndex]
                activityIndex += 1

                // Get time slot
                let slotIndex = blockIndex % timeSlots.count
                let timeSlot = timeSlots[slotIndex]
                let (hour, minute) = getOptimalTime(for: activity.blockType, slot: timeSlot, energyPattern: domainPlan.energyDistribution)

                var components = calendar.dateComponents([.year, .month, .day], from: blockDate)
                components.hour = hour
                components.minute = minute

                guard let startTime = calendar.date(from: components) else { continue }

                // Calculate duration
                let durationMultiplier = isFirstWeek ? 0.8 : 1.0
                let duration = Int(Double(activity.duration) * durationMultiplier)
                let boundedDuration = max(15, min(120, duration))

                let endTime = startTime.addingTimeInterval(Double(boundedDuration * 60))

                allBlocks.append(PlanBlock.PlanBlockData(
                    startDateTime: isoFormatter.string(from: startTime),
                    endDateTime: isoFormatter.string(from: endTime),
                    title: activity.title,
                    blockType: activity.blockType.rawValue,
                    intentShort: activity.intent,
                    weekNumber: currentWeek
                ))

                blocksThisWeek += 1
            }
        }

        // Add weekly review blocks
        for week in 1...min(3, totalWeeks) {
            if let reviewDate = calendar.date(byAdding: .day, value: (week * 7) - 1, to: today) {
                var components = calendar.dateComponents([.year, .month, .day], from: reviewDate)
                components.hour = 19
                components.minute = 0

                if let reviewStart = calendar.date(from: components) {
                    let reviewEnd = reviewStart.addingTimeInterval(30 * 60)

                    allBlocks.append(PlanBlock.PlanBlockData(
                        startDateTime: isoFormatter.string(from: reviewStart),
                        endDateTime: isoFormatter.string(from: reviewEnd),
                        title: "Weekly Review & Planning",
                        blockType: BlockType.review.rawValue,
                        intentShort: "Reflect on progress and plan ahead",
                        weekNumber: week
                    ))
                }
            }
        }

        return allBlocks
    }

    func generateWeekBlocks(
        domainPlan: DomainPlan,
        weekStart: Date,
        blockCount: Int,
        weekNumber: Int,
        durationMultiplier: Double,
        energyPattern: EnergyDistribution
    ) -> [PlanBlock.PlanBlockData] {
        var blocks: [PlanBlock.PlanBlockData] = []

        // Get activities for this phase
        let activities = selectActivitiesForWeek(
            domainPlan: domainPlan,
            weekNumber: weekNumber,
            totalActivitiesNeeded: blockCount
        )

        // Determine available days (excluding rest days)
        let allDays: [DayOfWeek] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]
        let availableDays = allDays.filter { !domainPlan.restDays.contains($0) }

        // Distribute activities across days
        var dayIndex = 0
        var timeSlots = generateTimeSlots(for: energyPattern)
        var slotIndex = 0

        for activity in activities {
            let day = availableDays[dayIndex % availableDays.count]
            let dayOffset = day.dayOffset

            guard let blockDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                continue
            }

            // Get optimal time for this block type
            let timeSlot = timeSlots[slotIndex % timeSlots.count]
            let (hour, minute) = getOptimalTime(for: activity.blockType, slot: timeSlot, energyPattern: energyPattern)

            var components = calendar.dateComponents([.year, .month, .day], from: blockDate)
            components.hour = hour
            components.minute = minute

            guard let startTime = calendar.date(from: components) else { continue }

            // Calculate duration with multiplier
            let duration = Int(Double(activity.duration) * durationMultiplier)
            let boundedDuration = max(15, min(120, duration))

            let endTime = startTime.addingTimeInterval(Double(boundedDuration * 60))

            blocks.append(PlanBlock.PlanBlockData(
                startDateTime: isoFormatter.string(from: startTime),
                endDateTime: isoFormatter.string(from: endTime),
                title: activity.title,
                blockType: activity.blockType.rawValue,
                intentShort: activity.intent,
                weekNumber: weekNumber
            ))

            dayIndex += 1
            slotIndex += 1
        }

        // Add weekly review block on last available day
        if let lastDay = availableDays.last {
            let dayOffset = lastDay.dayOffset
            if let reviewDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) {
                var components = calendar.dateComponents([.year, .month, .day], from: reviewDate)
                components.hour = 19
                components.minute = 0

                if let reviewStart = calendar.date(from: components) {
                    let reviewEnd = reviewStart.addingTimeInterval(30 * 60)

                    blocks.append(PlanBlock.PlanBlockData(
                        startDateTime: isoFormatter.string(from: reviewStart),
                        endDateTime: isoFormatter.string(from: reviewEnd),
                        title: "Weekly Review & Planning",
                        blockType: BlockType.review.rawValue,
                        intentShort: "Reflect on progress and plan ahead",
                        weekNumber: weekNumber
                    ))
                }
            }
        }

        return blocks
    }

    private func selectActivitiesForWeek(
        domainPlan: DomainPlan,
        weekNumber: Int,
        totalActivitiesNeeded: Int
    ) -> [DomainActivity] {
        var selected: [DomainActivity] = []

        // Filter activities by phase appropriateness
        let totalWeeksEstimate = 12 // Default estimate
        let progressRatio = Double(weekNumber) / Double(totalWeeksEstimate)

        let currentPhase: ActivityPhase
        if progressRatio < 0.3 {
            currentPhase = .early
        } else if progressRatio < 0.7 {
            currentPhase = .middle
        } else {
            currentPhase = .late
        }

        // Get phase-appropriate and ongoing activities
        var appropriateActivities = domainPlan.activities.filter { activity in
            activity.phase == .ongoing || activity.phase == currentPhase
        }

        // If no phase-specific activities, use all activities
        if appropriateActivities.isEmpty {
            appropriateActivities = domainPlan.activities
        }

        // Still empty? Return empty
        guard !appropriateActivities.isEmpty else { return [] }

        // Build the week's schedule based on frequency
        var activityCounts: [String: Int] = [:]
        var maxIterations = totalActivitiesNeeded * 3 // Safety limit

        while selected.count < totalActivitiesNeeded && maxIterations > 0 {
            maxIterations -= 1
            var addedAny = false

            for activity in appropriateActivities {
                guard selected.count < totalActivitiesNeeded else { break }

                let currentCount = activityCounts[activity.title] ?? 0
                let maxCount: Int

                switch activity.frequency {
                case .daily:
                    maxCount = 6
                case .timesPerWeek(let times):
                    maxCount = times
                }

                if currentCount < maxCount {
                    selected.append(activity)
                    activityCounts[activity.title] = currentCount + 1
                    addedAny = true
                }
            }

            // If we couldn't add anything, cycle through again allowing repeats
            if !addedAny {
                // Allow repeats of any activity
                if let randomActivity = appropriateActivities.randomElement() {
                    selected.append(randomActivity)
                }
            }
        }

        // Shuffle to add variety
        return selected.shuffled()
    }

    private func generateTimeSlots(for energyPattern: EnergyDistribution) -> [ScheduleTimeSlot] {
        switch energyPattern {
        case .morningHeavy:
            return [.earlyMorning, .morning, .morning, .lateMorning, .afternoon, .evening]
        case .eveningHeavy:
            return [.morning, .afternoon, .afternoon, .evening, .evening, .lateEvening]
        case .flexible:
            return [.morning, .lateMorning, .afternoon, .lateAfternoon, .evening, .lateEvening]
        }
    }

    private func getOptimalTime(for blockType: BlockType, slot: ScheduleTimeSlot, energyPattern: EnergyDistribution) -> (hour: Int, minute: Int) {
        // Focus blocks go in high-energy times
        // Light blocks go in lower-energy times
        // Habits can be any time

        switch blockType {
        case .focus:
            switch slot {
            case .earlyMorning: return (7, 0)
            case .morning: return (9, 0)
            case .lateMorning: return (10, 30)
            case .afternoon: return (14, 0)
            case .lateAfternoon: return (16, 0)
            case .evening: return (18, 0)
            case .lateEvening: return (20, 0)
            }
        case .light:
            switch slot {
            case .earlyMorning: return (7, 30)
            case .morning: return (11, 0)
            case .lateMorning: return (11, 30)
            case .afternoon: return (14, 30)
            case .lateAfternoon: return (16, 30)
            case .evening: return (18, 30)
            case .lateEvening: return (20, 30)
            }
        case .habit:
            switch slot {
            case .earlyMorning: return (6, 30)
            case .morning: return (8, 0)
            case .lateMorning: return (10, 0)
            case .afternoon: return (13, 0)
            case .lateAfternoon: return (17, 0)
            case .evening: return (19, 0)
            case .lateEvening: return (21, 0)
            }
        case .review:
            return (19, 0)
        }
    }

    func findOptimalRescheduleSlot(
        for block: PlanBlock,
        availableSlots: [DateInterval]
    ) -> Date? {
        let blockDuration = block.duration

        // Prefer slots that match the block's original time of day
        let originalHour = calendar.component(.hour, from: block.originalStartDateTime)

        // Score each slot
        var bestSlot: DateInterval?
        var bestScore = -1.0

        for slot in availableSlots {
            guard slot.duration >= blockDuration else { continue }

            let slotHour = calendar.component(.hour, from: slot.start)

            // Score based on time similarity
            let hourDifference = abs(slotHour - originalHour)
            let timeScore = max(0, 10 - hourDifference)

            // Prefer sooner rather than later
            let daysFromNow = calendar.dateComponents([.day], from: Date(), to: slot.start).day ?? 0
            let urgencyScore = max(0, 7 - daysFromNow)

            let totalScore = Double(timeScore + urgencyScore)

            if totalScore > bestScore {
                bestScore = totalScore
                bestSlot = slot
            }
        }

        return bestSlot?.start
    }
}

// MARK: - Adaptive Learning Engine

/// Learns from user behavior to improve planning
final class AdaptiveLearningEngine {

    func analyzeUserPatterns(
        reflection: WeeklyReflection,
        blocks: [PlanBlock]
    ) -> UserPatterns {
        // Analyze completion patterns
        let completedBlocks = blocks.filter { $0.status == .completed }
        let skippedBlocks = blocks.filter { $0.status == .skipped }

        // Time of day analysis
        var morningCompletions = 0
        var afternoonCompletions = 0
        var eveningCompletions = 0

        for block in completedBlocks {
            let hour = Calendar.current.component(.hour, from: block.startDateTime)
            if hour < 12 {
                morningCompletions += 1
            } else if hour < 17 {
                afternoonCompletions += 1
            } else {
                eveningCompletions += 1
            }
        }

        let preferredTime: PreferredTimeOfDay
        if morningCompletions >= afternoonCompletions && morningCompletions >= eveningCompletions {
            preferredTime = .morning
        } else if afternoonCompletions >= eveningCompletions {
            preferredTime = .afternoon
        } else {
            preferredTime = .evening
        }

        // Block type preferences
        var blockTypeSuccess: [BlockType: Double] = [:]
        for type in BlockType.allCases {
            let typeBlocks = blocks.filter { $0.blockType == type }
            let typeCompleted = typeBlocks.filter { $0.status == .completed }.count
            if !typeBlocks.isEmpty {
                blockTypeSuccess[type] = Double(typeCompleted) / Double(typeBlocks.count)
            }
        }

        // Duration analysis
        let averageCompletedDuration = completedBlocks.isEmpty ? 45.0 :
            completedBlocks.reduce(0.0) { $0 + $1.duration } / Double(completedBlocks.count) / 60.0

        let averageSkippedDuration = skippedBlocks.isEmpty ? 60.0 :
            skippedBlocks.reduce(0.0) { $0 + $1.duration } / Double(skippedBlocks.count) / 60.0

        let optimalDuration = averageCompletedDuration < averageSkippedDuration
            ? min(averageCompletedDuration, 45.0)
            : 45.0

        return UserPatterns(
            preferredTimeOfDay: preferredTime,
            blockTypeSuccessRates: blockTypeSuccess,
            optimalBlockDuration: optimalDuration,
            completionRate: reflection.completionRate,
            engagementRate: reflection.engagementRate,
            consistentDays: detectConsistentDays(blocks: completedBlocks)
        )
    }

    func determineAdaptationStrategy(
        patterns: UserPatterns,
        reflection: WeeklyReflection
    ) -> AdaptationStrategy {
        var adjustmentType: AIAdaptationResponse.AdjustmentType = .maintained
        var summary: String
        var energyPattern: EnergyDistribution

        // Determine energy pattern from preferred time
        switch patterns.preferredTimeOfDay {
        case .morning:
            energyPattern = .morningHeavy
        case .afternoon, .evening:
            energyPattern = .eveningHeavy
        }

        // Analyze feeling and completion
        switch reflection.weekFeeling {
        case .tooEasy:
            if patterns.completionRate > 0.8 {
                adjustmentType = .increased
                summary = "You crushed it! Adding more challenging blocks this week."
            } else {
                adjustmentType = .maintained
                summary = "Let's build on your momentum with a similar plan."
            }

        case .justRight:
            adjustmentType = .maintained
            summary = "Your plan is working well. Keeping the same pace."

        case .tooHard:
            if patterns.completionRate < 0.5 {
                adjustmentType = .lighter
                summary = "I've reduced the load to help you build momentum."
            } else {
                adjustmentType = .restructured
                summary = "I've reorganized your week for better balance."
            }
        }

        // Consider obstacles
        if let obstacle = reflection.obstacle {
            switch obstacle {
            case .time:
                adjustmentType = .restructured
                summary = "I've created shorter, more focused blocks."
                energyPattern = .flexible
            case .energy:
                adjustmentType = .lighter
                summary = "I've spread activities out and added recovery time."
            case .motivation:
                adjustmentType = .restructured
                summary = "I've mixed things up to keep it fresh and engaging."
            case .life:
                adjustmentType = .lighter
                summary = "I've added flexibility for life's unpredictability."
            }
        }

        return AdaptationStrategy(
            adjustmentType: adjustmentType,
            summary: summary,
            preferredEnergyPattern: energyPattern,
            optimalDuration: patterns.optimalBlockDuration,
            focusOnBlockTypes: patterns.blockTypeSuccessRates.filter { $0.value > 0.7 }.map { $0.key }
        )
    }

    private func detectConsistentDays(blocks: [PlanBlock]) -> [Int] {
        var dayCompletions: [Int: Int] = [:]

        for block in blocks {
            let weekday = Calendar.current.component(.weekday, from: block.startDateTime)
            dayCompletions[weekday, default: 0] += 1
        }

        // Return days with above average completions
        let average = dayCompletions.values.reduce(0, +) / max(1, dayCompletions.count)
        return dayCompletions.filter { $0.value > average }.map { $0.key }
    }
}

// MARK: - Supporting Types

enum GoalDomain {
    case finance
    case technology
    case academia
    case fitness
    case business
    case creative
    case language
    case career
    case income         // Making money, side hustles, income goals
    case weightLoss     // Weight loss, body transformation
    case health         // General health, wellness, longevity
    case productivity   // Time management, habits, efficiency
    case relationship   // Social skills, dating, networking
    case mindfulness    // Mental health, meditation, stress
    case general
}

struct GoalTarget {
    let type: String
    let quantity: Int
    let timeframe: String?
}

enum PlanConstraint {
    case limitedTime
    case beginner
    case hasFullTimeJob
    case isStudent
}

struct ParsedGoalAnalysis {
    let originalGoal: IdentityGoal
    let domain: GoalDomain
    let subDomains: [GoalDomain]
    let targets: [GoalTarget]
    let constraints: [PlanConstraint]
    let detectedIntensity: Intensity
    let detectedTimelineWeeks: Int?
    let urgencyScore: Double
    let keywords: [String]
}

struct DomainActivity {
    let title: String
    let intent: String
    let blockType: BlockType
    let duration: Int // minutes
    let frequency: ActivityFrequency
    let phase: ActivityPhase
    let skillCategory: String
}

// ActivityFrequency is defined in Models.swift

enum ActivityPhase {
    case early
    case middle
    case late
    case ongoing
}

struct DomainMilestone {
    let title: String
    let description: String
    let weekRatio: Double // 0-1, when in timeline
}

struct DomainTheme {
    let title: String
    let focus: String
    let phaseRatio: ClosedRange<Double>
}

struct DomainPlan {
    let activities: [DomainActivity]
    let keyMilestones: [DomainMilestone]
    let weeklyThemes: [DomainTheme]
    let baseBlocksPerWeek: Int
    let energyDistribution: EnergyDistribution
    let restDays: [DayOfWeek]
    let specialConsiderations: [String]
}

enum EnergyDistribution {
    case morningHeavy
    case eveningHeavy
    case flexible
}

enum DayOfWeek {
    case sunday, monday, tuesday, wednesday, thursday, friday, saturday

    var dayOffset: Int {
        switch self {
        case .sunday: return 0
        case .monday: return 1
        case .tuesday: return 2
        case .wednesday: return 3
        case .thursday: return 4
        case .friday: return 5
        case .saturday: return 6
        }
    }

    /// Create from Calendar weekday (1 = Sunday, 7 = Saturday)
    static func from(weekday: Int) -> DayOfWeek {
        switch weekday {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return .sunday
        }
    }
}

enum ScheduleTimeSlot {
    case earlyMorning
    case morning
    case lateMorning
    case afternoon
    case lateAfternoon
    case evening
    case lateEvening
}

struct UserPatterns {
    let preferredTimeOfDay: PreferredTimeOfDay
    let blockTypeSuccessRates: [BlockType: Double]
    let optimalBlockDuration: Double
    let completionRate: Double
    let engagementRate: Double
    let consistentDays: [Int]
}

enum PreferredTimeOfDay {
    case morning
    case afternoon
    case evening
}

struct AdaptationStrategy {
    let adjustmentType: AIAdaptationResponse.AdjustmentType
    let summary: String
    let preferredEnergyPattern: EnergyDistribution
    let optimalDuration: Double
    let focusOnBlockTypes: [BlockType]
}
