import Foundation
import SwiftUI

// MARK: - Generated Plan Model

struct GeneratedPlan {
    let goalSummary: String
    let timelineDescription: String
    let milestones: [PlanMilestone]
    let weeklyHours: Int
    let sessionsPerWeek: Int
    let blocks: [PlanBlock.PlanBlockData]
}

struct PlanMilestone: Identifiable {
    let id = UUID()
    let title: String
    let timeframe: String
    let weekNumber: Int
}

// MARK: - Onboarding Steps

enum NewOnboardingStep {
    case welcome
    case goalInput
    case processing
    case planPreview
    case error
}

// MARK: - ViewModel

@MainActor
final class NewOnboardingViewModel: ObservableObject {
    // MARK: - Published State

    @Published var currentStep: NewOnboardingStep = .welcome
    @Published var goalText: String = ""
    @Published var isProcessing = false
    @Published var generatedPlan: GeneratedPlan?
    @Published var errorMessage: String?
    @Published var createdGoal: IdentityGoal?

    // MARK: - Dependencies

    private let dataService: DataService
    private let aiPlanner: AIPlannerService

    // MARK: - Initialization

    init(
        dataService: DataService = .shared,
        aiPlanner: AIPlannerService? = nil
    ) {
        self.dataService = dataService
        // Use the Advanced AI Planner for intelligent planning
        self.aiPlanner = aiPlanner ?? AdvancedAIPlannerService()
    }

    // MARK: - Navigation

    func goToWelcome() {
        withAnimation {
            currentStep = .welcome
        }
    }

    func goToGoalInput() {
        Haptics.navigate()
        withAnimation {
            currentStep = .goalInput
        }
    }

    // MARK: - Goal Processing

    func processGoal() {
        guard goalText.count >= 20 else { return }

        Haptics.tap()
        isProcessing = true

        withAnimation {
            currentStep = .processing
        }

        Task {
            do {
                // Simulate AI processing delay
                try await Task.sleep(nanoseconds: 2_500_000_000)

                // Parse the goal text and generate a plan
                let plan = try await generatePlanFromGoal(goalText)

                await MainActor.run {
                    self.generatedPlan = plan
                    self.isProcessing = false
                    withAnimation {
                        self.currentStep = .planPreview
                    }
                    Haptics.success()
                }
            } catch {
                await MainActor.run {
                    self.isProcessing = false
                    self.errorMessage = "We couldn't process your goal. Please try again."
                    withAnimation {
                        self.currentStep = .error
                    }
                    Haptics.error()
                }
            }
        }
    }

    func regeneratePlan() {
        Haptics.tap()
        processGoal()
    }

    func retryProcessing() {
        processGoal()
    }

    // MARK: - Accept Plan

    func acceptPlan() {
        guard let plan = generatedPlan else { return }

        Haptics.success()

        // Create the goal in the database
        let goal = dataService.createGoal(
            identityType: .custom,
            customName: extractGoalTitle(from: goalText),
            timeHorizon: determineTimeHorizon(from: plan),
            availability: .normal,
            intensity: .balanced,
            planConfidence: .balanced
        )

        // Add milestones
        let milestones = plan.milestones.map { pm in
            Milestone(
                title: pm.title,
                description: pm.timeframe,
                targetDate: Date().adding(weeks: pm.weekNumber),
                weekNumber: pm.weekNumber,
                sortOrder: pm.weekNumber
            )
        }
        dataService.addMilestones(milestones, to: goal)

        // Add blocks
        let blocks = plan.blocks.compactMap { $0.toPlanBlock() }
        dataService.addBlocks(blocks, to: goal)

        // Mark onboarding complete
        dataService.completeOnboarding()

        createdGoal = goal
    }

    // MARK: - Private Helpers

    private func generatePlanFromGoal(_ text: String) async throws -> GeneratedPlan {
        // In a real implementation, this would call an AI API
        // For now, we use intelligent parsing and the mock service

        let parsedGoal = parseGoalText(text)

        // Create a temporary goal for the AI service
        let tempGoal = IdentityGoal(
            identityType: .custom,
            customIdentityName: parsedGoal.title,
            timeHorizon: parsedGoal.timeHorizon,
            availability: parsedGoal.availability,
            intensity: parsedGoal.intensity,
            planConfidence: .balanced
        )

        // Generate the plan using AI service
        let response = try await aiPlanner.generateInitialPlan(for: tempGoal)

        // Convert to GeneratedPlan
        let milestones = response.milestones.enumerated().map { index, m in
            PlanMilestone(
                title: m.title,
                timeframe: "Week \(m.weekNumber)",
                weekNumber: m.weekNumber
            )
        }

        return GeneratedPlan(
            goalSummary: parsedGoal.summary,
            timelineDescription: parsedGoal.timeHorizon.displayName,
            milestones: milestones,
            weeklyHours: calculateWeeklyHours(for: parsedGoal),
            sessionsPerWeek: calculateSessionsPerWeek(for: parsedGoal),
            blocks: response.planBlocks
        )
    }

