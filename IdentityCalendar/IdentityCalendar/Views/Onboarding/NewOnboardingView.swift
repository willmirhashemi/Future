import SwiftUI

/// New AI-powered onboarding with free-form goal input
struct NewOnboardingView: View {
    @StateObject private var viewModel = NewOnboardingViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.appColorScheme) private var appColorScheme

    var onComplete: (() -> Void)?

    var body: some View {
        ZStack {
            AppTheme.background(appColorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                switch viewModel.currentStep {
                case .welcome:
                    WelcomeStepView(onContinue: viewModel.goToGoalInput)

                case .goalInput:
                    GoalInputStepView(
                        goalText: $viewModel.goalText,
                        isProcessing: viewModel.isProcessing,
                        onSubmit: viewModel.processGoal,
                        onBack: viewModel.goToWelcome
                    )

                case .processing:
                    ProcessingStepView()

                case .planPreview:
                    PlanPreviewStepView(
                        plan: viewModel.generatedPlan,
                        onAccept: {
                            viewModel.acceptPlan()
                            onComplete?()
                        },
                        onRegenerate: viewModel.regeneratePlan
                    )

                case .error:
                    ErrorStepView(
                        message: viewModel.errorMessage ?? "Something went wrong",
                        onRetry: viewModel.retryProcessing,
                        onBack: viewModel.goToGoalInput
                    )
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
    }
}

// MARK: - Welcome Step

struct WelcomeStepView: View {
    @Environment(\.appColorScheme) private var colorScheme
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Logo/Icon
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 50))
                    .foregroundColor(AppTheme.accent)
            }

            VStack(spacing: 16) {
                Text("Your Future Starts Here")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))
                    .multilineTextAlignment(.center)

                Text("Tell us your goals and we'll create a personalized plan to help you achieve them.")
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Features preview
            VStack(spacing: 16) {
                FeatureRow(icon: "brain.head.profile", text: "AI-powered planning", colorScheme: colorScheme)
                FeatureRow(icon: "calendar", text: "Smart calendar integration", colorScheme: colorScheme)
                FeatureRow(icon: "arrow.triangle.2.circlepath", text: "Adaptive scheduling", colorScheme: colorScheme)
            }
            .padding(.horizontal, 32)

            Spacer()

            // CTA
            Button(action: onContinue) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppTheme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.accent)
                .frame(width: 32)

            Text(text)
                .font(.subheadline)
                .foregroundColor(AppTheme.secondaryText(colorScheme))

            Spacer()
        }
    }
}

// MARK: - Goal Input Step

struct GoalInputStepView: View {
    @Environment(\.appColorScheme) private var colorScheme
    @Binding var goalText: String
    let isProcessing: Bool
    let onSubmit: () -> Void
    let onBack: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What's your goal?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))

                        Text("Describe what you want to achieve. Be as specific as you'd like.")
                            .font(.body)
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                    }
                    .padding(.top, 20)

                    // Text input area
                    ZStack(alignment: .topLeading) {
                        if goalText.isEmpty {
                            Text("Example: I want to break into investment banking. I'm a freshman at University of Illinois and want to secure internships and job offers over the next 4 years...")
                                .font(.body)
                                .foregroundColor(AppTheme.tertiaryText(colorScheme))
                                .padding(16)
                        }

                        TextEditor(text: $goalText)
                            .font(.body)
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                            .scrollContentBackground(.hidden)
                            .padding(12)
                            .focused($isTextFieldFocused)
                    }
                    .frame(minHeight: 200)
                    .background(AppTheme.secondaryBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips for better results:")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))

                        TipRow(text: "Include your current situation", colorScheme: colorScheme)
                        TipRow(text: "Mention your timeline", colorScheme: colorScheme)
                        TipRow(text: "Be specific about what success looks like", colorScheme: colorScheme)
                    }
                    .padding(16)
                    .background(AppTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 20)
            }

            // Submit button
            VStack(spacing: 16) {
                Button(action: onSubmit) {
                    HStack(spacing: 8) {
                        if isProcessing {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "sparkles")
                            Text("Create My Plan")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(goalText.count >= 20 ? AppTheme.accent : AppTheme.accent.opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(goalText.count < 20 || isProcessing)

                Text("\(goalText.count) characters • minimum 20")
                    .font(.caption)
                    .foregroundColor(AppTheme.tertiaryText(colorScheme))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

struct TipRow: View {
    let text: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 6, height: 6)

            Text(text)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText(colorScheme))
        }
    }
}

