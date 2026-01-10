import Foundation
import FirebaseFirestore

// MARK: - Journal Entry Model
struct JournalEntry: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var date: Date
    var content: String
    var mood: Mood
    var guidedResponses: GuidedResponses?
    var accomplishments: [String]
    var gratitude: [String]
    var tags: [String]
    var createdAt: Date
    var updatedAt: Date

    init(
        id: String? = nil,
        userId: String,
        date: Date = Date(),
        content: String = "",
        mood: Mood = .neutral,
        guidedResponses: GuidedResponses? = nil,
        accomplishments: [String] = [],
        gratitude: [String] = [],
        tags: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.date = date
        self.content = content
        self.mood = mood
        self.guidedResponses = guidedResponses
        self.accomplishments = accomplishments
        self.gratitude = gratitude
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }

    var shortFormattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Mood
enum Mood: String, Codable, CaseIterable {
    case great = "great"
    case good = "good"
    case neutral = "neutral"
    case bad = "bad"
    case terrible = "terrible"

    var displayName: String {
        switch self {
        case .great: return "Great"
        case .good: return "Good"
        case .neutral: return "Neutral"
        case .bad: return "Bad"
        case .terrible: return "Terrible"
        }
    }

    var emoji: String {
        switch self {
        case .great: return "😄"
        case .good: return "🙂"
        case .neutral: return "😐"
        case .bad: return "😔"
        case .terrible: return "😢"
        }
    }

    var icon: String {
        switch self {
        case .great: return "face.smiling.fill"
        case .good: return "face.smiling"
        case .neutral: return "minus.circle"
        case .bad: return "cloud.rain"
        case .terrible: return "cloud.bolt.rain"
        }
    }

    var colorHex: String {
        switch self {
        case .great: return "4CAF50"
        case .good: return "8BC34A"
        case .neutral: return "FFC107"
        case .bad: return "FF9800"
        case .terrible: return "F44336"
        }
    }
}

// MARK: - Guided Responses
struct GuidedResponses: Codable {
    var whatAccomplished: String?
    var whatLearned: String?
    var challengesFaced: String?
    var tomorrowGoals: String?
    var gratefulFor: String?
    var overallThoughts: String?

    init(
        whatAccomplished: String? = nil,
        whatLearned: String? = nil,
        challengesFaced: String? = nil,
        tomorrowGoals: String? = nil,
        gratefulFor: String? = nil,
        overallThoughts: String? = nil
    ) {
        self.whatAccomplished = whatAccomplished
        self.whatLearned = whatLearned
        self.challengesFaced = challengesFaced
        self.tomorrowGoals = tomorrowGoals
        self.gratefulFor = gratefulFor
        self.overallThoughts = overallThoughts
    }
}

// MARK: - Weekly Review
struct WeeklyReview: Codable, Identifiable {
    @DocumentID var id: String?
    var userId: String
    var weekStartDate: Date
    var weekEndDate: Date
    var journalEntries: [String] // Journal entry IDs
    var accomplishedGoals: [String]
    var missedGoals: [String]
    var overallMood: Mood
    var reflectionNotes: String
    var nextWeekIntentions: String
    var createdAt: Date

    init(
        id: String? = nil,
        userId: String,
        weekStartDate: Date,
        weekEndDate: Date,
        journalEntries: [String] = [],
        accomplishedGoals: [String] = [],
        missedGoals: [String] = [],
        overallMood: Mood = .neutral,
        reflectionNotes: String = "",
        nextWeekIntentions: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.weekStartDate = weekStartDate
        self.weekEndDate = weekEndDate
        self.journalEntries = journalEntries
        self.accomplishedGoals = accomplishedGoals
        self.missedGoals = missedGoals
        self.overallMood = overallMood
        self.reflectionNotes = reflectionNotes
        self.nextWeekIntentions = nextWeekIntentions
        self.createdAt = createdAt
    }

    var weekRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "\(formatter.string(from: weekStartDate)) - \(formatter.string(from: weekEndDate))"
    }
}
