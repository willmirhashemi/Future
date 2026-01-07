import SwiftUI

// MARK: - Date Extensions

extension Date {
    // MARK: - Formatting

    var shortTimeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: self)
    }

    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }

    var mediumDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: self)
    }

    var dayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: self)
    }

    var shortDayOfWeekString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: self)
    }

    var dayNumberString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: self)
    }

    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    var monthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: self)
    }

    var shortMonthString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: self)
    }

    var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: self)
    }

    // MARK: - Calendar Helpers

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)?.addingTimeInterval(-1) ?? self
    }

    var startOfWeek: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfWeek: Date {
        Calendar.current.date(byAdding: .day, value: 6, to: startOfWeek) ?? self
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    var isToday: Bool { Calendar.current.isDateInToday(self) }
    var isTomorrow: Bool { Calendar.current.isDateInTomorrow(self) }
    var isYesterday: Bool { Calendar.current.isDateInYesterday(self) }
    var isWeekend: Bool { Calendar.current.isDateInWeekend(self) }
    var isSunday: Bool { Calendar.current.component(.weekday, from: self) == 1 }
    var weekday: Int { Calendar.current.component(.weekday, from: self) }
    var hour: Int { Calendar.current.component(.hour, from: self) }
    var minute: Int { Calendar.current.component(.minute, from: self) }

    // MARK: - Date Manipulation

    func adding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func adding(weeks: Int) -> Date {
        Calendar.current.date(byAdding: .weekOfYear, value: weeks, to: self) ?? self
    }

    func adding(hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }

    func adding(minutes: Int) -> Date {
        Calendar.current.date(byAdding: .minute, value: minutes, to: self) ?? self
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func isSameWeek(as other: Date) -> Bool {
        let calendar = Calendar.current
        let selfWeek = calendar.component(.weekOfYear, from: self)
        let otherWeek = calendar.component(.weekOfYear, from: other)
        let selfYear = calendar.component(.yearForWeekOfYear, from: self)
        let otherYear = calendar.component(.yearForWeekOfYear, from: other)
        return selfWeek == otherWeek && selfYear == otherYear
    }

    func daysOfWeek() -> [Date] {
        let start = startOfWeek
        return (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: start) }
    }

    var relativeString: String {
        if isToday { return "Today" }
        if isTomorrow { return "Tomorrow" }
        if isYesterday { return "Yesterday" }
        return mediumDateString
    }

    static func durationString(from start: Date, to end: Date) -> String {
        let minutes = Int(end.timeIntervalSince(start) / 60)
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0 ? "\(hours)h" : "\(hours)h \(remainingMinutes)m"
    }
}

extension TimeInterval {
    var minutesString: String {
        let minutes = Int(self / 60)
        if minutes < 60 { return "\(minutes) min" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        return remainingMinutes == 0 ? "\(hours)h" : "\(hours)h \(remainingMinutes)m"
    }
}

// MARK: - View Extensions

extension View {
    // MARK: - Modern Card Styling

    func cardStyle(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            )
    }

    func elevatedCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(AppTheme.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.largeCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Constants.Layout.largeCornerRadius, style: .continuous)
                    .stroke(AppTheme.borderLight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Button Styling

    func primaryButtonStyle() -> some View {
        self
            .font(.body.weight(.semibold))
            .foregroundColor(AppTheme.background)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Layout.buttonHeight)
            .background(AppTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius, style: .continuous))
    }

    func secondaryButtonStyle() -> some View {
        self
            .font(.body.weight(.medium))
            .foregroundColor(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Layout.buttonHeight)
            .background(AppTheme.accent.opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: Constants.Layout.cornerRadius, style: .continuous))
    }

    func tertiaryButtonStyle() -> some View {
        self
            .font(.body.weight(.medium))
            .foregroundColor(AppTheme.textSecondary)
    }

    // MARK: - Text Styling

    func headlineStyle() -> some View {
        self
            .font(.system(size: 28, weight: .bold, design: .default))
            .foregroundColor(AppTheme.textPrimary)
    }

    func titleStyle() -> some View {
        self
            .font(.title2.weight(.semibold))
            .foregroundColor(AppTheme.textPrimary)
    }

    func subtitleStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(AppTheme.textSecondary)
    }

    func captionStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(AppTheme.textTertiary)
    }

    // MARK: - Layout Helpers

    func screenPadding() -> some View {
        self.padding(.horizontal, Constants.Layout.screenPadding)
    }

    // MARK: - Conditional Modifiers

    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition { transform(self) } else { self }
    }

    @ViewBuilder
    func ifLet<T, Transform: View>(_ value: T?, transform: (Self, T) -> Transform) -> some View {
        if let value = value { transform(self, value) } else { self }
    }

    // MARK: - Transitions

    func subtleAppear() -> some View {
        self.transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    func slideUp() -> some View {
        self.transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: - Shimmer Loading Effect

    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }
}

// MARK: - Shimmer Modifier

struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [.clear, .white.opacity(0.3), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + (geometry.size.width * 2 * phase))
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Button Styles

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(Constants.Animation.quick, value: configuration.isPressed)
    }
}

struct SoftButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(Constants.Animation.quick, value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ScaleButtonStyle {
    static var scale: ScaleButtonStyle { ScaleButtonStyle() }
}

extension ButtonStyle where Self == SoftButtonStyle {
    static var soft: SoftButtonStyle { SoftButtonStyle() }
}
