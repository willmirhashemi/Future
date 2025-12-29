import SwiftUI

/// Step 1: Identity selection
struct IdentitySelectionView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        OnboardingStepView(
            title: "Who do you want to become?",
            subtitle: nil,
            showBackButton: false,
            canProceed: viewModel.canProceed,
            buttonTitle: "Continue",
            onBack: {},
            onNext: viewModel.goToNextStep
        ) {
            VStack(spacing: 12) {
                ForEach(IdentityType.allCases, id: \.self) { identity in
                    if identity == .custom {
                        // Custom identity with text field
                        CustomIdentityCard(
                            isSelected: viewModel.selectedIdentity == .custom,
                            customName: $viewModel.customIdentityName,
                            isFocused: $isTextFieldFocused,
                            action: {
                                viewModel.selectIdentity(.custom)
                                isTextFieldFocused = true
                            }
                        )
                    } else {
                        IdentityCard(
                            identity: identity,
                            isSelected: viewModel.selectedIdentity == identity,
                            action: {
                                viewModel.selectIdentity(identity)
                                isTextFieldFocused = false
                            }
                        )
                    }
                }
            }
        }
    }
}

/// Custom identity input card
struct CustomIdentityCard: View {
    let isSelected: Bool
    @Binding var customName: String
    @FocusState.Binding var isFocused: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            HStack(spacing: 14) {
                Image(systemName: "star")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .appAccent : .appSecondaryText)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom")
                        .font(.body.weight(.medium))
                        .foregroundColor(.appPrimaryText)

                    if isSelected {
                        TextField("What do you want to become?", text: $customName)
                            .font(.subheadline)
                            .foregroundColor(.appPrimaryText)
                            .focused($isFocused)
                            .textFieldStyle(.plain)
                            .submitLabel(.done)
                    } else {
                        Text("Define your own path")
                            .font(.subheadline)
                            .foregroundColor(.appSecondaryText)
                    }
                }

                Spacer()

                if isSelected && !customName.isEmpty {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appAccent)
                        .font(.system(size: 22))
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    IdentitySelectionView(viewModel: OnboardingViewModel())
}
