import SwiftUI

/// Weekly reflection flow triggered on Sundays
struct WeeklyReflectionView: View {
    @StateObject private var viewModel = ReflectionViewModel()
    @Environment(\.dismiss) private var dismiss

    let onComplete: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Progress bar
                    if viewModel.currentStep != .complete {
                        OnboardingProgressBar(progress: viewModel.progressValue)
                            .padding(.horizontal, Constants.Layout.screenPadding)
                            .padding(.top, 8)
                    }

                    // Content
                    switch viewModel.currentStep {
                    case .feeling:
                        FeelingStepView(viewModel: viewModel)
                    case .obstacle:
                        ObstacleStepView(viewModel: viewModel)
                    case .note:
                        NoteStepView(viewModel: viewModel)
                    case .processing:
                        ProcessingView(viewModel: viewModel)
                    case .complete:
                        CompleteView(viewModel: viewModel, onDone: {
                            onComplete()
                            dismiss()
                        })
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.currentStep != .processing && viewModel.currentStep != .complete {
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            }
            .interactiveDismissDisabled(viewModel.currentStep == .processing)
        }
    }
}

/// Step 1: How did the week feel?
struct FeelingStepView: View {
    @ObservedObject var viewModel: ReflectionViewModel

    var body: some View {
        OnboardingStepView(
            title: "How did this week feel?",
            subtitle: "Be honest — this helps us adapt",
            showBackButton: false,
            canProceed: viewModel.canProceed,
            buttonTitle: "Continue",
            onBack: {},
            onNext: viewModel.goToNextStep
        ) {
            VStack(spacing: 12) {
                ForEach(WeekFeeling.allCases, id: \.self) { feeling in
                    FeelingCard(
                        feeling: feeling,
                        isSelected: viewModel.selectedFeeling == feeling,
                        action: { viewModel.selectFeeling(feeling) }
                    )
                }

                // Week stats summary
                if let stats = viewModel.weekStats, stats.total > 0 {
                    WeekStatsSummary(
                        completed: stats.completed,
                        skipped: stats.skipped,
                        total: stats.total
                    )
                    .padding(.top, 16)
                }
            }
        }
    }
}

/// Feeling selection card
struct FeelingCard: View {
    let feeling: WeekFeeling
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            HStack(spacing: 14) {
                Image(systemName: feeling.icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .appAccent : .appSecondaryText)
                    .frame(width: 32)

                Text(feeling.displayName)
                    .font(.body.weight(.medium))
                    .foregroundColor(.appPrimaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appAccent)
                        .font(.system(size: 22))
                }
            }
        }
    }
}

/// Week stats summary
struct WeekStatsSummary: View {
    let completed: Int
    let skipped: Int
    let total: Int

    var body: some View {
        HStack(spacing: 20) {
            StatItem(value: "\(completed)/\(total)", label: "Completed")
            StatItem(value: "\(skipped)", label: "Skipped")
            StatItem(value: "\(Int((Double(completed) / Double(total)) * 100))%", label: "Rate")
        }
        .padding(16)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

/// Stat item
struct StatItem: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundColor(.appPrimaryText)

            Text(label)
                .font(.caption)
                .foregroundColor(.appSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Step 2: What got in the way?
struct ObstacleStepView: View {
    @ObservedObject var viewModel: ReflectionViewModel

    var body: some View {
        OnboardingStepView(
            title: "What got in the way?",
            subtitle: "Optional, but helps us understand",
            showBackButton: true,
            canProceed: true,
            buttonTitle: viewModel.selectedObstacle == nil ? "Skip" : "Continue",
            onBack: viewModel.goToPreviousStep,
            onNext: viewModel.goToNextStep
        ) {
            VStack(spacing: 12) {
                ForEach(WeekObstacle.allCases, id: \.self) { obstacle in
                    ObstacleCard(
                        obstacle: obstacle,
                        isSelected: viewModel.selectedObstacle == obstacle,
                        action: {
                            if viewModel.selectedObstacle == obstacle {
                                viewModel.selectObstacle(nil)
                            } else {
                                viewModel.selectObstacle(obstacle)
                            }
                        }
                    )
                }
            }
        }
    }
}

/// Obstacle selection card
struct ObstacleCard: View {
    let obstacle: WeekObstacle
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            HStack(spacing: 14) {
                Image(systemName: obstacle.icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .appAccent : .appSecondaryText)
                    .frame(width: 32)

                Text(obstacle.displayName)
                    .font(.body.weight(.medium))
                    .foregroundColor(.appPrimaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appAccent)
                        .font(.system(size: 22))
                }
            }
        }
    }
}

/// Step 3: Optional note
struct NoteStepView: View {
    @ObservedObject var viewModel: ReflectionViewModel
    @FocusState private var isFocused: Bool

    var body: some View {
        OnboardingStepView(
            title: "Anything else?",
            subtitle: "Optional quick note",
            showBackButton: true,
            canProceed: true,
            buttonTitle: "Submit reflection",
            onBack: viewModel.goToPreviousStep,
            onNext: viewModel.goToNextStep
        ) {
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $viewModel.note)
                    .font(.body)
                    .foregroundColor(.appPrimaryText)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .focused($isFocused)

                Text("\(viewModel.note.count)/\(Constants.Limits.maxNoteLength)")
                    .font(.caption)
                    .foregroundColor(.appTertiaryText)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .onAppear {
                isFocused = true
            }
        }
    }
}

/// Processing view
struct ProcessingView: View {
    @ObservedObject var viewModel: ReflectionViewModel
    @State private var animationPhase = 0

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.1))
                    .frame(width: 100, height: 100)

                Circle()
                    .fill(Color.appAccent.opacity(0.05))
                    .frame(width: 140, height: 140)
                    .scaleEffect(animationPhase > 0 ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: animationPhase
                    )

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .appAccent))
                    .scaleEffect(1.3)
            }

            VStack(spacing: 8) {
                Text("Adjusting your plan")
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.appPrimaryText)

                Text("AI is adapting your upcoming week")
                    .font(.body)
                    .foregroundColor(.appSecondaryText)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            animationPhase = 1
        }
    }
}

/// Complete view with summary
struct CompleteView: View {
    @ObservedObject var viewModel: ReflectionViewModel
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success icon
            ZStack {
                Circle()
                    .fill(Color.appSuccess.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.appSuccess)
            }

            VStack(spacing: 12) {
                Text("All set")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.appPrimaryText)

                if let summary = viewModel.adaptationSummary {
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.appSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                } else {
                    Text("Your plan has been updated based on your feedback")
                        .font(.body)
                        .foregroundColor(.appSecondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
            }

            // AI adaptation confirmation
            AIAdaptationConfirmation()
                .padding(.top, 16)

            Spacer()

            PrimaryButton(title: "Done", action: onDone)
                .padding(.horizontal, Constants.Layout.screenPadding)
                .padding(.bottom, 32)
        }
    }
}

/// AI adaptation confirmation card - shows users that AI has adjusted their plan
struct AIAdaptationConfirmation: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 24))
                .foregroundColor(.appAccent)

            Text("AI Plan Adjusted")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.appPrimaryText)

            Text("Your upcoming week has been optimized based on your reflection")
                .font(.caption)
                .foregroundColor(.appSecondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, Constants.Layout.screenPadding)
    }
}

// MARK: - Preview

#Preview {
    WeeklyReflectionView(onComplete: {})
}
