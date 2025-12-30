import SwiftUI

/// Beautiful, rich detail sheet for a block with WHOOP-inspired design
struct BlockDetailSheet: View {
    let block: PlanBlock
    let onComplete: () -> Void
    let onSkip: () -> Void
    let onMove: (Date) -> Void
    let onReduce: () -> Void
    let onDismiss: () -> Void
    let onEdit: ((PlanBlock) -> Void)?

    @State private var showMoveSheet = false
    @State private var showEditSheet = false
    @Environment(\.appColorScheme) private var colorScheme

    init(
        block: PlanBlock,
        onComplete: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onMove: @escaping (Date) -> Void,
        onReduce: @escaping () -> Void,
        onDismiss: @escaping () -> Void,
        onEdit: ((PlanBlock) -> Void)? = nil
    ) {
        self.block = block
        self.onComplete = onComplete
        self.onSkip = onSkip
        self.onMove = onMove
        self.onReduce = onReduce
        self.onDismiss = onDismiss
        self.onEdit = onEdit
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero Header
                    heroHeader
                        .padding(.bottom, 24)

                    // Main Content Sections
                    VStack(spacing: 16) {
                        // Time Card
                        timeCard

                        // Intent Section
                        if !block.intentShort.isEmpty {
                            intentSection
                        }

                        // Location Section
                        if let location = block.location, !location.isEmpty {
                            locationSection(location)
                        }

                        // Notes Section
                        if let notes = block.notes, !notes.isEmpty {
                            notesSection(notes)
                        }

                        // Links Section (Zoom, YouTube, Resources)
                        if hasLinks {
                            linksSection
                        }

                        // Tips Section
                        if let tips = block.tips, !tips.isEmpty {
                            tipsSection(tips)
                        }

                        // Energy & Priority Info
                        if block.energyLevel != nil || block.priority != nil {
                            metadataSection
                        }

                        // Modification History
                        if block.wasMoved || block.wasReduced {
                            modificationSection
                        }
                    }
                    .padding(.horizontal, 20)

                    Spacer(minLength: 32)

                    // Action Buttons
                    if block.status == .scheduled || block.status == .inProgress {
                        actionButtons
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                    }
                }
            }
            .background(AppTheme.background(colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if onEdit != nil {
                        Button(action: { showEditSheet = true }) {
                            Image(systemName: "pencil")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.accent)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.accent)
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

    // MARK: - Hero Header

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Status & Type Badges
            HStack(spacing: 8) {
                BlockTypeBadge(type: block.blockType)

                if block.status != .scheduled {
                    BlockStatusBadge(status: block.status)
                }

                if let priority = block.priority, priority == .high || priority == .critical {
                    priorityBadge(priority)
                }

                Spacer()

                if block.isActive {
                    activeBadge
                }
            }

            // Title
            Text(block.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .lineLimit(3)

            // Category tag
            if let category = block.category, !category.isEmpty {
                Text(category.uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppTheme.accent)
                    .tracking(1.2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [
                    block.blockType.color.opacity(0.15),
                    AppTheme.cardBackground(colorScheme)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }

    // MARK: - Time Card

    private var timeCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                // Date
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.accent)
                        Text("DATE")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .tracking(1)
                    }
                    Text(block.startDateTime.mediumDateString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Divider
                Rectangle()
                    .fill(AppTheme.separator(colorScheme))
                    .frame(width: 1, height: 40)

                // Time
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.accent)
                        Text("TIME")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .tracking(1)
                    }
                    Text("\(block.startDateTime.shortTimeString) - \(block.endDateTime.shortTimeString)")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)

                // Divider
                Rectangle()
                    .fill(AppTheme.separator(colorScheme))
                    .frame(width: 1, height: 40)

                // Duration
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppTheme.accent)
                        Text("DURATION")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.secondaryText(colorScheme))
                            .tracking(1)
                    }
                    Text(block.duration.minutesString)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.primaryText(colorScheme))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
            }
            .padding(16)
        }
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Intent Section

    private var intentSection: some View {
        DetailSection(title: "INTENT", icon: "sparkles") {
            Text(block.intentShort)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - Location Section

    private func locationSection(_ location: String) -> some View {
        DetailSection(title: "LOCATION", icon: "mappin.circle.fill") {
            HStack {
                Text(location)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Spacer()

                Button(action: {
                    // Open in Maps
                    if let url = URL(string: "maps://?q=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }

    // MARK: - Notes Section

    private func notesSection(_ notes: String) -> some View {
        DetailSection(title: "NOTES", icon: "note.text") {
            Text(notes)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppTheme.primaryText(colorScheme))
                .lineSpacing(4)
        }
    }

    // MARK: - Links Section

    private var hasLinks: Bool {
        (block.zoomLink != nil && !block.zoomLink!.isEmpty) ||
        (block.youtubeLink != nil && !block.youtubeLink!.isEmpty) ||
        (block.resourceLinks != nil && !block.resourceLinks!.isEmpty)
    }

    private var linksSection: some View {
        DetailSection(title: "RESOURCES", icon: "link.circle.fill") {
            VStack(spacing: 12) {
                // Zoom Link
                if let zoomLink = block.zoomLink, !zoomLink.isEmpty {
                    LinkRow(
                        icon: "video.fill",
                        iconColor: Color(hex: "2D8CFF"),
                        title: "Join Zoom Meeting",
                        url: zoomLink
                    )
                }

                // YouTube Link
                if let youtubeLink = block.youtubeLink, !youtubeLink.isEmpty {
                    LinkRow(
                        icon: "play.rectangle.fill",
                        iconColor: Color(hex: "FF0000"),
                        title: "Watch on YouTube",
                        url: youtubeLink
                    )
                }

                // Other Resources
                if let resources = block.resourceLinks {
                    ForEach(resources, id: \.self) { link in
                        LinkRow(
                            icon: "doc.fill",
                            iconColor: AppTheme.accent,
                            title: formatLinkTitle(link),
                            url: link
                        )
                    }
                }
            }
        }
    }

    // MARK: - Tips Section

    private func tipsSection(_ tips: [String]) -> some View {
        DetailSection(title: "TIPS", icon: "lightbulb.fill") {
            VStack(alignment: .leading, spacing: 10) {
                ForEach(tips.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: 10) {
                        Text("•")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.accent)
                        Text(tips[index])
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(AppTheme.primaryText(colorScheme))
                            .lineSpacing(3)
                    }
                }
            }
        }
    }

    // MARK: - Metadata Section

    private var metadataSection: some View {
        HStack(spacing: 12) {
            if let energy = block.energyLevel {
                MetadataChip(
                    icon: energy.icon,
                    text: energy.displayName,
                    color: energy.color
                )
            }

            if let priority = block.priority {
                MetadataChip(
                    icon: priority.icon,
                    text: "\(priority.displayName) Priority",
                    color: priority.color
                )
            }

            if let reminder = block.reminder {
                MetadataChip(
                    icon: "bell.fill",
                    text: "\(reminder) min before",
                    color: AppTheme.warning
                )
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }

    // MARK: - Modification Section

    private var modificationSection: some View {
        HStack(spacing: 16) {
            if block.wasMoved {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(AppTheme.warning)
                    Text("Moved \(block.moveCount)×")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
            }

            if block.wasReduced {
                HStack(spacing: 6) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(AppTheme.strain)
                    Text("Duration Reduced")
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.secondaryText(colorScheme))
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppTheme.secondaryBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if block.status == .inProgress || block.isActive {
                // Primary: Complete
                PrimaryActionButton(
                    title: "Mark as Complete",
                    icon: "checkmark.circle.fill",
                    action: {
                        Haptics.success()
                        onComplete()
                    }
                )

                // Secondary actions
                HStack(spacing: 12) {
                    SecondaryActionButton(
                        title: "Skip",
                        icon: "forward.fill",
                        action: {
                            Haptics.tap()
                            onSkip()
                        }
                    )

                    SecondaryActionButton(
                        title: "Reduce",
                        icon: "minus.circle.fill",
                        action: {
                            Haptics.tap()
                            onReduce()
                        }
                    )
                }
            } else if block.isFuture {
                // Future block actions
                HStack(spacing: 12) {
                    PrimaryActionButton(
                        title: "Move",
                        icon: "calendar.badge.clock",
                        action: { showMoveSheet = true }
                    )

                    SecondaryActionButton(
                        title: "Skip",
                        icon: "forward.fill",
                        action: {
                            Haptics.tap()
                            onSkip()
                        }
                    )
                }

                TertiaryActionButton(
                    title: "Reduce to \(reducedDuration)",
                    icon: "minus.circle",
                    action: {
                        Haptics.tap()
                        onReduce()
                    }
                )
            } else {
                // Past but not addressed
                HStack(spacing: 12) {
                    PrimaryActionButton(
                        title: "Mark Done",
                        icon: "checkmark.circle.fill",
                        action: {
                            Haptics.success()
                            onComplete()
                        }
                    )

                    SecondaryActionButton(
                        title: "Missed",
                        icon: "xmark.circle.fill",
                        action: {
                            Haptics.tap()
                            onSkip()
                        }
                    )
                }
            }
        }
    }

    private var reducedDuration: String {
        let newDuration = block.duration / 2
        return newDuration.minutesString
    }

    private var activeBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(AppTheme.accent)
                .frame(width: 6, height: 6)
            Text("ACTIVE")
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(AppTheme.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppTheme.accent.opacity(0.15))
        .clipShape(Capsule())
    }

    private func priorityBadge(_ priority: BlockPriority) -> some View {
        HStack(spacing: 4) {
            Image(systemName: priority.icon)
                .font(.system(size: 10, weight: .bold))
            Text(priority.displayName.uppercased())
                .font(.system(size: 10, weight: .bold))
                .tracking(0.5)
        }
        .foregroundColor(priority.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(priority.color.opacity(0.15))
        .clipShape(Capsule())
    }

    private func formatLinkTitle(_ url: String) -> String {
        if let host = URL(string: url)?.host {
            return host.replacingOccurrences(of: "www.", with: "")
        }
        return "Resource Link"
    }
}

// MARK: - Detail Section Component

struct DetailSection<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
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

            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.cardBackground(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Link Row Component

struct LinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let url: String
    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        Button(action: {
            if let linkURL = URL(string: url) {
                UIApplication.shared.open(linkURL)
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.tertiaryText(colorScheme))
            }
            .padding(12)
            .background(AppTheme.secondaryBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Metadata Chip Component

struct MetadataChip: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Action Button Components

struct PrimaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accentLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.scale)
    }
}

struct SecondaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(AppTheme.accent)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(AppTheme.accent.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.scale)
    }
}

struct TertiaryActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @Environment(\.appColorScheme) private var colorScheme

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(AppTheme.secondaryText(colorScheme))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppTheme.secondaryBackground(colorScheme))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.scale)
    }
}

