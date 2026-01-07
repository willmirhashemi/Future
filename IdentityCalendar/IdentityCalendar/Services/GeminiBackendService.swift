import Foundation

// MARK: - Gemini Backend Service

/// Service that communicates with our secure backend server
/// The backend holds the Gemini API key securely - never exposed to the client
final class GeminiBackendService: AIPlannerService {

    // MARK: - Configuration

    /// Backend server URL - configure this for your deployment
    /// For local development: http://localhost:3000
    /// For production: https://your-backend-server.com
    private let baseURL: URL

    private let session: URLSession

    // MARK: - Singleton

    static let shared: GeminiBackendService = {
        // Default to localhost for development
        // Change this URL when deploying to production
        let serverURL = URL(string: ProcessInfo.processInfo.environment["BACKEND_URL"] ?? "http://localhost:3000")!
        return GeminiBackendService(baseURL: serverURL)
    }()

    // MARK: - Initialization

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    // MARK: - AIPlannerService Protocol

    func generateInitialPlan(for goal: IdentityGoal) async throws -> AIPlanResponse {
        let request = AIPlanRequest.from(goal: goal)
        let endpoint = baseURL.appendingPathComponent("api/v1/plan/generate")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60 // Gemini can take a while

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        urlRequest.httpBody = try encoder.encode(request)

        do {
            let (data, response) = try await session.data(for: urlRequest)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AIPlannerError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try decoder.decode(AIPlanResponse.self, from: data)
            case 429:
                throw AIPlannerError.rateLimited
            case 500...599:
                let message = String(data: data, encoding: .utf8) ?? "Server error"
                throw AIPlannerError.serverError(message: message)
            default:
                throw AIPlannerError.invalidResponse
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
        let endpoint = baseURL.appendingPathComponent("api/v1/plan/adapt")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 60

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
        // For now, use smart scheduler logic locally
        // Backend can be extended for AI-powered rescheduling
        return availableSlots.first?.start
    }

    // MARK: - Chat Functionality

    /// Send a general chat message to Gemini via the backend
    /// Useful for custom AI interactions beyond plan generation
    func chat(message: String, context: String? = nil) async throws -> String {
        let endpoint = baseURL.appendingPathComponent("api/v1/chat")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.timeoutInterval = 30

        var body: [String: Any] = ["message": message]
        if let context = context {
            body["context"] = context
        }

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIPlannerError.serverError(message: "Chat request failed")
        }

        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let responseText = json["response"] as? String {
            return responseText
        }

        throw AIPlannerError.invalidResponse
    }

    // MARK: - Health Check

    /// Check if the backend server is available
    func healthCheck() async -> Bool {
        let endpoint = baseURL.appendingPathComponent("health")

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = 5

        do {
            let (_, response) = try await session.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                return false
            }
            return httpResponse.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Backend Configuration

/// Configuration for the backend server
struct BackendConfiguration {
    static var serverURL: URL {
        // Check for environment variable first (useful for different build configs)
        if let urlString = ProcessInfo.processInfo.environment["BACKEND_URL"],
           let url = URL(string: urlString) {
            return url
        }

        // Default URLs based on build configuration
        #if DEBUG
        // Local development server
        return URL(string: "http://localhost:3000")!
        #else
        // Production server - UPDATE THIS with your deployed backend URL
        return URL(string: "https://your-production-server.com")!
        #endif
    }
}
