import Foundation
import SwiftUI

/// App-wide constants
enum Constants {
    // MARK: - App Info
    enum App {
        static let name = "Identity Calendar"
        static let bundleId = "com.identitycalendar.app"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        static let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    // MARK: - Layout
    enum Layout {
        static let screenPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let smallSpacing: CGFloat = 8
        static let tinySpacing: CGFloat = 4

        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16

        static let buttonHeight: CGFloat = 54
        static let smallButtonHeight: CGFloat = 44

        static let iconSize: CGFloat = 24
        static let smallIconSize: CGFloat = 18
        static let largeIconSize: CGFloat = 32
    }

    // MARK: - Animation
    enum Animation {
        static let quick: SwiftUI.Animation = .easeInOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.35)
        static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.75)
    }

    // MARK: - Calendar
    enum Calendar {
        static let hourHeight: CGFloat = 60
        static let timeColumnWidth: CGFloat = 50
        static let dayHeaderHeight: CGFloat = 60
        static let blockMinHeight: CGFloat = 30
        static let startHour = 6 // 6 AM
        static let endHour = 23 // 11 PM
    }

    // MARK: - Onboarding
    enum Onboarding {
        static let totalSteps = 5
        static let progressBarHeight: CGFloat = 4
    }

    // MARK: - Timing
    enum Timing {
        static let debounceDelay: TimeInterval = 0.3
        static let autoSaveDelay: TimeInterval = 1.0
        static let notificationLeadTime: TimeInterval = 15 * 60 // 15 minutes
    }

    // MARK: - Limits
    enum Limits {
        static let maxCustomIdentityNameLength = 50
        static let maxNoteLength = 500
        static let maxGoalsFree = 1
        static let maxGoalsPro = Int.max
    }

    // MARK: - URLs
    enum URLs {
        static let privacyPolicy = URL(string: "https://identitycalendar.com/privacy")!
        static let termsOfService = URL(string: "https://identitycalendar.com/terms")!
        static let support = URL(string: "https://identitycalendar.com/support")!
    }

    // MARK: - UserDefaults Keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedCalendarView = "selectedCalendarView"
        static let lastReflectionPrompt = "lastReflectionPrompt"
        static let notificationsEnabled = "notificationsEnabled"
    }

    // MARK: - Notification Identifiers
    enum NotificationIds {
        static let blockReminder = "block_reminder"
        static let reflectionReminder = "reflection_reminder"
        static let weeklyAdaptation = "weekly_adaptation"
    }
}

// MARK: - Feature Flags

enum FeatureFlags {
    static let enableAIPlanning = true
    static let enableWeeklyAdaptation = true
    static let enableSmartRescheduling = true
    static let enableDebugMenu = false

    #if DEBUG
    static let useMockAI = true
    #else
    static let useMockAI = false
    #endif
}
