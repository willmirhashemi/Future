import SwiftUI
import SwiftData

/// Main app entry point
@main
struct IdentityCalendarApp: App {
    @StateObject private var dataService = DataService.shared
    @StateObject private var subscriptionService = SubscriptionService.shared
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataService)
                .environmentObject(subscriptionService)
                .environmentObject(notificationService)
                .modelContainer(dataService.modelContainer)
        }
    }
}

/// Root view that handles navigation between onboarding and main app
struct RootView: View {
    @EnvironmentObject private var dataService: DataService
    @State private var showOnboarding = false
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if isLoading {
                LaunchView()
            } else if showOnboarding {
                OnboardingContainerView {
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
    @State private var iconScale: CGFloat = 0.8
    @State private var iconOpacity: Double = 0

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            VStack(spacing: 16) {
                Image(systemName: "calendar")
                    .font(.system(size: 60))
                    .foregroundColor(.appAccent)
                    .scaleEffect(iconScale)
                    .opacity(iconOpacity)

                Text("Identity Calendar")
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.appPrimaryText)
                    .opacity(iconOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }
        }
    }
}

/// Main tab view (currently just calendar, expandable)
struct MainTabView: View {
    var body: some View {
        CalendarView()
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
}
