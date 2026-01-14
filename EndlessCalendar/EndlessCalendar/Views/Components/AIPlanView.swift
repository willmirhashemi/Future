import SwiftUI

// MARK: - AI Plan Overview View
struct AIPlanView: View {
    let plan: AIPlanResponse
    @State private var expandedSections: Set<String> = ["strategy"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Goal Header
                goalHeader

                // Strategy Summary
                strategySummarySection

                // Phases
                phasesSection

                // Risk Flags
                if !plan.plan.riskFlags.isEmpty {
                    riskFlagsSection
                }

                // Schedule Actions Preview
                scheduleActionsSection

                // Unknowns to Clarify
                if !plan.unknownsToClarify.isEmpty {
                    unknownsSection
                }

                // Sources
                if !plan.sources.isEmpty {
                    sourcesSection
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background)
    }

    // MARK: - Goal Header
    private var goalHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Image(systemName: "target")
                    .font(.title2)
                    .foregroundColor(Theme.Colors.accent)

                Text(plan.goal.title)
                    .font(Theme.Fonts.title2())
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            Text(plan.goal.category)
                .font(Theme.Fonts.subheadline())
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.horizontal, Theme.Spacing.sm)
                .padding(.vertical, Theme.Spacing.xxs)
                .background(Theme.Colors.accent.opacity(0.2))
                .cornerRadius(Theme.CornerRadius.small)

            // Success Definition
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Success looks like:")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textTertiary)

                ForEach(plan.goal.successDefinition, id: \.self) { definition in
                    HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(Theme.Colors.success)

                        Text(definition)
                            .font(Theme.Fonts.subheadline())
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)

            // What AI Understood
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("AI Interpretation")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textTertiary)

                Text(plan.interpretation.whatUserIsReallyTryingToDo)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)

                if !plan.interpretation.leveragePoints.isEmpty {
                    Text("Key leverage points:")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.accent)
                        .padding(.top, Theme.Spacing.xs)

                    ForEach(plan.interpretation.leveragePoints, id: \.self) { point in
                        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(Theme.Colors.studyLearning)

                            Text(point)
                                .font(Theme.Fonts.caption())
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Strategy Summary Section
    private var strategySummarySection: some View {
        CollapsibleSection(
            title: "Strategy",
            icon: "lightbulb.fill",
            isExpanded: expandedSections.contains("strategy")
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(plan.plan.strategySummary)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)

                // Confidence Meter
                HStack {
                    Text("AI Confidence:")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)

                    ConfidenceMeter(confidence: plan.plan.confidence)

                    Text("\(Int(plan.plan.confidence * 100))%")
                        .font(Theme.Fonts.caption())
                        .fontWeight(.semibold)
                        .foregroundColor(confidenceColor)
                }

                // Time Profile
                HStack(spacing: Theme.Spacing.lg) {
                    StatBadge(
                        icon: "calendar",
                        value: "\(plan.userProfile.timeHorizonMonths)",
                        label: "months"
                    )

                    StatBadge(
                        icon: "clock",
                        value: "\(plan.userProfile.hoursPerWeek)",
                        label: "hrs/week"
                    )

                    StatBadge(
                        icon: "flame.fill",
                        value: "\(plan.userProfile.ambitionLevel)",
                        label: "ambition"
                    )
                }
            }
        } onToggle: {
            toggleSection("strategy")
        }
    }

    private var confidenceColor: Color {
        if plan.plan.confidence >= 0.8 {
            return Theme.Colors.success
        } else if plan.plan.confidence >= 0.6 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.error
        }
    }

    // MARK: - Phases Section
    private var phasesSection: some View {
        CollapsibleSection(
            title: "Phases (\(plan.plan.phases.count))",
            icon: "arrow.right.circle.fill",
            isExpanded: expandedSections.contains("phases")
        ) {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(Array(plan.plan.phases.enumerated()), id: \.element.name) { index, phase in
                    PhaseCard(phase: phase, phaseNumber: index + 1)
                }
            }
        } onToggle: {
            toggleSection("phases")
        }
    }

    // MARK: - Risk Flags Section
    private var riskFlagsSection: some View {
        CollapsibleSection(
            title: "Risk Flags",
            icon: "exclamationmark.triangle.fill",
            iconColor: Theme.Colors.warning,
            isExpanded: expandedSections.contains("risks")
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                ForEach(plan.plan.riskFlags, id: \.self) { risk in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(Theme.Colors.warning)
                            .font(.caption)

                        Text(risk)
                            .font(Theme.Fonts.subheadline())
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                }
            }
        } onToggle: {
            toggleSection("risks")
        }
    }

    // MARK: - Schedule Actions Section
    private var scheduleActionsSection: some View {
        CollapsibleSection(
            title: "Scheduled Actions (\(plan.scheduleActions.count))",
            icon: "calendar.badge.clock",
            isExpanded: expandedSections.contains("actions")
        ) {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(plan.scheduleActions.prefix(5)) { action in
                    ScheduleActionRow(action: action)
                }

                if plan.scheduleActions.count > 5 {
                    Text("+ \(plan.scheduleActions.count - 5) more actions")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textTertiary)
                        .padding(.top, Theme.Spacing.xs)
                }
            }
        } onToggle: {
            toggleSection("actions")
        }
    }

    // MARK: - Unknowns Section
    private var unknownsSection: some View {
        CollapsibleSection(
            title: "Clarification Needed",
            icon: "questionmark.circle.fill",
            iconColor: Theme.Colors.info,
            isExpanded: expandedSections.contains("unknowns")
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(plan.unknownsToClarify) { unknown in
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        HStack {
                            Text(unknown.field)
                                .font(Theme.Fonts.caption())
                                .foregroundColor(Theme.Colors.accent)

                            Spacer()

                            Text(unknown.priority.rawValue.uppercased())
                                .font(Theme.Fonts.caption2())
                                .foregroundColor(unknown.priority == .high ? Theme.Colors.error : Theme.Colors.warning)
                                .padding(.horizontal, Theme.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(
                                    (unknown.priority == .high ? Theme.Colors.error : Theme.Colors.warning).opacity(0.2)
                                )
                                .cornerRadius(4)
                        }

                        Text(unknown.question)
                            .font(Theme.Fonts.subheadline())
                            .foregroundColor(Theme.Colors.textPrimary)
                    }
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.tertiaryBackground)
                    .cornerRadius(Theme.CornerRadius.small)
                }

                if !plan.assumptionsIfUserDoesntAnswer.isEmpty {
                    Text("If not answered, AI will assume:")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textTertiary)
                        .padding(.top, Theme.Spacing.xs)

                    ForEach(plan.assumptionsIfUserDoesntAnswer, id: \.self) { assumption in
                        Text("• \(assumption)")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }
        } onToggle: {
            toggleSection("unknowns")
        }
    }

    // MARK: - Sources Section
    private var sourcesSection: some View {
        CollapsibleSection(
            title: "Sources",
            icon: "link.circle.fill",
            isExpanded: expandedSections.contains("sources")
        ) {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(plan.sources) { source in
                    SourceRow(source: source)
                }
            }
        } onToggle: {
            toggleSection("sources")
        }
    }

    // MARK: - Helper
    private func toggleSection(_ section: String) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if expandedSections.contains(section) {
                expandedSections.remove(section)
            } else {
                expandedSections.insert(section)
            }
        }
    }
}

