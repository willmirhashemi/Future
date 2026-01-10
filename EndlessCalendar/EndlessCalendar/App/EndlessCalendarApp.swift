import SwiftUI
import FirebaseCore

@main
struct EndlessCalendarApp: App {
    @StateObject private var authService = AuthService()
    @StateObject private var themeManager = ThemeManager()

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .preferredColorScheme(.dark)
        }
    }
}
