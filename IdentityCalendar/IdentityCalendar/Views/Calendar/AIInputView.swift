import SwiftUI

// MARK: - AI Input View
/// Natural language input for quick block creation

struct AIInputView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 16) {
            // Input field
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 18))

                TextField("e.g., workout tomorrow at 9am for 1 hour", text: $viewModel.aiInputText)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        viewModel.createBlockFromNaturalLanguage(viewModel.aiInputText)
                    }

                if !viewModel.aiInputText.isEmpty {
                    Button {
                        viewModel.createBlockFromNaturalLanguage(viewModel.aiInputText)
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)

            // Quick suggestions
            if viewModel.aiInputText.isEmpty {
                quickSuggestions
            }

            // Suggested time slots
            if !viewModel.suggestedSlots.isEmpty {
                suggestedSlotsView
            }

            // Loading indicator
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
        .onAppear {
            isInputFocused = true
        }
    }

    // MARK: - Quick Suggestions

    private var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick add")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            viewModel.aiInputText = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.accentColor.opacity(0.1))
                                .foregroundColor(.accentColor)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
    }

    private var suggestions: [String] {
        [
            "Focus work tomorrow 9am",
            "Gym today 6pm",
            "Review session Friday 5pm",
            "Meditation morning 15min",
            "Study 2 hours today"
        ]
    }

    // MARK: - Suggested Slots

    private var suggestedSlotsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suggested times")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(viewModel.suggestedSlots.prefix(3), id: \.startTime) { slot in
                SlotRow(slot: slot) {
                    let title = viewModel.aiInputText.isEmpty ? "New Block" : extractTitle(from: viewModel.aiInputText)
                    viewModel.applySlot(slot, title: title, blockType: .focus)
                }
            }
        }
    }

    private func extractTitle(from input: String) -> String {
        let parsed = NaturalLanguageBlockParser.shared.parse(input)
        return parsed?.title ?? "New Block"
    }
}

// MARK: - Slot Row

struct SlotRow: View {
    let slot: TimeSlot
    let onSelect: () -> Void

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d 'at' h:mm a"
        return formatter
    }()

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(timeFormatter.string(from: slot.startTime))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(slot.reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                scoreIndicator
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private var scoreIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: scoreIcon)
                .foregroundColor(scoreColor)
            Text("\(Int(slot.score))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(scoreColor)
        }
    }

    private var scoreIcon: String {
        if slot.score >= 80 { return "star.fill" }
        if slot.score >= 60 { return "hand.thumbsup.fill" }
        return "checkmark.circle"
    }

    private var scoreColor: Color {
        if slot.score >= 80 { return .green }
        if slot.score >= 60 { return .blue }
        return .secondary
    }
}

// MARK: - AI Input Button

struct AIInputButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("Quick Add")
            }
            .font(.subheadline.weight(.medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(20)
        }
    }
}

// MARK: - Day Analysis Card

struct DayAnalysisCard: View {
    let analysis: DayAnalysis

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Today's Schedule")
                    .font(.headline)
                Spacer()
                balanceIndicator
            }

            HStack(spacing: 16) {
                statItem(value: "\(analysis.totalBlocks)", label: "Blocks")
                statItem(value: "\(analysis.totalMinutes)m", label: "Total")
                statItem(value: "\(analysis.focusMinutes)m", label: "Focus")
            }

            if let suggestion = analysis.suggestion {
                Text(suggestion)
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(8)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var balanceIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(balanceColor)
                .frame(width: 8, height: 8)
            Text(balanceText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var balanceColor: Color {
        if analysis.balanceScore >= 66 { return .green }
        if analysis.balanceScore >= 33 { return .yellow }
        return .red
    }

    private var balanceText: String {
        if analysis.balanceScore >= 66 { return "Balanced" }
        if analysis.balanceScore >= 33 { return "Moderate" }
        return "Needs adjustment"
    }
}

// MARK: - Preview

#Preview {
    AIInputView(viewModel: CalendarViewModel())
        .padding()
}
