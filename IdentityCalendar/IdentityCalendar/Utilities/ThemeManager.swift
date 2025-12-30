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

// MARK: - Theme Colors (WHOOP-inspired dark aesthetic)

struct AppTheme {
    // MARK: - Dynamic Colors (Deep black backgrounds like WHOOP)

    static func background(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "000000") : Color(hex: "F8F9FA")
    }

    static func cardBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "0F0F0F") : Color.white
    }

    static func secondaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "F0F1F3")
    }

    static func tertiaryBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "242424") : Color(hex: "E8E9EB")
    }

    static func primaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color.white : Color(hex: "1A1A1E")
    }

    static func secondaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "9A9A9A") : Color(hex: "6B6B70")
    }

    static func tertiaryText(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "666666") : Color(hex: "9A9A9E")
    }

    static func separator(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "E0E0E2")
    }

    // MARK: - Accent Colors (WHOOP-style mint/teal green)

    static let accent = Color(hex: "00D9A5") // WHOOP mint green
    static let accentLight = Color(hex: "00F5B8") // Lighter mint
    static let accentDark = Color(hex: "00B88A") // Darker mint for contrast
    static let success = Color(hex: "00D9A5") // Same as accent (green = success)
    static let warning = Color(hex: "FFB020") // Warm amber
    static let error = Color(hex: "FF4757") // Soft red

    // MARK: - Additional WHOOP-style colors

    static let strain = Color(hex: "00B4D8") // Blue for strain/effort metrics
    static let recovery = Color(hex: "00D9A5") // Green for recovery/progress
    static let sleep = Color(hex: "9B5DE5") // Purple for rest/sleep

    // MARK: - Block Colors (More vibrant for dark backgrounds)

    static func blockFocus(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "00D9A5") : Color(hex: "00B88A")
    }

    static func blockLight(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "00B4D8") : Color(hex: "0096B4")
    }

    static func blockHabit(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "FFB020") : Color(hex: "E69D00")
    }

    static func blockReview(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "9B5DE5") : Color(hex: "8347D1")
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
            colors: [Color(hex: "00D9A5"), Color(hex: "00B4D8")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Ring/Progress Colors (WHOOP-style circular metrics)

    static func ringBackground(_ colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: "1A1A1A") : Color(hex: "E8E9EB")
    }

    static let ringProgress = Color(hex: "00D9A5")
    static let ringSecondary = Color(hex: "00B4D8")
    static let ringTertiary = Color(hex: "9B5DE5")
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
