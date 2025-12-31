import Foundation

// MARK: - User Pattern Analyzer
/// Analyzes user behavior to learn preferences and improve AI recommendations

final class UserPatternAnalyzer {
    static let shared = UserPatternAnalyzer()

    private let calendar = Calendar.current
    private let defaults = UserDefaults.standard

    private init() {}

    // MARK: - Analyze Patterns

    /// Generate comprehensive user patterns from historical data
    func analyzePatterns(from blocks: [PlanBlock], reflections: [WeeklyReflection] = []) -> UserPatterns {
        let completedBlocks = blocks.filter { $0.status == .completed }

        return UserPatterns(
            peakProductivityHour: findPeakProductivityHour(from: completedBlocks),
            preferredBlockDuration: findPreferredDuration(from: completedBlocks),
            averageCompletionRate: calculateCompletionRate(from: blocks),
            preferredDays: findPreferredDays(from: completedBlocks)
        )
    }

    // MARK: - Peak Productivity

    private func findPeakProductivityHour(from completedBlocks: [PlanBlock]) -> Int {
        guard !completedBlocks.isEmpty else { return 9 }

        var hourScores: [Int: Double] = [:]

        for block in completedBlocks {
            let hour = calendar.component(.hour, from: block.startDateTime)

            // Weight by block type (focus blocks count more)
            let weight: Double = block.blockType == .focus ? 2.0 : 1.0

            // Bonus if completed on time (not moved)
            let onTimeBonus: Double = block.wasMoved ? 0.5 : 1.0

            hourScores[hour, default: 0] += weight * onTimeBonus
        }

        // Find hour with highest score
        let peakHour = hourScores.max(by: { $0.value < $1.value })?.key ?? 9

        // Cache result
        defaults.set(peakHour, forKey: "user_peak_hour")

        return peakHour
    }

    // MARK: - Preferred Duration

    private func findPreferredDuration(from completedBlocks: [PlanBlock]) -> Int {
        guard !completedBlocks.isEmpty else { return 45 }

        // Group by duration ranges
        var durationCounts: [Int: Int] = [:]

        for block in completedBlocks {
            let duration = block.durationMinutes
            // Round to nearest 15
            let rounded = (duration / 15) * 15
            durationCounts[rounded, default: 0] += 1
        }

        // Find most common
        let preferred = durationCounts.max(by: { $0.value < $1.value })?.key ?? 45

        defaults.set(preferred, forKey: "user_preferred_duration")

        return preferred
    }

    // MARK: - Completion Rate

    private func calculateCompletionRate(from blocks: [PlanBlock]) -> Double {
        guard !blocks.isEmpty else { return 0.7 }

        let completed = blocks.filter { $0.status == .completed }.count
        let rate = Double(completed) / Double(blocks.count)

        defaults.set(rate, forKey: "user_completion_rate")

        return rate
    }

    // MARK: - Preferred Days

    private func findPreferredDays(from completedBlocks: [PlanBlock]) -> [Int] {
        guard !completedBlocks.isEmpty else { return [2, 3, 4, 5, 6] } // Mon-Fri

        var dayScores: [Int: Double] = [:]

        for block in completedBlocks {
            let weekday = calendar.component(.weekday, from: block.startDateTime)
            dayScores[weekday, default: 0] += 1
        }

        // Return days with above-average activity
        let average = dayScores.values.reduce(0, +) / Double(max(1, dayScores.count))
        let preferred = dayScores.filter { $0.value >= average * 0.7 }.map { $0.key }.sorted()

        return preferred.isEmpty ? [2, 3, 4, 5, 6] : preferred
    }

    // MARK: - Detailed Analytics

