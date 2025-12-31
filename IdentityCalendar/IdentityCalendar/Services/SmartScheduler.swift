import Foundation

// MARK: - Smart Scheduler
/// Enhanced scheduling with conflict detection, energy matching, and optimal time finding

final class SmartScheduler {
    static let shared = SmartScheduler()

    private let calendar = Calendar.current

    private init() {}

    // MARK: - Find Optimal Time Slots

    /// Find the best available time slots for a new block
    func findOptimalSlots(
        for duration: Int,
        blockType: BlockType,
        energyLevel: EnergyLevel?,
        existingBlocks: [PlanBlock],
        userPatterns: UserPatterns,
        preferredDate: Date? = nil,
        count: Int = 5
    ) -> [TimeSlot] {
        let targetDate = preferredDate ?? Date()
        var slots: [TimeSlot] = []

        // Search the next 7 days
        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: targetDate) else { continue }

            let daySlots = findSlotsForDay(
                date: date,
                duration: duration,
                blockType: blockType,
                energyLevel: energyLevel,
                existingBlocks: existingBlocks,
                userPatterns: userPatterns
            )
            slots.append(contentsOf: daySlots)
        }

        // Sort by score and return top results
        return Array(slots.sorted { $0.score > $1.score }.prefix(count))
    }

    /// Find available slots for a specific day
    private func findSlotsForDay(
        date: Date,
        duration: Int,
        blockType: BlockType,
        energyLevel: EnergyLevel?,
        existingBlocks: [PlanBlock],
        userPatterns: UserPatterns
    ) -> [TimeSlot] {
        var slots: [TimeSlot] = []

        let dayStart = 6  // 6 AM
        let dayEnd = 22   // 10 PM

        // Get blocks for this day
        let dayBlocks = existingBlocks.filter { calendar.isDate($0.startDateTime, inSameDayAs: date) }

        // Check each hour
        for hour in dayStart..<dayEnd {
            guard let slotStart = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: date),
                  let slotEnd = calendar.date(byAdding: .minute, value: duration, to: slotStart) else {
                continue
            }

            // Check for conflicts
            let hasConflict = dayBlocks.contains { block in
                let blockEnd = block.endDateTime
                return (slotStart < blockEnd && slotEnd > block.startDateTime)
            }

            if !hasConflict {
                let score = calculateSlotScore(
                    hour: hour,
                    date: date,
                    blockType: blockType,
                    energyLevel: energyLevel,
                    userPatterns: userPatterns,
                    existingBlockCount: dayBlocks.count
                )

                slots.append(TimeSlot(
                    startTime: slotStart,
                    endTime: slotEnd,
                    score: score,
                    reason: generateReason(hour: hour, score: score, blockType: blockType)
                ))
            }
        }

        return slots
    }

    // MARK: - Scoring Algorithm

    private func calculateSlotScore(
        hour: Int,
        date: Date,
        blockType: BlockType,
        energyLevel: EnergyLevel?,
        userPatterns: UserPatterns,
        existingBlockCount: Int
    ) -> Double {
        var score = 50.0 // Base score

        // Energy matching (high-energy blocks in peak hours)
        let energy = energyLevel ?? .medium
        let peakHours = userPatterns.peakProductivityHour...(userPatterns.peakProductivityHour + 3)
        let isPeakHour = peakHours.contains(hour)

        switch energy {
        case .high:
            score += isPeakHour ? 20 : -10
        case .medium:
            score += (hour >= 9 && hour <= 17) ? 10 : 0
        case .low:
            score += isPeakHour ? -5 : 10 // Low energy = off-peak is fine
        }

        // Block type preferences
        switch blockType {
        case .focus:
            // Focus blocks best in morning
            if hour >= 8 && hour <= 11 { score += 15 }
            else if hour >= 14 && hour <= 16 { score += 10 }
        case .light:
            // Light blocks good afternoon/evening
            if hour >= 14 && hour <= 18 { score += 10 }
        case .habit:
            // Habits best at consistent times (morning or evening)
            if hour <= 8 || hour >= 19 { score += 15 }
        case .review:
            // Review best at end of day/week
            if hour >= 17 { score += 10 }
        }

        // Weekday preference
        let weekday = calendar.component(.weekday, from: date)
        if userPatterns.preferredDays.contains(weekday) {
            score += 5
        }

        // Don't overload a single day
        if existingBlockCount >= 4 {
            score -= Double(existingBlockCount - 3) * 5
        }

        // Prefer today/tomorrow over later days
        let daysFromNow = calendar.dateComponents([.day], from: Date(), to: date).day ?? 0
        score -= Double(daysFromNow) * 2

        return max(0, min(100, score))
    }

    private func generateReason(hour: Int, score: Double, blockType: BlockType) -> String {
        if score >= 80 {
            return "Optimal time for \(blockType.displayName.lowercased()) work"
        } else if score >= 60 {
            return "Good availability"
        } else if hour < 9 {
            return "Early slot available"
        } else if hour >= 18 {
            return "Evening option"
        } else {
            return "Available"
        }
    }

    // MARK: - Conflict Detection

    /// Check if a proposed block conflicts with existing ones
    func detectConflicts(
        proposedStart: Date,
        proposedEnd: Date,
        existingBlocks: [PlanBlock]
    ) -> [ConflictInfo] {
        var conflicts: [ConflictInfo] = []

        for block in existingBlocks {
            let blockEnd = block.endDateTime

            // Check overlap
            if proposedStart < blockEnd && proposedEnd > block.startDateTime {
                let overlapStart = max(proposedStart, block.startDateTime)
                let overlapEnd = min(proposedEnd, blockEnd)
                let overlapMinutes = Int(overlapEnd.timeIntervalSince(overlapStart) / 60)

                conflicts.append(ConflictInfo(
                    conflictingBlock: block,
                    overlapMinutes: overlapMinutes,
                    type: determineConflictType(proposed: proposedStart...proposedEnd, existing: block.startDateTime...blockEnd)
                ))
            }
        }

        return conflicts
    }

    private func determineConflictType(proposed: ClosedRange<Date>, existing: ClosedRange<Date>) -> ConflictType {
        if proposed.lowerBound >= existing.lowerBound && proposed.upperBound <= existing.upperBound {
            return .containedWithin
        } else if existing.lowerBound >= proposed.lowerBound && existing.upperBound <= proposed.upperBound {
            return .contains
        } else if proposed.lowerBound < existing.lowerBound {
            return .overlapEnd
        } else {
            return .overlapStart
        }
    }

    // MARK: - Smart Rescheduling

    /// Find the best reschedule option for a block
    func findBestReschedule(
        for block: PlanBlock,
        existingBlocks: [PlanBlock],
        userPatterns: UserPatterns
    ) -> TimeSlot? {
        // Exclude the block being rescheduled
        let otherBlocks = existingBlocks.filter { $0.id != block.id }

        let slots = findOptimalSlots(
            for: block.durationMinutes,
            blockType: block.blockType,
            energyLevel: block.energyLevel,
            existingBlocks: otherBlocks,
            userPatterns: userPatterns,
            preferredDate: block.startDateTime,
            count: 1
        )

        return slots.first
    }

    // MARK: - Day Analysis

    /// Analyze a day's schedule and provide insights
    func analyzeDay(date: Date, blocks: [PlanBlock]) -> DayAnalysis {
        let dayBlocks = blocks.filter { calendar.isDate($0.startDateTime, inSameDayAs: date) }
            .sorted { $0.startDateTime < $1.startDateTime }

        let totalMinutes = dayBlocks.reduce(0) { $0 + $1.durationMinutes }
        let focusMinutes = dayBlocks.filter { $0.blockType == .focus }.reduce(0) { $0 + $1.durationMinutes }

        // Find gaps
        var gaps: [TimeGap] = []
        for i in 0..<(dayBlocks.count - 1) {
            let current = dayBlocks[i]
            let next = dayBlocks[i + 1]
            let gapMinutes = Int(next.startDateTime.timeIntervalSince(current.endDateTime) / 60)

            if gapMinutes >= 30 {
                gaps.append(TimeGap(
                    start: current.endDateTime,
                    end: next.startDateTime,
                    minutes: gapMinutes
                ))
            }
        }

        // Calculate balance score
        let hasVariety = Set(dayBlocks.map { $0.blockType }).count >= 2
        let notOverloaded = dayBlocks.count <= 6
        let hasBreaks = gaps.count >= 1 || dayBlocks.count <= 2
        let balanceScore = [hasVariety, notOverloaded, hasBreaks].filter { $0 }.count * 33

        return DayAnalysis(
            totalBlocks: dayBlocks.count,
            totalMinutes: totalMinutes,
            focusMinutes: focusMinutes,
            gaps: gaps,
            balanceScore: balanceScore,
            suggestion: generateDaySuggestion(blocks: dayBlocks, gaps: gaps)
        )
    }

    private func generateDaySuggestion(blocks: [PlanBlock], gaps: [TimeGap]) -> String? {
        if blocks.isEmpty {
            return "No blocks scheduled. Add at least one activity."
        }
        if blocks.count > 6 {
            return "Heavy day. Consider moving some blocks."
        }
        if gaps.isEmpty && blocks.count > 2 {
            return "Tight schedule. Build in buffer time."
        }
        if blocks.allSatisfy({ $0.blockType == .focus }) && blocks.count > 2 {
            return "All focus blocks. Mix in lighter activities."
        }
        return nil
    }

    // MARK: - Weekly Optimization

    /// Suggest redistributions to balance the week
    func suggestWeeklyOptimization(blocks: [PlanBlock], userPatterns: UserPatterns) -> [OptimizationSuggestion] {
        var suggestions: [OptimizationSuggestion] = []

        // Group by day
        var blocksByDay: [Int: [PlanBlock]] = [:]
        for block in blocks {
            let day = calendar.component(.weekday, from: block.startDateTime)
            blocksByDay[day, default: []].append(block)
        }

        // Check for overloaded days
        for (day, dayBlocks) in blocksByDay where dayBlocks.count > 5 {
            if let lightestDay = blocksByDay.min(by: { $0.value.count < $1.value.count }),
               lightestDay.value.count < 3 {
                suggestions.append(OptimizationSuggestion(
                    type: .redistribute,
                    message: "Move some blocks from \(dayName(day)) to \(dayName(lightestDay.key))",
                    affectedBlocks: Array(dayBlocks.suffix(2))
                ))
            }
        }

        // Check for no rest days
        let activeDays = blocksByDay.keys.count
        if activeDays == 7 {
            suggestions.append(OptimizationSuggestion(
                type: .addRest,
                message: "Consider taking a rest day for recovery",
                affectedBlocks: []
            ))
        }

        return suggestions
    }

    private func dayName(_ weekday: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let date = calendar.date(from: DateComponents(weekday: weekday)) ?? Date()
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Types

struct TimeSlot {
    let startTime: Date
    let endTime: Date
    let score: Double
    let reason: String

    var duration: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
}

struct ConflictInfo {
    let conflictingBlock: PlanBlock
    let overlapMinutes: Int
    let type: ConflictType
}

enum ConflictType {
    case overlapStart    // New block starts during existing
    case overlapEnd      // New block ends during existing
    case contains        // New block contains existing
    case containedWithin // New block within existing
}

struct TimeGap {
    let start: Date
    let end: Date
    let minutes: Int
}

struct DayAnalysis {
    let totalBlocks: Int
    let totalMinutes: Int
    let focusMinutes: Int
    let gaps: [TimeGap]
    let balanceScore: Int
    let suggestion: String?
}

struct OptimizationSuggestion {
    let type: OptimizationType
    let message: String
    let affectedBlocks: [PlanBlock]
}

enum OptimizationType {
    case redistribute
    case addRest
    case changeTime
    case reduceDuration
}
