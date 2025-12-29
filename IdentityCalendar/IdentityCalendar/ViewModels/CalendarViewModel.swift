import Foundation
import SwiftUI

/// Manages the calendar view state and interactions
@MainActor
final class CalendarViewModel: ObservableObject {
    // MARK: - Published State

    @Published var selectedDate: Date = Date()
    @Published var viewMode: CalendarViewMode = .week
    @Published var blocksForDisplay: [PlanBlock] = []
    @Published var selectedBlock: PlanBlock?
    @Published var showBlockDetail = false
    @Published var showReflectionPrompt = false
    @Published var currentWeekTheme: WeeklyTheme?
    @Published var isLoading = false

    // MARK: - Dependencies

    private let dataService: DataService
    private let subscriptionService: SubscriptionService

    // MARK: - Computed Properties

    var activeGoal: IdentityGoal? {
        dataService.activeGoal
    }

    var displayDates: [Date] {
        switch viewMode {
        case .week:
            return selectedDate.daysOfWeek()
        case .day:
            return [selectedDate]
        }
    }

    var headerTitle: String {
        switch viewMode {
        case .week:
            let weekDates = selectedDate.daysOfWeek()
            guard let first = weekDates.first, let last = weekDates.last else {
                return selectedDate.monthYearString
            }

            if first.monthString == last.monthString {
                return first.monthYearString
            } else {
                return "\(first.shortMonthString) - \(last.shortMonthString) \(last.monthYearString.suffix(4))"
            }
        case .day:
            return selectedDate.relativeString
        }
    }

    var weekNumber: Int {
        guard let goal = activeGoal else { return 1 }
        let weeks = Calendar.current.dateComponents([.weekOfYear], from: goal.createdAt, to: selectedDate).weekOfYear ?? 0
        return max(1, weeks + 1)
    }

    var todayBlocksCount: Int {
        guard let goal = activeGoal else { return 0 }
        return dataService.blocksForDate(Date(), goal: goal).count
    }

    var todayCompletedCount: Int {
        guard let goal = activeGoal else { return 0 }
        return dataService.blocksForDate(Date(), goal: goal).filter { $0.status == .completed }.count
    }

    // MARK: - Initialization

    init(
        dataService: DataService = .shared,
        subscriptionService: SubscriptionService = .shared
    ) {
        self.dataService = dataService
        self.subscriptionService = subscriptionService

        loadBlocks()
        checkForReflection()
    }

    // MARK: - Data Loading

    func loadBlocks() {
        guard let goal = activeGoal else {
            blocksForDisplay = []
            return
        }

        switch viewMode {
        case .week:
            blocksForDisplay = dataService.blocksForWeek(containing: selectedDate, goal: goal)
        case .day:
            blocksForDisplay = dataService.blocksForDate(selectedDate, goal: goal)
        }

        currentWeekTheme = dataService.currentWeekTheme(for: goal)
    }

    func refresh() {
        loadBlocks()
        checkForReflection()
    }

    // MARK: - Navigation

    func goToToday() {
        Haptics.navigate()
        withAnimation(Constants.Animation.standard) {
            selectedDate = Date()
            loadBlocks()
        }
    }

    func goToPreviousPeriod() {
        Haptics.navigate()
        withAnimation(Constants.Animation.standard) {
            switch viewMode {
            case .week:
                selectedDate = selectedDate.adding(weeks: -1)
            case .day:
                selectedDate = selectedDate.adding(days: -1)
            }
            loadBlocks()
        }
    }

    func goToNextPeriod() {
        Haptics.navigate()
        withAnimation(Constants.Animation.standard) {
            switch viewMode {
            case .week:
                selectedDate = selectedDate.adding(weeks: 1)
            case .day:
                selectedDate = selectedDate.adding(days: 1)
            }
            loadBlocks()
        }
    }

    func selectDate(_ date: Date) {
        Haptics.select()
        withAnimation(Constants.Animation.quick) {
            selectedDate = date
            if viewMode == .day {
                loadBlocks()
            }
        }
    }

    func toggleViewMode() {
        Haptics.toggle()
        withAnimation(Constants.Animation.standard) {
            viewMode = viewMode == .week ? .day : .week
            loadBlocks()
        }
    }

    func setViewMode(_ mode: CalendarViewMode) {
        guard mode != viewMode else { return }
        Haptics.toggle()
        withAnimation(Constants.Animation.standard) {
            viewMode = mode
            loadBlocks()
        }
    }

    // MARK: - Block Selection

    func selectBlock(_ block: PlanBlock) {
        Haptics.select()
        selectedBlock = block
        showBlockDetail = true
    }

    func dismissBlockDetail() {
        showBlockDetail = false
        selectedBlock = nil
        loadBlocks()
    }

    // MARK: - Block Actions

    func startBlock(_ block: PlanBlock) {
        Haptics.tap()
        block.markAsInProgress()
        dataService.updateBlock(block)
        loadBlocks()
    }

    func completeBlock(_ block: PlanBlock) {
        Haptics.complete()
        dataService.completeBlock(block)
        loadBlocks()
        dismissBlockDetail()
    }

    func skipBlock(_ block: PlanBlock) {
        Haptics.tap()
        dataService.skipBlock(block)
        loadBlocks()
        dismissBlockDetail()
    }

    func moveBlock(_ block: PlanBlock, to newDate: Date) {
        Haptics.tap()
        dataService.moveBlock(block, to: newDate)
        loadBlocks()
        dismissBlockDetail()
    }

    func reduceBlock(_ block: PlanBlock) {
        Haptics.tap()
        dataService.reduceBlock(block)
        loadBlocks()
    }

    func addBlock(_ block: PlanBlock) {
        Haptics.success()
        guard let goal = activeGoal else { return }
        dataService.addBlocks([block], to: goal)
        loadBlocks()
    }

    // MARK: - Reflection

    func checkForReflection() {
        guard let goal = activeGoal else {
            showReflectionPrompt = false
            return
        }

        showReflectionPrompt = dataService.needsReflection(for: goal)
    }

    func dismissReflectionPrompt() {
        showReflectionPrompt = false
    }

    // MARK: - Helpers

    func blocksForDate(_ date: Date) -> [PlanBlock] {
        blocksForDisplay.filter { block in
            Calendar.current.isDate(block.startDateTime, inSameDayAs: date)
        }
    }

    func hasBlocksOnDate(_ date: Date) -> Bool {
        !blocksForDate(date).isEmpty
    }

    func isDateSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    func blockPosition(for block: PlanBlock, in height: CGFloat) -> (top: CGFloat, blockHeight: CGFloat) {
        let hourHeight = height / CGFloat(Constants.Calendar.endHour - Constants.Calendar.startHour)

        let startMinutes = CGFloat(block.startDateTime.hour * 60 + block.startDateTime.minute)
        let startOffset = startMinutes - CGFloat(Constants.Calendar.startHour * 60)
        let top = (startOffset / 60) * hourHeight

        let durationMinutes = CGFloat(block.durationMinutes)
        let blockHeight = max(Constants.Calendar.blockMinHeight, (durationMinutes / 60) * hourHeight)

        return (top, blockHeight)
    }
}

// MARK: - Calendar View Mode

enum CalendarViewMode: String, CaseIterable {
    case week = "week"
    case day = "day"

    var displayName: String {
        switch self {
        case .week: return "Week"
        case .day: return "Day"
        }
    }

    var icon: String {
        switch self {
        case .week: return "calendar"
        case .day: return "square"
        }
    }
}