    /// Get detailed behavior insights
    func getDetailedInsights(from blocks: [PlanBlock]) -> BehaviorInsights {
        let completedBlocks = blocks.filter { $0.status == .completed }
        let skippedBlocks = blocks.filter { $0.status == .skipped }
        let movedBlocks = blocks.filter { $0.wasMoved }

        return BehaviorInsights(
            totalBlocks: blocks.count,
            completedCount: completedBlocks.count,
            skippedCount: skippedBlocks.count,
            movedCount: movedBlocks.count,
            averageMoveCount: calculateAverageMoves(from: movedBlocks),
            completionByType: calculateCompletionByType(from: blocks),
            completionByHour: calculateCompletionByHour(from: blocks),
            completionByDay: calculateCompletionByDay(from: blocks),
            streakData: calculateStreakData(from: completedBlocks),
            consistencyScore: calculateConsistencyScore(from: blocks)
        )
    }

    private func calculateAverageMoves(from movedBlocks: [PlanBlock]) -> Double {
        guard !movedBlocks.isEmpty else { return 0 }
        let totalMoves = movedBlocks.reduce(0) { $0 + $1.moveCount }
        return Double(totalMoves) / Double(movedBlocks.count)
    }

    private func calculateCompletionByType(from blocks: [PlanBlock]) -> [BlockType: Double] {
        var result: [BlockType: Double] = [:]

        for type in BlockType.allCases {
            let typeBlocks = blocks.filter { $0.blockType == type }
            guard !typeBlocks.isEmpty else {
                result[type] = 0
                continue
            }
            let completed = typeBlocks.filter { $0.status == .completed }.count
            result[type] = Double(completed) / Double(typeBlocks.count)
        }

        return result
    }

    private func calculateCompletionByHour(from blocks: [PlanBlock]) -> [Int: Double] {
        var hourBlocks: [Int: [PlanBlock]] = [:]

        for block in blocks {
            let hour = calendar.component(.hour, from: block.startDateTime)
            hourBlocks[hour, default: []].append(block)
        }

        var result: [Int: Double] = [:]
        for (hour, hourBlockList) in hourBlocks {
            let completed = hourBlockList.filter { $0.status == .completed }.count
            result[hour] = Double(completed) / Double(hourBlockList.count)
        }

        return result
    }

    private func calculateCompletionByDay(from blocks: [PlanBlock]) -> [Int: Double] {
        var dayBlocks: [Int: [PlanBlock]] = [:]

        for block in blocks {
            let day = calendar.component(.weekday, from: block.startDateTime)
            dayBlocks[day, default: []].append(block)
        }

        var result: [Int: Double] = [:]
        for (day, dayBlockList) in dayBlocks {
            let completed = dayBlockList.filter { $0.status == .completed }.count
            result[day] = Double(completed) / Double(dayBlockList.count)
        }

        return result
    }

    private func calculateStreakData(from completedBlocks: [PlanBlock]) -> StreakData {
        guard !completedBlocks.isEmpty else {
            return StreakData(currentStreak: 0, longestStreak: 0, lastActiveDate: nil)
        }

        let sortedDates = completedBlocks.map { calendar.startOfDay(for: $0.completedAt ?? $0.startDateTime) }
            .sorted()

        var uniqueDates = Array(Set(sortedDates)).sorted()
        guard !uniqueDates.isEmpty else {
            return StreakData(currentStreak: 0, longestStreak: 0, lastActiveDate: nil)
        }

        var currentStreak = 1
        var longestStreak = 1
        var tempStreak = 1

        for i in 1..<uniqueDates.count {
            let daysBetween = calendar.dateComponents([.day], from: uniqueDates[i-1], to: uniqueDates[i]).day ?? 0

            if daysBetween == 1 {
                tempStreak += 1
                longestStreak = max(longestStreak, tempStreak)
            } else {
                tempStreak = 1
            }
        }

        // Check if streak is current (includes today or yesterday)
        let lastDate = uniqueDates.last!
        let daysSinceLast = calendar.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

        if daysSinceLast <= 1 {
            currentStreak = tempStreak
        } else {
            currentStreak = 0
        }

        return StreakData(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            lastActiveDate: uniqueDates.last
        )
    }

