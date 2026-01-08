import Foundation
import SwiftUI
import Combine

/// Manages the weekly reflection flow
@MainActor
final class ReflectionViewModel: ObservableObject {
    // MARK: - Published State

    @Published var currentStep: ReflectionStep = .feeling
    @Published var selectedFeeling: WeekFeeling?
    @Published var selectedObstacle: WeekObstacle?
    @Published var note: String = ""
    @Published var isProcessing = false
    @Published var adaptationSummary: String?
    @Published var isComplete = false

    // MARK: - Dependencies

    private let dataService: DataService
    private let aiPlanner: AIPlannerService

    // MARK: - Week Info

    private(set) var weekNumber: Int = 1
    private(set) var weekStart: Date = Date()
    private(set) var weekEnd: Date = Date()

    // MARK: - Computed Properties

    var canProceed: Bool {
        switch currentStep {
        case .feeling:
            return selectedFeeling != nil
        case .obstacle:
            return true // Obstacle is optional
        case .note:
            return true // Note is optional
        case .processing, .complete:
            return false
        }
    }

    var progressValue: Double {
        Double(currentStep.rawValue) / Double(ReflectionStep.allCases.count - 1)
    }

    var weekStats: (completed: Int, skipped: Int, total: Int)? {
        guard let goal = dataService.activeGoal else { return nil }
        let blocks = dataService.blocksForDateRange(start: weekStart, end: weekEnd, goal: goal)
        return (
            completed: blocks.filter { $0.status == .completed }.count,
            skipped: blocks.filter { $0.status == .skipped }.count,
            total: blocks.count
        )
    }

    // MARK: - Initialization

    init(
        dataService: DataService = .shared,
        aiPlanner: AIPlannerService? = nil
    ) {
        self.dataService = dataService
        self.aiPlanner = aiPlanner ?? MockAIPlannerService()

        setupWeekInfo()
    }

    private func setupWeekInfo() {
        let calendar = Calendar.current
        let today = Date()

        // Get the current week's start (Sunday)
        if let weekStartDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) {
            weekStart = weekStartDate
            weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStartDate) ?? today
        }

        if let goal = dataService.activeGoal {
            let weeks = calendar.dateComponents([.weekOfYear], from: goal.createdAt, to: today).weekOfYear ?? 0
            weekNumber = max(1, weeks + 1)
        }
    }

    // MARK: - Navigation

    func goToNextStep() {
        guard canProceed else { return }

        Haptics.navigate()

        withAnimation(Constants.Animation.standard) {
            switch currentStep {
            case .feeling:
                currentStep = .obstacle
            case .obstacle:
                currentStep = .note
            case .note:
                submitReflection()
            case .processing, .complete:
                break
            }
        }
    }

    func goToPreviousStep() {
        Haptics.navigate()

        withAnimation(Constants.Animation.standard) {
            switch currentStep {
            case .feeling:
                break
            case .obstacle:
                currentStep = .feeling
            case .note:
                currentStep = .obstacle
            case .processing:
                currentStep = .note
            case .complete:
                break
            }
        }
    }

    func skipStep() {
        Haptics.tap()
        goToNextStep()
    }

    // MARK: - Selection Handlers

    func selectFeeling(_ feeling: WeekFeeling) {
        Haptics.select()
        selectedFeeling = feeling
    }

    func selectObstacle(_ obstacle: WeekObstacle?) {
        Haptics.select()
        selectedObstacle = obstacle
    }

    // MARK: - Submission

    func submitReflection() {
        guard let feeling = selectedFeeling,
              let goal = dataService.activeGoal else {
            return
        }

        currentStep = .processing
        isProcessing = true

        Task {
            // Create reflection record
            let reflection = dataService.createReflection(
                for: goal,
                weekNumber: weekNumber,
                weekStart: weekStart,
                weekEnd: weekEnd,
                feeling: feeling,
                obstacle: selectedObstacle,
                note: note.isEmpty ? nil : note
            )

            // All users get AI adaptation (no paywall)
            do {
                // Get current blocks for the next week
                let nextWeekStart = weekEnd.adding(days: 1)
                let nextWeekEnd = nextWeekStart.adding(days: 6)
                let currentBlocks = dataService.blocksForDateRange(
                    start: nextWeekStart,
                    end: nextWeekEnd,
                    goal: goal
                )

                // Call AI for adaptation
                let response = try await aiPlanner.adaptWeeklyPlan(
                    for: goal,
                    reflection: reflection,
                    currentBlocks: currentBlocks
                )

                // Apply new blocks
                let newBlocks = response.updatedBlocks.compactMap { $0.toPlanBlock() }
                dataService.addBlocks(newBlocks, to: goal)

                // Update reflection with AI summary
                reflection.aiAdjustmentSummary = response.summary
                reflection.wasProcessed = true
                dataService.saveContext()

                adaptationSummary = response.summary

            } catch {
                // Fallback summary on error
                adaptationSummary = "Your reflection has been saved. We'll adjust your plan based on your feedback."
            }

            isProcessing = false
            isComplete = true

            withAnimation(Constants.Animation.standard) {
                currentStep = .complete
            }

            Haptics.success()
        }
    }

    // MARK: - Reset

    func reset() {
        currentStep = .feeling
        selectedFeeling = nil
        selectedObstacle = nil
        note = ""
        isProcessing = false
        adaptationSummary = nil
        isComplete = false
    }
}

// MARK: - Reflection Step

enum ReflectionStep: Int, CaseIterable {
    case feeling = 0
    case obstacle = 1
    case note = 2
    case processing = 3
    case complete = 4

    var title: String {
        switch self {
        case .feeling: return "How did this week feel?"
        case .obstacle: return "What got in the way?"
        case .note: return "Anything else?"
        case .processing: return "Adjusting your plan"
        case .complete: return "All set"
        }
    }

    var subtitle: String? {
        switch self {
        case .feeling: return "Be honest — this helps us adapt"
        case .obstacle: return "Optional, but helps us understand"
        case .note: return "Optional quick note"
        case .processing: return nil
        case .complete: return nil
        }
    }
}
