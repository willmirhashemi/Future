import Foundation
import GoogleGenerativeAI

// MARK: - Gemini AI Planning Agent Service
@MainActor
class GeminiService: ObservableObject {
    private var model: GenerativeModel?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var currentPlan: AIPlanResponse?

    init() {
        setupModel()
    }

    private func setupModel() {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !apiKey.isEmpty else {
            print("Gemini API key not found")
            return
        }

        // Use gemini-1.5-pro for better JSON handling
        model = GenerativeModel(name: "gemini-1.5-pro", apiKey: apiKey)
    }

    // MARK: - System Prompt (AI Planning Agent)
    private let systemPrompt = """
    You are Gemini, operating as an external AI Planning Agent.

    You are accessed through a backend service and integrated into a mobile app.
    You do NOT run inside the app.
    You do NOT manage UI, storage, or scheduling directly.

    Your role is to act as the reasoning and planning engine for the app.

    The app provides you with:
    - unstructured user input
    - structured user context
    - ambition level (1–10)
    - available hours per week
    - existing scheduled events
    - user preferences

    You return:
    - interpretation
    - strategy
    - phases
    - concrete actions (tasks/events/reviews)

    You do NOT:
    - store memory
    - choose exact calendar times
    - manage reminders
    - make UI decisions

    ━━━━━━━━━━━━━━━━━━
    PLANNING PRINCIPLES
    ━━━━━━━━━━━━━━━━━━

    You are not a chatbot.
    You are not generic.
    You are not motivational.

    You are a strategic planning agent.

    Every output must:
    - be specific
    - be actionable
    - be schedulable
    - respect time constraints
    - scale to long-term goals (up to 60 months)

    If a recommendation cannot be turned into a task or event, it does not belong in the output.

    ━━━━━━━━━━━━━━━━━━
    TIME & INTENSITY PARAMETERS
    ━━━━━━━━━━━━━━━━━━

    You will receive:
    - ambition_level (1–10)
    - hours_per_week (number)

    Rules:
    - hours_per_week is a HARD constraint.
    - ambition_level controls aggressiveness, not volume.
    - Prefer fewer high-impact actions over many low-impact ones.

    Ambition behavior:
    - 1–3: maintenance, minimum viable progress
    - 4–6: steady, sustainable execution
    - 7–8: ambitious but realistic
    - 9–10: elite mode (deep work, stretch goals)

    ━━━━━━━━━━━━━━━━━━
    SCHEDULING CONSTRAINTS
    ━━━━━━━━━━━━━━━━━━

    You must NOT assign fixed times.

    Instead, every action must include:
    - duration_minutes
    - cadence
    - preferred_days OR a flexible time_window_local

    The app will later propose exact times to the user.

    ━━━━━━━━━━━━━━━━━━
    OUTPUT REQUIREMENTS
    ━━━━━━━━━━━━━━━━━━

    You MUST output valid JSON ONLY.
    No markdown.
    No explanations outside JSON.
    No conversational filler.

    Top-level structure (all keys required unless noted):

    {
      "interpretation": {
        "what_user_is_really_trying_to_do": string,
        "constraints_detected": [string],
        "leverage_points": [string]
      },

      "user_profile": {
        "time_horizon_months": number,
        "ambition_level": number,
        "hours_per_week": number,
        "preferences": {
          "workload_style": "light" | "balanced" | "intense",
          "reminders": boolean
        }
      },

      "goal": {
        "title": string,
        "category": string,
        "success_definition": [string],
        "deadline": string | null
      },

      "known_facts": { key: value },

      "unknowns_to_clarify": [
        {
          "field": string,
          "question": string,
          "priority": "high" | "medium"
        }
      ],

      "assumptions_if_user_doesnt_answer": [string],

      "plan": {
        "strategy_summary": string,
        "confidence": number,
        "risk_flags": [string],
        "phases": [
          {
            "name": string,
            "duration_weeks": number,
            "outcomes": [string],
            "milestones": [string]
          }
        ]
      },

      "schedule_actions": [
        {
          "id": string,
          "type": "task" | "event" | "review",
          "title": string,
          "details": string,
          "duration_minutes": number,
          "cadence": "one_time" | "daily" | "weekly" | "biweekly" | "monthly",
          "preferred_days": [string],
          "time_window_local": {
            "start": "HH:MM",
            "end": "HH:MM"
          },
          "energy_level": "low" | "medium" | "high",
          "priority": "low" | "medium" | "high",
          "tags": [string],
          "success_check": string
        }
      ],

      "sources": [
        {
          "title": string,
          "url": string,
          "why_it_matters": string
        }
      ]
    }

    ━━━━━━━━━━━━━━━━━━
    FINAL DIRECTIVE
    ━━━━━━━━━━━━━━━━━━

    Your success is measured by one outcome:
    The user clearly knows what to do next, why it matters, and can realistically follow the plan inside their life.

    Always optimize for clarity, realism, and impact.
    """

