import Foundation

// ============================================================================
// MARK: - AI SERVICE (Unified AI Integration)
// ============================================================================

/// Main AI service that routes requests through the secure backend proxy
/// API key is stored on the server, never in the client
@MainActor
final class AIService: ObservableObject {
    static let shared = AIService()

    @Published var isConfigured = true  // Backend handles API key
    @Published var isProcessing = false

    private let session = URLSession.shared
    private var backendURL: URL

    private init() {
        // Default to localhost for development
        // Change to your production URL when deploying
        #if DEBUG
        self.backendURL = URL(string: "http://localhost:3000")!
        #else
        self.backendURL = URL(string: "https://your-production-server.com")!
        #endif

        // Load saved backend URL if available
        if let saved = UserDefaults.standard.string(forKey: "ai_backend_url"),
           let url = URL(string: saved) {
            self.backendURL = url
        }
    }

    // MARK: - Configuration

    func configure(backendURL: String) {
        if let url = URL(string: backendURL) {
            self.backendURL = url
            UserDefaults.standard.set(backendURL, forKey: "ai_backend_url")
        }
    }

    // MARK: - Health Check

    func checkHealth() async -> Bool {
        let endpoint = backendURL.appendingPathComponent("health")
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 5

        do {
            let (_, response) = try await session.data(for: request)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }

    // MARK: - Plan Generation

    func generatePlan(for goal: IdentityGoal) async throws -> AIPlanResponse {
        isProcessing = true
        defer { isProcessing = false }

        let request = AIPlanRequest.from(goal: goal)
        let endpoint = backendURL.appendingPathComponent("api/v1/plan/generate")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(AIPlanResponse.self, from: data)
        case 429:
            throw AIError.rateLimited
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.serverError(message)
        }
    }

    // MARK: - Plan Adaptation

    func adaptPlan(for goal: IdentityGoal, reflection: WeeklyReflection) async throws -> AIAdaptationResponse {
        isProcessing = true
        defer { isProcessing = false }

        let request = AIAdaptationRequest.from(reflection: reflection, goal: goal)
        let endpoint = backendURL.appendingPathComponent("api/v1/plan/adapt")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(AIAdaptationResponse.self, from: data)
        case 429:
            throw AIError.rateLimited
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIError.serverError(message)
        }
    }

    // MARK: - Chat

    func chat(message: String, context: String? = nil) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }

        let endpoint = backendURL.appendingPathComponent("api/v1/chat")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30

        var body: [String: Any] = ["message": message]
        if let context = context { body["context"] = context }
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.serverError("Chat request failed")
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let responseText = json["response"] as? String {
            return responseText
        }

        throw AIError.invalidResponse
    }

    // MARK: - Block Tips

    func generateBlockTips(for block: PlanBlock, goal: IdentityGoal) async -> [String] {
        let prompt = """
        Generate 3 brief, actionable tips for this activity:
        Activity: \(block.title)
        Intent: \(block.intentShort)
        Duration: \(block.durationMinutes) minutes
        Goal: \(goal.displayName)
        Return only 3 tips, one per line.
        """

        do {
            let response = try await chat(message: prompt)
            return response.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .prefix(3)
                .map { String($0) }
        } catch {
            return generateLocalTips(for: block)
        }
    }

    private func generateLocalTips(for block: PlanBlock) -> [String] {
        switch block.blockType {
        case .focus:
            return ["Eliminate distractions before starting", "Set a clear goal for this session", "Take a short break if focus drops"]
        case .light:
            return ["Keep it relaxed but intentional", "Perfect for lower energy moments", "Build momentum with small wins"]
        case .habit:
            return ["Consistency beats intensity", "Link this to an existing routine", "Track your streak for motivation"]
        case .review:
            return ["Reflect on what worked this week", "Identify one thing to improve", "Celebrate your progress"]
        }
    }
}

// ============================================================================
// MARK: - AI REQUEST/RESPONSE TYPES
// ============================================================================

struct AIPlanRequest: Codable {
    let identityType: String
    let customIdentityName: String?
    let timeHorizon: String
    let availability: String
    let intensity: String
    let planConfidence: String
    let isFirstWeek: Bool
    let startDate: String

    static func from(goal: IdentityGoal) -> AIPlanRequest {
        let formatter = ISO8601DateFormatter()
        return AIPlanRequest(
            identityType: goal.identityType.rawValue,
            customIdentityName: goal.customIdentityName,
            timeHorizon: goal.timeHorizon.rawValue,
            availability: goal.availability.rawValue,
            intensity: goal.intensity.rawValue,
            planConfidence: goal.planConfidence.rawValue,
            isFirstWeek: goal.isFirstWeek,
            startDate: formatter.string(from: goal.createdAt)
        )
    }
}

