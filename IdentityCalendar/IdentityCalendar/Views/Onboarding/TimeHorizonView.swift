import SwiftUI

/// Step 2: Time horizon selection
struct TimeHorizonView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepView(
            title: "What's your time horizon?",
            subtitle: "Choose how long you want to work toward this",
            showBackButton: true,
            canProceed: viewModel.canProceed,
            buttonTitle: "Continue",
            onBack: viewModel.goToPreviousStep,
            onNext: viewModel.goToNextStep
        ) {
            VStack(spacing: 12) {
                ForEach(TimeHorizon.allCases, id: \.self) { horizon in
                    TimeHorizonCard(
                        horizon: horizon,
                        isSelected: viewModel.selectedTimeHorizon == horizon,
                        action: { viewModel.selectTimeHorizon(horizon) }
                    )
                }
            }
        }
    }
}

/// Time horizon selection card
struct TimeHorizonCard: View {
    let horizon: TimeHorizon
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(horizon.displayName)
                        .font(.body.weight(.medium))
                        .foregroundColor(.appPrimaryText)

                    Text(durationDescription)
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appAccent)
                        .font(.system(size: 22))
                }
            }
        }
    }

    private var durationDescription: String {
        switch horizon {
        case .oneMonth:
            return "Quick sprint to build momentum"
        case .threeMonths:
            return "Form lasting habits"
        case .sixMonths:
            return "Deep transformation"
        case .oneYear:
            return "Complete identity shift"
        }
    }
}

// MARK: - Preview

#Preview {
    TimeHorizonView(viewModel: OnboardingViewModel())
}
