import SwiftUI

/// Premium subscription paywall
struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    let source: PaywallSource
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        PaywallHeader()

                        // Features
                        FeaturesSection(features: viewModel.features)

                        // Product selection
                        ProductSelectionSection(
                            selectedProduct: viewModel.selectedProduct,
                            monthlyPrice: viewModel.monthlyPriceString,
                            yearlyPrice: viewModel.yearlyPriceString,
                            yearlyMonthly: viewModel.yearlyMonthlyPriceString,
                            savings: viewModel.savingsPercentage,
                            onSelect: viewModel.selectProduct
                        )

                        // CTA
                        VStack(spacing: 16) {
                            PrimaryButton(
                                title: ctaTitle,
                                action: { Task { await viewModel.purchase() } },
                                isLoading: viewModel.isPurchasing
                            )

                            TertiaryButton(
                                title: "Continue with free version",
                                action: {
                                    onDismiss()
                                    dismiss()
                                }
                            )

                            // Restore purchases
                            Button(action: { Task { await viewModel.restore() } }) {
                                if viewModel.isRestoring {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                } else {
                                    Text("Restore Purchases")
                                        .font(.caption)
                                        .foregroundColor(.appSecondaryText)
                                }
                            }
                            .disabled(viewModel.isRestoring)
                        }
                        .padding(.horizontal, Constants.Layout.screenPadding)

                        // Legal
                        LegalFooter()
                            .padding(.bottom, 20)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onDismiss()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.appSecondaryText)
                            .frame(width: 28, height: 28)
                            .background(Color.appSecondaryBackground)
                            .clipShape(Circle())
                    }
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") { viewModel.dismissError() }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .onChange(of: viewModel.purchaseSuccessful) { _, success in
                if success {
                    onDismiss()
                    dismiss()
                }
            }
        }
    }

    private var ctaTitle: String {
        if viewModel.selectedProduct == .yearlyPro {
            return "Start Free Trial"
        }
        return "Subscribe"
    }
}

/// Paywall header with messaging
struct PaywallHeader: View {
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color.appAccent.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 32))
                    .foregroundColor(.appAccent)
            }

            VStack(spacing: 8) {
                Text("Turn intention into consistency")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.appPrimaryText)
                    .multilineTextAlignment(.center)

                Text("Your calendar adapts when life gets in the way")
                    .font(.body)
                    .foregroundColor(.appSecondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, Constants.Layout.screenPadding)
    }
}

/// Features section
struct FeaturesSection: View {
    let features: [PaywallFeature]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            ForEach(features) { feature in
                FeatureRow(feature: feature)
            }
        }
        .padding(20)
        .background(Color.appSecondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, Constants.Layout.screenPadding)
    }
}

/// Individual feature row
struct FeatureRow: View {
    let feature: PaywallFeature

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: feature.icon)
                .font(.system(size: 20))
                .foregroundColor(.appAccent)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundColor(.appPrimaryText)

                Text(feature.description)
                    .font(.caption)
                    .foregroundColor(.appSecondaryText)
            }
        }
    }
}

/// Product selection section
struct ProductSelectionSection: View {
    let selectedProduct: SubscriptionProduct
    let monthlyPrice: String
    let yearlyPrice: String
    let yearlyMonthly: String
    let savings: String
    let onSelect: (SubscriptionProduct) -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Yearly option
            ProductCard(
                title: "Yearly",
                price: yearlyPrice,
                perMonth: yearlyMonthly,
                badge: savings,
                isSelected: selectedProduct == .yearlyPro,
                action: { onSelect(.yearlyPro) }
            )

            // Monthly option
            ProductCard(
                title: "Monthly",
                price: monthlyPrice,
                perMonth: nil,
                badge: nil,
                isSelected: selectedProduct == .monthlyPro,
                action: { onSelect(.monthlyPro) }
            )
        }
        .padding(.horizontal, Constants.Layout.screenPadding)
    }
}

/// Individual product card
struct ProductCard: View {
    let title: String
    let price: String
    let perMonth: String?
    let badge: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.appPrimaryText)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.appSuccess)
                                .clipShape(Capsule())
                        }
                    }

                    if let perMonth = perMonth {
                        Text(perMonth)
                            .font(.caption)
                            .foregroundColor(.appSecondaryText)
                    }
                }

                Spacer()

                Text(price)
                    .font(.body.weight(.semibold))
                    .foregroundColor(.appPrimaryText)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? .appAccent : .appSecondaryText.opacity(0.5))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.appAccent.opacity(0.08) : Color.appSecondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? Color.appAccent : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.scale)
    }
}

/// Legal footer
struct LegalFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("7-day free trial, then auto-renews.")
                .font(.caption)
                .foregroundColor(.appSecondaryText)

            HStack(spacing: 16) {
                Link("Privacy", destination: Constants.URLs.privacyPolicy)
                Link("Terms", destination: Constants.URLs.termsOfService)
            }
            .font(.caption)
            .foregroundColor(.appTertiaryText)
        }
    }
}

/// Paywall trigger source
enum PaywallSource {
    case onboarding
    case settings
    case weeklyAdaptation
    case featureGate
}

// MARK: - Preview

#Preview {
    PaywallView(source: .onboarding, onDismiss: {})
}
