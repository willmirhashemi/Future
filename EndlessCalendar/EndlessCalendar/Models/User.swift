import Foundation
import FirebaseFirestore

// MARK: - User Model
struct User: Codable, Identifiable {
    @DocumentID var id: String?
    var email: String
    var displayName: String
    var profileImageURL: String?
    var createdAt: Date
    var lastActiveAt: Date
    var hasCompletedOnboarding: Bool
    var selectedCategory: GoalCategory?
    var questionnaireResponses: QuestionnaireResponses?
    var preferences: UserPreferences
    var stats: UserStats

    init(
        id: String? = nil,
        email: String,
        displayName: String,
        profileImageURL: String? = nil,
        createdAt: Date = Date(),
        lastActiveAt: Date = Date(),
        hasCompletedOnboarding: Bool = false,
        selectedCategory: GoalCategory? = nil,
        questionnaireResponses: QuestionnaireResponses? = nil,
        preferences: UserPreferences = UserPreferences(),
        stats: UserStats = UserStats()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.createdAt = createdAt
        self.lastActiveAt = lastActiveAt
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.selectedCategory = selectedCategory
        self.questionnaireResponses = questionnaireResponses
        self.preferences = preferences
        self.stats = stats
    }
}

// MARK: - Goal Categories
enum GoalCategory: String, Codable, CaseIterable, Identifiable {
    case studyLearning = "study_learning"
    case fitnessHealth = "fitness_health"
    case financial = "financial"
    case creativeHobby = "creative_hobby"
    case networkingSocial = "networking_social"
    case selfCareRest = "self_care_rest"
    case careerDevelopment = "career_development"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .studyLearning: return "Study & Learning"
        case .fitnessHealth: return "Fitness & Health"
        case .financial: return "Financial"
        case .creativeHobby: return "Creative & Hobby"
        case .networkingSocial: return "Networking & Social"
        case .selfCareRest: return "Self-Care & Rest"
        case .careerDevelopment: return "Career Development"
        }
    }

    var icon: String {
        switch self {
        case .studyLearning: return "book.fill"
        case .fitnessHealth: return "figure.run"
        case .financial: return "dollarsign.circle.fill"
        case .creativeHobby: return "paintbrush.fill"
        case .networkingSocial: return "person.3.fill"
        case .selfCareRest: return "leaf.fill"
        case .careerDevelopment: return "briefcase.fill"
        }
    }

    var description: String {
        switch self {
        case .studyLearning:
            return "Master new skills, ace exams, and expand your knowledge"
        case .fitnessHealth:
            return "Build healthy habits, achieve fitness goals, and improve wellness"
        case .financial:
            return "Save money, invest wisely, and build financial freedom"
        case .creativeHobby:
            return "Develop creative skills, start projects, and express yourself"
        case .networkingSocial:
            return "Build relationships, expand your network, and connect with others"
        case .selfCareRest:
            return "Prioritize mental health, relaxation, and personal well-being"
        case .careerDevelopment:
            return "Advance your career, develop professional skills, and achieve success"
        }
    }
}

// MARK: - Questionnaire Responses
struct QuestionnaireResponses: Codable {
    var age: Int
    var educationLevel: EducationLevel
    var currentOccupation: String
    var financialSituation: FinancialSituation
    var specificGoal: String
    var timeframe: GoalTimeframe
    var availableHoursPerDay: Int
    var preferredTimeOfDay: PreferredTime
    var additionalNotes: String?

    init(
        age: Int = 18,
        educationLevel: EducationLevel = .highSchool,
        currentOccupation: String = "",
        financialSituation: FinancialSituation = .comfortable,
        specificGoal: String = "",
        timeframe: GoalTimeframe = .threeMonths,
        availableHoursPerDay: Int = 2,
        preferredTimeOfDay: PreferredTime = .morning,
        additionalNotes: String? = nil
    ) {
        self.age = age
        self.educationLevel = educationLevel
        self.currentOccupation = currentOccupation
        self.financialSituation = financialSituation
        self.specificGoal = specificGoal
        self.timeframe = timeframe
        self.availableHoursPerDay = availableHoursPerDay
        self.preferredTimeOfDay = preferredTimeOfDay
        self.additionalNotes = additionalNotes
    }
}

