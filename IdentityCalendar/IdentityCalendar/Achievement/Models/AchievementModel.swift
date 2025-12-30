import Foundation
import SwiftData
import SwiftUI

// MARK: - Achievement Model

/// Core SwiftData model for tracking user achievements
/// Designed with minimal stored properties to avoid isolation issues
@Model
final class Achievement {
    // MARK: - Stored Properties

    var id: UUID
    private var typeRawValue: String
    var unlockedAt: Date?
    var isUnlocked: Bool
    var progress: Int
    var notifiedUser: Bool

    @Relationship(inverse: \User.achievements)
    var user: User?

    // MARK: - Computed Properties

    /// The achievement type - uses nonisolated to avoid actor isolation issues
    nonisolated var achievementType: AchievementType {
        get {
            AchievementType(rawValue: typeRawValue) ?? .firstStep
        }
    }

    /// Get metadata for this achievement - safe to call from any context
    nonisolated var metadata: AchievementMetadata {
        AchievementRegistry.metadata(for: achievementType)
    }

    /// Whether this achievement is new and should show a badge
    var isNew: Bool {
        guard isUnlocked, let unlockedAt = unlockedAt else { return false }
        let daysSinceUnlock = Calendar.current.dateComponents([.day], from: unlockedAt, to: Date()).day ?? 0
        return daysSinceUnlock <= 3 && !notifiedUser
    }

    /// Progress percentage (0.0 to 1.0)
    nonisolated var progressPercentage: Double {
        let requirement = metadata.requirement
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        achievementType: AchievementType,
        unlockedAt: Date? = nil,
        isUnlocked: Bool = false,
        progress: Int = 0,
        notifiedUser: Bool = false
    ) {
        self.id = id
        self.typeRawValue = achievementType.rawValue
        self.unlockedAt = unlockedAt
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.notifiedUser = notifiedUser
    }

    // MARK: - Methods

    /// Unlock this achievement
    func unlock() {
        guard !isUnlocked else { return }
        isUnlocked = true
        unlockedAt = Date()
        notifiedUser = false
    }

    /// Mark this achievement as having been notified to the user
    func markAsNotified() {
        notifiedUser = true
    }

    /// Update progress toward this achievement
    func updateProgress(_ newProgress: Int) {
        progress = newProgress
        // Auto-unlock if requirement met
        if progress >= metadata.requirement && !isUnlocked {
            unlock()
        }
    }

    /// Set the achievement type (for migration or updates)
    func setType(_ type: AchievementType) {
        typeRawValue = type.rawValue
    }
}

// MARK: - Achievement Snapshot

/// A thread-safe, immutable snapshot of an achievement for use in views
/// This avoids SwiftData isolation issues when passing data to views
struct AchievementSnapshot: Identifiable, Sendable, Hashable {
    let id: UUID
    let type: AchievementType
    let isUnlocked: Bool
    let progress: Int
    let unlockedAt: Date?
    let notifiedUser: Bool

    var metadata: AchievementMetadata {
        AchievementRegistry.metadata(for: type)
    }

    var isNew: Bool {
        guard isUnlocked, let unlockedAt = unlockedAt else { return false }
        let daysSinceUnlock = Calendar.current.dateComponents([.day], from: unlockedAt, to: Date()).day ?? 0
        return daysSinceUnlock <= 3 && !notifiedUser
    }

    var progressPercentage: Double {
        let requirement = metadata.requirement
        guard requirement > 0 else { return 0 }
        return min(1.0, Double(progress) / Double(requirement))
    }

    init(from achievement: Achievement) {
        self.id = achievement.id
        self.type = achievement.achievementType
        self.isUnlocked = achievement.isUnlocked
        self.progress = achievement.progress
        self.unlockedAt = achievement.unlockedAt
        self.notifiedUser = achievement.notifiedUser
    }

    init(
        id: UUID = UUID(),
        type: AchievementType,
        isUnlocked: Bool = false,
        progress: Int = 0,
        unlockedAt: Date? = nil,
        notifiedUser: Bool = false
    ) {
        self.id = id
        self.type = type
        self.isUnlocked = isUnlocked
        self.progress = progress
        self.unlockedAt = unlockedAt
        self.notifiedUser = notifiedUser
    }

    // MARK: - Hashable

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: AchievementSnapshot, rhs: AchievementSnapshot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Achievement Extensions

extension Achievement {
    /// Create a thread-safe snapshot of this achievement
    func snapshot() -> AchievementSnapshot {
        AchievementSnapshot(from: self)
    }
}

extension Array where Element == Achievement {
    /// Create snapshots of all achievements
    func snapshots() -> [AchievementSnapshot] {
        map { $0.snapshot() }
    }
}