    private func parseGoalText(_ text: String) -> ParsedGoal {
        let lowercased = text.lowercased()

        // Detect time horizon from text
        var timeHorizon: TimeHorizon = .threeMonths
        if lowercased.contains("year") || lowercased.contains("4 year") || lowercased.contains("four year") {
            timeHorizon = .oneYear
        } else if lowercased.contains("6 month") || lowercased.contains("six month") {
            timeHorizon = .sixMonths
        } else if lowercased.contains("month") {
            timeHorizon = .oneMonth
        }

        // Detect intensity
        var intensity: Intensity = .balanced
        if lowercased.contains("aggressive") || lowercased.contains("intense") || lowercased.contains("serious") {
            intensity = .aggressive
        } else if lowercased.contains("gentle") || lowercased.contains("light") || lowercased.contains("easy") {
            intensity = .light
        }

        // Detect availability
        var availability: Availability = .normal
        if lowercased.contains("busy") || lowercased.contains("limited time") {
            availability = .busy
        } else if lowercased.contains("open") || lowercased.contains("lots of time") || lowercased.contains("flexible") {
            availability = .open
        }

        // Extract title
        let title = extractGoalTitle(from: text)

        // Create summary
        let summary = text.count > 200 ? String(text.prefix(200)) + "..." : text

        return ParsedGoal(
            title: title,
            summary: summary,
            timeHorizon: timeHorizon,
            intensity: intensity,
            availability: availability
        )
    }

    private func extractGoalTitle(from text: String) -> String {
        let lowercased = text.lowercased()

        // Try to extract a meaningful title
        if lowercased.contains("investment banking") {
            return "Investment Banking Career"
        } else if lowercased.contains("software") || lowercased.contains("developer") || lowercased.contains("programming") {
            return "Software Development"
        } else if lowercased.contains("fitness") || lowercased.contains("workout") || lowercased.contains("gym") {
            return "Fitness Journey"
        } else if lowercased.contains("study") || lowercased.contains("exam") || lowercased.contains("degree") {
            return "Academic Excellence"
        } else if lowercased.contains("business") || lowercased.contains("entrepreneur") || lowercased.contains("startup") {
            return "Entrepreneurship"
        } else if lowercased.contains("learn") {
            return "Learning Path"
        }

        // Default: extract first few words
        let words = text.split(separator: " ").prefix(4).joined(separator: " ")
        return String(words).capitalized
    }

    private func calculateWeeklyHours(for goal: ParsedGoal) -> Int {
        let baseHours: Int
        switch goal.availability {
        case .busy: baseHours = 5
        case .normal: baseHours = 10
        case .open: baseHours = 15
        }

        let multiplier: Double
        switch goal.intensity {
        case .light: multiplier = 0.7
        case .balanced: multiplier = 1.0
        case .aggressive: multiplier = 1.3
        }

        return Int(Double(baseHours) * multiplier)
    }

    private func calculateSessionsPerWeek(for goal: ParsedGoal) -> Int {
        let baseSessions: Int
        switch goal.availability {
        case .busy: baseSessions = 4
        case .normal: baseSessions = 6
        case .open: baseSessions = 8
        }

        let multiplier: Double
        switch goal.intensity {
        case .light: multiplier = 0.8
        case .balanced: multiplier = 1.0
        case .aggressive: multiplier = 1.2
        }

        return Int(Double(baseSessions) * multiplier)
    }

    private func determineTimeHorizon(from plan: GeneratedPlan) -> TimeHorizon {
        if plan.timelineDescription.contains("1 Year") {
            return .oneYear
        } else if plan.timelineDescription.contains("6 Month") {
            return .sixMonths
        } else if plan.timelineDescription.contains("1 Month") {
            return .oneMonth
        }
        return .threeMonths
    }
}

// MARK: - Parsed Goal

private struct ParsedGoal {
    let title: String
    let summary: String
    let timeHorizon: TimeHorizon
    let intensity: Intensity
    let availability: Availability
}