// MARK: - Collapsible Section
struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    var iconColor: Color = Theme.Colors.accent
    let isExpanded: Bool
    @ViewBuilder let content: Content
    let onToggle: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)

                    Text(title)
                        .font(Theme.Fonts.headline())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(Theme.Colors.textTertiary)
                        .font(.caption)
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
            }

            if isExpanded {
                content
                    .padding(Theme.Spacing.md)
                    .background(Theme.Colors.cardBackground.opacity(0.5))
            }
        }
        .cornerRadius(Theme.CornerRadius.medium)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                .stroke(Theme.Colors.textTertiary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Confidence Meter
struct ConfidenceMeter: View {
    let confidence: Double

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Theme.Colors.tertiaryBackground)

                RoundedRectangle(cornerRadius: 4)
                    .fill(meterColor)
                    .frame(width: geometry.size.width * confidence)
            }
        }
        .frame(width: 100, height: 8)
    }

    private var meterColor: Color {
        if confidence >= 0.8 {
            return Theme.Colors.success
        } else if confidence >= 0.6 {
            return Theme.Colors.warning
        } else {
            return Theme.Colors.error
        }
    }
}

// MARK: - Stat Badge
struct StatBadge: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(Theme.Colors.accent)

                Text(value)
                    .font(Theme.Fonts.headline())
                    .foregroundColor(Theme.Colors.textPrimary)
            }

            Text(label)
                .font(Theme.Fonts.caption2())
                .foregroundColor(Theme.Colors.textTertiary)
        }
        .padding(.horizontal, Theme.Spacing.sm)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.tertiaryBackground)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

// MARK: - Phase Card
struct PhaseCard: View {
    let phase: AIPhase
    let phaseNumber: Int

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Phase \(phaseNumber)")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.accent)

                Spacer()

                Text("\(phase.durationWeeks) weeks")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Text(phase.name)
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            // Outcomes
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Outcomes:")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textTertiary)