// MARK: - Processing Step

struct ProcessingStepView: View {
    @Environment(\.appColorScheme) private var colorScheme
    @State private var animationPhase = 0
    @State private var currentMessage = 0

    let messages = [
        "Analyzing your goals...",
        "Creating milestones...",
        "Building your schedule...",
        "Optimizing for success..."
    ]

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Animated icon
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.1))
                    .frame(width: 140, height: 140)
                    .scaleEffect(animationPhase > 0 ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: animationPhase
                    )

                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.accent)
            }

            VStack(spacing: 12) {
                Text("Creating Your Plan")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text(messages[currentMessage])
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .animation(.easeInOut, value: currentMessage)
            }

            Spacer()
            Spacer()
        }
        .onAppear {
            animationPhase = 1
            // Cycle through messages
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { timer in
                withAnimation {
                    currentMessage = (currentMessage + 1) % messages.count
                }
            }
        }
    }
}

// MARK: - Plan Preview Step

struct PlanPreviewStepView: View {
    @Environment(\.appColorScheme) private var colorScheme
    let plan: GeneratedPlan?
    let onAccept: () -> Void
    let onRegenerate: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.success)
                            Text("Plan Created")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(AppTheme.success)
                        }

                        Text("Your Personalized Path")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                    }
                    .padding(.top, 20)

                    if let plan = plan {
                        // Goal summary
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goal")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.secondaryText(colorScheme))

                            Text(plan.goalSummary)
                                .font(.body)
                                .foregroundColor(AppTheme.primaryText(colorScheme))
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        // Timeline
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Timeline: \(plan.timelineDescription)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.secondaryText(colorScheme))

                            // Milestones
                            ForEach(Array(plan.milestones.enumerated()), id: \.offset) { index, milestone in
                                MilestonePreviewRow(
                                    number: index + 1,
                                    title: milestone.title,
                                    timeframe: milestone.timeframe,
                                    colorScheme: colorScheme
                                )
                            }
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        // Weekly commitment
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Weekly Commitment")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                                Text("\(plan.weeklyHours) hours")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(AppTheme.primaryText(colorScheme))
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Sessions/Week")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                                Text("\(plan.sessionsPerWeek)")
                                    .font(.title3.weight(.bold))
                                    .foregroundColor(AppTheme.primaryText(colorScheme))
                            }
                        }
                        .padding(16)
                        .background(AppTheme.cardBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                }
                .padding(.horizontal, 20)
            }

            // Actions
            VStack(spacing: 12) {
                Button(action: onAccept) {
                    Text("Start My Journey")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(action: onRegenerate) {
                    Text("Regenerate Plan")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

struct MilestonePreviewRow: View {
    let number: Int
    let title: String
    let timeframe: String
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accent.opacity(0.15))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(AppTheme.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text(timeframe)
                    .font(.caption)
                    .foregroundColor(AppTheme.tertiaryText(colorScheme))
            }

            Spacer()
        }
    }
}

// MARK: - Error Step

struct ErrorStepView: View {
    @Environment(\.appColorScheme) private var colorScheme
    let message: String
    let onRetry: () -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                Circle()
                    .fill(AppTheme.error.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.error)
            }

            VStack(spacing: 12) {
                Text("Something Went Wrong")
                    .font(.title2.weight(.bold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Text(message)
                    .font(.body)
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                Button(action: onRetry) {
                    Text("Try Again")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                Button(action: onBack) {
                    Text("Edit Goal")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Preview

#Preview {
    NewOnboardingView()
        .themed()
}
