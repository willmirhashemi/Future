import SwiftUI

struct JournalTab: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var firestoreService = FirestoreService()

    @State private var selectedSegment = 0
    @State private var journalEntries: [JournalEntry] = []
    @State private var showingNewEntry = false
    @State private var selectedEntry: JournalEntry?

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Segment Control
                    segmentControl

                    // Content
                    if selectedSegment == 0 {
                        journalListView
                    } else {
                        achievementsView
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if selectedSegment == 0 {
                        Button(action: { showingNewEntry = true }) {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(Theme.Colors.accent)
                        }
                    }
                }
            }
        }
        .onAppear {
            loadJournalEntries()
        }
        .sheet(isPresented: $showingNewEntry) {
            JournalEntrySheet(onSave: { entry in
                saveJournalEntry(entry)
            })
        }
        .sheet(item: $selectedEntry) { entry in
            JournalEntrySheet(
                existingEntry: entry,
                onSave: { updatedEntry in
                    saveJournalEntry(updatedEntry)
                }
            )
        }
    }

    // MARK: - Segment Control
    private var segmentControl: some View {
        HStack(spacing: 0) {
            ForEach(["Journal", "Achievements"], id: \.self) { segment in
                let index = segment == "Journal" ? 0 : 1

                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSegment = index
                    }
                }) {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(segment)
                            .font(Theme.Fonts.headline())
                            .foregroundColor(selectedSegment == index ? Theme.Colors.accent : Theme.Colors.textSecondary)

                        Rectangle()
                            .fill(selectedSegment == index ? Theme.Colors.accent : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Journal List View
    private var journalListView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.md) {
                // Today's Entry Prompt
                if !hasEntryForToday {
                    todayPromptCard
                }

                // Streak Card
                streakCard

                // Journal Entries
                ForEach(journalEntries) { entry in
                    JournalEntryCard(entry: entry)
                        .onTapGesture {
                            selectedEntry = entry
                        }
                }

                if journalEntries.isEmpty {
                    emptyJournalView
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    // MARK: - Today's Prompt Card
    private var todayPromptCard: some View {
        Button(action: { showingNewEntry = true }) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "sun.max.fill")
                    .font(.title)
                    .foregroundColor(Theme.Colors.studyLearning)

                VStack(alignment: .leading, spacing: 4) {
                    Text("How was your day?")
                        .font(Theme.Fonts.headline())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("Tap to write today's journal entry")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.textTertiary)
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: Theme.Spacing.lg) {
            VStack(spacing: 4) {
                Text("\(authService.currentUser?.stats.currentJournalStreak ?? 0)")
                    .font(Theme.Fonts.title())
                    .foregroundColor(Theme.Colors.accent)

                Text("Current Streak")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(authService.currentUser?.stats.longestJournalStreak ?? 0)")
                    .font(Theme.Fonts.title())
                    .foregroundColor(Theme.Colors.studyLearning)

                Text("Longest Streak")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textSecondary)
            }

            Divider()
                .frame(height: 40)

            VStack(spacing: 4) {
                Text("\(authService.currentUser?.stats.totalJournalEntries ?? 0)")
                    .font(Theme.Fonts.title())
                    .foregroundColor(Theme.Colors.fitnessHealth)

                Text("Total Entries")
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }

    // MARK: - Achievements View
    private var achievementsView: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.lg) {
                // Progress Overview
                achievementProgressOverview

                // Achievement Categories
                ForEach(AchievementType.allCases, id: \.self) { type in
                    achievementSection(for: type)
                }
            }
            .padding(Theme.Spacing.lg)
        }
    }

    // MARK: - Achievement Progress Overview
    private var achievementProgressOverview: some View {
        let unlockedCount = authService.currentUser?.stats.achievementsUnlocked.count ?? 0
        let totalCount = AchievementDefinitions.all.count

        return VStack(spacing: Theme.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Achievements")
                        .font(Theme.Fonts.title2())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text("\(unlockedCount) of \(totalCount) unlocked")
                        .font(Theme.Fonts.subheadline())
                        .foregroundColor(Theme.Colors.textSecondary)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Theme.Colors.textTertiary, lineWidth: 4)
                        .frame(width: 60, height: 60)

                    Circle()
                        .trim(from: 0, to: CGFloat(unlockedCount) / CGFloat(totalCount))
                        .stroke(Theme.Colors.accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(Double(unlockedCount) / Double(totalCount) * 100))%")
                        .font(Theme.Fonts.caption())
                        .fontWeight(.bold)
                        .foregroundColor(Theme.Colors.textPrimary)
                }
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Achievement Section
    private func achievementSection(for type: AchievementType) -> some View {
        let achievements = AchievementDefinitions.achievements(for: type)

        return VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(achievementSectionTitle(for: type))
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(achievements, id: \.id) { achievement in
                    AchievementRow(
                        achievement: achievement,
                        isUnlocked: authService.currentUser?.stats.achievementsUnlocked.contains(achievement.id) ?? false,
                        currentProgress: getProgress(for: achievement)
                    )
                }
            }
        }
    }

    private func achievementSectionTitle(for type: AchievementType) -> String {
        switch type {
        case .journalStreak: return "Journal Streaks"
        case .manualEvents: return "Event Creation"
        case .completedTasks: return "Task Completion"
        case .appUsageStreak: return "App Usage"
        case .weeklyReviews: return "Weekly Reviews"
        }
    }

    private func getProgress(for achievement: Achievement) -> Int {
        guard let stats = authService.currentUser?.stats else { return 0 }

        switch achievement.requirement.type {
        case .journalStreak:
            return stats.currentJournalStreak
        case .manualEvents:
            return stats.totalManualEvents
        case .completedTasks:
            return stats.totalAIEventsCompleted
        case .appUsageStreak:
            return stats.currentJournalStreak // Simplified
        case .weeklyReviews:
            return 0 // Would need separate tracking
        }
    }

    // MARK: - Empty Journal View
    private var emptyJournalView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(Theme.Colors.textTertiary)

            Text("No journal entries yet")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textSecondary)

            Text("Start documenting your journey by writing your first entry")
                .font(Theme.Fonts.subheadline())
                .foregroundColor(Theme.Colors.textTertiary)
                .multilineTextAlignment(.center)

            Button("Write First Entry") {
                showingNewEntry = true
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(Theme.Spacing.xxl)
    }

    // MARK: - Computed Properties
    private var hasEntryForToday: Bool {
        let calendar = Calendar.current
        return journalEntries.contains { entry in
            calendar.isDate(entry.date, inSameDayAs: Date())
        }
    }

    // MARK: - Methods
    private func loadJournalEntries() {
        guard let userId = authService.currentUser?.id else { return }

        Task {
            journalEntries = try await firestoreService.fetchJournalEntries(userId: userId)
        }
    }

    private func saveJournalEntry(_ entry: JournalEntry) {
        Task {
            let savedEntry = try await firestoreService.saveJournalEntry(entry)

            if let index = journalEntries.firstIndex(where: { $0.id == savedEntry.id }) {
                journalEntries[index] = savedEntry
            } else {
                journalEntries.insert(savedEntry, at: 0)
            }
        }
    }
}

