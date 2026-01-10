import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    @State private var showingWeeklyReview = false

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            TabView(selection: $selectedTab) {
                CalendarTab()
                    .tabItem {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }
                    .tag(0)

                JournalTab()
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("Journal")
                    }
                    .tag(1)
            }
            .tint(Theme.Colors.accent)
        }
        .onAppear {
            setupTabBarAppearance()
            checkForWeeklyReview()
        }
        .sheet(isPresented: $showingWeeklyReview) {
            WeeklyReviewSheet()
        }
    }

    private func setupTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Theme.Colors.secondaryBackground)

        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Theme.Colors.accent)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.accent)
        ]

        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Theme.Colors.textSecondary)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor(Theme.Colors.textSecondary)
        ]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    private func checkForWeeklyReview() {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        let hour = calendar.component(.hour, from: Date())

        // Show weekly review popup on Sunday evening (after 6 PM)
        if weekday == 1 && hour >= 18 {
            // Check if user hasn't completed review this week
            // For now, show it - in production, check against stored data
            showingWeeklyReview = true
        }
    }
}

// MARK: - Weekly Review Sheet
struct WeeklyReviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService
    @StateObject private var firestoreService = FirestoreService()

    @State private var journalEntries: [JournalEntry] = []
    @State private var accomplishedGoals = ""
    @State private var missedGoals = ""
    @State private var overallMood: Mood = .neutral
    @State private var reflectionNotes = ""
    @State private var nextWeekIntentions = ""
    @State private var isSaving = false

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Header
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Weekly Review")
                                .font(Theme.Fonts.title())
                                .foregroundColor(Theme.Colors.textPrimary)

                            Text("Take a moment to reflect on your week")
                                .font(Theme.Fonts.subheadline())
                                .foregroundColor(Theme.Colors.textSecondary)
                        }

                        // Journal Summary
                        if !journalEntries.isEmpty {
                            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                                Text("This Week's Journal Entries")
                                    .font(Theme.Fonts.headline())
                                    .foregroundColor(Theme.Colors.textPrimary)

                                ForEach(journalEntries) { entry in
                                    JournalEntrySummaryRow(entry: entry)
                                }
                            }
                            .padding(Theme.Spacing.md)
                            .background(Theme.Colors.cardBackground)
                            .cornerRadius(Theme.CornerRadius.medium)
                        }

                        // Overall Mood
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Overall Mood This Week")
                                .font(Theme.Fonts.headline())
                                .foregroundColor(Theme.Colors.textPrimary)

                            MoodSelector(selectedMood: $overallMood)
                        }

                        // Accomplishments
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("What did you accomplish?")
                                .font(Theme.Fonts.headline())
                                .foregroundColor(Theme.Colors.textPrimary)

                            TextEditor(text: $accomplishedGoals)
                                .font(Theme.Fonts.body())
                                .foregroundColor(Theme.Colors.textPrimary)
                                .frame(minHeight: 80)
                                .padding(Theme.Spacing.sm)
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.CornerRadius.medium)
                        }

                        // Missed Goals
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("What didn't go as planned?")
                                .font(Theme.Fonts.headline())
                                .foregroundColor(Theme.Colors.textPrimary)

                            TextEditor(text: $missedGoals)
                                .font(Theme.Fonts.body())
                                .foregroundColor(Theme.Colors.textPrimary)
                                .frame(minHeight: 80)
                                .padding(Theme.Spacing.sm)
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.CornerRadius.medium)
                        }

                        // Reflections
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Any other reflections?")
                                .font(Theme.Fonts.headline())
                                .foregroundColor(Theme.Colors.textPrimary)

                            TextEditor(text: $reflectionNotes)
                                .font(Theme.Fonts.body())
                                .foregroundColor(Theme.Colors.textPrimary)
                                .frame(minHeight: 80)
                                .padding(Theme.Spacing.sm)
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.CornerRadius.medium)
                        }

                        // Next Week Intentions
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            Text("Intentions for next week")
                                .font(Theme.Fonts.headline())
                                .foregroundColor(Theme.Colors.textPrimary)

                            TextEditor(text: $nextWeekIntentions)
                                .font(Theme.Fonts.body())
                                .foregroundColor(Theme.Colors.textPrimary)
                                .frame(minHeight: 80)
                                .padding(Theme.Spacing.sm)
                                .background(Theme.Colors.cardBackground)
                                .cornerRadius(Theme.CornerRadius.medium)
                        }

                        // Save Button
                        Button(action: saveReview) {
                            if isSaving {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Review")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isSaving)
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
        .onAppear {
            loadWeeklyJournalEntries()
        }
    }

    private func loadWeeklyJournalEntries() {
        guard let userId = authService.currentUser?.id else { return }

        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        Task {
            journalEntries = try await firestoreService.fetchJournalEntriesForWeek(
                userId: userId,
                weekStartDate: weekStart
            )
        }
    }

    private func saveReview() {
        guard let userId = authService.currentUser?.id else { return }

        isSaving = true

        let calendar = Calendar.current
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart)!

        let review = WeeklyReview(
            userId: userId,
            weekStartDate: weekStart,
            weekEndDate: weekEnd,
            journalEntries: journalEntries.compactMap { $0.id },
            accomplishedGoals: accomplishedGoals.components(separatedBy: "\n").filter { !$0.isEmpty },
            missedGoals: missedGoals.components(separatedBy: "\n").filter { !$0.isEmpty },
            overallMood: overallMood,
            reflectionNotes: reflectionNotes,
            nextWeekIntentions: nextWeekIntentions
        )

        Task {
            do {
                _ = try await firestoreService.saveWeeklyReview(review)
                isSaving = false
                dismiss()
            } catch {
                isSaving = false
                print("Error saving review: \(error)")
            }
        }
    }
}

struct JournalEntrySummaryRow: View {
    let entry: JournalEntry

    var body: some View {
        HStack {
            Text(entry.mood.emoji)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.shortFormattedDate)
                    .font(Theme.Fonts.subheadline())
                    .foregroundColor(Theme.Colors.textPrimary)

                if !entry.content.isEmpty {
                    Text(entry.content)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Colors.secondaryBackground)
        .cornerRadius(Theme.CornerRadius.small)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthService())
        .environmentObject(ThemeManager())
}
