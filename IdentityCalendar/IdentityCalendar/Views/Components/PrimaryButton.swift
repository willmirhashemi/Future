import SwiftUI

/// Primary action button with Apple-like styling
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            Haptics.tap()
            action()
        }) {
            ZStack {
                Text(title)
                    .font(.body.weight(.semibold))
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Layout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isDisabled ? Color.appAccent.opacity(0.5) : Color.appAccent)
            )
        }
        .buttonStyle(.scale)
        .disabled(isDisabled || isLoading)
    }
}

/// Secondary action button
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var isLoading: Bool = false

    var body: some View {
        Button(action: {
            guard !isLoading else { return }
            Haptics.tap()
            action()
        }) {
            ZStack {
                Text(title)
                    .font(.body.weight(.medium))
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appAccent))
                }
            }
            .foregroundColor(.appAccent)
            .frame(maxWidth: .infinity)
            .frame(height: Constants.Layout.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appAccent.opacity(0.1))
            )
        }
        .buttonStyle(.scale)
        .disabled(isLoading)
    }
}

/// Tertiary text button
struct TertiaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Text(title)
                .font(.body.weight(.medium))
                .foregroundColor(.appSecondaryText)
        }
        .buttonStyle(.soft)
    }
}

/// Icon button for navigation and actions
struct IconButton: View {
    let icon: String
    let action: () -> Void
    var size: CGFloat = 44

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.appPrimaryText)
                .frame(width: size, height: size)
                .background(Color.appSecondaryBackground)
                .clipShape(Circle())
        }
        .buttonStyle(.scale)
    }
}

// MARK: - Previews

#Preview("Primary Button") {
    VStack(spacing: 16) {
        PrimaryButton(title: "Continue", action: {})
        PrimaryButton(title: "Loading...", action: {}, isLoading: true)
        PrimaryButton(title: "Disabled", action: {}, isDisabled: true)
    }
    .padding()
}

#Preview("Secondary Button") {
    VStack(spacing: 16) {
        SecondaryButton(title: "Skip for now", action: {})
        SecondaryButton(title: "Loading...", action: {}, isLoading: true)
    }
    .padding()
}

#Preview("Tertiary Button") {
    TertiaryButton(title: "Learn more", action: {})
        .padding()
}