enum EducationLevel: String, Codable, CaseIterable {
    case highSchool = "high_school"
    case someCollege = "some_college"
    case bachelors = "bachelors"
    case masters = "masters"
    case doctorate = "doctorate"
    case other = "other"

    var displayName: String {
        switch self {
        case .highSchool: return "High School"
        case .someCollege: return "Some College"
        case .bachelors: return "Bachelor's Degree"
        case .masters: return "Master's Degree"
        case .doctorate: return "Doctorate"
        case .other: return "Other"
        }
    }
}

enum FinancialSituation: String, Codable, CaseIterable {
    case struggling = "struggling"
    case tight = "tight"
    case comfortable = "comfortable"
    case wellOff = "well_off"
    case preferNotToSay = "prefer_not_to_say"

    var displayName: String {
        switch self {
        case .struggling: return "Struggling"
        case .tight: return "Tight Budget"
        case .comfortable: return "Comfortable"
        case .wellOff: return "Well Off"
        case .preferNotToSay: return "Prefer Not to Say"
        }
    }
}

enum GoalTimeframe: String, Codable, CaseIterable {
    case oneMonth = "one_month"
    case threeMonths = "three_months"
    case sixMonths = "six_months"
    case oneYear = "one_year"
    case fiveYears = "five_years"

    var displayName: String {
        switch self {
        case .oneMonth: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .oneYear: return "1 Year"
        case .fiveYears: return "5 Years"
        }
    }
}

enum PreferredTime: String, Codable, CaseIterable {
    case earlyMorning = "early_morning"
    case morning = "morning"
    case afternoon = "afternoon"
    case evening = "evening"
    case night = "night"
    case flexible = "flexible"

    var displayName: String {
        switch self {
        case .earlyMorning: return "Early Morning (5-7 AM)"
        case .morning: return "Morning (7-12 PM)"
        case .afternoon: return "Afternoon (12-5 PM)"
        case .evening: return "Evening (5-9 PM)"
        case .night: return "Night (9 PM+)"
        case .flexible: return "Flexible"
        }
    }
}

// MARK: - User Preferences
struct UserPreferences: Codable {
    var inactivityResetWeeks: Int
    var journalFormat: JournalFormat
    var notificationsEnabled: Bool
    var dailyReminderTime: Date?
    var weeklyReviewEnabled: Bool
    var weeklyReviewDay: Int // 1 = Sunday, 7 = Saturday

    init(
        inactivityResetWeeks: Int = 2,
        journalFormat: JournalFormat = .freeForm,
        notificationsEnabled: Bool = true,
        dailyReminderTime: Date? = nil,
        weeklyReviewEnabled: Bool = true,
        weeklyReviewDay: Int = 1
    ) {
        self.inactivityResetWeeks = inactivityResetWeeks
        self.journalFormat = journalFormat
        self.notificationsEnabled = notificationsEnabled
        self.dailyReminderTime = dailyReminderTime
        self.weeklyReviewEnabled = weeklyReviewEnabled
        self.weeklyReviewDay = weeklyReviewDay
    }
}

enum JournalFormat: String, Codable, CaseIterable {
    case freeForm = "free_form"
    case guidedPrompts = "guided_prompts"

    var displayName: String {
        switch self {
        case .freeForm: return "Free Form"
        case .guidedPrompts: return "Guided Prompts"
        }
    }
}

// MARK: - User Stats
struct UserStats: Codable {
    var totalJournalEntries: Int
    var currentJournalStreak: Int
    var longestJournalStreak: Int
    var totalManualEvents: Int
    var totalAIEventsCompleted: Int
    var achievementsUnlocked: [String]

    init(
        totalJournalEntries: Int = 0,
        currentJournalStreak: Int = 0,
        longestJournalStreak: Int = 0,
        totalManualEvents: Int = 0,
        totalAIEventsCompleted: Int = 0,
        achievementsUnlocked: [String] = []
    ) {
        self.totalJournalEntries = totalJournalEntries
        self.currentJournalStreak = currentJournalStreak
        self.longestJournalStreak = longestJournalStreak
        self.totalManualEvents = totalManualEvents
        self.totalAIEventsCompleted = totalAIEventsCompleted
        self.achievementsUnlocked = achievementsUnlocked
    }
}
