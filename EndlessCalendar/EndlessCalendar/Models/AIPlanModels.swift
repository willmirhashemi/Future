import Foundation

// MARK: - AI Planning Agent Response Models
// These models match the exact JSON schema required by the Gemini Planning Agent

struct AIPlanResponse: Codable {
    let interpretation: AIInterpretation
    let userProfile: AIUserProfile
    let goal: AIGoal
    let knownFacts: [String: String]
    let unknownsToClarify: [AIUnknown]
    let assumptionsIfUserDoesntAnswer: [String]
    let plan: AIPlan
    let scheduleActions: [AIScheduleAction]
    let sources: [AISource]

    enum CodingKeys: String, CodingKey {
        case interpretation
        case userProfile = "user_profile"
        case goal
        case knownFacts = "known_facts"
        case unknownsToClarify = "unknowns_to_clarify"
        case assumptionsIfUserDoesntAnswer = "assumptions_if_user_doesnt_answer"
        case plan
        case scheduleActions = "schedule_actions"
        case sources
    }
}

// MARK: - Interpretation
struct AIInterpretation: Codable {
    let whatUserIsReallyTryingToDo: String
    let constraintsDetected: [String]
    let leveragePoints: [String]

    enum CodingKeys: String, CodingKey {
        case whatUserIsReallyTryingToDo = "what_user_is_really_trying_to_do"
        case constraintsDetected = "constraints_detected"
        case leveragePoints = "leverage_points"
    }
}

// MARK: - User Profile (from AI response)
struct AIUserProfile: Codable {
    let timeHorizonMonths: Int
    let ambitionLevel: Int
    let hoursPerWeek: Int
    let preferences: AIPreferences

    enum CodingKeys: String, CodingKey {
        case timeHorizonMonths = "time_horizon_months"
        case ambitionLevel = "ambition_level"
        case hoursPerWeek = "hours_per_week"
        case preferences
    }
}

struct AIPreferences: Codable {
    let workloadStyle: WorkloadStyle
    let reminders: Bool

    enum CodingKeys: String, CodingKey {
        case workloadStyle = "workload_style"
        case reminders
    }
}

enum WorkloadStyle: String, Codable {
    case light
    case balanced
    case intense
}

// MARK: - Goal
struct AIGoal: Codable {
    let title: String
    let category: String
    let successDefinition: [String]
    let deadline: String?

    enum CodingKeys: String, CodingKey {
        case title
        case category
        case successDefinition = "success_definition"
        case deadline
    }
}

// MARK: - Unknowns to Clarify
struct AIUnknown: Codable, Identifiable {
    var id: String { field }
    let field: String
    let question: String
    let priority: AIPriority
}

enum AIPriority: String, Codable {
    case high
    case medium
    case low
}

// MARK: - Plan
struct AIPlan: Codable {
    let strategySummary: String
    let confidence: Double
    let riskFlags: [String]
    let phases: [AIPhase]

    enum CodingKeys: String, CodingKey {
        case strategySummary = "strategy_summary"
        case confidence
        case riskFlags = "risk_flags"
        case phases
    }
}

struct AIPhase: Codable, Identifiable {
    var id: String { name }
    let name: String
    let durationWeeks: Int
    let outcomes: [String]
    let milestones: [String]

    enum CodingKeys: String, CodingKey {
        case name
        case durationWeeks = "duration_weeks"
        case outcomes
        case milestones
    }
}

// MARK: - Schedule Actions
struct AIScheduleAction: Codable, Identifiable {
    let id: String
    let type: ActionType
    let title: String
    let details: String
    let durationMinutes: Int
    let cadence: ActionCadence
    let preferredDays: [String]?
    let timeWindowLocal: TimeWindow?
    let energyLevel: EnergyLevel
    let priority: AIPriority
    let tags: [String]
    let successCheck: String

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case title
        case details
        case durationMinutes = "duration_minutes"
        case cadence
        case preferredDays = "preferred_days"
        case timeWindowLocal = "time_window_local"
        case energyLevel = "energy_level"
        case priority
        case tags
        case successCheck = "success_check"
    }
}

enum ActionType: String, Codable {
    case task
    case event
    case review
}

enum ActionCadence: String, Codable {
    case oneTime = "one_time"
    case daily
    case weekly
    case biweekly
    case monthly
}

struct TimeWindow: Codable {
    let start: String // "HH:MM"
    let end: String   // "HH:MM"

    var startHour: Int {
        let components = start.split(separator: ":")
        return Int(components.first ?? "9") ?? 9
    }

    var startMinute: Int {
        let components = start.split(separator: ":")
        return Int(components.last ?? "0") ?? 0
    }

    var endHour: Int {
        let components = end.split(separator: ":")
        return Int(components.first ?? "17") ?? 17
    }
}

enum EnergyLevel: String, Codable {
    case low
    case medium
    case high
}

// MARK: - Sources
struct AISource: Codable, Identifiable {
    var id: String { url }
    let title: String
    let url: String
    let whyItMatters: String

    enum CodingKeys: String, CodingKey {
        case title
        case url
        case whyItMatters = "why_it_matters"
    }
}

// MARK: - User Context (Input to AI)
struct AIUserContext: Codable {
    let unstructuredInput: String
    let structuredContext: StructuredUserContext
    let ambitionLevel: Int
    let hoursPerWeek: Int
    let existingEvents: [ExistingEventContext]
    let preferences: UserContextPreferences

    enum CodingKeys: String, CodingKey {
        case unstructuredInput = "unstructured_input"
        case structuredContext = "structured_context"
        case ambitionLevel = "ambition_level"
        case hoursPerWeek = "hours_per_week"
        case existingEvents = "existing_events"
        case preferences
    }
}

struct StructuredUserContext: Codable {
    let age: Int
    let educationLevel: String
    let currentOccupation: String
    let financialSituation: String
    let selectedCategory: String
    let specificGoal: String
    let timeframe: String
    let preferredTimeOfDay: String
    let additionalNotes: String?

    enum CodingKeys: String, CodingKey {
        case age
        case educationLevel = "education_level"
        case currentOccupation = "current_occupation"
        case financialSituation = "financial_situation"
        case selectedCategory = "selected_category"
        case specificGoal = "specific_goal"
        case timeframe
        case preferredTimeOfDay = "preferred_time_of_day"
        case additionalNotes = "additional_notes"
    }
}

struct ExistingEventContext: Codable {
    let title: String
    let dayOfWeek: String
    let timeSlot: String
    let durationMinutes: Int

    enum CodingKeys: String, CodingKey {
        case title
        case dayOfWeek = "day_of_week"
        case timeSlot = "time_slot"
        case durationMinutes = "duration_minutes"
    }
}

struct UserContextPreferences: Codable {
    let workloadStyle: String
    let reminderPreference: Bool
    let journalFormat: String

    enum CodingKeys: String, CodingKey {
        case workloadStyle = "workload_style"
        case reminderPreference = "reminder_preference"
        case journalFormat = "journal_format"
    }
}

// MARK: - Stored Plan Model (for Firestore)
struct StoredAIPlan: Codable, Identifiable {
    var id: String?
    let userId: String
    let response: AIPlanResponse
    let createdAt: Date
    let isActive: Bool
    let userInputSummary: String

    init(
        id: String? = nil,
        userId: String,
        response: AIPlanResponse,
        createdAt: Date = Date(),
        isActive: Bool = true,
        userInputSummary: String
    ) {
        self.id = id
        self.userId = userId
        self.response = response
        self.createdAt = createdAt
        self.isActive = isActive
        self.userInputSummary = userInputSummary
    }
}