                ForEach(phase.outcomes, id: \.self) { outcome in
                    HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(Theme.Colors.success)

                        Text(outcome)
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.textSecondary)
                    }
                }
            }

            // Milestones
            if !phase.milestones.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text("Milestones:")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textTertiary)

                    ForEach(phase.milestones, id: \.self) { milestone in
                        HStack(alignment: .top, spacing: Theme.Spacing.xs) {
                            Image(systemName: "flag.fill")
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.studyLearning)

                            Text(milestone)
                                .font(Theme.Fonts.caption())
                                .foregroundColor(Theme.Colors.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.tertiaryBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Schedule Action Row
struct ScheduleActionRow: View {
    let action: AIScheduleAction

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            // Type indicator
            ZStack {
                Circle()
                    .fill(typeColor.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: typeIcon)
                    .font(.caption)
                    .foregroundColor(typeColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(action.title)
                    .font(Theme.Fonts.subheadline())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: Theme.Spacing.xs) {
                    Text("\(action.durationMinutes)min")
                        .font(Theme.Fonts.caption2())

                    Text("•")

                    Text(action.cadence.rawValue.replacingOccurrences(of: "_", with: " "))
                        .font(Theme.Fonts.caption2())

                    Text("•")

                    Text(action.priority.rawValue)
                        .font(Theme.Fonts.caption2())
                        .foregroundColor(priorityColor)
                }
                .foregroundColor(Theme.Colors.textTertiary)
            }

            Spacer()

            // Energy indicator
            EnergyIndicator(level: action.energyLevel)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.tertiaryBackground)
        .cornerRadius(Theme.CornerRadius.small)
    }

    private var typeIcon: String {
        switch action.type {
        case .task: return "checkmark.circle"
        case .event: return "calendar"
        case .review: return "arrow.triangle.2.circlepath"
        }
    }

    private var typeColor: Color {
        switch action.type {
        case .task: return Theme.Colors.accent
        case .event: return Theme.Colors.fitnessHealth
        case .review: return Theme.Colors.studyLearning
        }
    }

    private var priorityColor: Color {
        switch action.priority {
        case .high: return Theme.Colors.error
        case .medium: return Theme.Colors.warning
        case .low: return Theme.Colors.textTertiary
        }
    }
}

// MARK: - Energy Indicator
struct EnergyIndicator: View {
    let level: EnergyLevel

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(index < energyBars ? energyColor : Theme.Colors.textTertiary.opacity(0.3))
                    .frame(width: 6, height: 6)
            }
        }
    }

    private var energyBars: Int {
        switch level {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }

    private var energyColor: Color {
        switch level {
        case .low: return Theme.Colors.success
        case .medium: return Theme.Colors.warning
        case .high: return Theme.Colors.error
        }
    }
}

// MARK: - Source Row
struct SourceRow: View {
    let source: AISource

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(source.title)
                .font(Theme.Fonts.subheadline())
                .foregroundColor(Theme.Colors.accent)

            Text(source.whyItMatters)
                .font(Theme.Fonts.caption())
                .foregroundColor(Theme.Colors.textSecondary)

            Text(source.url)
                .font(Theme.Fonts.caption2())
                .foregroundColor(Theme.Colors.textTertiary)
                .lineLimit(1)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.tertiaryBackground)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

#Preview {
    let samplePlan = AIPlanResponse(
        interpretation: AIInterpretation(
            whatUserIsReallyTryingToDo: "Build a sustainable habit of learning Spanish to achieve conversational fluency",
            constraintsDetected: ["Limited to 2 hours per day", "Works full-time"],
            leveragePoints: ["Strong motivation", "Previous language experience"]
        ),
        userProfile: AIUserProfile(
            timeHorizonMonths: 6,
            ambitionLevel: 7,
            hoursPerWeek: 14,
            preferences: AIPreferences(workloadStyle: .balanced, reminders: true)
        ),
        goal: AIGoal(
            title: "Achieve Spanish Conversational Fluency",
            category: "Study & Learning",
            successDefinition: ["Hold 15-minute conversation with native speaker", "Understand 80% of Spanish podcasts"],
            deadline: "2025-07-01"
        ),
        knownFacts: [:],
        unknownsToClarify: [],
        assumptionsIfUserDoesntAnswer: [],
        plan: AIPlan(
            strategySummary: "A progressive 6-month plan focusing on immersive learning with daily practice sessions.",
            confidence: 0.85,
            riskFlags: ["Consistency may drop after initial motivation"],
            phases: [
                AIPhase(name: "Foundation Building", durationWeeks: 4, outcomes: ["Basic vocabulary", "Simple sentences"], milestones: ["Complete 100 words"])
            ]
        ),
        scheduleActions: [
            AIScheduleAction(
                id: "1",
                type: .task,
                title: "Daily Vocabulary Practice",
                details: "Learn 10 new words using spaced repetition",
                durationMinutes: 30,
                cadence: .daily,
                preferredDays: nil,
                timeWindowLocal: TimeWindow(start: "07:00", end: "09:00"),
                energyLevel: .medium,
                priority: .high,
                tags: ["study", "vocabulary"],
                successCheck: "Complete Anki deck review"
            )
        ],
        sources: []
    )

    return AIPlanView(plan: samplePlan)
}
