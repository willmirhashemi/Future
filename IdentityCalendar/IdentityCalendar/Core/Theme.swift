import SwiftUI
import UIKit
import Combine

// MARK: - App Theme (Dark Matte Aesthetic - Single Theme)

struct AppTheme {
    // MARK: - Core Background Colors

    static let background = Color(hex: "0B0F14")           // Deep charcoal
    static let surface = Color(hex: "111827")              // Card background
    static let surfaceSecondary = Color(hex: "0F172A")     // Elevated surface
    static let surfaceTertiary = Color(hex: "1E293B")      // Subtle elevation

    // MARK: - Border Colors

    static let border = Color.white.opacity(0.06)          // Subtle borders
    static let borderLight = Color.white.opacity(0.10)     // Visible borders

    // MARK: - Text Colors

    static let textPrimary = Color.white.opacity(0.92)     // Main text
    static let textSecondary = Color.white.opacity(0.62)   // Secondary text
    static let textTertiary = Color.white.opacity(0.38)    // Muted text

    // MARK: - Accent Colors (Muted, Sophisticated)

    static let accent = Color(hex: "7FAE8A")               // Muted sage green
    static let accentLight = Color(hex: "9ABFA3")          // Lighter sage
    static let accentDark = Color(hex: "5E8A68")           // Darker sage

    static let accentBlue = Color(hex: "7AA2E3")           // Muted blue
    static let accentPurple = Color(hex: "9B8AC4")         // Muted purple
    static let accentAmber = Color(hex: "D4A574")          // Muted amber

    // MARK: - Semantic Colors

    static let success = Color(hex: "7FAE8A")              // Same as accent
    static let warning = Color(hex: "D4A574")              // Muted amber
    static let error = Color(hex: "E07A7A")                // Muted red

    // MARK: - Block Type Colors

    static let blockFocus = Color(hex: "7AA2E3")           // Blue - deep work
    static let blockLight = Color(hex: "7FAE8A")           // Green - easy tasks
    static let blockHabit = Color(hex: "D4A574")           // Amber - routines
    static let blockReview = Color(hex: "9B8AC4")          // Purple - reflection

    // MARK: - Ring/Progress Colors

    static let ringProgress = Color(hex: "7FAE8A")
    static let ringSecondary = Color(hex: "7AA2E3")
    static let ringTertiary = Color(hex: "9B8AC4")

    // MARK: - Gradients

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var surfaceGradient: LinearGradient {
        LinearGradient(
            colors: [surface, surfaceSecondary],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var premiumGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentBlue],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Helper Functions (for legacy compatibility)

    static func background(_ scheme: ColorScheme) -> Color { background }
    static func surface(_ scheme: ColorScheme) -> Color { surface }
    static func textPrimary(_ scheme: ColorScheme) -> Color { textPrimary }
    static func textSecondary(_ scheme: ColorScheme) -> Color { textSecondary }
    static func border(_ scheme: ColorScheme) -> Color { border }

    static func blockColor(for type: BlockType) -> Color {
        switch type {
        case .focus: return blockFocus
        case .light: return blockLight
        case .habit: return blockHabit
        case .review: return blockReview
        }
    }

    // Legacy function names for compatibility
    static func cardBackground(_ scheme: ColorScheme) -> Color { surface }
    static func secondaryBackground(_ scheme: ColorScheme) -> Color { surfaceSecondary }
    static func tertiaryBackground(_ scheme: ColorScheme) -> Color { surfaceTertiary }
    static func primaryText(_ scheme: ColorScheme) -> Color { textPrimary }
    static func secondaryText(_ scheme: ColorScheme) -> Color { textSecondary }
    static func tertiaryText(_ scheme: ColorScheme) -> Color { textTertiary }
    static func separator(_ scheme: ColorScheme) -> Color { border }
    static func ringBackground(_ scheme: ColorScheme) -> Color { surfaceSecondary }

    static func blockFocus(_ scheme: ColorScheme) -> Color { blockFocus }
    static func blockLight(_ scheme: ColorScheme) -> Color { blockLight }
    static func blockHabit(_ scheme: ColorScheme) -> Color { blockHabit }
    static func blockReview(_ scheme: ColorScheme) -> Color { blockReview }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
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

    // Static color shortcuts
    static let appAccent = AppTheme.accent
    static let appSuccess = AppTheme.success
    static let appWarning = AppTheme.warning
    static let appError = AppTheme.error
    static let appBackground = AppTheme.background
    static let appCardBackground = AppTheme.surface
    static let appSecondaryBackground = AppTheme.surfaceSecondary
    static let appTertiaryBackground = AppTheme.surfaceTertiary
    static let appPrimaryText = AppTheme.textPrimary
    static let appSecondaryText = AppTheme.textSecondary
    static let appTertiaryText = AppTheme.textTertiary
    static let appSeparator = AppTheme.border

    static func blockColor(for type: BlockType, colorScheme: ColorScheme) -> Color {
        AppTheme.blockColor(for: type)
    }

    static func blockBackgroundColor(for type: BlockType, colorScheme: ColorScheme) -> Color {
        AppTheme.blockColor(for: type).opacity(0.15)
    }

    static func blockColor(for type: BlockType) -> Color {
        AppTheme.blockColor(for: type)
    }

    static func blockBackgroundColor(for type: BlockType) -> Color {
        AppTheme.blockColor(for: type).opacity(0.15)
    }

    static func calendarToday(_ colorScheme: ColorScheme) -> Color {
        AppTheme.accent.opacity(0.15)
    }

    static func calendarSelected(_ colorScheme: ColorScheme) -> Color {
        AppTheme.accent.opacity(0.25)
    }
}

extension ShapeStyle where Self == Color {
    static var appAccent: Color { .appAccent }
}

// MARK: - Constants

enum Constants {
    enum App {
        static let name = "Endless Future"
        static let bundleId = "com.endlessfuture.app"
        static let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    enum Layout {
        static let screenPadding: CGFloat = 20
        static let sectionSpacing: CGFloat = 24
        static let itemSpacing: CGFloat = 12
        static let smallSpacing: CGFloat = 8
        static let tinySpacing: CGFloat = 4

        static let cornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 12
        static let largeCornerRadius: CGFloat = 24

        static let buttonHeight: CGFloat = 54
        static let smallButtonHeight: CGFloat = 44

        static let iconSize: CGFloat = 24
        static let smallIconSize: CGFloat = 18
        static let largeIconSize: CGFloat = 32
    }

