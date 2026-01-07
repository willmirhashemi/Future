import SwiftUI

/// Main container for the onboarding flow
struct OnboardingContainerView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                OnboardingProgressBar(progress: viewModel.progressValue)
                    .padding(.horizontal, Constants.Layout.screenPadding)
                    .padding(.top, 8)

                // Content
                TabView(selection: $viewModel.currentStep) {
                    IdentitySelectionView(viewModel: viewModel)
                        .tag(OnboardingStep.identity)

                    TimeHorizonView(viewModel: viewModel)
                        .tag(OnboardingStep.timeHorizon)

                    AvailabilityView(viewModel: viewModel)
                        .tag(OnboardingStep.availability)

                    IntensityView(viewModel: viewModel)
                        .tag(OnboardingStep.intensity)

                    PlanConfidenceView(viewModel: viewModel)
                        .tag(OnboardingStep.planConfidence)

                    PlanGenerationView(viewModel: viewModel)
                        .tag(OnboardingStep.generating)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
            }
        }
        .onChange(of: viewModel.createdGoal) { _, goal in
            if goal != nil {
                // Plan created successfully - complete onboarding
                onComplete?()
            }
        }
    }
}

/// Reusable onboarding step layout
struct OnboardingStepView<Content: View>: View {
    let title: String
    let subtitle: String?
    let showBackButton: Bool
    let canProceed: Bool
    let buttonTitle: String
    let onBack: () -> Void
    let onNext: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.appPrimaryText)
                    .multilineTextAlignment(.center)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.body)
                        .foregroundColor(.appSecondaryText)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, Constants.Layout.screenPadding)
            .padding(.top, 32)
            .padding(.bottom, 32)

            // Content
            ScrollView {
                content()
                    .padding(.horizontal, Constants.Layout.screenPadding)
            }

            Spacer()

            // Bottom buttons
            VStack(spacing: 12) {
                PrimaryButton(
                    title: buttonTitle,
                    action: onNext,
                    isDisabled: !canProceed
                )

                if showBackButton {
                    TertiaryButton(title: "Back", action: onBack)
                }
            }
            .padding(.horizontal, Constants.Layout.screenPadding)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingContainerView()
}
