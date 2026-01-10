import SwiftUI

struct EventDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let event: Event
    let onUpdate: (Event) -> Void

    @State private var editedStartTime: Date
    @State private var editedEndTime: Date
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    init(event: Event, onUpdate: @escaping (Event) -> Void) {
        self.event = event
        self.onUpdate = onUpdate
        _editedStartTime = State(initialValue: event.startTime)
        _editedEndTime = State(initialValue: event.endTime)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        // Event Header
                        eventHeader

                        Divider()
                            .background(Theme.Colors.textTertiary)

                        // Time Section
                        timeSection

                        // Description
                        if let description = event.description, !description.isEmpty {
                            descriptionSection(description)
                        }

                        // Event Info
                        eventInfoSection

                        // Actions
                        if !event.isAIGenerated {
                            actionButtons
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Theme.Colors.textSecondary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        Button("Save") {
                            saveChanges()
                        }
                        .foregroundColor(Theme.Colors.accent)
                    } else {
                        Button("Edit Time") {
                            isEditing = true
                        }
                        .foregroundColor(Theme.Colors.accent)
                    }
                }
            }
        }
        .alert("Delete Event", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // Delete handled by parent
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete this event?")
        }
    }

    // MARK: - Event Header
    private var eventHeader: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(event.displayColor)
                .frame(width: 8)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(event.title)
                    .font(Theme.Fonts.title2())
                    .foregroundColor(Theme.Colors.textPrimary)

                HStack(spacing: Theme.Spacing.sm) {
                    // Event type badge
                    HStack(spacing: 4) {
                        Image(systemName: event.eventType.icon)
                            .font(.caption)
                        Text(event.eventType.displayName)
                            .font(Theme.Fonts.caption())
                    }
                    .foregroundColor(event.displayColor)
                    .padding(.horizontal, Theme.Spacing.sm)
                    .padding(.vertical, Theme.Spacing.xxs)
                    .background(event.displayColor.opacity(0.2))
                    .cornerRadius(Theme.CornerRadius.small)

                    // AI badge
                    if event.isAIGenerated {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                                .font(.caption)
                            Text("AI Generated")
                                .font(Theme.Fonts.caption())
                        }
                        .foregroundColor(Theme.Colors.aiEvent)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xxs)
                        .background(Theme.Colors.aiEvent.opacity(0.2))
                        .cornerRadius(Theme.CornerRadius.small)
                    }
                }
            }

            Spacer()
        }
    }

    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Time")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            if isEditing {
                // Editable time pickers
                VStack(spacing: Theme.Spacing.md) {
                    HStack {
                        Text("Start")
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textSecondary)
                            .frame(width: 60, alignment: .leading)

                        DatePicker("", selection: $editedStartTime)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }

                    HStack {
                        Text("End")
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textSecondary)
                            .frame(width: 60, alignment: .leading)

                        DatePicker("", selection: $editedEndTime)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)

                if event.isAIGenerated {
                    Text("Note: AI-generated events can only have their times adjusted.")
                        .font(Theme.Fonts.caption())
                        .foregroundColor(Theme.Colors.textTertiary)
                }
            } else {
                // Display time
                HStack(spacing: Theme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Start")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.textSecondary)

                        Text(formattedDateTime(event.startTime))
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textPrimary)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(Theme.Colors.textTertiary)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("End")
                            .font(Theme.Fonts.caption())
                            .foregroundColor(Theme.Colors.textSecondary)

                        Text(formattedDateTime(event.endTime))
                            .font(Theme.Fonts.body())
                            .foregroundColor(Theme.Colors.textPrimary)
                    }

                    Spacer()
                }
                .padding(Theme.Spacing.md)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)

                // Duration
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(Theme.Colors.textSecondary)

                    Text("Duration: \(event.durationInMinutes) minutes")
                        .font(Theme.Fonts.subheadline())
                        .foregroundColor(Theme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - Description Section
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Description")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            Text(description)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(Theme.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.Colors.cardBackground)
                .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Event Info Section
    private var eventInfoSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Details")
                .font(Theme.Fonts.headline())
                .foregroundColor(Theme.Colors.textPrimary)

            VStack(spacing: Theme.Spacing.sm) {
                if let category = event.category {
                    InfoRow(icon: "folder", label: "Category", value: category.displayName)
                }

                InfoRow(
                    icon: event.isCompleted ? "checkmark.circle.fill" : "circle",
                    label: "Status",
                    value: event.isCompleted ? "Completed" : "Pending"
                )

                if let reminder = event.reminder, reminder.isEnabled {
                    InfoRow(icon: "bell", label: "Reminder", value: reminder.displayText)
                }

                InfoRow(icon: "calendar", label: "Created", value: formattedDate(event.createdAt))
            }
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.cardBackground)
            .cornerRadius(Theme.CornerRadius.medium)
        }
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: Theme.Spacing.md) {
            Button(action: { toggleComplete() }) {
                HStack {
                    Image(systemName: event.isCompleted ? "arrow.uturn.backward" : "checkmark")
                    Text(event.isCompleted ? "Mark as Incomplete" : "Mark as Complete")
                }
            }
            .buttonStyle(SecondaryButtonStyle())

            Button(action: { showDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Event")
                }
                .foregroundColor(Theme.Colors.error)
            }
            .buttonStyle(SecondaryButtonStyle())
        }
    }

    // MARK: - Helper Methods
    private func formattedDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func saveChanges() {
        var updatedEvent = event
        updatedEvent.startTime = editedStartTime
        updatedEvent.endTime = editedEndTime
        onUpdate(updatedEvent)
        isEditing = false
    }

    private func toggleComplete() {
        var updatedEvent = event
        updatedEvent.isCompleted.toggle()
        onUpdate(updatedEvent)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.Colors.textSecondary)
                .frame(width: 24)

            Text(label)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textSecondary)

            Spacer()

            Text(value)
                .font(Theme.Fonts.body())
                .foregroundColor(Theme.Colors.textPrimary)
        }
    }
}

#Preview {
    EventDetailSheet(
        event: Event(
            userId: "123",
            title: "Morning Study Session",
            description: "Review chapter 5 and complete practice problems",
            startTime: Date(),
            endTime: Date().addingTimeInterval(3600),
            eventType: .study,
            category: .studyLearning,
            isAIGenerated: true,
            color: "4D96FF"
        ),
        onUpdate: { _ in }
    )
}
