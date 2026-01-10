import SwiftUI

struct AddEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authService: AuthService

    let selectedDate: Date
    let onSave: (Event) -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var eventType: EventType = .task
    @State private var selectedColor = "4ECDC4"
    @State private var isAllDay = false
    @State private var reminderEnabled = false
    @State private var reminderMinutes = 15

    private let colors = [
        "4ECDC4", "FF6B6B", "4D96FF", "6BCB77", "FFD93D",
        "9B59B6", "FF8C42", "A8E6CF", "FF6B9D", "45B7D1"
    ]

    init(selectedDate: Date, onSave: @escaping (Event) -> Void) {
        self.selectedDate = selectedDate
        self.onSave = onSave

        // Default start time to next hour
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: Date())
        var components = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        components.hour = currentHour + 1
        components.minute = 0
        let defaultStart = calendar.date(from: components) ?? selectedDate

        _startTime = State(initialValue: defaultStart)
        _endTime = State(initialValue: defaultStart.addingTimeInterval(3600))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Title
                        titleSection

                        // Description
                        descriptionSection

                        // Time
                        timeSection

                        // Event Type
                        eventTypeSection

                        // Color
                        colorSection

                        // Reminder
                        reminderSection
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationTitle("New Event")
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
                        saveEvent()
                    }
                    .foregroundColor(Theme.Colors.accent)
                    .disabled(title.isEmpty)
                }
            }
        }
    }

    // MARK: - Title Section
    private var titleSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Title")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            TextField("Event title", text: $title)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Description (optional)")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            TextEditor(text: $description)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)
                .frame(minHeight: 80)
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Time")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            // All day toggle
            Toggle(isOn: $isAllDay) {
                Text("All Day")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .tint(Theme.Colors.accent)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)

            if !isAllDay {
                VStack(spacing: Theme.Spacing.md) {
                    HStack {
                        Text("Start")
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textSecondary)
                            .frame(width: 50, alignment: .leading)

                        DatePicker("", selection: $startTime)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }

                    HStack {
                        Text("End")
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textSecondary)
                            .frame(width: 50, alignment: .leading)

                        DatePicker("", selection: $endTime)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
            }
        }
    }

    // MARK: - Event Type Section
    private var eventTypeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Event Type")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Theme.Spacing.sm) {
                    ForEach(EventType.allCases, id: \.self) { type in
                        EventTypeChip(
                            type: type,
                            isSelected: eventType == type
                        ) {
                            eventType = type
                            selectedColor = type.defaultColor
                        }
                    }
                }
            }
        }
    }

    // MARK: - Color Section
    private var colorSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Color")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(colors, id: \.self) { color in
                    ColorCircle(
                        color: color,
                        isSelected: selectedColor == color
                    ) {
                        selectedColor = color
                    }
                }
            }
        }
    }

    // MARK: - Reminder Section
    private var reminderSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Reminder")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            Toggle(isOn: $reminderEnabled) {
                Text("Enable Reminder")
                    .font(Theme.Fonts.body())
                    .foregroundColor(Theme.Colors.textPrimary)
            }
            .tint(Theme.Colors.accent)
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)

            if reminderEnabled {
                Picker("Remind me", selection: $reminderMinutes) {
                    Text("5 minutes before").tag(5)
                    Text("15 minutes before").tag(15)
                    Text("30 minutes before").tag(30)
                    Text("1 hour before").tag(60)
                    Text("1 day before").tag(1440)
                }
                .pickerStyle(.menu)
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
            }
        }
    }

    // MARK: - Save Event
    private func saveEvent() {
        guard let userId = authService.currentUser?.id else { return }

        let calendar = Calendar.current
        var finalStartTime = startTime
        var finalEndTime = endTime

        if isAllDay {
            finalStartTime = calendar.startOfDay(for: selectedDate)
            finalEndTime = calendar.date(byAdding: .day, value: 1, to: finalStartTime)!
        }

        let event = Event(
            userId: userId,
            title: title,
            description: description.isEmpty ? nil : description,
            startTime: finalStartTime,
            endTime: finalEndTime,
            isAllDay: isAllDay,
            eventType: eventType,
            isAIGenerated: false,
            color: selectedColor,
            reminder: reminderEnabled ? EventReminder(minutesBefore: reminderMinutes) : nil
        )

        onSave(event)
        dismiss()
    }
}

// MARK: - Event Type Chip
struct EventTypeChip: View {
    let type: EventType
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: type.icon)
                    .font(.caption)

                Text(type.displayName)
                    .font(Theme.Fonts.caption())
            }
            .foregroundColor(isSelected ? .white : Theme.Colors.textSecondary)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, Theme.Spacing.xs)
            .background(isSelected ? Color(hex: type.defaultColor) : Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.small)
        }
    }
}

// MARK: - Color Circle
struct ColorCircle: View {
    let color: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 32, height: 32)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                )
                .overlay(
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .opacity(isSelected ? 1 : 0)
                )
        }
    }
}

#Preview {
    AddEventSheet(selectedDate: Date()) { _ in }
        .environmentObject(AuthService())
}
