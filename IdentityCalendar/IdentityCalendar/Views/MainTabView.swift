import SwiftUI

/// Main tab view with Calendar and Future sections
struct MainTabView: View {
    @State private var selectedTab: AppTab = .calendar
    @State private var showDailyReflection = false
    @Environment(\.appColorScheme) private var colorScheme

    private let dataService = DataService.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            TabView(selection: $selectedTab) {
                NewCalendarView()
                    .tag(AppTab.calendar)

                FutureView()
                    .tag(AppTab.future)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom tab bar
            CustomTabBar(
                selectedTab: $selectedTab,
                colorScheme: colorScheme
            )
        }
        .ignoresSafeArea(.keyboard)
        // Feature 4: Daily reflection prompt (subtle, end-of-day)
        .sheet(isPresented: $showDailyReflection) {
            DailyReflectionSheet()
                .presentationDetents([.height(280)])
                .presentationDragIndicator(.visible)
        }
        .onAppear {
            checkForDailyReflection()
        }
    }

    private func checkForDailyReflection() {
        // Delay check to not interrupt app launch
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showDailyReflection = dataService.shouldShowDailyReflection()
        }
    }
}

// MARK: - App Tabs

enum AppTab: String, CaseIterable {
    case calendar
    case future

    var title: String {
        switch self {
        case .calendar: return "Calendar"
        case .future: return "Future"
        }
    }

    var icon: String {
        switch self {
        case .calendar: return "calendar"
        case .future: return "sparkles"
        }
    }

    var selectedIcon: String {
        switch self {
        case .calendar: return "calendar"
        case .future: return "sparkles"
        }
    }
}

// MARK: - Custom Tab Bar

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    let colorScheme: ColorScheme

    var body: some View {
        HStack(spacing: 40) { // Closer spacing between tabs
            ForEach(AppTab.allCases, id: \.self) { tab in
                TabBarButton(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    colorScheme: colorScheme,
                    action: {
                        Haptics.select()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity) // Center the tabs
        .padding(.top, 14)
        .padding(.bottom, 30)
        .background(
            TabBarBackground(colorScheme: colorScheme)
        )
    }
}

struct TabBarButton: View {
    let tab: AppTab
    let isSelected: Bool
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    // Selected indicator background
                    if isSelected {
                        Circle()
                            .fill(AppTheme.accent.opacity(0.15))
                            .frame(width: 48, height: 48)
                    }

                    Image(systemName: isSelected ? tab.selectedIcon : tab.icon)
                        .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                        .foregroundColor(isSelected ? AppTheme.accent : AppTheme.tertiaryText(colorScheme))
                }
                .frame(width: 48, height: 48)

                Text(tab.title)
                    .font(.caption2.weight(isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppTheme.accent : AppTheme.tertiaryText(colorScheme))
            }
            .frame(width: 80) // Fixed width for consistent spacing
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct TabBarBackground: View {
    let colorScheme: ColorScheme

    var body: some View {
        Rectangle()
            .fill(AppTheme.cardBackground(colorScheme))
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(AppTheme.separator(colorScheme))
                    .frame(height: 0.5)
            }
            .shadow(color: .black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 20, y: -5)
    }
}

// ============================================================================
// MARK: - Feature 4: Daily Reflection Sheet
// ============================================================================

/// Minimal end-of-day reflection - one question, 10 seconds max, always skippable
/// No guilt, no reminders, no streaks - just a gentle check-in
struct DailyReflectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appColorScheme) private var colorScheme
    @State private var reflectionText = ""
    @FocusState private var isFocused: Bool

    private let dataService = DataService.shared
    private let prompt: DailyReflectionPrompt

    init() {
        self.prompt = DataService.shared.getDailyReflectionPrompt()
    }

    var body: some View {
        VStack(spacing: 20) {
            // Simple header
            Text(prompt.question)
                .font(.title3.weight(.medium))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.top, 8)

            // Text input - minimal, not overwhelming
            TextField(prompt.placeholder, text: $reflectionText, axis: .vertical)
                .font(.body)
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .padding(12)
                .background(AppTheme.secondaryBackground(colorScheme))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .lineLimit(2...4)
                .focused($isFocused)

            Spacer()

            // Action buttons - skip is always easy to access
            HStack(spacing: 16) {
                // Skip button - prominent, no guilt
                Button {
                    Haptics.tap()
                    dataService.recordDailyReflection(note: nil, skipped: true)
                    dismiss()
                } label: {
                    Text("Skip")
                        .font(.body.weight(.medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.secondaryBackground(colorScheme))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Done button
                Button {
                    Haptics.success()
                    dataService.recordDailyReflection(
                        note: reflectionText.isEmpty ? nil : reflectionText,
                        skipped: false
                    )
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppTheme.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(20)
        .background(AppTheme.background(colorScheme))
        .onAppear {
            // Auto-focus for quick input
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .themed()
}

#Preview("Daily Reflection") {
    DailyReflectionSheet()
        .themed()
}
