import Foundation

// MARK: - AI Integration Service
/// Unified service for external AI API calls (OpenAI/Claude/Gemini)
/// Falls back gracefully when API unavailable
/// Supports secure backend proxy for Gemini API

@MainActor
final class AIIntegrationService: ObservableObject {
    static let shared = AIIntegrationService()

    // MARK: - Configuration

    enum AIProvider: String, CaseIterable {
        case openai = "openai"
        case claude = "claude"
        case gemini = "gemini" // Uses secure backend proxy

        var displayName: String {
            switch self {
            case .openai: return "OpenAI"
            case .claude: return "Claude"
            case .gemini: return "Gemini (Recommended)"
            }
        }

        var description: String {
            switch self {
            case .openai: return "GPT-4o Mini"
            case .claude: return "Claude 3 Haiku"
            case .gemini: return "Gemini 1.5 Flash via secure backend"
            }
        }
    }

    struct Config {
        var provider: AIProvider = .gemini // Default to Gemini
        var apiKey: String = ""
        var backendURL: String = "http://localhost:3000" // For Gemini backend
        var baseURL: String {
            switch provider {
            case .openai: return "https://api.openai.com/v1"
            case .claude: return "https://api.anthropic.com/v1"
            case .gemini: return backendURL // Uses backend proxy
            }
        }
        var model: String {
            switch provider {
            case .openai: return "gpt-4o-mini"
            case .claude: return "claude-3-haiku-20240307"
            case .gemini: return "gemini-1.5-flash"
            }
        }
    }

    // MARK: - State

    @Published var isConfigured: Bool = false
    @Published var isProcessing: Bool = false

    private var config = Config()
    private let session = URLSession.shared

    private init() {
        loadConfig()
    }

    // MARK: - Configuration

    func configure(provider: AIProvider, apiKey: String = "", backendURL: String? = nil) {
        config.provider = provider
        config.apiKey = apiKey

        if let backendURL = backendURL {
            config.backendURL = backendURL
        }

        // Gemini uses backend (no API key needed on client)
        // Other providers need API key
        if provider == .gemini {
            isConfigured = true // Backend handles the API key
        } else {
            isConfigured = !apiKey.isEmpty
        }

        saveConfig()
    }

    /// Configure to use Gemini backend (recommended - most secure)
    func configureGeminiBackend(backendURL: String = "http://localhost:3000") {
        configure(provider: .gemini, backendURL: backendURL)
    }

    /// Check if Gemini backend is available
    func checkGeminiBackendHealth() async -> Bool {
        return await GeminiBackendService.shared.healthCheck()
    }

    private func loadConfig() {
        if let provider = UserDefaults.standard.string(forKey: "ai_provider"),
           let p = AIProvider(rawValue: provider) {
            config.provider = p
        }
        if let key = UserDefaults.standard.string(forKey: "ai_api_key") {
            config.apiKey = key
        }
        if let backendURL = UserDefaults.standard.string(forKey: "ai_backend_url") {
            config.backendURL = backendURL
        }

        // Set isConfigured based on provider
        if config.provider == .gemini {
            isConfigured = true
        } else {
            isConfigured = !config.apiKey.isEmpty
        }
    }

    private func saveConfig() {
        UserDefaults.standard.set(config.provider.rawValue, forKey: "ai_provider")
        UserDefaults.standard.set(config.apiKey, forKey: "ai_api_key")
        UserDefaults.standard.set(config.backendURL, forKey: "ai_backend_url")
    }

    // MARK: - API Calls

    /// Generate personalized tips for a block
    func generateBlockTips(for block: PlanBlock, goal: IdentityGoal) async -> [String] {
        guard isConfigured else { return generateLocalTips(for: block) }

        let prompt = """
        Generate 3 brief, actionable tips for this activity:
        Activity: \(block.title)
        Intent: \(block.intentShort)
        Duration: \(block.durationMinutes) minutes
        Goal: \(goal.customIdentityName ?? goal.identityType.displayName)

        Return only 3 tips, one per line, no numbering or bullets.
        """

        do {
            let response = try await sendPrompt(prompt, maxTokens: 150)
            let tips = response.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            return Array(tips.prefix(3))
        } catch {
            return generateLocalTips(for: block)
        }
    }

