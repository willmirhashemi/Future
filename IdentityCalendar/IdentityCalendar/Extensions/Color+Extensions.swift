import SwiftUI

extension Color {
    // MARK: - App Color Palette (Apple-like, calm, neutral)

    /// Primary background - pure white
    static let appBackground = Color(uiColor: .systemBackground)

    /// Secondary background - very subtle gray
    static let appSecondaryBackground = Color(uiColor: .secondarySystemBackground)

    /// Tertiary background - slightly darker
    static let appTertiaryBackground = Color(uiColor: .tertiarySystemBackground)

    /// Primary text - near black
    static let appPrimaryText = Color(uiColor: .label)

    /// Secondary text - muted gray
    static let appSecondaryText = Color(uiColor: .secondaryLabel)

    /// Tertiary text - lighter gray
    static let appTertiaryText = Color(uiColor: .tertiaryLabel)

    /// Primary accent - calm blue
    static let appAccent = Color(red: 0.25, green: 0.45, blue: 0.65)

    /// Success color - soft green
    static let appSuccess = Color(red: 0.35, green: 0.55, blue: 0.35)

    /// Warning color - muted amber
    static let appWarning = Color(red: 0.65, green: 0.55, blue: 0.35)

    /// Separator color
    static let appSeparator = Color(uiColor: .separator)

    /// Card background
    static let appCardBackground = Color.white

    // MARK: - Block Type Colors (Subtle, calm)

    static let blockFocus = Color(red: 0.20, green: 0.40, blue: 0.60)
    static let blockLight = Color(red: 0.45, green: 0.55, blue: 0.45)
    static let blockHabit = Color(red: 0.55, green: 0.45, blue: 0.40)
    static let blockReview = Color(red: 0.40, green: 0.40, blue: 0.50)

    // MARK: - Semantic Colors

    static let calendarToday = Color.appAccent.opacity(0.08)
    static let calendarSelected = Color.appAccent.opacity(0.15)
    static let blockBackground = Color.appSecondaryBackground

    // MARK: - Gradient Helpers

    static var subtleGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.white,
                Color(red: 0.98, green: 0.98, blue: 0.99)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var premiumGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.15, green: 0.25, blue: 0.35),
                Color(red: 0.25, green: 0.35, blue: 0.45)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Dynamic Colors

    static func blockColor(for type: BlockType) -> Color {
        switch type {
        case .focus: return .blockFocus
        case .light: return .blockLight
        case .habit: return .blockHabit
        case .review: return .blockReview
        }
    }

    static func blockBackgroundColor(for type: BlockType) -> Color {
        blockColor(for: type).opacity(0.12)
    }

    // MARK: - Initialization Helpers

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - ShapeStyle Extension

extension ShapeStyle where Self == Color {
    static var appAccent: Color { .appAccent }
    static var appBackground: Color { .appBackground }
    static var appSecondaryBackground: Color { .appSecondaryBackground }
}
