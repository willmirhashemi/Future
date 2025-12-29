import Foundation
import UserNotifications

/// Handles all notification-related functionality
final class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published private(set) var isAuthorized = false

    private let center = UNUserNotificationCenter.current()

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        let authorized = settings.authorizationStatus == .authorized
        await MainActor.run {
            isAuthorized = authorized
        }
    }

    // MARK: - Block Reminders

    func scheduleBlockReminder(for block: PlanBlock, minutesBefore: Int = 15) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = block.title
        content.body = block.intentShort
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.blockReminder.rawValue

        let triggerDate = block.startDateTime.addingTimeInterval(-Double(minutesBefore * 60))
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "block-\(block.id.uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule block reminder: \(error)")
        }
    }

    func cancelBlockReminder(for block: PlanBlock) {
        center.removePendingNotificationRequests(withIdentifiers: ["block-\(block.id.uuidString)"])
    }

    // MARK: - Weekly Reflection Reminder

    func scheduleWeeklyReflectionReminder() async {
        guard isAuthorized else { return }

        // Remove existing reflection reminders
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-reflection"])

        let content = UNMutableNotificationContent()
        content.title = "Weekly Reflection"
        content.body = "Take a moment to reflect on your week."
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.reflection.rawValue

        // Schedule for Sunday at 6 PM
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 18
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "weekly-reflection",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to schedule reflection reminder: \(error)")
        }
    }

    func cancelWeeklyReflectionReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["weekly-reflection"])
    }

    // MARK: - Adaptation Notification

    func sendAdaptationNotification(summary: String) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "Plan Updated"
        content.body = summary
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.adaptation.rawValue

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "adaptation-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Failed to send adaptation notification: \(error)")
        }
    }

    // MARK: - Bulk Operations

    func scheduleAllBlockReminders(for blocks: [PlanBlock]) async {
        for block in blocks where block.status == .scheduled && block.startDateTime > Date() {
            await scheduleBlockReminder(for: block)
        }
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
    }

    // MARK: - Quiet Hours

    func isWithinQuietHours(start: Date?, end: Date?) -> Bool {
        guard let start = start, let end = end else { return false }

        let now = Date()
        let calendar = Calendar.current

        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)
        let startComponents = calendar.dateComponents([.hour, .minute], from: start)
        let endComponents = calendar.dateComponents([.hour, .minute], from: end)

        guard let nowMinutes = nowComponents.hour.map({ $0 * 60 + (nowComponents.minute ?? 0) }),
              let startMinutes = startComponents.hour.map({ $0 * 60 + (startComponents.minute ?? 0) }),
              let endMinutes = endComponents.hour.map({ $0 * 60 + (endComponents.minute ?? 0) }) else {
            return false
        }

        if startMinutes <= endMinutes {
            return nowMinutes >= startMinutes && nowMinutes <= endMinutes
        } else {
            // Quiet hours span midnight
            return nowMinutes >= startMinutes || nowMinutes <= endMinutes
        }
    }
}

// MARK: - Notification Categories

enum NotificationCategory: String {
    case blockReminder = "BLOCK_REMINDER"
    case reflection = "REFLECTION"
    case adaptation = "ADAPTATION"
}

// MARK: - Notification Actions

enum NotificationAction: String {
    case start = "START_BLOCK"
    case skip = "SKIP_BLOCK"
    case snooze = "SNOOZE_BLOCK"
    case openReflection = "OPEN_REFLECTION"
}
