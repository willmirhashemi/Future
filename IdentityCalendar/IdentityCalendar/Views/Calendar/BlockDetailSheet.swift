import SwiftUI

/// Detail sheet for a block with actions
struct BlockDetailSheet: View {
    let block: PlanBlock
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onMove: (Date) -> Void
    let onReduce: () -> Void
    let onDismiss: () -> Void

    @State private var showMoveSheet = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            BlockTypeBadge(type: block.blockType)

                            if block.status != .scheduled {
                                BlockStatusBadge(status: block.status)
                            }
                        }

                        Text(block.title)
                            .font(.title2.weight(.bold))
                            .foregroundColor(.appPrimaryText)
                    }

                    // Intent
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Intent")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.appSecondaryText)

                        Text(block.intentShort)
                            .font(.body)
                            .foregroundColor(.appPrimaryText)
                    }

                    // Time info
                    HStack(spacing: 24) {
                        InfoItem(
                            icon: "calendar",
                            title: "Date",
                            value: block.startDateTime.mediumDateString
                        )

                        InfoItem(
                            icon: "clock",
                            title: "Time",
                            value: "\(block.startDateTime.shortTimeString) - \(block.endDateTime.shortTimeString)"
                        )

                        InfoItem(
                            icon: "hourglass",
                            title: "Duration",
                            value: block.duration.minutesString
                        )
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 12)
                    .background(Color.appSecondaryBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                    // Modification indicators
                    if block.wasMoved || block.wasReduced {
                        ModificationIndicators(block: block)
                    }

                    Spacer(minLength: 20)

                    // Actions
                    if block.status == .scheduled || block.status == .inProgress {
                        VStack(spacing: 12) {
                            if block.status == .inProgress || block.isActive {
                                // Primary: Complete
                                PrimaryButton(title: "Mark as Done", action: onComplete)

                                // Secondary actions
                                HStack(spacing: 12) {
                                    ActionButton(
                                        title: "Skip",
                                        icon: "forward.fill",
                                        style: .secondary,
                                        action: onSkip
                                    )

                                    ActionButton(
                                        title: "Reduce",
                                        icon: "minus.circle",
                                        style: .secondary,
                                        action: onReduce
                                    )
                                }
                            } else if block.isFuture {
                                // Future block actions
                                HStack(spacing: 12) {
                                    ActionButton(
                                        title: "Move",
                                        icon: "arrow.right.circle",
                                        style: .primary,
                                        action: { showMoveSheet = true }
                                    )

                                    ActionButton(
                                        title: "Skip",
                                        icon: "forward.fill",
                                        style: .secondary,
                                        action: onSkip
                                    )
                                }

                                ActionButton(
                                    title: "Reduce to \(reducedDuration)",
                                    icon: "minus.circle",
                                    style: .tertiary,
                                    action: onReduce
                                )
                            } else {
                                // Past but not addressed
                                HStack(spacing: 12) {
                                    ActionButton(
                                        title: "Done",
                                        icon: "checkmark.circle",
                                        style: .primary,
                                        action: onComplete
                                    )

                                    ActionButton(
                                        title: "Skip",
                                        icon: "forward.fill",
                                        style: .secondary,
                                        action: onSkip
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(Constants.Layout.screenPadding)
            }
            .background(Color.appBackground)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.medium)
                }
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveBlockSheet(
                    currentDate: block.startDateTime,
                    onMove: { date in
                        showMoveSheet = false
                        onMove(date)
                    },
                    onCancel: { showMoveSheet = false }
                )
                .presentationDetents([.medium])
            }
        }
    }

    private var reducedDuration: String {
        let newDuration = block.duration / 2
        return newDuration.minutesString
    }
}

/// Info item display
struct InfoItem: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
            }
            .foregroundColor(.appTertiaryText)

            Text(value)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.appPrimaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Shows if block was moved or reduced
struct ModificationIndicators: View {
    let block: PlanBlock

    var body: some View {
        HStack(spacing: 16) {
            if block.wasMoved {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.right.circle")
                    Text("Moved \(block.moveCount)x")
                }
                .font(.caption)
                .foregroundColor(.appSecondaryText)
            }

            if block.wasReduced {
                HStack(spacing: 4) {
                    Image(systemName: "minus.circle")
                    Text("Reduced")
                }
                .font(.caption)
                .foregroundColor(.appSecondaryText)
            }
        }
    }
}

/// Action button with style variants
struct ActionButton: View {
    let title: String
    let icon: String
    let style: ActionButtonStyle
    let action: () -> Void

    enum ActionButtonStyle {
        case primary, secondary, tertiary
    }

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.body.weight(.medium))
            }
            .foregroundColor(foregroundColor)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Layout.buttonHeight)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.scale)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary: return .white
        case .secondary: return .appAccent
        case .tertiary: return .appSecondaryText
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary: return .appAccent
        case .secondary: return .appAccent.opacity(0.1)
        case .tertiary: return .appSecondaryBackground
        }
    }
}

/// Sheet for moving a block to a new time
struct MoveBlockSheet: View {
    let currentDate: Date
    let onMove: (Date) -> Void
    let onCancel: () -> Void

    @State private var selectedDate: Date

    init(currentDate: Date, onMove: @escaping (Date) -> Void, onCancel: @escaping () -> Void) {
        self.currentDate = currentDate
        self.onMove = onMove
        self.onCancel = onCancel
        _selectedDate = State(initialValue: currentDate)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Move to a new time")
                    .font(.headline)
                    .foregroundColor(.appPrimaryText)

                DatePicker(
                    "New time",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(.appAccent)

                Spacer()

                PrimaryButton(title: "Move Block", action: {
                    onMove(selectedDate)
                })
            }
            .padding(Constants.Layout.screenPadding)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    BlockDetailSheet(
        block: PlanBlock(
            startDateTime: Date(),
            endDateTime: Date().addingTimeInterval(60 * 60),
            title: "Morning Workout",
            intentShort: "Build strength and start the day right",
            blockType: .focus
        ),
        onComplete: {},
        onSkip: {},
        onMove: { _ in },
        onReduce: {},
        onDismiss: {}
    )
}
