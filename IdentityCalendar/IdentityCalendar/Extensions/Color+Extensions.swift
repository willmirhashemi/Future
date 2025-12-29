import SwiftUI

extension Color {
    // MARK: - Hex Initialization

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

    // MARK: - Static Accent Colors

    static let appAccent = AppTheme.accent
    static let appSuccess = AppTheme.success
    static let appWarning = AppTheme.warning
    static let appError = AppTheme.error

    // MARK: - Legacy Compatibility (use AppTheme instead)

    static let appBackground = Color(uiColor: .systemBackground)
    static let appSecondaryBackground = Color(uiColor: .secondarySystemBackground)
    static let appTertiaryBackground = Color(uiColor: .tertiarySystemBackground)
    static let appPrimaryText = Color(uiColor: .label)
    static let appSecondaryText = Color(uiColor: .secondaryLabel)
    static let appTertiaryText = Color(uiColor: .tertiaryLabel)
    static let appSeparator = Color(uiColor: .separator)
    static let appCardBackground = Color(uiColor: .systemBackground)

    // MARK: - Block Type Colors

    static func blockColor(for type: BlockType, colorScheme: ColorScheme) -> Color {
        switch type {
        case .focus: return AppTheme.blockFocus(colorScheme)
        case .light: return AppTheme.blockLight(colorScheme)
        case .habit: return AppTheme.blockHabit(colorScheme)
        case .review: return AppTheme.blockReview(colorScheme)
        }
    }

    static func blockBackgroundColor(for type: BlockType, colorScheme: ColorScheme) -> Color {
        blockColor(for: type, colorScheme: colorScheme).opacity(colorScheme == .dark ? 0.25 : 0.15)
    }

    // Legacy support
    static func blockColor(for type: BlockType) -> Color {
        switch type {
        case .focus: return Color(hex: "3B82F6")
        case .light: return Color(hex: "10B981")
        case .habit: return Color(hex: "F59E0B")
        case .review: return Color(hex: "8B5CF6")
        }
    }

    static func blockBackgroundColor(for type: BlockType) -> Color {
        blockColor(for: type).opacity(0.2)
    }

    // MARK: - Calendar Colors

    static func calendarToday(_ colorScheme: ColorScheme) -> Color {
        AppTheme.accent.opacity(colorScheme == .dark ? 0.15 : 0.1)
    }

    static func calendarSelected(_ colorScheme: ColorScheme) -> Color {
        AppTheme.accent.opacity(colorScheme == .dark ? 0.25 : 0.15)
    }
}

// MARK: - ShapeStyle Extension

extension ShapeStyle where Self == Color {
    static var appAccent: Color { .appAccent }
}
