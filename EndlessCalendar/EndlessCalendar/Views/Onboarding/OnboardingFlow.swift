import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var geminiService = GeminiService()
    @StateObject private var firestoreService = FirestoreService()

    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedCategory: GoalCategory?
    @State private var questionnaireResponses = QuestionnaireResponses()
    @State private var isGeneratingPlan = false
    @State private var showError = false
    @State private var errorMessage = ""

    enum OnboardingStep {
        case welcome
        case categorySelection
        case questionnaire
        case generating
    }

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack {
                // Progress Indicator
                progressIndicator

                // Content
                TabView(selection: $currentStep) {
                    WelcomeStep(onContinue: { currentStep = .categorySelection })
                        .tag(OnboardingStep.welcome)

                    CategorySelectionStep(
                        selectedCategory: $selectedCategory,
                        onContinue: { currentStep = .questionnaire }
                    )
                    .tag(OnboardingStep.categorySelection)

                    QuestionnaireStep(
                        category: selectedCategory ?? .studyLearning,
                        responses: $questionnaireResponses,
                        onContinue: { generatePlan() }
                    )
                    .tag(OnboardingStep.questionnaire)

                    GeneratingStep()
                        .tag(OnboardingStep.generating)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(0..<4) { index in
                Capsule()
                    .fill(stepIndex >= index ? Theme.Colors.accent : Theme.Colors.textTertiary)
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, Theme.Spacing.md)
    }

    private var stepIndex: Int {
        switch currentStep {
        case .welcome: return 0
        case .categorySelection: return 1
        case .questionnaire: return 2
        case .generating: return 3
        }
    }

    // MARK: - Generate Plan
    private func generatePlan() {
        guard let category = selectedCategory else { return }

        currentStep = .generating

        Task {
            do {
                // Generate AI plan
                let events = try await geminiService.generatePersonalizedPlan(
                    userId: authService.currentUser?.id ?? "",
                    category: category,
                    responses: questionnaireResponses
                )

                // Save events to Firestore
                _ = try await firestoreService.createEvents(events)

                // Complete onboarding
                try await authService.completeOnboarding(
                    category: category,
                    responses: questionnaireResponses
                )

                // Schedule notifications
                await NotificationService.shared.scheduleWeeklyReviewReminder()
                await NotificationService.shared.scheduleRemindersForEvents(events)

            } catch {
                errorMessage = error.localizedDescription
                showError = true
                currentStep = .questionnaire
            }
        }
    }
}

// MARK: - Welcome Step
struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: Theme.Spacing.lg) {
                Image(systemName: "sparkles")
                    .font(.system(size: 60))
                    .foregroundColor(Theme.Colors.accent)

                Text("Welcome to Your Journey")
                    .font(Theme.Fonts.title())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Let's create a personalized plan to help you achieve your dreams. Our AI will generate a comprehensive calendar tailored just for you.")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }

            Spacer()

            // Features List
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                FeatureRow(icon: "brain.head.profile", text: "AI-powered personalized planning")
                FeatureRow(icon: "calendar", text: "Daily tasks tailored to your goals")
                FeatureRow(icon: "book", text: "Journal to track your progress")
                FeatureRow(icon: "trophy", text: "Achievements to keep you motivated")
            }
            .padding(.horizontal, Theme.Spacing.xl)

            Spacer()

            Button("Get Started") {
                onContinue()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 32)

            Text(text)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()
        }
    }
}

