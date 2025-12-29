import SwiftUI
import SwiftData

/// Main app entry point
@main
struct IdentityCalendarApp: App {
    @StateObject private var dataService = DataService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataService)
                .environmentObject(subscriptionService)
                .environmentObject(notificationService)
                .environmentObject(themeManager)
                .modelContainer(dataService.modelContainer)
                .themed()
        }
    }
}

/// Root view that handles navigation between onboarding and main app
struct RootView: View {
    @EnvironmentObject private var dataService: DataService
    @Environment(\.appColorScheme) private var colorScheme
    @State private var showOnboarding = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            AppTheme.background(colorScheme)
                .ignoresSafeArea()

            if isLoading {
                LaunchView(colorScheme: colorScheme)
            } else if showOnboarding {
                NewOnboardingView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                }
                .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isLoading)
        .animation(.easeInOut(duration: 0.3), value: showOnboarding)
        .onAppear {
            checkOnboardingStatus()
        }
    }

    private func checkOnboardingStatus() {
        // Brief delay for launch screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let user = dataService.currentUser
            let needsOnboarding = user == nil || !user!.hasCompletedOnboarding

            withAnimation {
                showOnboarding = needsOnboarding
                isLoading = false
            }
        }
    }
}

/// Launch screen view
struct LaunchView: View {
    let colorScheme: ColorScheme
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            AppTheme.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Animated logo
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .scaleEffect(iconScale)

                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundColor(AppTheme.accent)
                        .scaleEffect(iconScale)
                }
                .opacity(iconOpacity)

                VStack(spacing: 8) {
                    Text("Future")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))

                    Text("Plan your path")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                }
                .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                textOpacity = 1.0
            }
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Configure notification categories
        configureNotificationCategories()

        // Request notification permissions early
        Task {
            _ = await NotificationService.shared.requestAuthorization()
        }

        return true
    }

    private func configureNotificationCategories() {
        let blockCategory = UNNotificationCategory(
            identifier: NotificationCategory.blockReminder.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        let reflectionCategory = UNNotificationCategory(
            identifier: NotificationCategory.reflection.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            blockCategory,
            reflectionCategory
        ])
    }
}

// MARK: - Preview

#Preview {
    RootView()
        .environmentObject(DataService.shared)
        .environmentObject(SubscriptionService.shared)
        .environmentObject(NotificationService.shared)
        .environmentObject(ThemeManager.shared)
        .themed()
}
