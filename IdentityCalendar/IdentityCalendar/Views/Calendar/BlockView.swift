import SwiftUI

/// Compact block view for week calendar
struct BlockView: View {
    let block: PlanBlock

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Title
            Text(block.title)
                .font(.caption2.weight(.medium))
                .foregroundColor(textColor)
                .lineLimit(1)

            // Duration (only if block is tall enough)
            if block.durationMinutes >= 30 {
                Text(block.duration.minutesString)
                    .font(.caption2)
                    .foregroundColor(textColor.opacity(0.8))
            }

            Spacer(minLength: 0)

            // Status indicator
            if block.status == .completed {
                Image(systemName: "checkmark")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(textColor)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(borderColor, lineWidth: 1)
        )
    }

    private var backgroundColor: Color {
        switch block.status {
        case .completed:
            return block.blockType.color.opacity(0.3)
        case .skipped:
            return Color.appSecondaryBackground
        case .inProgress:
            return block.blockType.backgroundColor
        default:
            return block.blockType.backgroundColor
        }
    }

    private var textColor: Color {
        switch block.status {
        case .skipped:
            return .appTertiaryText
        default:
            return block.blockType.color
        }
    }

    private var borderColor: Color {
        switch block.status {
        case .inProgress:
            return block.blockType.color
        default:
            return block.blockType.color.opacity(0.2)
        }
    }
}

/// Empty time slot indicator
struct EmptyTimeSlot: View {
    let hour: Int

    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: Constants.Calendar.hourHeight)
    }
}

// MARK: - Block Type Badges

struct BlockTypeBadge: View {
    let type: BlockType

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: type.icon)
                .font(.caption2)

            Text(type.displayName)
                .font(.caption2.weight(.medium))
        }
        .foregroundColor(type.color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(type.backgroundColor)
        .clipShape(Capsule())
    }
}

/// Block status badge
struct BlockStatusBadge: View {
    let status: BlockStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.caption2)

            Text(status.displayName)
                .font(.caption2.weight(.medium))
        }
        .foregroundColor(statusColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.1))
        .clipShape(Capsule())
    }

    private var statusColor: Color {
        switch status {
        case .completed:
            return .appSuccess
        case .inProgress:
            return .appAccent
        case .skipped:
            return .appSecondaryText
        case .scheduled:
            return .appSecondaryText
        case .missed:
            return .appWarning
        }
    }
}

// MARK: - Preview

#Preview("Block View") {
    VStack(spacing: 8) {
        BlockView(block: PlanBlock(
            startDateTime: Date(),
            endDateTime: Date().addingTimeInterval(60 * 60),
            title: "Morning Workout",
            intentShort: "Build strength",
            blockType: .focus
        ))
        .frame(height: 60)

        BlockView(block: PlanBlock(
            startDateTime: Date(),
            endDateTime: Date().addingTimeInterval(30 * 60),
            title: "Review Notes",
            intentShort: "Quick review",
            blockType: .light
        ))
        .frame(height: 40)
    }
    .padding()
}

#Preview("Block Badges") {
    VStack(spacing: 8) {
        HStack {
            BlockTypeBadge(type: .focus)
            BlockTypeBadge(type: .light)
            BlockTypeBadge(type: .habit)
            BlockTypeBadge(type: .review)
        }

        HStack {
            BlockStatusBadge(status: .scheduled)
            BlockStatusBadge(status: .completed)
            BlockStatusBadge(status: .skipped)
        }
    }
    .padding()
}