// MARK: - Category Selection Step
struct CategorySelectionStep: View {
    @Binding var selectedCategory: GoalCategory?
    let onContinue: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: Theme.Spacing.sm) {
                Text("Choose Your Focus")
                    .font(Theme.Fonts.title())
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("Select the area you want to focus on. You can only choose one category.")
                    .font(Theme.Fonts.subheadline())
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(.top, Theme.Spacing.lg)

            ScrollView {
                LazyVGrid(columns: columns, spacing: Theme.Spacing.md) {
                    ForEach(GoalCategory.allCases) { category in
                        CategoryCard(
                            category: category,
                            isSelected: selectedCategory == category
                        ) {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = category
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }

            Button("Continue") {
                onContinue()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selectedCategory == nil)
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }
}

struct CategoryCard: View {
    let category: GoalCategory
    let isSelected: Bool
    let onTap: () -> Void

    private var categoryColor: Color {
        switch category {
        case .studyLearning: return Theme.Colors.studyLearning
        case .fitnessHealth: return Theme.Colors.fitnessHealth
        case .financial: return Theme.Colors.financial
        case .creativeHobby: return Theme.Colors.creativeHobby
        case .networkingSocial: return Theme.Colors.networkingSocial
        case .selfCareRest: return Theme.Colors.selfCareRest
        case .careerDevelopment: return Theme.Colors.careerDevelopment
        }
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: Theme.Spacing.sm) {
                ZStack {
                    Circle()
                        .fill(categoryColor.opacity(0.2))
                        .frame(width: 60, height: 60)

                    Image(systemName: category.icon)
                        .font(.title2)
                        .foregroundColor(categoryColor)
                }

                Text(category.displayName)
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(category.description)
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(isSelected ? categoryColor.opacity(0.15) : Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.large)
                    .stroke(isSelected ? categoryColor : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Questionnaire Step
struct QuestionnaireStep: View {
    let category: GoalCategory
    @Binding var responses: QuestionnaireResponses
    let onContinue: () -> Void

    @State private var currentQuestion = 0

    private let totalQuestions = 8

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            // Question Progress
            VStack(spacing: Theme.Spacing.xs) {
                Text("Question \(currentQuestion + 1) of \(totalQuestions)")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textSecondary)

                ProgressView(value: Double(currentQuestion + 1), total: Double(totalQuestions))
                    .progressViewStyle(LinearProgressViewStyle(tint: Theme.Colors.accent))
                    .padding(.horizontal, Theme.Spacing.lg)
            }
            .padding(.top, Theme.Spacing.lg)

            // Question Content
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    questionContent
                }
                .padding(.horizontal, Theme.Spacing.lg)
            }

            // Navigation Buttons
            HStack(spacing: Theme.Spacing.md) {
                if currentQuestion > 0 {
                    Button("Back") {
                        withAnimation {
                            currentQuestion -= 1
                        }
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }

                Button(currentQuestion == totalQuestions - 1 ? "Generate My Plan" : "Next") {
                    if currentQuestion == totalQuestions - 1 {
                        onContinue()
                    } else {
                        withAnimation {
                            currentQuestion += 1
                        }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!isCurrentQuestionValid)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xxl)
        }
    }

    @ViewBuilder
    private var questionContent: some View {
        switch currentQuestion {
        case 0:
            QuestionView(
                title: "How old are you?",
                subtitle: "This helps us tailor activities appropriate for your age"
            ) {
                Stepper(value: $responses.age, in: 13...100) {
                    Text("\(responses.age) years old")
                        .font(Theme.Fonts.title2())
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
            }

        case 1:
            QuestionView(
                title: "What's your education level?",
                subtitle: "We'll adjust the complexity of your plan accordingly"
            ) {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(EducationLevel.allCases, id: \.self) { level in
                        SelectionRow(
                            title: level.displayName,
                            isSelected: responses.educationLevel == level
                        ) {
                            responses.educationLevel = level
                        }
                    }
                }
            }

        case 2:
            QuestionView(
                title: "What's your current occupation?",
                subtitle: "Student, employed, self-employed, etc."
            ) {
                CustomTextField(
                    icon: "briefcase",
                    placeholder: "e.g., College Student, Software Engineer",
                    text: $responses.currentOccupation
                )
            }

        case 3:
            QuestionView(
                title: "How would you describe your financial situation?",
                subtitle: "This helps us suggest realistic activities"
            ) {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(FinancialSituation.allCases, id: \.self) { situation in
                        SelectionRow(
                            title: situation.displayName,
                            isSelected: responses.financialSituation == situation
                        ) {
                            responses.financialSituation = situation
                        }
                    }
                }
            }

        case 4:
            QuestionView(
                title: "Describe your specific goal",
                subtitle: "Be as detailed as possible - what do you want to achieve in \(category.displayName.lowercased())?"
            ) {
                TextEditor(text: $responses.specificGoal)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .frame(minHeight: 150)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.cardBackground)
                    .cornerRadius(Theme.CornerRadius.medium)
                    .overlay(
                        Group {
                            if responses.specificGoal.isEmpty {
                                Text("e.g., I want to learn Spanish to be conversational in 6 months...")
                                    .font(Theme.Fonts.body())
                                    .foregroundColor(Theme.Colors.textTertiary)
                                    .padding(Theme.Spacing.md)
                                    .allowsHitTesting(false)
                            }
                        },
                        alignment: .topLeading
                    )
            }

        case 5:
            QuestionView(
                title: "What's your timeframe?",
                subtitle: "When do you want to achieve this goal?"
            ) {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(GoalTimeframe.allCases, id: \.self) { timeframe in
                        SelectionRow(
                            title: timeframe.displayName,
                            isSelected: responses.timeframe == timeframe
                        ) {
                            responses.timeframe = timeframe
                        }
                    }
                }
            }

        case 6:
            QuestionView(
                title: "How many hours can you dedicate daily?",
                subtitle: "Be realistic - consistency beats intensity"
            ) {
                Stepper(value: $responses.availableHoursPerDay, in: 1...8) {
                    Text("\(responses.availableHoursPerDay) hour\(responses.availableHoursPerDay == 1 ? "" : "s") per day")
                        .font(Theme.Fonts.title2())
                        .foregroundColor(Theme.Colors.textPrimary)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
            }

        case 7:
            QuestionView(
                title: "When do you prefer to work on your goals?",
                subtitle: "We'll schedule most activities during this time"
            ) {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(PreferredTime.allCases, id: \.self) { time in
                        SelectionRow(
                            title: time.displayName,
                            isSelected: responses.preferredTimeOfDay == time
                        ) {
                            responses.preferredTimeOfDay = time
                        }
                    }
                }
            }

        default:
            EmptyView()
        }
    }

    private var isCurrentQuestionValid: Bool {
        switch currentQuestion {
        case 2: return !responses.currentOccupation.isEmpty
        case 4: return !responses.specificGoal.isEmpty
        default: return true
        }
    }
}

