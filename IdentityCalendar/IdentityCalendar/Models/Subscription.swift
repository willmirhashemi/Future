import Foundation
import SwiftData

/// Represents subscription status and entitlements
struct Subscription {
    let tier: SubscriptionTier
    let status: SubscriptionStatus
    let expiresAt: Date?
    let startedAt: Date?

    var isActive: Bool {
        switch status {
        case .active, .trial:
            if let expiresAt = expiresAt {
                return Date() < expiresAt
            }
            return true
        default:
            return false
        }
    }

    var isPremium: Bool {
        isActive && tier == .pro
    }

    var daysRemaining: Int? {
        guard let expiresAt = expiresAt else { return nil }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: expiresAt).day
        return max(0, days ?? 0)
    }

    static let free = Subscription(
        tier: .free,
        status: .active,
        expiresAt: nil,
        startedAt: nil
    )
}

// MARK: - Subscription Tier

enum SubscriptionTier: String, Codable {
    case free = "free"
    case pro = "pro"

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Identity Pro"
        }
    }

    var maxGoals: Int {
        switch self {
        case .free: return 1
        case .pro: return .max
        }
    }

    var hasWeeklyAdaptation: Bool {
        self == .pro
    }

    var hasSmartRescheduling: Bool {
        self == .pro
    }

    var hasProgressTracking: Bool {
        self == .pro
    }
}

// MARK: - Subscription Status

enum SubscriptionStatus: String, Codable {
    case active = "active"
    case trial = "trial"
    case expired = "expired"
    case cancelled = "cancelled"
    case none = "none"
}

// MARK: - Subscription Products

enum SubscriptionProduct: String, CaseIterable {
    case monthlyPro = "com.identitycalendar.pro.monthly"
    case yearlyPro = "com.identitycalendar.pro.yearly"

    var displayName: String {
        switch self {
        case .monthlyPro: return "Monthly"
        case .yearlyPro: return "Yearly"
        }
    }

    var price: String {
        switch self {
        case .monthlyPro: return "$9.99"
        case .yearlyPro: return "$59.99"
        }
    }

    var pricePerMonth: String {
        switch self {
        case .monthlyPro: return "$9.99/mo"
        case .yearlyPro: return "$4.99/mo"
        }
    }

    var savings: String? {
        switch self {
        case .monthlyPro: return nil
        case .yearlyPro: return "Save 50%"
        }
    }

    var billingPeriod: String {
        switch self {
        case .monthlyPro: return "per month"
        case .yearlyPro: return "per year"
        }
    }

    var trialDays: Int {
        7
    }
}

// MARK: - Feature Entitlements

struct FeatureEntitlements {
    let canCreateMultipleGoals: Bool
    let hasAIWeeklyAdaptation: Bool
    let hasSmartRescheduling: Bool
    let hasAdvancedProgress: Bool
    let hasPrioritySupport: Bool

    static func forTier(_ tier: SubscriptionTier) -> FeatureEntitlements {
        switch tier {
        case .free:
            return FeatureEntitlements(
                canCreateMultipleGoals: false,
                hasAIWeeklyAdaptation: false,
                hasSmartRescheduling: false,
                hasAdvancedProgress: false,
                hasPrioritySupport: false
            )
        case .pro:
            return FeatureEntitlements(
                canCreateMultipleGoals: true,
                hasAIWeeklyAdaptation: true,
                hasSmartRescheduling: true,
                hasAdvancedProgress: true,
                hasPrioritySupport: true
            )
        }
    }
}
