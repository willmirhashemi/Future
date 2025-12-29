import Foundation

// MARK: - AI Planner Protocol

/// Protocol defining the AI planning engine interface
/// All AI implementations must conform to this protocol
protocol AIPlannerService {
    /// Generate an initial plan based on user's identity goal
    func generateInitialPlan(for goal: IdentityGoal) async throws -> AIPlanResponse

    /// Adapt the weekly plan based on reflection data
    func adaptWeeklyPlan(
        for goal: IdentityGoal,
        reflection: WeeklyReflection,
        currentBlocks: [PlanBlock]
    ) async throws -> AIAdaptationResponse

    /// Suggest optimal reschedule time for a block
    func suggestReschedule(
        for block: PlanBlock,
        availableSlots: [DateInterval]
    ) async throws -> Date?
}

// MARK: - AI Response Types

struct AIPlanResponse: Codable {
    let milestones: [Milestone.MilestoneData]
    let weeklyThemes: [WeeklyTheme.WeeklyThemeData]
    let planBlocks: [PlanBlock.PlanBlockData]

    var totalWeeks: Int {
        weeklyThemes.count
    }
}

struct AIAdaptationResponse: Codable {
    let updatedBlocks: [PlanBlock.PlanBlockData]
    let summary: String
    let adjustmentType: AdjustmentType

    enum AdjustmentType: String, Codable {
        case lighter = "lighter"
        case maintained = "maintained"
        case increased = "increased"
        case restructured = "restructured"
    }
}

// MARK: - AI Request Types

struct AIPlanRequest: Codable {
    let identityType: String
    let customIdentityName: String?
    let timeHorizon: String
    let availability: String
    let intensity: String
    let planConfidence: String
    let isFirstWeek: Bool
    let startDate: String // ISO8601

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
        return AIAdaptationRequest(
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

// MARK: - AI Error Types

enum AIPlannerError: Error, LocalizedError {
    case networkError(underlying: Error)
    case invalidResponse
    case decodingError(underlying: Error)
    case apiKeyMissing
    case rateLimited
    case serverError(message: String)

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from AI service"
        case .decodingError(let error):
            return "Failed to process response: \(error.localizedDescription)"
        case .apiKeyMissing:
            return "API key not configured"
        case .rateLimited:
            return "Too many requests. Please try again later."
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

// MARK: - Real AI Planner Service (URLSession-based)

final class RealAIPlannerService: AIPlannerService {
    private let baseURL: URL
    private let apiKey: String
    private let session: URLSession

    init(baseURL: URL, apiKey: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.session = session
    }

    func generateInitialPlan(for goal: IdentityGoal) async throws -> AIPlanResponse {
        let request = AIPlanRequest.from(goal: goal)
        let endpoint = baseURL.appendingPathComponent("v1/plan/generate")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIPlannerError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(AIPlanResponse.self, from: data)
            case 429:
                throw AIPlannerError.rateLimited
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIPlannerError.serverError(message: message)
            }
        } catch let error as AIPlannerError {
            throw error
        } catch let error as DecodingError {
            throw AIPlannerError.decodingError(underlying: error)
        } catch {
            throw AIPlannerError.networkError(underlying: error)
        }
    }

    func adaptWeeklyPlan(
        for goal: IdentityGoal,
        reflection: WeeklyReflection,
        currentBlocks: [PlanBlock]
    ) async throws -> AIAdaptationResponse {
        let request = AIAdaptationRequest.from(reflection: reflection, goal: goal)
        let endpoint = baseURL.appendingPathComponent("v1/plan/adapt")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIPlannerError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return try JSONDecoder().decode(AIAdaptationResponse.self, from: data)
            case 429:
                throw AIPlannerError.rateLimited
            default:
                let message = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw AIPlannerError.serverError(message: message)
            }
        } catch let error as AIPlannerError {
            throw error
        } catch let error as DecodingError {
            throw AIPlannerError.decodingError(underlying: error)
        } catch {
            throw AIPlannerError.networkError(underlying: error)
        }
    }

    func suggestReschedule(
        for block: PlanBlock,
        availableSlots: [DateInterval]
    ) async throws -> Date? {
        // For MVP, return the first available slot
        return availableSlots.first?.start
    }
}