    private func calculateConsistencyScore(from blocks: [PlanBlock]) -> Double {
        guard blocks.count >= 7 else { return 0.5 }

        // Factors: completion rate, low skip rate, low move rate, regular timing
        let completionRate = calculateCompletionRate(from: blocks)
        let skipRate = Double(blocks.filter { $0.status == .skipped }.count) / Double(blocks.count)
        let moveRate = Double(blocks.filter { $0.wasMoved }.count) / Double(blocks.count)

        // Higher completion = higher score
        // Lower skip/move = higher score
        let score = (completionRate * 0.5) + ((1 - skipRate) * 0.25) + ((1 - moveRate) * 0.25)

        return min(1.0, max(0.0, score))
    }

    // MARK: - Recommendations

    /// Generate recommendations based on patterns
    func generateRecommendations(from insights: BehaviorInsights) -> [PatternRecommendation] {
        var recommendations: [PatternRecommendation] = []

        // Low completion rate
        if Double(insights.completedCount) / Double(max(1, insights.totalBlocks)) < 0.5 {
            recommendations.append(PatternRecommendation(
                type: .reduceLoad,
                message: "Try scheduling fewer blocks - quality over quantity",
                priority: .high
            ))
        }

        // High skip rate
        if Double(insights.skippedCount) / Double(max(1, insights.totalBlocks)) > 0.3 {
            recommendations.append(PatternRecommendation(
                type: .adjustTiming,
                message: "Many skipped blocks - consider different times or shorter durations",
                priority: .medium
            ))
        }

        // Frequent moves
        if insights.averageMoveCount > 2 {
            recommendations.append(PatternRecommendation(
                type: .addBuffer,
                message: "Blocks often get moved - add buffer time between activities",
                priority: .medium
            ))
        }

        // Type-specific issues
        for (type, rate) in insights.completionByType where rate < 0.4 {
            recommendations.append(PatternRecommendation(
                type: .changeBlockType,
                message: "\(type.displayName) blocks have low completion - try shorter sessions",
                priority: .low
            ))
        }

        // Streak encouragement
        if insights.streakData.currentStreak >= 3 {
            recommendations.append(PatternRecommendation(
                type: .encouragement,
                message: "\(insights.streakData.currentStreak)-day streak! Keep the momentum",
                priority: .low
            ))
        }

        return recommendations.sorted { $0.priority.rawValue > $1.priority.rawValue }
    }

    // MARK: - Quick Access Patterns

    /// Get cached patterns quickly
    func getCachedPatterns() -> UserPatterns {
        UserPatterns(
            peakProductivityHour: defaults.integer(forKey: "user_peak_hour").nonZero ?? 9,
            preferredBlockDuration: defaults.integer(forKey: "user_preferred_duration").nonZero ?? 45,
            averageCompletionRate: defaults.double(forKey: "user_completion_rate").nonZero ?? 0.7,
            preferredDays: [2, 3, 4, 5, 6]
        )
    }
}

// MARK: - Supporting Types

struct BehaviorInsights {
    let totalBlocks: Int
    let completedCount: Int
    let skippedCount: Int
    let movedCount: Int
    let averageMoveCount: Double
    let completionByType: [BlockType: Double]
    let completionByHour: [Int: Double]
    let completionByDay: [Int: Double]
    let streakData: StreakData
    let consistencyScore: Double
}

struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let lastActiveDate: Date?
}

struct PatternRecommendation {
    let type: RecommendationType
    let message: String
    let priority: Priority

    enum Priority: Int {
        case low = 1
        case medium = 2
        case high = 3
    }
}

enum RecommendationType {
    case reduceLoad
    case adjustTiming
    case addBuffer
    case changeBlockType
    case encouragement
}

// MARK: - Extensions

private extension Int {
    var nonZero: Int? {
        self != 0 ? self : nil
    }
}

private extension Double {
    var nonZero: Double? {
        self != 0 ? self : nil
    }
}
