import Foundation

// MARK: - Natural Language Block Parser
/// Parses natural language input like "workout tomorrow at 9am for 1 hour" into PlanBlock data

final class NaturalLanguageBlockParser {
    static let shared = NaturalLanguageBlockParser()

    private let calendar = Calendar.current

    private init() {}

    // MARK: - Main Parse Function

    /// Parse natural language into a PlanBlock
    func parse(_ input: String) -> ParsedBlock? {
        let lowercased = input.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        guard !lowercased.isEmpty else { return nil }

        // Extract components
        let title = extractTitle(from: lowercased)
        let date = extractDate(from: lowercased)
        let time = extractTime(from: lowercased)
        let duration = extractDuration(from: lowercased)
        let blockType = inferBlockType(from: lowercased, title: title)

        // Combine date and time
        guard let startDateTime = combineDateTime(date: date, time: time) else {
            return nil
        }

        let endDateTime = calendar.date(byAdding: .minute, value: duration, to: startDateTime) ?? startDateTime

        return ParsedBlock(
            title: title.capitalized,
            intent: generateIntent(for: title, type: blockType),
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            blockType: blockType,
            confidence: calculateConfidence(hasTitle: !title.isEmpty, hasDate: date != nil, hasTime: time != nil)
        )
    }

    // MARK: - Title Extraction

