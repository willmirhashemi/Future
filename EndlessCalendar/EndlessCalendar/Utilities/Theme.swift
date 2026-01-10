import SwiftUI

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = true

    func toggleTheme() {
        isDarkMode.toggle()
    }
}

// MARK: - Theme Colors and Styles
struct Theme {
    // MARK: - Colors
    struct Colors {
        // Background colors - dark matte
        static let background = Color(hex: "0D0D0D")
        static let secondaryBackground = Color(hex: "1A1A1A")
        static let tertiaryBackground = Color(hex: "252525")
        static let cardBackground = Color(hex: "1E1E1E")

        // Text colors
        static let textPrimary = Color(hex: "FFFFFF")
        static let textSecondary = Color(hex: "A0A0A0")
        static let textTertiary = Color(hex: "6B6B6B")

        // Accent colors
        static let accent = Color(hex: "FF6B6B")
        static let accentSecondary = Color(hex: "4ECDC4")
        static let accentTertiary = Color(hex: "45B7D1")

        // Category colors
        static let studyLearning = Color(hex: "FFD93D")
        static let fitnessHealth = Color(hex: "6BCB77")
        static let financial = Color(hex: "4D96FF")
        static let creativeHobby = Color(hex: "9B59B6")
        static let networkingSocial = Color(hex: "FF8C42")
        static let selfCareRest = Color(hex: "A8E6CF")
        static let careerDevelopment = Color(hex: "FF6B9D")

        // Status colors
        static let success = Color(hex: "4CAF50")
        static let warning = Color(hex: "FFC107")
        static let error = Color(hex: "F44336")
        static let info = Color(hex: "2196F3")

        // Event type colors
        static let aiEvent = Color(hex: "7C4DFF")
        static let manualEvent = Color(hex: "00BCD4")

        // Timeline
        static let timelineIndicator = Color(hex: "FF6B6B")
        static let timelineGrid = Color(hex: "2A2A2A")

        // Mood colors
        static let moodGreat = Color(hex: "4CAF50")
        static let moodGood = Color(hex: "8BC34A")
        static let moodNeutral = Color(hex: "FFC107")
        static let moodBad = Color(hex: "FF9800")
        static let moodTerrible = Color(hex: "F44336")
    }

    // MARK: - Fonts
    struct Fonts {
        static func largeTitle() -> Font {
            .system(size: 34, weight: .bold, design: .rounded)
        }

        static func title() -> Font {
            .system(size: 28, weight: .bold, design: .rounded)
        }

        static func title2() -> Font {
            .system(size: 22, weight: .semibold, design: .rounded)
        }

        static func title3() -> Font {
            .system(size: 20, weight: .semibold, design: .rounded)
        }

        static func headline() -> Font {
            .system(size: 17, weight: .semibold, design: .rounded)
        }

        static func body() -> Font {
            .system(size: 17, weight: .regular, design: .rounded)
        }

        static func callout() -> Font {
            .system(size: 16, weight: .regular, design: .rounded)
        }

        static func subheadline() -> Font {
            .system(size: 15, weight: .regular, design: .rounded)
        }

        static func footnote() -> Font {
            .system(size: 13, weight: .regular, design: .rounded)
        }

        static func caption() -> Font {
            .system(size: 12, weight: .regular, design: .rounded)
        }

        static func caption2() -> Font {
            .system(size: 11, weight: .regular, design: .rounded)
        }
    }

    // MARK: - Spacing
    struct Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 24
    }

    // MARK: - Shadows
    struct Shadows {
        static let small = Shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        static let medium = Shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        static let large = Shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Shadow Helper
struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extension for Hex
extension Color {
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
            (a, r, g, b) = (1, 1, 1, 0)
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

// MARK: - View Modifiers
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.headline())
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.accent)
            .cornerRadius(Theme.CornerRadius.medium)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.headline())
            .foregroundColor(Theme.Colors.accent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.md)
            .background(Theme.Colors.secondaryBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(Theme.Colors.accent, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