struct QuestionView<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Fonts.title2())
                    .foregroundColor(Theme.Colors.textPrimary)

                Text(subtitle)
                    .font(Theme.Fonts.subheadline())
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            content
        }
    }
}

struct SelectionRow: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(title)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.accent)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(isSelected ? Theme.Colors.accent.opacity(0.1) : Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Generating Step
struct GeneratingStep: View {
    @State private var animationPhase = 0

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            VStack(spacing: Theme.Spacing.lg) {
                ZStack {
                    Circle()
                        .stroke(Theme.Colors.accent.opacity(0.2), lineWidth: 4)
                        .frame(width: 120, height: 120)

                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(Double(animationPhase) * 360))

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 40))
                        .foregroundColor(Theme.Colors.accent)
                }

                Text("Creating Your Plan")
                    .font(Theme.Fonts.title())
                    .foregroundColor(Theme.Colors.textPrimary)

                Text("Our AI is analyzing your goals and creating a personalized schedule just for you...")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            Spacer()

            // Loading tips
            VStack(spacing: Theme.Spacing.md) {
                Text("Did you know?")
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.accent)

                Text("Consistent small steps lead to big achievements. Your plan will include daily manageable tasks.")
                    .font(Theme.Fonts.subheadline())
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(Theme.Spacing.lg)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.large)
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                animationPhase = 1
            }
        }
    }
}

#Preview {
    OnboardingFlow()
        .environmentObject(AuthService())
        .environmentObject(ThemeManager())
}
