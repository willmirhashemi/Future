import SwiftUI

/// Main tab view with Calendar and Future sections
struct MainTabView: View {
    @State private var selectedTab: AppTab = .calendar
    @Environment(\.appColorScheme) private var colorScheme

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

// MARK: - Preview

#Preview {
    MainTabView()
        .themed()
}
