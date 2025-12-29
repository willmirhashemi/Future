import SwiftUI

// MARK: - Theme Manager

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("isDarkMode") var isDarkMode: Bool = true
    @AppStorage("useSystemTheme") var useSystemTheme: Bool = false

    var colorScheme: ColorScheme? {
        if useSystemTheme {
            return nil
        }
        return isDarkMode ? .dark : .light
    }

    func toggleTheme() {
        isDarkMode.toggle()
        Haptics.toggle()
    }

    func setDarkMode(_ enabled: Bool) {
        isDarkMode = enabled
    }
}

// MARK: - Theme Colors

struct AppTheme {
    // MARK: - Dynamic Colors

    static func background(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "0D0D0F") : Color(hex: "F8F9FA")
    }

    static func cardBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1E") : Color.white
    }

    static func secondaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "252529") : Color(hex: "F0F1F3")
    }

    static func tertiaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "2D2D32") : Color(hex: "E8E9EB")
    }

    static func primaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color(hex: "1A1A1E")
    }

    static func secondaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "8E8E93") : Color(hex: "6B6B70")
    }

    static func tertiaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "636366") : Color(hex: "9A9A9E")
    }

    static func separator(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "38383A") : Color(hex: "E0E0E2")
    }

    // MARK: - Accent Colors (Same for both modes)

    static let accent = Color(hex: "3B82F6") // Blue
    static let accentLight = Color(hex: "60A5FA")
    static let success = Color(hex: "22C55E") // Green
    static let warning = Color(hex: "F59E0B") // Amber
    static let error = Color(hex: "EF4444") // Red

    // MARK: - Block Colors

    static func blockFocus(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "3B82F6") : Color(hex: "2563EB")
    }

    static func blockLight(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "10B981") : Color(hex: "059669")
    }

    static func blockHabit(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "F59E0B") : Color(hex: "D97706")
    }

    static func blockReview(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "8B5CF6") : Color(hex: "7C3AED")
    }

    // MARK: - Gradients

    static func cardGradient(_ colorScheme: ColorScheme) -> LinearGradient {
        LinearGradient(
            colors: [
                cardBackground(colorScheme),
                cardBackground(colorScheme).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentLight],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var premiumGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "6366F1"), Color(hex: "8B5CF6")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Environment Key

private struct ColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .dark
}

extension EnvironmentValues {
    var appColorScheme: ColorScheme {
        get { self[ColorSchemeKey.self] }
        set { self[ColorSchemeKey.self] = newValue }
    }
}

// MARK: - View Modifier for Theming

struct ThemedView: ViewModifier {
    @Environment(\.colorScheme) var systemColorScheme
    @ObservedObject var themeManager = ThemeManager.shared

    var effectiveColorScheme: ColorScheme {
        if themeManager.useSystemTheme {
            return systemColorScheme
        }
        return themeManager.isDarkMode ? .dark : .light
    }

    func body(content: Content) -> some View {
        content
            .environment(\.appColorScheme, effectiveColorScheme)
            .preferredColorScheme(themeManager.colorScheme)
    }
}

extension View {
    func themed() -> some View {
        modifier(ThemedView())
    }
}

// MARK: - Themed Color Extension

extension Color {
    static func themed(_ keyPath: (ColorScheme) -> Color, for colorScheme: ColorScheme) -> Color {
        keyPath(colorScheme)
    }
}
