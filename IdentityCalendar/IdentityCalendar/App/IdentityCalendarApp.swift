import SwiftUI
import SwiftData

/// Main app entry point
@main
struct IdentityCalendarApp: App {
    @StateObject private var dataService = DataService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var themeManager = ThemeManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(dataService)
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
                NewOnboardingView(onComplete: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showOnboarding = false
                    }
                })
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

/// Launch screen view with polished animations
struct LaunchView: View {
    let colorScheme: ColorScheme
    @State private var iconScale: CGFloat = 0.6
    @State private var iconOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            AppTheme.background(colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Animated logo with glow effect
                ZStack {
                    // Outer glow pulse
                    Circle()
                        .fill(AppTheme.accent.opacity(0.08))
                        .frame(width: 140, height: 140)
                        .scaleEffect(pulseScale)
                        .opacity(glowOpacity)

                    // Inner glow
                    Circle()
                        .fill(AppTheme.accent.opacity(0.15))
                        .frame(width: 110, height: 110)
                        .scaleEffect(iconScale)

                    // Icon background
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.2), AppTheme.accent.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 90, height: 90)
                        .scaleEffect(iconScale)

                    // Sparkles icon
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(iconScale)
                }
                .opacity(iconOpacity)

                VStack(spacing: 10) {
                    Text("Endless Future")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                        .opacity(textOpacity)

                    Text("Your path, infinitely planned")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.secondaryText(colorScheme))
                        .opacity(subtitleOpacity)
                }
            }
        }
        .onAppear {
            // Staggered entrance animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                iconScale = 1.0
                iconOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.15)) {
                glowOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.25)) {
                textOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.5).delay(0.4)) {
                subtitleOpacity = 1.0
            }

            // Subtle pulse animation
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.6)) {
                pulseScale = 1.15
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
        .environmentObject(NotificationService.shared)
        .environmentObject(ThemeManager.shared)
        .themed()
}
