import Foundation
import GoogleGenerativeAI

// MARK: - Gemini AI Service
@MainActor
class GeminiService: ObservableObject {
    private var model: GenerativeModel?
    @Published var isGenerating = false
    @Published var errorMessage: String?

    init() {
        setupModel()
    }

    private func setupModel() {
        // API key should be stored securely - using Config for now
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String,
              !apiKey.isEmpty else {
            print("Gemini API key not found")
            return
        }

        model = GenerativeModel(name: "gemini-pro", apiKey: apiKey)
    }

    // MARK: - Generate Personalized Plan
    func generatePersonalizedPlan(
        userId: String,
        category: GoalCategory,
        responses: QuestionnaireResponses
    ) async throws -> [Event] {
        guard let model = model else {
            throw GeminiError.modelNotInitialized
        }

        isGenerating = true
        errorMessage = nil

        defer { isGenerating = false }

        let prompt = buildPrompt(category: category, responses: responses)

        do {
            let response = try await model.generateContent(prompt)

            guard let text = response.text else {
                throw GeminiError.emptyResponse
            }

            let events = parseEventsFromResponse(text, userId: userId, category: category)
            return events
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    // MARK: - Build Prompt
    private func buildPrompt(category: GoalCategory, responses: QuestionnaireResponses) -> String {
        let timeframeDescription: String
        switch responses.timeframe {
        case .oneMonth: timeframeDescription = "1 month"
        case .threeMonths: timeframeDescription = "3 months"
        case .sixMonths: timeframeDescription = "6 months"
        case .oneYear: timeframeDescription = "1 year"
        case .fiveYears: timeframeDescription = "5 years"
        }

        let preferredTimeDescription: String
        switch responses.preferredTimeOfDay {
        case .earlyMorning: preferredTimeDescription = "early morning (5-7 AM)"
        case .morning: preferredTimeDescription = "morning (7 AM-12 PM)"
        case .afternoon: preferredTimeDescription = "afternoon (12-5 PM)"
        case .evening: preferredTimeDescription = "evening (5-9 PM)"
        case .night: preferredTimeDescription = "night (after 9 PM)"
        case .flexible: preferredTimeDescription = "flexible throughout the day"
        }

        return """
        You are a personal goal achievement coach creating a detailed, actionable plan. Create a comprehensive calendar schedule for someone with the following profile:

        **Category Focus:** \(category.displayName)
        **Age:** \(responses.age)
        **Education Level:** \(responses.educationLevel.displayName)
        **Current Occupation:** \(responses.currentOccupation)
        **Financial Situation:** \(responses.financialSituation.displayName)
        **Specific Goal:** \(responses.specificGoal)
        **Timeframe:** \(timeframeDescription)
        **Available Hours Per Day:** \(responses.availableHoursPerDay)
        **Preferred Time:** \(preferredTimeDescription)
        \(responses.additionalNotes.map { "**Additional Notes:** \($0)" } ?? "")

        Generate a detailed 4-week plan with daily events. Each event should be:
        - Specific and actionable
        - Appropriate for their education level and schedule
        - Progressive (building on previous tasks)
        - Varied (different types of activities)

        Return the events in the following JSON format:
        ```json
        {
          "events": [
            {
              "title": "Event title",
              "description": "Detailed description of what to do",
              "dayOffset": 0,
              "startHour": 9,
              "startMinute": 0,
              "durationMinutes": 60,
              "eventType": "study|workout|meditation|reading|practice|networking|financial|creative|selfCare|task|milestone",
              "color": "hex color without #"
            }
          ],
          "summary": "A brief 2-3 sentence summary of this personalized plan"
        }
        ```

        Event types and their colors:
        - study: 4D96FF (blue)
        - workout: 6BCB77 (green)
        - meditation: A8E6CF (light green)
        - reading: 9B59B6 (purple)
        - practice: FF6B9D (pink)
        - networking: FF8C42 (orange)
        - financial: 4D96FF (blue)
        - creative: 9B59B6 (purple)
        - selfCare: A8E6CF (light green)
        - task: 4ECDC4 (teal)
        - milestone: FFD93D (yellow)

        Create at least 50 events spread across the 4 weeks. Include:
        - Daily routine tasks
        - Weekly milestones
        - Learning sessions
        - Practice/application time
        - Rest and self-care moments
        - Progress check-ins

        Be specific to their goal of: \(responses.specificGoal)
        """
    }

    // MARK: - Parse Events from Response
    private func parseEventsFromResponse(_ text: String, userId: String, category: GoalCategory) -> [Event] {
        var events: [Event] = []

        // Extract JSON from the response
        guard let jsonStart = text.range(of: "{"),
              let jsonEnd = text.range(of: "}", options: .backwards) else {
            return generateFallbackEvents(userId: userId, category: category)
        }

        let jsonString = String(text[jsonStart.lowerBound...jsonEnd.upperBound])

        guard let jsonData = jsonString.data(using: .utf8) else {
            return generateFallbackEvents(userId: userId, category: category)
        }

        do {
            let decoder = JSONDecoder()
            let planResponse = try decoder.decode(GeminiPlanResponse.self, from: jsonData)

            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())

            for eventData in planResponse.events {
                var startComponents = calendar.dateComponents([.year, .month, .day], from: today)
                startComponents.day! += eventData.dayOffset
                startComponents.hour = eventData.startHour
                startComponents.minute = eventData.startMinute

                guard let startTime = calendar.date(from: startComponents) else { continue }
                let endTime = calendar.date(byAdding: .minute, value: eventData.durationMinutes, to: startTime)!

                let event = Event(
                    userId: userId,
                    title: eventData.title,
                    description: eventData.description,
                    startTime: startTime,
                    endTime: endTime,
                    eventType: EventType(rawValue: eventData.eventType) ?? .task,
                    category: category,
                    isAIGenerated: true,
                    color: eventData.color
                )

                events.append(event)
            }
        } catch {
            print("JSON parsing error: \(error)")
            return generateFallbackEvents(userId: userId, category: category)
        }

        return events
    }

    // MARK: - Fallback Events
    private func generateFallbackEvents(userId: String, category: GoalCategory) -> [Event] {
        var events: [Event] = []
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Generate basic events for 4 weeks
        for dayOffset in 0..<28 {
            guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: today) else { continue }

            // Morning task
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

            // Evening review (every other day)
            if dayOffset % 2 == 0 {
                var eveningComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
                eveningComponents.hour = 19
                eveningComponents.minute = 0

                if let eveningStart = calendar.date(from: eveningComponents) {
                    let eveningEnd = calendar.date(byAdding: .minute, value: 30, to: eveningStart)!
                    events.append(Event(
                        userId: userId,
                        title: "Progress Review",
                        description: "Review your progress and plan for tomorrow",
                        startTime: eveningStart,
                        endTime: eveningEnd,
                        eventType: .task,
                        category: category,
                        isAIGenerated: true,
                        color: "FFD93D"
                    ))
                }
            }

            // Weekly milestone
            if dayOffset % 7 == 6 {
                var milestoneComponents = calendar.dateComponents([.year, .month, .day], from: dayDate)
                milestoneComponents.hour = 10
                milestoneComponents.minute = 0

                if let milestoneStart = calendar.date(from: milestoneComponents) {
                    let milestoneEnd = calendar.date(byAdding: .hour, value: 1, to: milestoneStart)!
                    events.append(Event(
                        userId: userId,
                        title: "Weekly Milestone Check",
                        description: "Assess your weekly progress and celebrate wins",
                        startTime: milestoneStart,
                        endTime: milestoneEnd,
                        eventType: .milestone,
                        category: category,
                        isAIGenerated: true,
                        color: "FF6B6B"
                    ))
                }
            }
        }

        return events
    }

