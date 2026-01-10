import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) private var dismiss
    @StateObject private var firestoreService = FirestoreService()

    @State private var showingResetGoalsAlert = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Theme.Spacing.lg) {
                        // Profile Section
                        profileSection

                        // Preferences Section
                        preferencesSection

                        // Notifications Section
                        notificationsSection

                        // Goals Section
                        goalsSection

                        // Account Section
                        accountSection

                        // About Section
                        aboutSection
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
            }
        }
        .alert("Reset Goals", isPresented: $showingResetGoalsAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                resetGoals()
            }
        } message: {
            Text("This will delete all AI-generated events and restart your journey. Your manual events and journal entries will be kept. Are you sure?")
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
    }

    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Profile")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textSecondary)

            VStack(spacing: 0) {
                HStack {
                    // Avatar
                    ZStack {
                        Circle()
                            .fill(Theme.Colors.accent.opacity(0.2))
                            .frame(width: 60, height: 60)

                        Text(String(authService.currentUser?.displayName.prefix(1) ?? "U"))
                            .font(Theme.Fonts.title())
                            .foregroundColor(Theme.Colors.accent)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.currentUser?.displayName ?? "User")
                            .font(Theme.Fonts.headline())
                            .foregroundColor(Theme.Colors.textPrimary)

                        Text(authService.currentUser?.email ?? "")
                            .font(Theme.Fonts.subheadline())
                            .foregroundColor(Theme.Colors.textSecondary)
                    }

                    Spacer()
                }
                .padding(Theme.Spacing.md)

                Divider()
                    .background(Theme.Colors.textTertiary)

                // Category badge
                if let category = authService.currentUser?.selectedCategory {
                    HStack {
                        Image(systemName: category.icon)
                            .foregroundColor(categoryColor(for: category))

                        Text("Focus: \(category.displayName)")
                            .font(Theme.Fonts.subheadline())
                            .foregroundColor(Theme.Colors.textPrimary)

                        Spacer()
                    }
                    .padding(Theme.Spacing.md)
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Preferences")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textSecondary)

            VStack(spacing: 0) {
                // Inactivity Reset
                NavigationLink {
                    InactivitySettingView()
                } label: {
                    SettingsRow(
                        icon: "clock.arrow.circlepath",
                        title: "Inactivity Reset",
                        subtitle: "\(authService.currentUser?.preferences.inactivityResetWeeks ?? 2) weeks"
                    )
                }

                Divider()
                    .background(Theme.Colors.textTertiary)
                    .padding(.leading, 52)

                // Journal Format
                NavigationLink {
                    JournalFormatSettingView()
                } label: {
                    SettingsRow(
                        icon: "doc.text",
                        title: "Journal Format",
                        subtitle: authService.currentUser?.preferences.journalFormat.displayName ?? "Free Form"
                    )
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Notifications Section
    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Notifications")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textSecondary)

            VStack(spacing: 0) {
                // Enable Notifications
                SettingsToggleRow(
                    icon: "bell",
                    title: "Push Notifications",
                    isOn: Binding(
                        get: { authService.currentUser?.preferences.notificationsEnabled ?? true },
                        set: { newValue in
                            updateNotificationPreference(enabled: newValue)
                        }
                    )
                )

                Divider()
                    .background(Theme.Colors.textTertiary)
                    .padding(.leading, 52)

                // Weekly Review
                SettingsToggleRow(
                    icon: "calendar.badge.clock",
                    title: "Weekly Review Reminder",
                    isOn: Binding(
                        get: { authService.currentUser?.preferences.weeklyReviewEnabled ?? true },
                        set: { newValue in
                            updateWeeklyReviewPreference(enabled: newValue)
                        }
                    )
                )
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Goals")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textSecondary)

            VStack(spacing: 0) {
                Button(action: { showingResetGoalsAlert = true }) {
                    SettingsRow(
                        icon: "arrow.counterclockwise",
                        title: "Reset Goals",
                        subtitle: "Start fresh with new AI-generated plan",
                        showChevron: false,
                        destructive: true
                    )
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Account Section
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Account")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textSecondary)

            VStack(spacing: 0) {
                Button(action: { showingSignOutAlert = true }) {
                    SettingsRow(
                        icon: "rectangle.portrait.and.arrow.right",
                        title: "Sign Out",
                        subtitle: nil,
                        showChevron: false
                    )
                }

                Divider()
                    .background(Theme.Colors.textTertiary)
                    .padding(.leading, 52)

                Button(action: { showingDeleteAccountAlert = true }) {
                    SettingsRow(
                        icon: "trash",
                        title: "Delete Account",
                        subtitle: nil,
                        showChevron: false,
                        destructive: true
                    )
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("About")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textSecondary)

            VStack(spacing: 0) {
                SettingsRow(
                    icon: "info.circle",
                    title: "Version",
                    subtitle: "1.0.0",
                    showChevron: false
                )

                Divider()
                    .background(Theme.Colors.textTertiary)
                    .padding(.leading, 52)

                NavigationLink {
                    Text("Privacy Policy")
                } label: {
                    SettingsRow(
                        icon: "hand.raised",
                        title: "Privacy Policy",
                        subtitle: nil
                    )
                }

                Divider()
                    .background(Theme.Colors.textTertiary)
                    .padding(.leading, 52)

                NavigationLink {
                    Text("Terms of Service")
                } label: {
                    SettingsRow(
                        icon: "doc.text",
                        title: "Terms of Service",
                        subtitle: nil
                    )
                }
            }
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Helper Methods
    private func categoryColor(for category: GoalCategory) -> Color {
        switch category {
        case .studyLearning: return Theme.Colors.studyLearning
        case .fitnessHealth: return Theme.Colors.fitnessHealth
        case .financial: return Theme.Colors.financial
        case .creativeHobby: return Theme.Colors.creativeHobby
        case .networkingSocial: return Theme.Colors.networkingSocial
        case .selfCareRest: return Theme.Colors.selfCareRest
        case .careerDevelopment: return Theme.Colors.careerDevelopment
        }
    }

    private func updateNotificationPreference(enabled: Bool) {
        guard var user = authService.currentUser else { return }
        user.preferences.notificationsEnabled = enabled

        Task {
            try await authService.updateUser(user)
        }
    }

    private func updateWeeklyReviewPreference(enabled: Bool) {
        guard var user = authService.currentUser else { return }
        user.preferences.weeklyReviewEnabled = enabled

        Task {
            try await authService.updateUser(user)

            if enabled {
                await NotificationService.shared.scheduleWeeklyReviewReminder()
            } else {
                NotificationService.shared.cancelWeeklyReviewReminder()
            }
        }
    }

    private func resetGoals() {
        guard let userId = authService.currentUser?.id else { return }

        Task {
            // Delete AI events
            try await firestoreService.deleteAIGeneratedEvents(userId: userId)
            try await firestoreService.deactivateAllAIPlans(userId: userId)

            // Reset onboarding
            try await authService.resetGoals()
        }
    }

    private func signOut() {
        try? authService.signOut()
    }

    private func deleteAccount() {
        // In production, implement proper account deletion
        try? authService.signOut()
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String?
    var showChevron: Bool = true
    var destructive: Bool = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(destructive ? Theme.Colors.error : Theme.Colors.accent)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(Theme.Fonts.body())
                    .foregroundColor(destructive ? Theme.Colors.error : Theme.Colors.textPrimary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }

            Spacer()

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.md)
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Theme.Colors.accent)
                .frame(width: 28)

            Text(title)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(Theme.Colors.accent)
        }
        .padding(Theme.Spacing.md)
    }
}

// MARK: - Inactivity Setting View
struct InactivitySettingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedWeeks: Int = 2

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("If you're inactive for this long, we'll suggest creating a new plan to get back on track.")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textSecondary)

                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(1...4, id: \.self) { weeks in
                        Button(action: {
                            selectedWeeks = weeks
                            savePreference()
                        }) {
                            HStack {
                                Text("\(weeks) week\(weeks > 1 ? "s" : "")")
                                    .font(Theme.Fonts.body())
                                    .foregroundColor(Theme.Colors.textPrimary)

                                Spacer()

                                if selectedWeeks == weeks {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Theme.Colors.accent)
                                }
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                    }
                }

                Spacer()
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle("Inactivity Reset")
        .onAppear {
            selectedWeeks = authService.currentUser?.preferences.inactivityResetWeeks ?? 2
        }
    }

    private func savePreference() {
        guard var user = authService.currentUser else { return }
        user.preferences.inactivityResetWeeks = selectedWeeks

        Task {
            try await authService.updateUser(user)
        }
    }
}

