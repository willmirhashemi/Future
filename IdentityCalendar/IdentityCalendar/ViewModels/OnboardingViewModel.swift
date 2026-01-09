import Foundation
import SwiftUI
import Combine

/// Manages the onboarding flow state and logic
@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Published State

    @Published var currentStep: OnboardingStep = .identity
    @Published var selectedIdentity: IdentityType?
    @Published var customIdentityName: String = ""
    @Published var selectedTimeHorizon: TimeHorizon?
    @Published var selectedAvailability: Availability?
    @Published var selectedIntensity: Intensity?
    @Published var planConfidenceValue: Double = 0.5
    @Published var isGeneratingPlan = false
    @Published var generationError: String?
    @Published var createdGoal: IdentityGoal?

    // MARK: - Dependencies

    private let dataService: DataService
    private let aiPlanner: AIPlannerService

    // MARK: - Computed Properties

    var planConfidence: PlanConfidence {
        PlanConfidence.from(value: planConfidenceValue)
    }

    var canProceed: Bool {
        switch currentStep {
        case .identity:
            if selectedIdentity == .custom {
                return !customIdentityName.trimmingCharacters(in: .whitespaces).isEmpty
            }
            return selectedIdentity != nil
        case .timeHorizon:
            return selectedTimeHorizon != nil
        case .availability:
            return selectedAvailability != nil
        case .intensity:
            return selectedIntensity != nil
        case .planConfidence:
            return true // Slider always has a value
        case .generating:
            return false
        }
    }

    var progressValue: Double {
        Double(currentStep.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }

    var isFirstStep: Bool {
        currentStep == .identity
    }

    var isLastInputStep: Bool {
        currentStep == .planConfidence
    }

    // MARK: - Initialization

    init(
        dataService: DataService = .shared,
        aiPlanner: AIPlannerService? = nil
    ) {
        self.dataService = dataService
        self.aiPlanner = aiPlanner ?? (FeatureFlags.useMockAI ? MockAIPlannerService() : AdvancedAIPlannerService())
    }

    // MARK: - Navigation

    func goToNextStep() {
        guard canProceed else { return }

        Haptics.navigate()

        withAnimation(Constants.Animation.standard) {
            switch currentStep {
            case .identity:
                currentStep = .timeHorizon
            case .timeHorizon:
                currentStep = .availability
            case .availability:
                currentStep = .intensity
            case .intensity:
                currentStep = .planConfidence
            case .planConfidence:
                generatePlan()
            case .generating:
                break
            }
        }
    }

    func goToPreviousStep() {
        Haptics.navigate()

        withAnimation(Constants.Animation.standard) {
            switch currentStep {
            case .identity:
                break
            case .timeHorizon:
                currentStep = .identity
            case .availability:
                currentStep = .timeHorizon
            case .intensity:
                currentStep = .availability
            case .planConfidence:
                currentStep = .intensity
            case .generating:
                currentStep = .planConfidence
            }
        }
    }

    // MARK: - Selection Handlers

    func selectIdentity(_ identity: IdentityType) {
        Haptics.select()
        selectedIdentity = identity
        if identity != .custom {
            customIdentityName = ""
        }
    }

    func selectTimeHorizon(_ horizon: TimeHorizon) {
        Haptics.select()
        selectedTimeHorizon = horizon
    }

    func selectAvailability(_ availability: Availability) {
        Haptics.select()
        selectedAvailability = availability
    }

    func selectIntensity(_ intensity: Intensity) {
        Haptics.select()
        selectedIntensity = intensity
    }

    func updatePlanConfidence(_ value: Double) {
        planConfidenceValue = value
    }

    // MARK: - Plan Generation

    func generatePlan() {
        guard let identity = selectedIdentity,
              let horizon = selectedTimeHorizon,
              let availability = selectedAvailability,
              let intensity = selectedIntensity else {
            return
        }

        currentStep = .generating
        isGeneratingPlan = true
        generationError = nil

        Task {
            do {
                // Create the goal
                let goal = dataService.createGoal(
                    identityType: identity,
                    customName: identity == .custom ? customIdentityName : nil,
                    timeHorizon: horizon,
                    availability: availability,
                    intensity: intensity,
                    planConfidence: planConfidence
                )

                // Generate AI plan
                let response = try await aiPlanner.generateInitialPlan(for: goal)

                // Create milestones
                let milestones = response.milestones.map { data in
                    data.toMilestone(startDate: goal.createdAt)
                }
                dataService.addMilestones(milestones, to: goal)

                // Create weekly themes
                let themes = response.weeklyThemes.map { data in
                    data.toWeeklyTheme(startDate: goal.createdAt)
                }
                dataService.addWeeklyThemes(themes, to: goal)

                // Create plan blocks
                let blocks = response.planBlocks.compactMap { $0.toPlanBlock() }
                dataService.addBlocks(blocks, to: goal)

                // Mark onboarding complete
                dataService.completeOnboarding()

                createdGoal = goal
                isGeneratingPlan = false

                Haptics.success()

            } catch {
                isGeneratingPlan = false
                generationError = "Unable to generate your plan. Please try again."
                currentStep = .planConfidence
                Haptics.error()
            }
        }
    }

    func retryGeneration() {
        generationError = nil
        generatePlan()
    }

    // MARK: - Reset

    func reset() {
        currentStep = .identity
        selectedIdentity = nil
        customIdentityName = ""
        selectedTimeHorizon = nil
        selectedAvailability = nil
        selectedIntensity = nil
        planConfidenceValue = 0.5
        isGeneratingPlan = false
        generationError = nil
        createdGoal = nil
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case identity = 0
    case timeHorizon = 1
    case availability = 2
    case intensity = 3
    case planConfidence = 4
    case generating = 5

    var title: String {
        switch self {
        case .identity: return "Who do you want to become?"
        case .timeHorizon: return "What's your time horizon?"
        case .availability: return "How's your schedule?"
        case .intensity: return "How intense should we go?"
        case .planConfidence: return "How ambitious should this plan be?"
        case .generating: return "Creating your plan"
        }
    }

    var subtitle: String? {
        switch self {
        case .identity: return nil
        case .timeHorizon: return "Choose how long you want to work toward this"
        case .availability: return "Be honest — it helps us plan realistically"
        case .intensity: return "This affects how much we schedule"
        case .planConfidence: return "Slide right for a more challenging plan"
        case .generating: return "This usually takes a few seconds"
        }
    }
}