// MARK: - Move Block Sheet (Keep existing)

struct MoveBlockSheet: View {
    let currentDate: Date
    let onMove: (Date) -> Void
    let onCancel: () -> Void

    @State private var selectedDate: Date
    @Environment(\.appColorScheme) private var colorScheme

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
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.primaryText(colorScheme))

                DatePicker(
                    "New time",
                    selection: $selectedDate,
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
                .tint(AppTheme.accent)

                Spacer()

                PrimaryActionButton(
                    title: "Move Block",
                    icon: "calendar.badge.clock",
                    action: { onMove(selectedDate) }
                )
            }
            .padding(20)
            .background(AppTheme.background(colorScheme))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(AppTheme.accent)
                }
            }
        }
    }
}

// MARK: - Legacy Components (for backward compatibility)

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

// MARK: - Preview

#Preview {
    BlockDetailSheet(
        block: PlanBlock(
            startDateTime: Date(),
            endDateTime: Date().addingTimeInterval(60 * 60),
            title: "Morning Workout Session",
            intentShort: "Build strength, improve cardio endurance, and start the day with energy",
            blockType: .focus,
            location: "Home Gym",
            notes: "Focus on compound movements today. Remember to warm up properly and stay hydrated throughout the session.",
            zoomLink: "https://zoom.us/j/123456789",
            youtubeLink: "https://youtube.com/watch?v=example",
            priority: .high,
            energyLevel: .high,
            tips: ["Start with 5 minutes of dynamic stretching", "Keep rest periods under 90 seconds", "End with 5 minutes of cool down"]
        ),
        onComplete: {},
        onSkip: {},
        onMove: { _ in },
        onReduce: {},
        onDismiss: {}
    )
    .themed()
}
