import SwiftUI

struct RootView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView()
            } else if authService.currentUser == nil {
                AuthenticationView()
            } else if !authService.hasCompletedOnboarding {
                OnboardingFlow()
            } else {
                MainTabView()
            }
        }
        .onAppear {
            checkAuthState()
        }
    }

    private func checkAuthState() {
        Task {
            await authService.checkCurrentUser()
            isLoading = false
        }
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "calendar.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(Theme.Colors.accent)

                Text("Endless Calendar")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Theme.Colors.textPrimary)

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Theme.Colors.accent))
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthService())
        .environmentObject(ThemeManager())
}