// MARK: - Journal Entry Card
struct JournalEntryCard: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text(entry.mood.emoji)
                    .font(.title2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.formattedDate)
                        .font(Theme.Fonts.headline())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Text(entry.mood.displayName)
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Color(hex: entry.mood.colorHex))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(Theme.Colors.textTertiary)
            }

            if !entry.content.isEmpty {
                Text(entry.content)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textSecondary)
                    .lineLimit(3)
            }

            if !entry.tags.isEmpty {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(entry.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.accent)
                            .padding(.horizontal, Theme.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Theme.Colors.accent.opacity(0.2))
                            .cornerRadius(Theme.CornerRadius.small)
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

// MARK: - Achievement Row
struct AchievementRow: View {
    let achievement: Achievement
    let isUnlocked: Bool
    let currentProgress: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? achievement.tier.color.opacity(0.2) : Theme.Colors.tertiaryBackground)
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? achievement.tier.color : Theme.Colors.textTertiary)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(achievement.title)
                        .font(Theme.Fonts.headline())
                        .foregroundColor(isUnlocked ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)

                    if isUnlocked {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(achievement.tier.color)
                    }
                }

                Text(achievement.description)
                    .font(Theme.Fonts.caption())
                    .foregroundColor(Theme.Colors.textTertiary)

                if !isUnlocked {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.Colors.tertiaryBackground)
                                .frame(height: 4)

                            RoundedRectangle(cornerRadius: 2)
                                .fill(Theme.Colors.accent)
                                .frame(width: geometry.size.width * CGFloat(currentProgress) / CGFloat(achievement.requirement.targetValue), height: 4)
                        }
                    }
                    .frame(height: 4)

                    Text("\(currentProgress)/\(achievement.requirement.targetValue)")
                        .font(Theme.Fonts.caption2())
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            }

            Spacer()

            // Tier badge
            Text(achievement.tier.displayName)
                .font(Theme.Fonts.caption2())
                .foregroundColor(achievement.tier.color)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 2)
                .background(achievement.tier.color.opacity(0.2))
                .cornerRadius(Theme.CornerRadius.small)
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
        .opacity(isUnlocked ? 1 : 0.7)
    }
}

// MARK: - Achievement Type Extension
extension AchievementType: CaseIterable {
    static var allCases: [AchievementType] {
        [.journalStreak, .manualEvents, .completedTasks, .appUsageStreak, .weeklyReviews]
    }
}

#Preview {
    JournalTab()
        .environmentObject(AuthService())
        .environmentObject(ThemeManager())
}
