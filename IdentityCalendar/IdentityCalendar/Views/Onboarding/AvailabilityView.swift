import SwiftUI

/// Step 3: Availability selection
struct AvailabilityView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepView(
            title: "How's your schedule?",
            subtitle: "Be honest — it helps us plan realistically",
            showBackButton: true,
            canProceed: viewModel.canProceed,
            buttonTitle: "Continue",
            onBack: viewModel.goToPreviousStep,
            onNext: viewModel.goToNextStep
        ) {
            VStack(spacing: 12) {
                ForEach(Availability.allCases, id: \.self) { availability in
                    AvailabilityCard(
                        availability: availability,
                        isSelected: viewModel.selectedAvailability == availability,
                        action: { viewModel.selectAvailability(availability) }
                    )
                }
            }
        }
    }
}

/// Availability selection card
struct AvailabilityCard: View {
    let availability: Availability
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            HStack(spacing: 14) {
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .appAccent : .appSecondaryText)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(availability.displayName)
                        .font(.body.weight(.medium))
                        .foregroundColor(.appPrimaryText)

                    Text(availability.description)
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(hoursRange)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(isSelected ? .appAccent : .appSecondaryText)

                    Text("hours/week")
                        .font(.caption)
                        .foregroundColor(.appTertiaryText)
                }

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appAccent)
                        .font(.system(size: 22))
                }
            }
        }
    }

    private var iconName: String {
        switch availability {
        case .busy: return "clock.badge.exclamationmark"
        case .normal: return "clock"
        case .open: return "clock.badge.checkmark"
        }
    }

    private var hoursRange: String {
        let range = availability.hoursPerWeek
        return "\(range.lowerBound)-\(range.upperBound)"
    }
}

// MARK: - Preview

#Preview {
    AvailabilityView(viewModel: OnboardingViewModel())
}