struct AIPlanResponse: Codable {
    let milestones: [Milestone.MilestoneData]
    let weeklyThemes: [WeeklyTheme.WeeklyThemeData]
    let planBlocks: [PlanBlock.PlanBlockData]

    var totalWeeks: Int { weeklyThemes.count }
}

struct AIAdaptationRequest: Codable {
    let weekNumber: Int
    let weekFeeling: String
    let obstacle: String?
    let note: String?
    let completionRate: Double
    let engagementRate: Double
    let blocksCompleted: Int
    let blocksSkipped: Int
    let blocksMoved: Int
    let blocksReduced: Int
    let currentPlanConfidence: String

    static func from(reflection: WeeklyReflection, goal: IdentityGoal) -> AIAdaptationRequest {
        AIAdaptationRequest(
            weekNumber: reflection.weekNumber,
            weekFeeling: reflection.weekFeeling.rawValue,
            obstacle: reflection.obstacle?.rawValue,
            note: reflection.note,
            completionRate: reflection.completionRate,
            engagementRate: reflection.engagementRate,
            blocksCompleted: reflection.blocksCompleted,
            blocksSkipped: reflection.blocksSkipped,
            blocksMoved: reflection.blocksMoved,
            blocksReduced: reflection.blocksReduced,
            currentPlanConfidence: goal.planConfidence.rawValue
        )
    }
}

struct AIAdaptationResponse: Codable {
    let updatedBlocks: [PlanBlock.PlanBlockData]
    let summary: String
    let adjustmentType: AdjustmentType

    enum AdjustmentType: String, Codable {
        case lighter, maintained, increased, restructured
    }
}

// ============================================================================
// MARK: - AI ERRORS
// ============================================================================

enum AIError: Error, LocalizedError {
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case rateLimited
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error): return "Network error: \(error.localizedDescription)"
        case .invalidResponse: return "Invalid response from AI service"
        case .decodingError(let error): return "Failed to process response: \(error.localizedDescription)"
        case .rateLimited: return "Too many requests. Please try again later."
        case .serverError(let message): return "Server error: \(message)"
        }
    }
}

// ============================================================================
// MARK: - MOCK AI SERVICE (for testing/preview)
// ============================================================================

final class MockAIService {
    static func generateMockPlan(for goal: IdentityGoal) -> AIPlanResponse {
        let milestones = [
            Milestone.MilestoneData(title: "Foundation", description: "Build your base", weekNumber: 1),
            Milestone.MilestoneData(title: "Momentum", description: "Establish consistency", weekNumber: 4),
            Milestone.MilestoneData(title: "Growth", description: "See real progress", weekNumber: 8)
        ]

        let themes = [
            WeeklyTheme.WeeklyThemeData(weekNumber: 1, title: "Getting Started", focus: "Build initial habits"),
            WeeklyTheme.WeeklyThemeData(weekNumber: 2, title: "Finding Rhythm", focus: "Establish your routine")
        ]

        let blocks = generateMockBlocks(for: goal, weeks: 2)

        return AIPlanResponse(milestones: milestones, weeklyThemes: themes, planBlocks: blocks)
    }

    private static func generateMockBlocks(for goal: IdentityGoal, weeks: Int) -> [PlanBlock.PlanBlockData] {
        var blocks: [PlanBlock.PlanBlockData] = []
        let formatter = ISO8601DateFormatter()
        let calendar = Calendar.current

        for week in 1...weeks {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: week - 1, to: goal.createdAt) ?? Date()

            for day in 0..<5 { // Mon-Fri
                let dayDate = calendar.date(byAdding: .day, value: day + 1, to: weekStart) ?? Date()

                var components = calendar.dateComponents([.year, .month, .day], from: dayDate)
                components.hour = 9
                components.minute = 0

                let startTime = calendar.date(from: components) ?? dayDate
                let endTime = startTime.addingTimeInterval(3600)

                blocks.append(PlanBlock.PlanBlockData(
                    startDateTime: formatter.string(from: startTime),
                    endDateTime: formatter.string(from: endTime),
                    title: "Focus Session",
                    blockType: "focus",
                    intentShort: "Deep work toward your goal",
                    weekNumber: week
                ))
            }
        }

        return blocks
    }
}
