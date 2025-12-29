import Foundation
import SwiftUI

/// Manages progress tracking view state
@MainActor
final class ProgressViewModel: ObservableObject {
    // MARK: - Published State

    @Published var progressPercentage: Double = 0
    @Published var currentStreak: Int = 0
    @Published var longestStreak: Int = 0
    @Published var milestones: [Milestone] = []
    @Published var weeklyStats: [WeeklyStatData] = []
    @Published var isLoading = false

    // MARK: - Dependencies

    private let dataService: DataService

    // MARK: - Computed Properties

    var activeGoal: IdentityGoal? {
        dataService.activeGoal
    }

    var identityName: String {
        activeGoal?.displayName ?? "Your Goal"
    }

    var timeRemaining: String {
        guard let goal = activeGoal else { return "" }

        let calendar = Calendar.current
        let endDate = calendar.date(
            byAdding: .day,
            value: goal.timeHorizon.days,
            to: goal.createdAt
        ) ?? Date()

        let daysRemaining = calendar.dateComponents([.day], from: Date(), to: endDate).day ?? 0

        if daysRemaining <= 0 {
            return "Complete"
        } else if daysRemaining == 1 {
            return "1 day left"
        } else if daysRemaining < 7 {
            return "\(daysRemaining) days left"
        } else {
            let weeks = daysRemaining / 7
            return "\(weeks) week\(weeks == 1 ? "" : "s") left"
        }
    }

    var completedMilestones: Int {
        milestones.filter { $0.isCompleted }.count
    }

    var totalBlocks: Int {
        activeGoal?.totalBlocksScheduled ?? 0
    }

    var completedBlocks: Int {
        activeGoal?.totalBlocksCompleted ?? 0
    }

    var engagementRate: Double {
        guard let goal = activeGoal, goal.totalBlocksScheduled > 0 else { return 0 }

        // Count engaged blocks (completed, moved, or reduced)
        let engagedCount = goal.planBlocks.filter { block in
            block.status == .completed || block.wasMoved || block.wasReduced
        }.count

        return Double(engagedCount) / Double(goal.totalBlocksScheduled)
    }

    // MARK: - Initialization

    init(dataService: DataService = .shared) {
        self.dataService = dataService
        loadData()
    }

    // MARK: - Data Loading

    func loadData() {
        guard let goal = activeGoal else { return }

        progressPercentage = dataService.calculateProgress(for: goal)
        currentStreak = goal.currentStreak
        longestStreak = goal.longestStreak

        milestones = goal.milestones.sorted { $0.weekNumber < $1.weekNumber }

        loadWeeklyStats()
    }

    func refresh() {
        loadData()
    }

    private func loadWeeklyStats() {
        guard let goal = activeGoal else {
            weeklyStats = []
            return
        }

        var stats: [WeeklyStatData] = []
        let calendar = Calendar.current
        let today = Date()

        // Get past weeks (up to 8 weeks)
        for weekOffset in (0..<8).reversed() {
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else {
                continue
            }

            let weekStartNormalized = weekStart.startOfWeek
            let weekEnd = weekStartNormalized.adding(days: 7)

            let blocks = dataService.blocksForDateRange(start: weekStartNormalized, end: weekEnd, goal: goal)

            guard !blocks.isEmpty else { continue }

            let completed = blocks.filter { $0.status == .completed }.count
            let total = blocks.count

            stats.append(WeeklyStatData(
                weekStart: weekStartNormalized,
                completedBlocks: completed,
                totalBlocks: total,
                completionRate: total > 0 ? Double(completed) / Double(total) : 0
            ))
        }

        weeklyStats = stats
    }

    // MARK: - Milestone Actions

    func markMilestoneComplete(_ milestone: Milestone) {
        Haptics.complete()
        dataService.completeMilestone(milestone)
        loadData()
    }
}

// MARK: - Weekly Stat Data

struct WeeklyStatData: Identifiable {
    let id = UUID()
    let weekStart: Date
    let completedBlocks: Int
    let totalBlocks: Int
    let completionRate: Double

    var weekLabel: String {
        weekStart.shortMonthString + " " + weekStart.dayNumberString
    }

    var barHeight: CGFloat {
        CGFloat(completionRate)
    }
}

// MARK: - Streak Display Helper

extension ProgressViewModel {
    var streakMessage: String {
        if currentStreak == 0 {
            return "Start your momentum"
        } else if currentStreak == 1 {
            return "1 day engaged"
        } else {
            return "\(currentStreak) days engaged"
        }
    }

    var streakEmoji: String {
        if currentStreak == 0 {
            return ""
        } else if currentStreak < 7 {
            return ""
        } else if currentStreak < 30 {
            return ""
        } else {
            return ""
        }
    }
}
