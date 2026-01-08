import Foundation
import SwiftUI
import Combine

/// Manages settings view state and actions
@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Published State

    @Published var blockRemindersEnabled: Bool = true
    @Published var reflectionRemindersEnabled: Bool = true
    @Published var quietHoursEnabled: Bool = false
    @Published var quietHoursStart: Date = Calendar.current.date(from: DateComponents(hour: 22, minute: 0)) ?? Date()
    @Published var quietHoursEnd: Date = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()

    @Published var availability: Availability = .normal
    @Published var intensity: Intensity = .balanced
    @Published var planConfidenceValue: Double = 0.5

    @Published var showPauseConfirmation = false
    @Published var showResetConfirmation = false
    @Published var isPaused = false

    // MARK: - Dependencies

    private let dataService: DataService
    private let notificationService: NotificationService

    // MARK: - Computed Properties

    var activeGoal: IdentityGoal? {
        dataService.activeGoal
    }

    var planConfidence: PlanConfidence {
        PlanConfidence.from(value: planConfidenceValue)
    }

    var appVersion: String {
        "\(Constants.App.version) (\(Constants.App.build))"
    }

    // MARK: - Initialization

    init(
        dataService: DataService = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.dataService = dataService
        self.notificationService = notificationService

        loadSettings()
    }

    // MARK: - Settings Loading

    func loadSettings() {
        guard let user = dataService.currentUser else { return }

        blockRemindersEnabled = user.blockRemindersEnabled
        reflectionRemindersEnabled = user.reflectionRemindersEnabled

        if let start = user.quietHoursStart, let end = user.quietHoursEnd {
            quietHoursEnabled = true
            quietHoursStart = start
            quietHoursEnd = end
        }

        if let goal = activeGoal {
            availability = goal.availability
            intensity = goal.intensity
            planConfidenceValue = goal.planConfidence.value
            isPaused = goal.status == .paused
        }
    }

    // MARK: - Notification Settings

    func toggleBlockReminders(_ enabled: Bool) {
        blockRemindersEnabled = enabled
        saveNotificationSettings()

        if enabled {
            Task {
                if let goal = activeGoal {
                    await notificationService.scheduleAllBlockReminders(for: goal.planBlocks)
                }
            }
        } else {
            // Cancel existing reminders
            notificationService.cancelAllNotifications()
        }
    }

    func toggleReflectionReminders(_ enabled: Bool) {
        reflectionRemindersEnabled = enabled
        saveNotificationSettings()

        if enabled {
            Task {
                await notificationService.scheduleWeeklyReflectionReminder()
            }
        } else {
            notificationService.cancelWeeklyReflectionReminder()
        }
    }

    func toggleQuietHours(_ enabled: Bool) {
        quietHoursEnabled = enabled
        saveNotificationSettings()
    }

    func updateQuietHours(start: Date, end: Date) {
        quietHoursStart = start
        quietHoursEnd = end
        saveNotificationSettings()
    }

    private func saveNotificationSettings() {
        guard let user = dataService.currentUser else { return }

        user.blockRemindersEnabled = blockRemindersEnabled
        user.reflectionRemindersEnabled = reflectionRemindersEnabled

        if quietHoursEnabled {
            user.quietHoursStart = quietHoursStart
            user.quietHoursEnd = quietHoursEnd
        } else {
            user.quietHoursStart = nil
            user.quietHoursEnd = nil
        }

        dataService.saveContext()
    }

    // MARK: - Goal Settings

    func updateAvailability(_ newValue: Availability) {
        Haptics.select()
        availability = newValue
        saveGoalSettings()
    }

    func updateIntensity(_ newValue: Intensity) {
        Haptics.select()
        intensity = newValue
        saveGoalSettings()
    }

    func updatePlanConfidence(_ value: Double) {
        planConfidenceValue = value
        saveGoalSettings()
    }

    private func saveGoalSettings() {
        guard let goal = activeGoal else { return }

        goal.availability = availability
        goal.intensity = intensity
        goal.planConfidence = planConfidence

        dataService.updateGoal(goal)
    }

    // MARK: - Goal Actions

    func pauseGoal() {
        guard let goal = activeGoal else { return }

        Haptics.medium()
        dataService.pauseGoal(goal)
        isPaused = true
        showPauseConfirmation = false
    }

    func resumeGoal() {
        guard let goal = activeGoal else { return }

        Haptics.tap()
        dataService.resumeGoal(goal)
        isPaused = false
    }

    func resetGoal() {
        guard let goal = activeGoal else { return }

        Haptics.delete()
        dataService.deleteGoal(goal)
        showResetConfirmation = false
    }

    // MARK: - External Links

    func openPrivacyPolicy() {
        if let url = URL(string: "https://endlessfuture.app/privacy") {
            UIApplication.shared.open(url)
        }
    }

    func openTermsOfService() {
        if let url = URL(string: "https://endlessfuture.app/terms") {
            UIApplication.shared.open(url)
        }
    }

    func openSupport() {
        if let url = URL(string: "https://endlessfuture.app/support") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Debug

    #if DEBUG
    func resetAllData() {
        dataService.resetAllData()
    }
    #endif
}
