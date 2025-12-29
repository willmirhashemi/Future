import SwiftUI

/// Single day view with detailed time slots
struct DayView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let date: Date

    private let startHour = Constants.Calendar.startHour
    private let endHour = Constants.Calendar.endHour

    var body: some View {
        VStack(spacing: 0) {
            // Day info header
            DayInfoHeader(date: date, blocksCount: blocks.count)

            // Time grid
            ScrollView {
                ScrollViewReader { proxy in
                    ZStack(alignment: .topLeading) {
                        // Hour lines
                        VStack(spacing: 0) {
                            ForEach(startHour..<endHour, id: \.self) { hour in
                                HourRow(hour: hour)
                                    .id("hour-\(hour)")
                            }
                        }

                        // Current time indicator
                        if date.isToday {
                            CurrentTimeIndicator(
                                startHour: startHour,
                                hourHeight: Constants.Calendar.hourHeight,
                                timeColumnWidth: Constants.Calendar.timeColumnWidth
                            )
                        }

                        // Blocks
                        blocksOverlay
                    }
                    .onAppear {
                        if date.isToday {
                            let currentHour = Calendar.current.component(.hour, from: Date())
                            if currentHour >= startHour {
                                proxy.scrollTo("hour-\(max(startHour, currentHour - 1))", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }

    private var blocks: [PlanBlock] {
        viewModel.blocksForDate(date)
    }

    private var blocksOverlay: some View {
        GeometryReader { geometry in
            let totalHeight = CGFloat(endHour - startHour) * Constants.Calendar.hourHeight

            ForEach(blocks) { block in
                let position = calculatePosition(for: block, in: totalHeight)

                DayBlockView(
                    block: block,
                    onTap: { viewModel.selectBlock(block) }
                )
                .frame(height: position.height)
                .offset(y: position.top)
                .padding(.leading, Constants.Calendar.timeColumnWidth + 8)
                .padding(.trailing, 16)
            }
        }
    }

    private func calculatePosition(for block: PlanBlock, in totalHeight: CGFloat) -> (top: CGFloat, height: CGFloat) {
        let totalMinutes = CGFloat((endHour - startHour) * 60)
        let minuteHeight = totalHeight / totalMinutes

        let startMinutes = CGFloat(block.startDateTime.hour * 60 + block.startDateTime.minute)
        let startOffset = startMinutes - CGFloat(startHour * 60)
        let top = startOffset * minuteHeight

        let durationMinutes = CGFloat(block.durationMinutes)
        let height = max(Constants.Calendar.blockMinHeight, durationMinutes * minuteHeight)

        return (max(0, top), height)
    }
}

/// Day info header showing date and block count
struct DayInfoHeader: View {
    let date: Date
    let blocksCount: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(date.dayOfWeekString)
                    .font(.headline)
                    .foregroundColor(.appPrimaryText)

                Text(date.mediumDateString)
                    .font(.subheadline)
                    .foregroundColor(.appSecondaryText)
            }

            Spacer()

            if blocksCount > 0 {
                Text("\(blocksCount) block\(blocksCount == 1 ? "" : "s")")
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appAccent)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.appAccent.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, Constants.Layout.screenPadding)
        .padding(.vertical, 12)
        .background(Color.appBackground)
    }
}

/// Hour row in day view
struct HourRow: View {
    let hour: Int

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Text(hourLabel)
                .font(.caption)
                .foregroundColor(.appTertiaryText)
                .frame(width: Constants.Calendar.timeColumnWidth, alignment: .trailing)
                .padding(.trailing, 8)

            VStack(spacing: 0) {
                Rectangle()
                    .fill(Color.appSeparator.opacity(0.5))
                    .frame(height: 0.5)

                Spacer()
            }
        }
        .frame(height: Constants.Calendar.hourHeight)
    }

    private var hourLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        var components = DateComponents()
        components.hour = hour
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return "\(hour)"
    }
}

/// Expanded block view for day view
struct DayBlockView: View {
    let block: PlanBlock
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(block.blockType.color)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(block.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.appPrimaryText)
                        .lineLimit(1)

                    Text(block.intentShort)
                        .font(.caption)
                        .foregroundColor(.appSecondaryText)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(timeRange, systemImage: "clock")
                        Label(block.duration.minutesString, systemImage: "hourglass")
                    }
                    .font(.caption2)
                    .foregroundColor(.appTertiaryText)
                }

                Spacer()

                // Status indicator
                statusIcon
            }
            .padding(12)
            .background(block.blockType.backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(block.blockType.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.scale)
    }

    private var timeRange: String {
        "\(block.startDateTime.shortTimeString) - \(block.endDateTime.shortTimeString)"
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch block.status {
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.appSuccess)
        case .inProgress:
            Image(systemName: "play.circle.fill")
                .foregroundColor(.appAccent)
        case .skipped:
            Image(systemName: "forward.circle.fill")
                .foregroundColor(.appSecondaryText)
        default:
            EmptyView()
        }
    }
}

// MARK: - Preview

#Preview {
    DayView(viewModel: CalendarViewModel(), date: Date())
}
