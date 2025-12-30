import SwiftUI

/// View for selecting and creating blocks from templates
struct TemplatePickerView: View {
    @ObservedObject var dataService: DataService
    let selectedDate: Date
    let onTemplateSelected: (BlockTemplate) -> Void
    let onDismiss: () -> Void

    @State private var showCreateTemplate = false
    @Environment(\.appColorScheme) private var colorScheme

    var user: User? { dataService.currentUser }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Favorites Section
                    if let favorites = user?.favoriteTemplates, !favorites.isEmpty {
                        TemplateSectionView(
                            title: "FAVORITES",
                            icon: "star.fill",
                            templates: favorites,
                            onSelect: selectTemplate,
                            onToggleFavorite: toggleFavorite,
                            onDelete: deleteTemplate
                        )
                    }

                    // Recent Section
                    if let recent = user?.recentTemplates, !recent.isEmpty {
                        TemplateSectionView(
                            title: "RECENT",
                            icon: "clock.fill",
                            templates: recent,
                            onSelect: selectTemplate,
                            onToggleFavorite: toggleFavorite,
                            onDelete: deleteTemplate
                        )
                    }

                    // All Templates
                    if let allTemplates = user?.blockTemplates, !allTemplates.isEmpty {
                        TemplateSectionView(
                            title: "ALL TEMPLATES",
                            icon: "square.grid.2x2.fill",
                            templates: allTemplates.sorted { $0.timesUsed > $1.timesUsed },
                            onSelect: selectTemplate,
                            onToggleFavorite: toggleFavorite,
                            onDelete: deleteTemplate
                        )
                    }

                    // Suggested Templates
                    if user?.blockTemplates.isEmpty ?? true {
                        suggestedTemplatesSection
                    }

                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(AppTheme.background(colorScheme))
            .navigationTitle("Add from Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onDismiss() }
                        .foregroundColor(AppTheme.accent)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateTemplate = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(AppTheme.accent)
                    }
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                CreateTemplateSheet(
                    dataService: dataService,
                    onSave: { template in
                        showCreateTemplate = false
                        selectTemplate(template)
                    },
                    onCancel: { showCreateTemplate = false }
                )
            }
        }
    }

    private var suggestedTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                Text("SUGGESTED TEMPLATES")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .tracking(1)
            }

            Text("Start with one of these popular templates")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppTheme.secondaryText(colorScheme))

            ForEach(BlockTemplate.defaultTemplates, id: \.title) { suggestion in
                Button {
                    createFromSuggestion(suggestion)
                } label: {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(blockTypeFromIndex(suggestion.type).color.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Image(systemName: blockTypeFromIndex(suggestion.type).icon)
                                    .foregroundColor(blockTypeFromIndex(suggestion.type).color)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.title)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppTheme.primaryText(colorScheme))

                            HStack(spacing: 8) {
                                Text(suggestion.category)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.secondaryText(colorScheme))

                                Text("•")
                                    .foregroundColor(AppTheme.tertiaryText(colorScheme))

                                Text("\(suggestion.duration) min")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                            }
                        }

                        Spacer()

                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.accent)
                    }
                    .padding(12)
                    .background(AppTheme.cardBackground(colorScheme))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func blockTypeFromIndex(_ type: BlockType) -> BlockType {
        return type
    }

    private func selectTemplate(_ template: BlockTemplate) {
        onTemplateSelected(template)
    }

    private func toggleFavorite(_ template: BlockTemplate) {
        dataService.toggleTemplateFavorite(template)
    }

    private func deleteTemplate(_ template: BlockTemplate) {
        dataService.deleteTemplate(template)
    }

    private func createFromSuggestion(_ suggestion: (title: String, intent: String, type: BlockType, duration: Int, category: String)) {
        let template = dataService.createTemplate(
            title: suggestion.title,
            intentShort: suggestion.intent,
            blockType: suggestion.type,
            durationMinutes: suggestion.duration
        )
        template.category = suggestion.category
        selectTemplate(template)
    }
}

/// Section of templates
struct TemplateSectionView: View {
    let title: String
    let icon: String
    let templates: [BlockTemplate]
    let onSelect: (BlockTemplate) -> Void
    let onToggleFavorite: (BlockTemplate) -> Void
    let onDelete: (BlockTemplate) -> Void

    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.accent)
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppTheme.secondaryText(colorScheme))
                    .tracking(1)
            }

            ForEach(templates, id: \.id) { template in
                TemplateRowView(
                    template: template,
                    onSelect: { onSelect(template) },
                    onToggleFavorite: { onToggleFavorite(template) },
                    onDelete: { onDelete(template) }
                )
            }
        }
    }
}

/// Individual template row
struct TemplateRowView: View {
    let template: BlockTemplate
    let onSelect: () -> Void
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void

