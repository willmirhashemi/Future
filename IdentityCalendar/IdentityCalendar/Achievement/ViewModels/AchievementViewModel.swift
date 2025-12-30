import Foundation
import SwiftUI
import Combine

// MARK: - Achievement View Model

/// View model for achievement-related views
@MainActor
final class AchievementViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var achievements: [AchievementSnapshot] = []
    @Published private(set) var achievementsByCategory: [AchievementCategory: [AchievementSnapshot]] = [:]
    @Published private(set) var recentlyUnlocked: [AchievementSnapshot] = []
    @Published private(set) var statistics: AchievementStatistics?
    @Published private(set) var isLoading: Bool = false
    @Published var selectedAchievement: AchievementSnapshot?
    @Published var showUnlockAnimation: Bool = false

    // MARK: - Dependencies

    private let achievementService: AchievementService
    private let dataService: DataService
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties

    var unlockedCount: Int {
        achievements.filter { $0.isUnlocked }.count
    }

    var totalCount: Int {
        achievements.count
    }

    var progressText: String {
        "\(unlockedCount)/\(totalCount)"
    }

    var hasNewAchievements: Bool {
        achievements.contains { $0.isNew }
    }

    var sortedCategories: [AchievementCategory] {
        AchievementCategory.allCases.sorted { $0.sortOrder < $1.sortOrder }
    }

    // MARK: - Initialization

    init(
        achievementService: AchievementService = .shared,
        dataService: DataService = .shared
    ) {
        self.achievementService = achievementService
        self.dataService = dataService

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        // Listen for achievement unlocks
        achievementService.unlockPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleUnlock(event)
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadAchievements() {
        guard let user = dataService.currentUser else { return }

        isLoading = true

        // Get all achievements as snapshots
        achievements = achievementService.getAchievementSnapshots(for: user)

        // Group by category
        achievementsByCategory = achievementService.getAchievementsByCategory(for: user)

        // Get recently unlocked (last 5)
        recentlyUnlocked = achievementService.getUnlockedAchievements(for: user)
            .prefix(5)
            .map { $0 }

        // Get statistics
        statistics = achievementService.getStatistics(for: user)

        isLoading = false
    }

    func refresh() {
        loadAchievements()
    }

    // MARK: - Actions

    func selectAchievement(_ achievement: AchievementSnapshot) {
        selectedAchievement = achievement
        Haptics.tap()
    }

    func dismissSelectedAchievement() {
        selectedAchievement = nil
    }

    func markAllAsSeen() {
        guard let user = dataService.currentUser else { return }
        achievementService.markAllAsNotified(for: user)
        loadAchievements()
    }

    func markAsSeen(_ achievement: AchievementSnapshot) {
        guard let user = dataService.currentUser else { return }
        achievementService.markAsNotified(achievement.id, for: user)
        loadAchievements()
    }

    // MARK: - Unlock Handling

    private func handleUnlock(_ event: AchievementUnlockEvent) {
        // Add to recently unlocked
        recentlyUnlocked.insert(event.achievement, at: 0)
        if recentlyUnlocked.count > 5 {
            recentlyUnlocked = Array(recentlyUnlocked.prefix(5))
        }

        // Show unlock animation
        showUnlockAnimation = true

        // Refresh achievements
        loadAchievements()

        // Trigger haptic
        Haptics.achievement()
    }

    func dismissUnlockAnimation() {
        showUnlockAnimation = false
        achievementService.clearRecentUnlocks()
    }

    // MARK: - Helpers

    func achievements(for category: AchievementCategory) -> [AchievementSnapshot] {
        achievementsByCategory[category] ?? []
    }

    func progressForCategory(_ category: AchievementCategory) -> (unlocked: Int, total: Int) {
        let categoryAchievements = achievements(for: category)
        let unlocked = categoryAchievements.filter { $0.isUnlocked }.count
        return (unlocked, categoryAchievements.count)
    }
}

// MARK: - Preview Support

extension AchievementViewModel {

    static var preview: AchievementViewModel {
        let vm = AchievementViewModel()

        // Add sample achievements
        vm.achievements = [
            AchievementSnapshot(type: .firstStep, isUnlocked: true, progress: 1, unlockedAt: Date()),
            AchievementSnapshot(type: .weekWarrior, isUnlocked: true, progress: 7, unlockedAt: Date().addingTimeInterval(-86400)),
            AchievementSnapshot(type: .twoWeekTitan, isUnlocked: false, progress: 10),
            AchievementSnapshot(type: .monthlyMaster, isUnlocked: false, progress: 10),
            AchievementSnapshot(type: .tenBlocks, isUnlocked: true, progress: 10, unlockedAt: Date().addingTimeInterval(-172800)),
            AchievementSnapshot(type: .fiftyBlocks, isUnlocked: false, progress: 35),
        ]

        // Group by category
        for category in AchievementCategory.allCases {
            vm.achievementsByCategory[category] = vm.achievements.filter { $0.metadata.category == category }
        }

        vm.recentlyUnlocked = vm.achievements.filter { $0.isUnlocked }

        return vm
    }
}