    /// Generate daily motivation/insight
    func generateDailyInsight(completionRate: Double, streak: Int, goal: IdentityGoal) async -> String {
        guard isConfigured else { return generateLocalInsight(completionRate: completionRate, streak: streak) }

        let prompt = """
        Generate a brief (1-2 sentences) motivational insight for someone working toward becoming: \(goal.customIdentityName ?? goal.identityType.displayName)
        Their completion rate: \(Int(completionRate * 100))%
        Current streak: \(streak) days

        Be encouraging but authentic. No emojis.
        """

        do {
            return try await sendPrompt(prompt, maxTokens: 80)
        } catch {
            return generateLocalInsight(completionRate: completionRate, streak: streak)
        }
    }

    /// Get AI suggestion for optimal reschedule time
    func suggestOptimalTime(
        for block: PlanBlock,
        availableSlots: [DateInterval],
        userPatterns: UserPatterns
    ) async -> Date? {
        guard isConfigured, !availableSlots.isEmpty else {
            return availableSlots.first?.start
        }

        let slotsDescription = availableSlots.prefix(5).map { slot in
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE HH:mm"
            return formatter.string(from: slot.start)
        }.joined(separator: ", ")

        let prompt = """
        Pick the best time for this activity:
        Activity: \(block.title) (\(block.blockType.displayName))
        Energy required: \(block.energyLevel?.displayName ?? "Medium")
        Available slots: \(slotsDescription)
        User's peak hours: \(userPatterns.peakProductivityHour):00

        Reply with ONLY the day and time in format "Day HH:mm"
        """

        do {
            let response = try await sendPrompt(prompt, maxTokens: 20)
            return parseTimeResponse(response, from: availableSlots)
        } catch {
            return availableSlots.first?.start
        }
    }

    /// Parse natural language into block data
    func parseNaturalLanguage(_ input: String) async -> ParsedBlockIntent? {
        guard isConfigured else { return nil }

        let prompt = """
        Parse this into a calendar block:
        "\(input)"

        Return JSON only:
        {"title":"string","duration":minutes,"day":"today/tomorrow/monday-sunday","hour":0-23,"type":"focus/light/habit/review"}
        """

        do {
            let response = try await sendPrompt(prompt, maxTokens: 100)
            return parseBlockJSON(response)
        } catch {
            return nil
        }
    }

    // MARK: - Core API Request