    // MARK: - Check Inactivity
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

        Write a brief, encouraging message (2-3 sentences) acknowledging they've been away, and gently suggest they might want to create a fresh plan. Be supportive, not judgmental.
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

        Return as a JSON array of strings:
        ["prompt 1", "prompt 2", "prompt 3", "prompt 4", "prompt 5"]
        """

        let response = try await model.generateContent(prompt)

        guard let text = response.text,
              let jsonData = text.data(using: .utf8) else {
            return defaultJournalPrompts(for: category)
        }

        do {
            let prompts = try JSONDecoder().decode([String].self, from: jsonData)
            return prompts
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

// MARK: - Gemini Response Models
struct GeminiPlanResponse: Codable {
    let events: [GeminiEventData]
    let summary: String?
}

struct GeminiEventData: Codable {
    let title: String
    let description: String
    let dayOffset: Int
    let startHour: Int
    let startMinute: Int
    let durationMinutes: Int
    let eventType: String
    let color: String
}

// MARK: - Gemini Errors
enum GeminiError: LocalizedError {
    case modelNotInitialized
    case emptyResponse
    case parsingError

    var errorDescription: String? {
        switch self {
        case .modelNotInitialized:
            return "AI model not initialized. Please check your API key."
        case .emptyResponse:
            return "Received an empty response from AI."
        case .parsingError:
            return "Failed to parse AI response."
        }
    }
}