// MARK: - Journal Format Setting View
struct JournalFormatSettingView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedFormat: JournalFormat = .freeForm

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("Choose your preferred journaling style.")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textSecondary)

                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(JournalFormat.allCases, id: \.self) { format in
                        Button(action: {
                            selectedFormat = format
                            savePreference()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(format.displayName)
                                        .font(Theme.Fonts.body())
                                        .foregroundColor(Theme.Colors.textPrimary)

                                    Text(formatDescription(format))
                                        .font(Theme.Fonts.caption())
                                        .foregroundColor(Theme.Colors.textSecondary)
                                }

                                Spacer()

                                if selectedFormat == format {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(Theme.Colors.accent)
                                }
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }
                    }
                }

                Spacer()
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle("Journal Format")
        .onAppear {
            selectedFormat = authService.currentUser?.preferences.journalFormat ?? .freeForm
        }
    }

    private func formatDescription(_ format: JournalFormat) -> String {
        switch format {
        case .freeForm:
            return "Write freely without any prompts"
        case .guidedPrompts:
            return "Answer guided questions about your day"
        }
    }

    private func savePreference() {
        guard var user = authService.currentUser else { return }
        user.preferences.journalFormat = selectedFormat

        Task {
            try await authService.updateUser(user)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService())
        .environmentObject(ThemeManager())
}