    @Environment(\.appColorScheme) private var colorScheme
    @State private var showActions = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Type indicator
                Circle()
                    .fill(template.blockType.color.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Image(systemName: template.blockType.icon)
                            .foregroundColor(template.blockType.color)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(template.title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.primaryText(colorScheme))

                        if template.isRecurring {
                            Image(systemName: "repeat")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.accent)
                        }
                    }

                    HStack(spacing: 8) {
                        Text("\(template.durationMinutes) min")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))

                        if let time = template.displayTime {
                            Text("•")
                                .foregroundColor(AppTheme.tertiaryText(colorScheme))
                            Text(time)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.secondaryText(colorScheme))
                        }

                        if template.timesUsed > 0 {
                            Text("•")
                                .foregroundColor(AppTheme.tertiaryText(colorScheme))
                            Text("Used \(template.timesUsed)x")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.tertiaryText(colorScheme))
                        }
                    }
                }

                Spacer()

                // Favorite button
                Button {
                    Haptics.tap()
                    onToggleFavorite()
                } label: {
                    Image(systemName: template.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 16))
                        .foregroundColor(template.isFavorite ? AppTheme.warning : AppTheme.tertiaryText(colorScheme))
                }
                .buttonStyle(.plain)

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.tertiaryText(colorScheme))
            }
            .padding(12)
            .background(AppTheme.cardBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                onToggleFavorite()
            } label: {
                Label(
                    template.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: template.isFavorite ? "star.slash" : "star"
                )
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Template", systemImage: "trash")
            }
        }
    }
}

/// Sheet for creating a new template
struct CreateTemplateSheet: View {
    @ObservedObject var dataService: DataService
    let onSave: (BlockTemplate) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var intentShort = ""
    @State private var blockType: BlockType = .focus
    @State private var durationMinutes = 45
    @State private var location = ""
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var recurrencePattern: RecurrencePattern = .daily
    @State private var selectedDays: Set<Int> = []
    @State private var preferredHour = 9
    @State private var preferredMinute = 0

    @Environment(\.appColorScheme) private var colorScheme

    var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Template Name", text: $title)
                    TextField("Intent (what's the purpose?)", text: $intentShort)
                }

                Section("Type & Duration") {
                    Picker("Block Type", selection: $blockType) {
                        ForEach(BlockType.allCases, id: \.self) { type in
                            Label(type.displayName, systemImage: type.icon)
                                .tag(type)
                        }
                    }

                    Stepper("\(durationMinutes) minutes", value: $durationMinutes, in: 5...180, step: 5)
                }

                Section("Time Preference") {
                    DatePicker(
                        "Preferred Time",
                        selection: Binding(
                            get: {
                                var components = DateComponents()
                                components.hour = preferredHour
                                components.minute = preferredMinute
                                return Calendar.current.date(from: components) ?? Date()
                            },
                            set: { date in
                                preferredHour = Calendar.current.component(.hour, from: date)
                                preferredMinute = Calendar.current.component(.minute, from: date)
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                }

                Section("Recurrence") {
                    Toggle("Recurring Block", isOn: $isRecurring)

                    if isRecurring {
                        Picker("Pattern", selection: $recurrencePattern) {
                            ForEach(RecurrencePattern.allCases, id: \.self) { pattern in
                                Text(pattern.displayName).tag(pattern)
                            }
                        }

                        if recurrencePattern == .weekly {
                            WeekdayPicker(selectedDays: $selectedDays)
                        }
                    }
                }

                Section("Optional Details") {
                    TextField("Location", text: $location)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { onCancel() }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveTemplate() }
                        .disabled(!isValid)
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveTemplate() {
        let template = dataService.createTemplate(
            title: title.trimmingCharacters(in: .whitespaces),
            intentShort: intentShort.trimmingCharacters(in: .whitespaces),
            blockType: blockType,
            durationMinutes: durationMinutes,
            location: location.isEmpty ? nil : location,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: isRecurring,
            recurrencePattern: isRecurring ? recurrencePattern : nil,
            recurrenceDays: recurrencePattern == .weekly ? Array(selectedDays) : nil,
            preferredTimeHour: preferredHour,
            preferredTimeMinute: preferredMinute
        )
        onSave(template)
    }
}

/// Weekday picker for recurring blocks
struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Int>
    @Environment(\.appColorScheme) private var colorScheme

    let weekdays = Calendar.current.shortWeekdaySymbols

    var body: some View {
        HStack(spacing: 8) {
            ForEach(1...7, id: \.self) { day in
                let index = day - 1
                Button {
                    if selectedDays.contains(day) {
                        selectedDays.remove(day)
                    } else {
                        selectedDays.insert(day)
                    }
                } label: {
                    Text(String(weekdays[index].prefix(1)))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(
                            selectedDays.contains(day)
                                ? .white
                                : AppTheme.secondaryText(colorScheme)
                        )
                        .frame(width: 32, height: 32)
                        .background(
                            selectedDays.contains(day)
                                ? AppTheme.accent
                                : AppTheme.secondaryBackground(colorScheme)
                        )
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    TemplatePickerView(
        dataService: DataService.shared,
        selectedDate: Date(),
        onTemplateSelected: { _ in },
        onDismiss: {}
    )
    .themed()
}
