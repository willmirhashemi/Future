import SwiftUI

struct JournalEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    let existingEntry: JournalEntry?
    let onSave: (JournalEntry) -> Void

    @State private var content = ""
    @State private var mood: Mood = .neutral
    @State private var accomplishments: [String] = []
    @State private var newAccomplishment = ""
    @State private var gratitude: [String] = []
    @State private var newGratitude = ""
    @State private var tags: [String] = []
    @State private var newTag = ""
    @State private var useGuidedPrompts = false

    // Guided prompt responses
    @State private var whatAccomplished = ""
    @State private var whatLearned = ""
    @State private var challengesFaced = ""
    @State private var tomorrowGoals = ""
    @State private var gratefulFor = ""
    @State private var overallThoughts = ""

    init(existingEntry: JournalEntry? = nil, onSave: @escaping (JournalEntry) -> Void) {
        self.existingEntry = existingEntry
        self.onSave = onSave

        if let entry = existingEntry {
            _content = State(initialValue: entry.content)
            _mood = State(initialValue: entry.mood)
            _accomplishments = State(initialValue: entry.accomplishments)
            _gratitude = State(initialValue: entry.gratitude)
            _tags = State(initialValue: entry.tags)

            if let guided = entry.guidedResponses {
                _useGuidedPrompts = State(initialValue: true)
                _whatAccomplished = State(initialValue: guided.whatAccomplished ?? "")
                _whatLearned = State(initialValue: guided.whatLearned ?? "")
                _challengesFaced = State(initialValue: guided.challengesFaced ?? "")
                _tomorrowGoals = State(initialValue: guided.tomorrowGoals ?? "")
                _gratefulFor = State(initialValue: guided.gratefulFor ?? "")
                _overallThoughts = State(initialValue: guided.overallThoughts ?? "")
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Date Header
                        dateHeader

                        // Mood Selector
                        moodSection

                        // Journal Format Toggle
                        formatToggle

                        // Content Section
                        if useGuidedPrompts {
                            guidedPromptsSection
                        } else {
                            freeFormSection
                        }

                        // Accomplishments
                        accomplishmentsSection

                        // Gratitude
                        gratitudeSection

                        // Tags
                        tagsSection
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle(existingEntry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveEntry()
                    }
                    .foregroundColor(Theme.Colors.accent)
                }
            }
        }
    }

    // MARK: - Date Header
    private var dateHeader: some View {
        HStack {
            Image(systemName: "calendar")
                .foregroundColor(Theme.Colors.accent)

            Text(formattedDate)
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            Spacer()
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: existingEntry?.date ?? Date())
    }

    // MARK: - Mood Section
    private var moodSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("How are you feeling?")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            MoodSelector(selectedMood: $mood)
        }
    }

    // MARK: - Format Toggle
    private var formatToggle: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Journal Format")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.md) {
                FormatButton(
                    title: "Free Form",
                    icon: "text.alignleft",
                    isSelected: !useGuidedPrompts
                ) {
                    useGuidedPrompts = false
                }

                FormatButton(
                    title: "Guided Prompts",
                    icon: "list.bullet.clipboard",
                    isSelected: useGuidedPrompts
                ) {
                    useGuidedPrompts = true
                }
            }
        }
    }

    // MARK: - Free Form Section
    private var freeFormSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("What's on your mind?")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            TextEditor(text: $content)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(minHeight: 200)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Guided Prompts Section
    private var guidedPromptsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            GuidedPromptField(
                prompt: "What did you accomplish today?",
                text: $whatAccomplished
            )

            GuidedPromptField(
                prompt: "What did you learn?",
                text: $whatLearned
            )

            GuidedPromptField(
                prompt: "What challenges did you face?",
                text: $challengesFaced
            )

            GuidedPromptField(
                prompt: "What are your goals for tomorrow?",
                text: $tomorrowGoals
            )

            GuidedPromptField(
                prompt: "What are you grateful for?",
                text: $gratefulFor
            )

            GuidedPromptField(
                prompt: "Any other thoughts?",
                text: $overallThoughts
            )
        }
    }

    // MARK: - Accomplishments Section
    private var accomplishmentsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Today's Wins")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            // Existing accomplishments
            ForEach(accomplishments, id: \.self) { item in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Theme.Colors.success)

                    Text(item)
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Button(action: { accomplishments.removeAll { $0 == item } }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.small)
            }

            // Add new
            HStack {
                TextField("Add an accomplishment...", text: $newAccomplishment)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)

                Button(action: addAccomplishment) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.Colors.accent)
                }
                .disabled(newAccomplishment.isEmpty)
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.small)
        }
    }

    // MARK: - Gratitude Section
    private var gratitudeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Gratitude")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            // Existing items
            ForEach(gratitude, id: \.self) { item in
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(Theme.Colors.accent)

                    Text(item)
                        .font(Theme.Fonts.body())
                        .foregroundColor(Theme.Colors.textPrimary)

                    Spacer()

                    Button(action: { gratitude.removeAll { $0 == item } }) {
                        Image(systemName: "xmark.circle")
                            .foregroundColor(Theme.Colors.textTertiary)
                    }
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.small)
            }

            // Add new
            HStack {
                TextField("I'm grateful for...", text: $newGratitude)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)

                Button(action: addGratitude) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.Colors.accent)
                }
                .disabled(newGratitude.isEmpty)
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.small)
        }
    }

    // MARK: - Tags Section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Tags")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            // Existing tags
            FlowLayout(spacing: Theme.Spacing.xs) {
                ForEach(tags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text("#\(tag)")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.accent)

                        Button(action: { tags.removeAll { $0 == tag } }) {
                            Image(systemName: "xmark")
                                .font(.caption2)
                                .foregroundColor(Theme.Colors.textTertiary)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(Theme.Colors.accent.opacity(0.2))
                    .cornerRadius(Theme.CornerRadius.small)
                }
            }

            // Add new tag
            HStack {
                TextField("Add tag...", text: $newTag)
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
                    .autocapitalization(.none)

                Button(action: addTag) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Theme.Colors.accent)
                }
                .disabled(newTag.isEmpty)
            }
            .padding(Theme.Spacing.sm)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.small)
        }
    }

    // MARK: - Actions
    private func addAccomplishment() {
        guard !newAccomplishment.isEmpty else { return }
        accomplishments.append(newAccomplishment)
        newAccomplishment = ""
    }

    private func addGratitude() {
        guard !newGratitude.isEmpty else { return }
        gratitude.append(newGratitude)
        newGratitude = ""
    }

    private func addTag() {
        guard !newTag.isEmpty else { return }
        tags.append(newTag.lowercased())
        newTag = ""
    }

    private func saveEntry() {
        guard let userId = authService.currentUser?.id else { return }

        var guidedResponses: GuidedResponses? = nil
        if useGuidedPrompts {
            guidedResponses = GuidedResponses(
                whatAccomplished: whatAccomplished.isEmpty ? nil : whatAccomplished,
                whatLearned: whatLearned.isEmpty ? nil : whatLearned,
                challengesFaced: challengesFaced.isEmpty ? nil : challengesFaced,
                tomorrowGoals: tomorrowGoals.isEmpty ? nil : tomorrowGoals,
                gratefulFor: gratefulFor.isEmpty ? nil : gratefulFor,
                overallThoughts: overallThoughts.isEmpty ? nil : overallThoughts
            )
        }

        let entry = JournalEntry(
            id: existingEntry?.id,
            userId: userId,
            date: existingEntry?.date ?? Date(),
            content: useGuidedPrompts ? combineGuidedResponses() : content,
            mood: mood,
            guidedResponses: guidedResponses,
            accomplishments: accomplishments,
            gratitude: gratitude,
            tags: tags,
            createdAt: existingEntry?.createdAt ?? Date(),
            updatedAt: Date()
        )

        onSave(entry)
        dismiss()
    }

    private func combineGuidedResponses() -> String {
        var parts: [String] = []

        if !whatAccomplished.isEmpty {
            parts.append("Accomplished: \(whatAccomplished)")
        }
        if !whatLearned.isEmpty {
            parts.append("Learned: \(whatLearned)")
        }
        if !challengesFaced.isEmpty {
            parts.append("Challenges: \(challengesFaced)")
        }
        if !tomorrowGoals.isEmpty {
            parts.append("Tomorrow: \(tomorrowGoals)")
        }
        if !gratefulFor.isEmpty {
            parts.append("Grateful for: \(gratefulFor)")
        }
        if !overallThoughts.isEmpty {
            parts.append(overallThoughts)
        }

        return parts.joined(separator: "\n\n")
    }
}

