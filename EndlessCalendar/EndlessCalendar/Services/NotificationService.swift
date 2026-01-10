import Foundation
import UserNotifications
import UIKit

// MARK: - Notification Service
@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    @Published var pendingNotifications: [UNNotificationRequest] = []

    private let notificationCenter = UNUserNotificationCenter.current()

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Event Reminders
    func scheduleEventReminder(for event: Event) async {
        guard isAuthorized, let reminder = event.reminder, reminder.isEnabled else { return }
        guard let eventId = event.id else { return }

        let content = UNMutableNotificationContent()
        content.title = "Upcoming: \(event.title)"
        content.body = event.description ?? "You have an event coming up"
        content.sound = .default
        content.categoryIdentifier = "EVENT_REMINDER"
        content.userInfo = ["eventId": eventId]

        let triggerDate = Calendar.current.date(
            byAdding: .minute,
            value: -reminder.minutesBefore,
            to: event.startTime
        )!

        // Only schedule if the trigger date is in the future
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "event_\(eventId)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule notification: \(error)")
        }
    }

    func cancelEventReminder(eventId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["event_\(eventId)"])
    }

    // MARK: - Daily Reminder
    func scheduleDailyReminder(at time: Date) async {
        guard isAuthorized else { return }

        // Cancel existing daily reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to check your calendar"
        content.body = "Review your tasks and stay on track with your goals!"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "daily_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule daily reminder: \(error)")
        }
    }

    func cancelDailyReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"])
    }

    // MARK: - Weekly Review Reminder
    func scheduleWeeklyReviewReminder() async {
        guard isAuthorized else { return }

        // Cancel existing weekly reminders
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weekly_review"])

        let content = UNMutableNotificationContent()
        content.title = "Weekly Review Time"
        content.body = "Take a moment to reflect on your week and set intentions for the next one."
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_REVIEW"

        // Schedule for Sunday at 6 PM
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly_review",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule weekly review reminder: \(error)")
        }
    }

    func cancelWeeklyReviewReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["weekly_review"])
    }

    // MARK: - Journal Reminder
    func scheduleJournalReminder(at time: Date) async {
        guard isAuthorized else { return }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["journal_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "Time to Journal"
        content.body = "Take a few minutes to reflect on your day and track your progress."
        content.sound = .default
        content.categoryIdentifier = "JOURNAL_REMINDER"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: "journal_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule journal reminder: \(error)")
        }
    }

    func cancelJournalReminder() {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["journal_reminder"])
    }

    // MARK: - Inactivity Reminder
    func scheduleInactivityReminder(afterDays days: Int) async {
        guard isAuthorized else { return }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["inactivity_reminder"])

        let content = UNMutableNotificationContent()
        content.title = "We miss you!"
        content.body = "It's been a while since you checked your goals. Come back and stay on track!"
        content.sound = .default
        content.categoryIdentifier = "INACTIVITY_REMINDER"

        let triggerDate = Calendar.current.date(byAdding: .day, value: days, to: Date())!
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "inactivity_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule inactivity reminder: \(error)")
        }
    }

    // MARK: - Achievement Notification
    func showAchievementNotification(achievement: Achievement) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "\(achievement.title): \(achievement.description)"
        content.sound = .default
        content.categoryIdentifier = "ACHIEVEMENT"

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "achievement_\(achievement.id)",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to show achievement notification: \(error)")
        }
    }

    // MARK: - Batch Schedule Events
    func scheduleRemindersForEvents(_ events: [Event]) async {
        for event in events {
            await scheduleEventReminder(for: event)
        }
    }

    // MARK: - Clear All Notifications
    func clearAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }

    // MARK: - Get Pending Notifications
    func fetchPendingNotifications() async {
        let requests = await notificationCenter.pendingNotificationRequests()
        await MainActor.run {
            pendingNotifications = requests
        }
    }

    // MARK: - Setup Notification Categories
    func setupNotificationCategories() {
        let viewAction = UNNotificationAction(
            identifier: "VIEW_ACTION",
            title: "View",
            options: [.foreground]
        )

        let dismissAction = UNNotificationAction(
            identifier: "DISMISS_ACTION",
            title: "Dismiss",
            options: [.destructive]
        )

        let snoozeAction = UNNotificationAction(
            identifier: "SNOOZE_ACTION",
            title: "Snooze 10 min",
            options: []
        )

        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_REMINDER",
            actions: [viewAction, snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let dailyCategory = UNNotificationCategory(
            identifier: "DAILY_REMINDER",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let weeklyCategory = UNNotificationCategory(
            identifier: "WEEKLY_REVIEW",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let journalCategory = UNNotificationCategory(
            identifier: "JOURNAL_REMINDER",
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )

        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT",
            actions: [viewAction],
            intentIdentifiers: [],
            options: []
        )

        notificationCenter.setNotificationCategories([
            eventCategory,
            dailyCategory,
            weeklyCategory,
            journalCategory,
            achievementCategory
        ])
    }
}