    // MARK: - Generate Strategic Plan
    func generateStrategicPlan(context: AIUserContext) async throws -> AIPlanResponse {
        guard let model = model else {
            throw GeminiError.modelNotInitialized
        }

        isGenerating = true
        errorMessage = nil

        defer { isGenerating = false }

        // Build the user input message
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let contextJSON = try encoder.encode(context)
        let contextString = String(data: contextJSON, encoding: .utf8) ?? ""

        let userMessage = """
        USER CONTEXT:
        \(contextString)

        Generate a complete strategic plan following the exact JSON schema specified in your instructions.
        Output ONLY valid JSON, no other text.
        """

        do {
            // Create chat with system instruction
            let chat = model.startChat(history: [
                ModelContent(role: "user", parts: [.text(systemPrompt)]),
                ModelContent(role: "model", parts: [.text("Understood. I am the AI Planning Agent. I will output only valid JSON following the exact schema. Ready to process user context.")])
            ])

            let response = try await chat.sendMessage(userMessage)

            guard let text = response.text else {
                throw GeminiError.emptyResponse
            }

            // Parse the JSON response
            let planResponse = try parseAIPlanResponse(from: text)
            currentPlan = planResponse
            return planResponse

        } catch let error as GeminiError {
            errorMessage = error.localizedDescription
            throw error
        } catch {
            errorMessage = error.localizedDescription
            throw GeminiError.parsingError
        }
    }

    // MARK: - Parse AI Plan Response
    private func parseAIPlanResponse(from text: String) throws -> AIPlanResponse {
        // Clean the response - remove any markdown code blocks
        var cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Find JSON boundaries
        guard let jsonStart = cleanedText.firstIndex(of: "{"),
              let jsonEnd = cleanedText.lastIndex(of: "}") else {
            throw GeminiError.parsingError
        }

        cleanedText = String(cleanedText[jsonStart...jsonEnd])

        guard let jsonData = cleanedText.data(using: .utf8) else {
            throw GeminiError.parsingError
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AIPlanResponse.self, from: jsonData)
    }

    // MARK: - Convert Schedule Actions to Events
    func convertToEvents(
        actions: [AIScheduleAction],
        userId: String,
        category: GoalCategory,
        startDate: Date = Date()
    ) -> [Event] {
        var events: [Event] = []
        let calendar = Calendar.current

        for action in actions {
            let generatedEvents = generateEventsFromAction(
                action: action,
                userId: userId,
                category: category,
                startDate: startDate,
                calendar: calendar
            )
            events.append(contentsOf: generatedEvents)
        }

        return events
    }

    private func generateEventsFromAction(
        action: AIScheduleAction,
        userId: String,
        category: GoalCategory,
        startDate: Date,
        calendar: Calendar
    ) -> [Event] {
        var events: [Event] = []

        // Determine how many events to create based on cadence
        let weeksToGenerate = 4 // Generate 4 weeks of events
        let occurrences: Int

        switch action.cadence {
        case .oneTime:
            occurrences = 1
        case .daily:
            occurrences = weeksToGenerate * 7
        case .weekly:
            occurrences = weeksToGenerate
        case .biweekly:
            occurrences = weeksToGenerate / 2
        case .monthly:
            occurrences = 1
        }

        // Get preferred days or default to weekdays
        let preferredDays = action.preferredDays ?? ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

        // Get time window or default
        let startHour = action.timeWindowLocal?.startHour ?? 9
        let startMinute = action.timeWindowLocal?.startMinute ?? 0

        var dayOffset = 0
        var eventsCreated = 0

        while eventsCreated < occurrences && dayOffset < 60 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startDate) else {
                dayOffset += 1
                continue
            }

            let weekday = calendar.component(.weekday, from: date)
            let dayName = dayNameFromWeekday(weekday)

            // Check if this day matches preferred days
            let shouldSchedule: Bool
            switch action.cadence {
            case .daily:
                shouldSchedule = true
            case .oneTime:
                shouldSchedule = dayOffset == 0
            default:
                shouldSchedule = preferredDays.contains { $0.lowercased() == dayName.lowercased() }
            }