// MARK: - Mood Selector
struct MoodSelector: View {
    @Binding var selectedMood: Mood

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            ForEach(Mood.allCases, id: \.self) { mood in
                MoodButton(
                    mood: mood,
                    isSelected: selectedMood == mood
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedMood = mood
                    }
                }
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.cardBackground)
        .cornerRadius(Theme.CornerRadius.medium)
    }
}

struct MoodButton: View {
    let mood: Mood
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                Text(mood.emoji)
                    .font(.system(size: isSelected ? 32 : 24))

                Text(mood.displayName)
                    .font(Theme.Fonts.caption2())
                    .foregroundColor(isSelected ? Color(hex: mood.colorHex) : Theme.Colors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? Color(hex: mood.colorHex).opacity(0.2) : Color.clear)
            .cornerRadius(Theme.CornerRadius.small)
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
    }
}

// MARK: - Format Button
struct FormatButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: icon)
                Text(title)
            }
            .font(Theme.Fonts.subheadline())
            .foregroundColor(isSelected ? Theme.Colors.accent : Theme.Colors.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(Theme.Spacing.md)
            .background(isSelected ? Theme.Colors.accent.opacity(0.2) : Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.CornerRadius.medium)
                    .stroke(isSelected ? Theme.Colors.accent : Color.clear, lineWidth: 1)
            )
        }
    }
}

// MARK: - Guided Prompt Field
struct GuidedPromptField: View {
    let prompt: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(prompt)
                .font(Theme.Fonts.subheadline())
                .foregroundColor(Theme.Colors.textSecondary)

            TextEditor(text: $text)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(minHeight: 60)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
        }
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                maxHeight = max(maxHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}

#Preview {
    JournalEntrySheet(onSave: { _ in })
        .environmentObject(AuthService())
}
