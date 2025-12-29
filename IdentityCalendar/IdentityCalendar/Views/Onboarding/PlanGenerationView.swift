import SwiftUI

/// Plan generation loading view
struct PlanGenerationView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @State private var animationPhase = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 32) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(Color.appAccent.opacity(0.1))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.appAccent.opacity(0.05))
                        .frame(width: 160, height: 160)
                        .scaleEffect(animationPhase > 0 ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: animationPhase
                        )

                    if viewModel.isGeneratingPlan {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .appAccent))
                            .scaleEffect(1.5)
                    } else if viewModel.generationError != nil {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.appWarning)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 40, weight: .medium))
                            .foregroundColor(.appAccent)
                    }
                }

                VStack(spacing: 12) {
                    Text(titleText)
                        .font(.title2.weight(.semibold))
                        .foregroundColor(.appPrimaryText)

                    Text(subtitleText)
                        .font(.body)
                        .foregroundColor(.appSecondaryText)
                        .multilineTextAlignment(.center)
                }

                if let error = viewModel.generationError {
                    VStack(spacing: 16) {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                            .multilineTextAlignment(.center)

                        SecondaryButton(title: "Try Again", action: viewModel.retryGeneration)
                            .frame(width: 200)
                    }
                    .padding(.top, 16)
                }
            }
            .padding(.horizontal, Constants.Layout.screenPadding)

            Spacer()
            Spacer()
        }
        .onAppear {
            animationPhase = 1
        }
    }

    private var titleText: String {
        if viewModel.generationError != nil {
            return "Something went wrong"
        } else if viewModel.isGeneratingPlan {
            return "Creating your plan"
        } else {
            return "Plan ready"
        }
    }

    private var subtitleText: String {
        if viewModel.generationError != nil {
            return "We couldn't create your plan"
        } else if viewModel.isGeneratingPlan {
            return "This usually takes a few seconds"
        } else {
            return "Your personalized calendar is ready"
        }
    }
}

// MARK: - Preview

#Preview("Loading") {
    let viewModel = OnboardingViewModel()
    viewModel.isGeneratingPlan = true
    return PlanGenerationView(viewModel: viewModel)
}

#Preview("Error") {
    let viewModel = OnboardingViewModel()
    viewModel.generationError = "Unable to connect to server"
    return PlanGenerationView(viewModel: viewModel)
}