    private func sendPrompt(_ prompt: String, maxTokens: Int) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }

        // For Gemini, use the secure backend service
        if config.provider == .gemini {
            return try await sendGeminiPrompt(prompt)
        }

        var request: URLRequest
        var body: Data

        switch config.provider {
        case .openai:
            request = URLRequest(url: URL(string: "\(config.baseURL)/chat/completions")!)
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
            let payload: [String: Any] = [
                "model": config.model,
                "messages": [["role": "user", "content": prompt]],
                "max_tokens": maxTokens,
                "temperature": 0.7
            ]
            body = try JSONSerialization.data(withJSONObject: payload)

        case .claude:
            request = URLRequest(url: URL(string: "\(config.baseURL)/messages")!)
            request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
            let payload: [String: Any] = [
                "model": config.model,
                "max_tokens": maxTokens,
                "messages": [["role": "user", "content": prompt]]
            ]
            body = try JSONSerialization.data(withJSONObject: payload)

        case .gemini:
            // Already handled above, but needed for exhaustive switch
            return try await sendGeminiPrompt(prompt)
        }

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 15

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.requestFailed
        }

        return try extractContent(from: data)
    }

    /// Send prompt to Gemini via secure backend
    private func sendGeminiPrompt(_ prompt: String) async throws -> String {
        do {
            let response = try await GeminiBackendService.shared.chat(message: prompt)
            return response
        } catch {
            throw AIError.requestFailed
        }
    }

    private func extractContent(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw AIError.invalidResponse
        }

        // OpenAI format
        if let choices = json["choices"] as? [[String: Any]],
           let message = choices.first?["message"] as? [String: Any],
           let content = message["content"] as? String {
            return content.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Claude format
        if let content = json["content"] as? [[String: Any]],
           let text = content.first?["text"] as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        throw AIError.invalidResponse
    }

    // MARK: - Local Fallbacks

    private func generateLocalTips(for block: PlanBlock) -> [String] {
        switch block.blockType {
        case .focus:
            return [
                "Eliminate distractions before starting",
                "Set a clear goal for this session",
                "Take a short break if focus drops"
            ]
        case .light:
            return [
                "Keep it relaxed but intentional",
                "Perfect for lower energy moments",
                "Build momentum with small wins"
            ]
        case .habit:
            return [
                "Consistency beats intensity",
                "Link this to an existing routine",
                "Track your streak for motivation"
            ]
        case .review:
            return [
                "Reflect on what worked this week",
                "Identify one thing to improve",
                "Celebrate your progress"
            ]
        }
    }

    private func generateLocalInsight(completionRate: Double, streak: Int) -> String {
        if streak >= 7 {
            return "A week of consistency. You're building real momentum."
        } else if completionRate >= 0.8 {
            return "Strong execution. Keep this pace and results will follow."
        } else if completionRate >= 0.5 {
            return "Progress over perfection. Every completed block counts."
        } else {
            return "Small steps lead to big changes. Focus on one block today."
        }
    }

    // MARK: - Helpers

    private func parseTimeResponse(_ response: String, from slots: [DateInterval]) -> Date? {
        // Simple matching - find slot that matches response
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE HH:mm"

        for slot in slots {
            let slotString = formatter.string(from: slot.start).lowercased()
            if response.lowercased().contains(slotString.components(separatedBy: " ").first ?? "") {
                return slot.start
            }
        }
        return slots.first?.start
    }

    private func parseBlockJSON(_ response: String) -> ParsedBlockIntent? {
        // Extract JSON from response
        let cleaned = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        guard let title = json["title"] as? String,
              let duration = json["duration"] as? Int else {
            return nil
        }

        return ParsedBlockIntent(
            title: title,
            duration: duration,
            day: json["day"] as? String ?? "today",
            hour: json["hour"] as? Int ?? 9,
            blockType: json["type"] as? String ?? "focus"
        )
    }
}

// MARK: - Supporting Types

struct ParsedBlockIntent {
    let title: String
    let duration: Int
    let day: String
    let hour: Int
    let blockType: String

    func toDate(from referenceDate: Date = Date()) -> Date? {
        let calendar = Calendar.current
        var targetDate = referenceDate

        switch day.lowercased() {
        case "today":
            break
        case "tomorrow":
            targetDate = calendar.date(byAdding: .day, value: 1, to: referenceDate) ?? referenceDate
        case "monday": targetDate = nextWeekday(1, from: referenceDate)
        case "tuesday": targetDate = nextWeekday(2, from: referenceDate)
        case "wednesday": targetDate = nextWeekday(3, from: referenceDate)
        case "thursday": targetDate = nextWeekday(4, from: referenceDate)
        case "friday": targetDate = nextWeekday(5, from: referenceDate)
        case "saturday": targetDate = nextWeekday(6, from: referenceDate)
        case "sunday": targetDate = nextWeekday(0, from: referenceDate)
        default:
            break
        }

        return calendar.date(bySettingHour: hour, minute: 0, second: 0, of: targetDate)
    }

    private func nextWeekday(_ weekday: Int, from date: Date) -> Date {
        let calendar = Calendar.current
        let current = calendar.component(.weekday, from: date)
        let daysToAdd = (weekday - current + 7) % 7
        return calendar.date(byAdding: .day, value: daysToAdd == 0 ? 7 : daysToAdd, to: date) ?? date
    }
}

struct UserPatterns {
    var peakProductivityHour: Int = 9
    var preferredBlockDuration: Int = 45
    var averageCompletionRate: Double = 0.7
    var preferredDays: [Int] = [2, 3, 4, 5, 6] // Mon-Fri
}

enum AIError: Error {
    case notConfigured
    case requestFailed
    case invalidResponse
}
