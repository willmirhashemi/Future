import SwiftUI

/// Step 5: Plan confidence slider
struct PlanConfidenceView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepView(
            title: "How ambitious should this plan be?",
            subtitle: "Slide right for a more challenging plan",
            showBackButton: true,
            canProceed: true,
            buttonTitle: "Create my plan",
            onBack: viewModel.goToPreviousStep,
            onNext: viewModel.goToNextStep
        ) {
            VStack(spacing: 40) {
                // Visualization of what this affects
                VStack(spacing: 24) {
                    ConfidenceMetric(
                        title: "Blocks per week",
                        value: blocksPerWeekText,
                        icon: "calendar"
                    )

                    ConfidenceMetric(
                        title: "Session length",
                        value: sessionLengthText,
                        icon: "clock"
                    )

                    ConfidenceMetric(
                        title: "Pace",
                        value: paceText,
                        icon: "speedometer"
                    )
                }
                .padding(.vertical, 20)

                // The slider
                ConfidenceSlider(value: $viewModel.planConfidenceValue)
            }
        }
    }

    private var blocksPerWeekText: String {
        switch viewModel.planConfidence {
        case .conservative: return "3-5"
        case .balanced: return "5-8"
        case .ambitious: return "8-12"
        }
    }

    private var sessionLengthText: String {
        switch viewModel.planConfidence {
        case .conservative: return "20-40 min"
        case .balanced: return "30-60 min"
        case .ambitious: return "45-90 min"
        }
    }

    private var paceText: String {
        switch viewModel.planConfidence {
        case .conservative: return "Gentle"
        case .balanced: return "Steady"
        case .ambitious: return "Intensive"
        }
    }
}

/// Individual metric display for confidence preview
struct ConfidenceMetric: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.appSecondaryText)
                .frame(width: 28)

            Text(title)
                .font(.body)
                .foregroundColor(.appSecondaryText)

            Spacer()

            Text(value)
                .font(.body.weight(.medium))
                .foregroundColor(.appPrimaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

// MARK: - Preview

#Preview {
    PlanConfidenceView(viewModel: OnboardingViewModel())
}