    private func extractTitle(from input: String) -> String {
        var text = input

        // Remove time-related phrases
        let removePatterns = [
            #"(tomorrow|today|monday|tuesday|wednesday|thursday|friday|saturday|sunday)"#,
            #"(at\s+\d{1,2}(:\d{2})?\s*(am|pm)?)"#,
            #"(for\s+\d+\s*(hour|hr|minute|min)s?)"#,
            #"(\d{1,2}(:\d{2})?\s*(am|pm))"#,
            #"(next\s+week)"#,
            #"(this\s+(morning|afternoon|evening))"#
        ]

        for pattern in removePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                text = regex.stringByReplacingMatches(
                    in: text,
                    range: NSRange(text.startIndex..., in: text),
                    withTemplate: ""
                )
            }
        }

        // Clean up
        text = text.replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove common prefixes
        let prefixes = ["add ", "schedule ", "create ", "new ", "set up ", "plan "]
        for prefix in prefixes {
            if text.hasPrefix(prefix) {
                text = String(text.dropFirst(prefix.count))
            }
        }

        return text.isEmpty ? "New Block" : text
    }

    // MARK: - Date Extraction

    private func extractDate(from input: String) -> Date? {
        let today = calendar.startOfDay(for: Date())

        // Check for relative days
        if input.contains("today") {
            return today
        }

        if input.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: today)
        }

        // Check for day names
        let dayMappings: [(String, Int)] = [
            ("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6), ("saturday", 7)
        ]

        for (dayName, weekday) in dayMappings {
            if input.contains(dayName) {
                return nextDate(for: weekday)
            }
        }

        // Check for "next week"
        if input.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: today)
        }

        // Default to today
        return today
    }

    private func nextDate(for weekday: Int) -> Date {
        let today = Date()
        let currentWeekday = calendar.component(.weekday, from: today)
        var daysToAdd = weekday - currentWeekday

        if daysToAdd <= 0 {
            daysToAdd += 7 // Next occurrence
        }

        return calendar.date(byAdding: .day, value: daysToAdd, to: today) ?? today
    }

    // MARK: - Time Extraction

    private func extractTime(from input: String) -> (hour: Int, minute: Int)? {
        // Pattern: "at 9", "at 9am", "at 9:30", "at 9:30pm", "9am", "14:00"
        let patterns = [
            #"at\s+(\d{1,2}):(\d{2})\s*(am|pm)?"#,
            #"at\s+(\d{1,2})\s*(am|pm)"#,
            #"at\s+(\d{1,2})"#,
            #"(\d{1,2}):(\d{2})\s*(am|pm)?"#,
            #"(\d{1,2})\s*(am|pm)"#
        ]

        for pattern in patterns {
            if let result = extractTimeFromPattern(input, pattern: pattern) {
                return result
            }
        }

        // Check for time-of-day words
        if input.contains("morning") { return (9, 0) }
        if input.contains("afternoon") { return (14, 0) }
        if input.contains("evening") { return (18, 0) }
        if input.contains("night") { return (20, 0) }

        // Default to 9 AM
        return (9, 0)
    }

    private func extractTimeFromPattern(_ input: String, pattern: String) -> (hour: Int, minute: Int)? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
              let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)) else {
            return nil
        }

        var hour = 0
        var minute = 0
        var isPM = false

        // Extract hour
        if let hourRange = Range(match.range(at: 1), in: input) {
            hour = Int(input[hourRange]) ?? 9
        }

        // Extract minute if present
        if match.numberOfRanges > 2, let minuteRange = Range(match.range(at: 2), in: input) {
            let minuteStr = String(input[minuteRange])
            if let m = Int(minuteStr) {
                minute = m
            } else if minuteStr.lowercased() == "pm" {
                isPM = true
            } else if minuteStr.lowercased() == "am" {
                isPM = false
            }
        }

        // Check for am/pm
        if match.numberOfRanges > 3, let ampmRange = Range(match.range(at: 3), in: input) {
            isPM = input[ampmRange].lowercased() == "pm"
        }

        // Also check the broader input for am/pm near the time
        let timeContext = String(input.suffix(20))
        if timeContext.contains("pm") && hour < 12 {
            isPM = true
        }

        // Convert to 24-hour
        if isPM && hour < 12 {
            hour += 12
        } else if !isPM && hour == 12 {
            hour = 0
        }

        // Validate
        guard hour >= 0 && hour < 24 && minute >= 0 && minute < 60 else {
            return nil
        }

        return (hour, minute)
    }

    // MARK: - Duration Extraction

    private func extractDuration(from input: String) -> Int {
        // Pattern: "for 1 hour", "for 30 minutes", "for 1.5 hours", "1hr", "90min"
        let patterns: [(String, (String) -> Int?)] = [
            (#"for\s+(\d+\.?\d*)\s*hours?"#, { str in
                if let hours = Double(str) { return Int(hours * 60) }
                return nil
            }),
            (#"for\s+(\d+)\s*(?:min|minutes?)"#, { str in Int(str) }),
            (#"(\d+\.?\d*)\s*(?:hr|hours?)"#, { str in
                if let hours = Double(str) { return Int(hours * 60) }
                return nil
            }),
            (#"(\d+)\s*(?:min|minutes?)"#, { str in Int(str) })
        ]

        for (pattern, converter) in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: input, range: NSRange(input.startIndex..., in: input)),
               let range = Range(match.range(at: 1), in: input),
               let duration = converter(String(input[range])) {
                return max(15, min(180, duration)) // Clamp 15min - 3hrs
            }
        }

        // Infer from activity type
        if input.contains("quick") || input.contains("short") { return 15 }
        if input.contains("deep") || input.contains("long") { return 90 }

        // Default duration
        return 45
    }

    // MARK: - Block Type Inference

    private func inferBlockType(from input: String, title: String) -> BlockType {
        let combined = "\(input) \(title)".lowercased()

        // Focus activities
        let focusKeywords = ["study", "work", "code", "coding", "write", "writing", "deep", "project", "focus", "practice", "learn"]
        if focusKeywords.contains(where: { combined.contains($0) }) {
            return .focus
        }

        // Habit activities
        let habitKeywords = ["workout", "gym", "exercise", "run", "running", "meditat", "journal", "read", "stretch", "yoga", "walk"]
        if habitKeywords.contains(where: { combined.contains($0) }) {
            return .habit
        }

        // Review activities
        let reviewKeywords = ["review", "reflect", "plan", "weekly", "check", "assess", "evaluate"]
        if reviewKeywords.contains(where: { combined.contains($0) }) {
            return .review
        }

        // Light activities
        let lightKeywords = ["email", "call", "meeting", "lunch", "break", "admin", "organize", "clean", "prep"]
        if lightKeywords.contains(where: { combined.contains($0) }) {
            return .light
        }

        // Default to focus
        return .focus
    }

    // MARK: - Helpers

    private func combineDateTime(date: Date?, time: (hour: Int, minute: Int)?) -> Date? {
        let baseDate = date ?? Date()
        let (hour, minute) = time ?? (9, 0)

        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }

    private func generateIntent(for title: String, type: BlockType) -> String {
        switch type {
        case .focus:
            return "Deep work on \(title.lowercased())"
        case .habit:
            return "Build consistency with \(title.lowercased())"
        case .light:
            return "Complete \(title.lowercased())"
        case .review:
            return "Reflect and plan for \(title.lowercased())"
        }
    }

    private func calculateConfidence(hasTitle: Bool, hasDate: Bool, hasTime: Bool) -> Double {
        var confidence = 0.4 // Base
        if hasTitle { confidence += 0.2 }
        if hasDate { confidence += 0.2 }
        if hasTime { confidence += 0.2 }
        return confidence
    }
}

// MARK: - Parsed Block Result

struct ParsedBlock {
    let title: String
    let intent: String
    let startDateTime: Date
    let endDateTime: Date
    let blockType: BlockType
    let confidence: Double

    var durationMinutes: Int {
        Int(endDateTime.timeIntervalSince(startDateTime) / 60)
    }

    /// Convert to PlanBlock model
    func toPlanBlock(weekNumber: Int = 1) -> PlanBlock {
        PlanBlock(
            startDateTime: startDateTime,
            endDateTime: endDateTime,
            title: title,
            intentShort: intent,
            blockType: blockType,
            weekNumber: weekNumber
        )
    }
}