    enum Animation {
        static let quick: SwiftUI.Animation = .easeInOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let smooth: SwiftUI.Animation = .easeInOut(duration: 0.35)
        static let spring: SwiftUI.Animation = .spring(response: 0.4, dampingFraction: 0.75)
    }

    enum Calendar {
        static let hourHeight: CGFloat = 60
        static let timeColumnWidth: CGFloat = 50
        static let dayHeaderHeight: CGFloat = 60
        static let blockMinHeight: CGFloat = 30
        static let startHour = 6
        static let endHour = 23
    }

    enum Timing {
        static let debounceDelay: TimeInterval = 0.3
        static let autoSaveDelay: TimeInterval = 1.0
        static let notificationLeadTime: TimeInterval = 15 * 60
    }

    enum Limits {
        static let maxCustomIdentityNameLength = 50
        static let maxNoteLength = 500
        static let maxGoalsFree = 1
    }

    enum URLs {
        static let privacyPolicy = URL(string: "https://endlessfuture.app/privacy")!
        static let termsOfService = URL(string: "https://endlessfuture.app/terms")!
        static let support = URL(string: "https://endlessfuture.app/support")!
    }

    enum NotificationIds {
        static let blockReminder = "block_reminder"
        static let reflectionReminder = "reflection_reminder"
    }

    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let selectedCalendarView = "selectedCalendarView"
        static let lastReflectionPrompt = "lastReflectionPrompt"
        static let notificationsEnabled = "notificationsEnabled"
    }

    enum Onboarding {
        static let totalSteps = 5
        static let progressBarHeight: CGFloat = 4
    }
}

enum FeatureFlags {
    static let enableAIPlanning = true
    static let enableWeeklyAdaptation = true
    static let enableSmartRescheduling = true
    static let enableDebugMenu = false

    #if DEBUG
    static let useMockAI = false
    #else
    static let useMockAI = false
    #endif
}

// MARK: - Haptics

enum Haptics {
    private static let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private static let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private static let selectionGenerator = UISelectionFeedbackGenerator()
    private static let notificationGenerator = UINotificationFeedbackGenerator()

    static func light() { lightGenerator.impactOccurred() }
    static func medium() { mediumGenerator.impactOccurred() }
    static func heavy() { heavyGenerator.impactOccurred() }
    static func selection() { selectionGenerator.selectionChanged() }
    static func success() { notificationGenerator.notificationOccurred(.success) }
    static func warning() { notificationGenerator.notificationOccurred(.warning) }
    static func error() { notificationGenerator.notificationOccurred(.error) }

    // Semantic shortcuts
    static func tap() { light() }
    static func navigate() { selection() }
    static func complete() { success() }
    static func select() { selection() }
    static func toggle() { light() }
    static func slide() { selection() }
    static func delete() { medium() }
    static func longPress() { medium() }

    static func prepare() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
}

// MARK: - Environment Key (for legacy compatibility)

private struct AppColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .dark
}

extension EnvironmentValues {
    var appColorScheme: ColorScheme {
        get { self[AppColorSchemeKey.self] }
        set { self[AppColorSchemeKey.self] = newValue }
    }
}

// MARK: - Theme Manager (Simplified - Always Dark)

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    // Always dark mode
    let isDarkMode = true

    var colorScheme: ColorScheme? { .dark }
}

// MARK: - Themed View Modifier (Simplified)

struct ThemedView: ViewModifier {
    func body(content: Content) -> some View {
        content
            .environment(\.appColorScheme, .dark)
            .preferredColorScheme(.dark)
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemedView())
    }
}
