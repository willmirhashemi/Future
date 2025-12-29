import SwiftUI

/// Step 4: Intensity selection
struct IntensityView: View {
    @ObservedObject var viewModel: OnboardingViewModel

    var body: some View {
        OnboardingStepView(
            title: "How intense should we go?",
            subtitle: "This affects how much we schedule",
            showBackButton: true,
            canProceed: viewModel.canProceed,
            buttonTitle: "Continue",
            onBack: viewModel.goToPreviousStep,
            onNext: viewModel.goToNextStep
        ) {
            VStack(spacing: 12) {
                ForEach(Intensity.allCases, id: \.self) { intensity in
                    IntensityCard(
                        intensity: intensity,
                        isSelected: viewModel.selectedIntensity == intensity,
                        action: { viewModel.selectIntensity(intensity) }
                    )
                }
            }
        }
    }
}

/// Intensity selection card
struct IntensityCard: View {
    let intensity: Intensity
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            HStack(spacing: 14) {
                // Intensity indicator dots
                HStack(spacing: 4) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(dotColor(for: index))
                            .frame(width: 8, height: 8)
                    }
                }
                .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text(intensity.displayName)
                        .font(.body.weight(.medium))
                        .foregroundColor(.appPrimaryText)

                    Text(intensity.description)
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

    private func dotColor(for index: Int) -> Color {
        let activeCount: Int
        switch intensity {
        case .light: activeCount = 1
        case .balanced: activeCount = 2
        case .aggressive: activeCount = 3
        }

        if index < activeCount {
            return isSelected ? .appAccent : .appSecondaryText
        } else {
            return .appSecondaryBackground
        }
    }
}

// MARK: - Preview

#Preview {
    IntensityView(viewModel: OnboardingViewModel())
}
