import SwiftUI

/// A selectable card for onboarding options
struct SelectionCard<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        Button(action: {
            Haptics.select()
            action()
        }) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? Color.appAccent.opacity(0.08) : Color.appSecondaryBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            isSelected ? Color.appAccent : Color.clear,
                            lineWidth: 2
                        )
                )
        }
        .buttonStyle(.scale)
    }
}

/// Selection card with icon, title, and description
struct OptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .appAccent : .appSecondaryText)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundColor(.appPrimaryText)

                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.appSecondaryText)
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appAccent)
                        .font(.system(size: 22))
                }
            }
        }
    }
}

/// Simple selection card with just title
struct SimpleOptionCard: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        SelectionCard(isSelected: isSelected, action: action) {
            HStack {
                Text(title)
                    .font(.body.weight(.medium))
                    .foregroundColor(.appPrimaryText)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.appAccent)
                        .font(.system(size: 20))
                }
            }
        }
    }
}

/// Identity type selection card
struct IdentityCard: View {
    let identity: IdentityType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        OptionCard(
            icon: identity.icon,
            title: identity.displayName,
            description: identity.description,
            isSelected: isSelected,
            action: action
        )
    }
}

// MARK: - Previews

#Preview("Option Card") {
    VStack(spacing: 12) {
        OptionCard(
            icon: "figure.run",
            title: "Fit & Disciplined",
            description: "Build lasting health habits",
            isSelected: true,
            action: {}
        )

        OptionCard(
            icon: "book.closed",
            title: "Structured Student",
            description: "Excel in your studies",
            isSelected: false,
            action: {}
        )
    }
    .padding()
}

#Preview("Simple Option Card") {
    VStack(spacing: 12) {
        SimpleOptionCard(title: "3 Months", isSelected: true, action: {})
        SimpleOptionCard(title: "6 Months", isSelected: false, action: {})
    }
    .padding()
}