            if shouldSchedule {
                var components = calendar.dateComponents([.year, .month, .day], from: date)
                components.hour = startHour
                components.minute = startMinute

                if let eventStart = calendar.date(from: components) {
                    let eventEnd = calendar.date(byAdding: .minute, value: action.durationMinutes, to: eventStart)!

                    let event = Event(
                        userId: userId,
                        title: action.title,
                        description: action.details,
                        startTime: eventStart,
                        endTime: eventEnd,
                        eventType: eventTypeFromAction(action),
                        category: category,
                        isAIGenerated: true,
                        color: colorForEnergyLevel(action.energyLevel)
                    )

                    events.append(event)
                    eventsCreated += 1

                    // For weekly/biweekly, skip appropriate days
                    if action.cadence == .weekly {
                        dayOffset += 6 // Will be incremented to 7 below
                    } else if action.cadence == .biweekly {
                        dayOffset += 13
                    }
                }
            }

            dayOffset += 1
        }

        return events
    }

    private func dayNameFromWeekday(_ weekday: Int) -> String {
        switch weekday {
        case 1: return "Sunday"
        case 2: return "Monday"
        case 3: return "Tuesday"
        case 4: return "Wednesday"
        case 5: return "Thursday"
        case 6: return "Friday"
        case 7: return "Saturday"
        default: return "Monday"
        }
    }

    private func eventTypeFromAction(_ action: AIScheduleAction) -> EventType {
        // Map based on tags or type
        if action.tags.contains("study") || action.tags.contains("learning") {
            return .study
        } else if action.tags.contains("workout") || action.tags.contains("fitness") {
            return .workout
        } else if action.tags.contains("meditation") || action.tags.contains("mindfulness") {
            return .meditation
        } else if action.tags.contains("reading") {
            return .reading
        } else if action.tags.contains("networking") || action.tags.contains("social") {
            return .networking
        } else if action.tags.contains("financial") || action.tags.contains("money") {
            return .financial
        } else if action.tags.contains("creative") || action.tags.contains("art") {
            return .creative
        } else if action.tags.contains("self-care") || action.tags.contains("rest") {
            return .selfCare
        } else if action.type == .review {
            return .milestone
        }
        return .task
    }

    private func colorForEnergyLevel(_ level: EnergyLevel) -> String {
        switch level {
        case .high: return "FF6B6B"   // Red-ish for high energy
        case .medium: return "4ECDC4" // Teal for medium
        case .low: return "A8E6CF"    // Light green for low energy
        }
    }

    // MARK: - Build User Context
    static func buildContext(
        user: User,
        category: GoalCategory,
        responses: QuestionnaireResponses,
        existingEvents: [Event] = []
    ) -> AIUserContext {
        // Calculate hours per week from daily hours
        let hoursPerWeek = responses.availableHoursPerDay * 7

        // Determine ambition level from timeframe and hours
        let ambitionLevel: Int
        switch responses.timeframe {
        case .oneMonth: ambitionLevel = 8
        case .threeMonths: ambitionLevel = 7
        case .sixMonths: ambitionLevel = 6
        case .oneYear: ambitionLevel = 5
        case .fiveYears: ambitionLevel = 4
        }

        // Build structured context
        let structuredContext = StructuredUserContext(
            age: responses.age,
            educationLevel: responses.educationLevel.displayName,
            currentOccupation: responses.currentOccupation,
            financialSituation: responses.financialSituation.displayName,
            selectedCategory: category.displayName,
            specificGoal: responses.specificGoal,
            timeframe: responses.timeframe.displayName,
            preferredTimeOfDay: responses.preferredTimeOfDay.displayName,
            additionalNotes: responses.additionalNotes
        )

        // Build existing events context
        let existingEventContexts = existingEvents.prefix(20).map { event in
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "EEEE"
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"

            return ExistingEventContext(
                title: event.title,
                dayOfWeek: dayFormatter.string(from: event.startTime),
                timeSlot: timeFormatter.string(from: event.startTime),
                durationMinutes: event.durationInMinutes
            )
        }

        // Determine workload style
        let workloadStyle: String
        if hoursPerWeek <= 7 {
            workloadStyle = "light"
        } else if hoursPerWeek <= 14 {
            workloadStyle = "balanced"
        } else {
            workloadStyle = "intense"
        }

        let preferences = UserContextPreferences(
            workloadStyle: workloadStyle,
            reminderPreference: user.preferences.notificationsEnabled,
            journalFormat: user.preferences.journalFormat.displayName
        )

        return AIUserContext(
            unstructuredInput: responses.specificGoal,
            structuredContext: structuredContext,
            ambitionLevel: ambitionLevel,
            hoursPerWeek: hoursPerWeek,
            existingEvents: Array(existingEventContexts),
            preferences: preferences
        )
    }

    // MARK: - Legacy Support (for existing onboarding)
    func generatePersonalizedPlan(
        userId: String,
        category: GoalCategory,
        responses: QuestionnaireResponses
    ) async throws -> [Event] {
        // Create a mock user for context building
        let mockUser = User(
            id: userId,
            email: "",
            displayName: "",
            preferences: UserPreferences()
        )

        let context = GeminiService.buildContext(
            user: mockUser,
            category: category,
            responses: responses
        )

        do {
            let planResponse = try await generateStrategicPlan(context: context)
            return convertToEvents(
                actions: planResponse.scheduleActions,
                userId: userId,
                category: category
            )
        } catch {
            // Fallback to basic events if AI fails
            print("AI plan generation failed, using fallback: \(error)")
            return generateFallbackEvents(userId: userId, category: category)
        }
    }

    // MARK: - Fallback Events
    private func generateFallbackEvents(userId: String, category: GoalCategory) -> [Event] {
        var events: [Event] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<28 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            var morningComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
            morningComponents.hour = 9
            morningComponents.minute = 0

            if let morningStart = calendar.date(from: morningComponents) {
                let morningEnd = calendar.date(byAdding: .hour, value: 1, to: morningStart)!
                events.append(Event(
                    userId: userId,
                    title: "Morning \(category.displayName) Focus",
                    description: "Dedicated time for your \(category.displayName.lowercased()) goals",
                    startTime: morningStart,
                    endTime: morningEnd,
                    eventType: .task,
                    category: category,
                    isAIGenerated: true,
                    color: "4ECDC4"
                ))
            }

            if dayOffset % 7 == 6 {
                var reviewComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
                reviewComponents.hour = 18
                reviewComponents.minute = 0

                if let reviewStart = calendar.date(from: reviewComponents) {
                    let reviewEnd = calendar.date(byAdding: .minute, value: 30, to: reviewStart)!
                    events.append(Event(
                        userId: userId,
                        title: "Weekly Review",
                        description: "Review your progress and plan for next week",
                        startTime: reviewStart,
                        endTime: reviewEnd,
                        eventType: .milestone,
                        category: category,
                        isAIGenerated: true,
                        color: "FFD93D"
                    ))
                }
            }
        }

        return events
    }

    // MARK: - Inactivity Suggestion
    func generateInactivitySuggestion(
        userId: String,
        category: GoalCategory,
        lastActiveDate: Date,
        originalGoal: String
    ) async throws -> String {
        guard let model = model else {
            throw GeminiError.modelNotInitialized
        }

        let daysSinceActive = Calendar.current.dateComponents([.day], from: lastActiveDate, to: Date()).day ?? 0

        let prompt = """
        A user working on their \(category.displayName) goal hasn't been active for \(daysSinceActive) days.
        Their original goal was: \(originalGoal)

        Write a brief, encouraging message (2-3 sentences) acknowledging they've been away, and gently suggest they might want to create a fresh plan. Be supportive, not judgmental. Output only the message text.
        """

        let response = try await model.generateContent(prompt)
        return response.text ?? "Welcome back! It looks like you've been away for a while. Would you like to create a fresh plan to get back on track with your goals?"
    }

    // MARK: - Generate Journal Prompts
    func generateJournalPrompts(category: GoalCategory) async throws -> [String] {
        guard let model = model else {
            throw GeminiError.modelNotInitialized
        }

        let prompt = """
        Generate 5 thoughtful journal prompts for someone working on their \(category.displayName) goals.
        The prompts should encourage reflection, self-awareness, and progress tracking.
        Return ONLY a JSON array of strings, no other text:
        ["prompt 1", "prompt 2", "prompt 3", "prompt 4", "prompt 5"]
        """

        let response = try await model.generateContent(prompt)

        guard let text = response.text else {
            return defaultJournalPrompts(for: category)
        }

        // Clean and parse
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = cleanedText.data(using: .utf8) else {
            return defaultJournalPrompts(for: category)
        }

        do {
            return try JSONDecoder().decode([String].self, from: jsonData)
        } catch {
            return defaultJournalPrompts(for: category)
        }
    }

    private func defaultJournalPrompts(for category: GoalCategory) -> [String] {
        [
            "What progress did you make toward your \(category.displayName.lowercased()) goals today?",
            "What challenges did you face and how did you handle them?",
            "What are you most proud of accomplishing recently?",
            "What would you like to focus on improving tomorrow?",
            "How are you feeling about your overall progress?"
        ]
    }
}

// MARK: - Gemini Errors
enum GeminiError: LocalizedError {
    case modelNotInitialized
    case emptyResponse
    case parsingError
    case invalidContext

    var errorDescription: String? {
        switch self {
        case .modelNotInitialized:
            return "AI model not initialized. Please check your API key."
        case .emptyResponse:
            return "Received an empty response from AI."
        case .parsingError:
            return "Failed to parse AI response. Please try again."
        case .invalidContext:
            return "Invalid user context provided."
        }
    }
}
