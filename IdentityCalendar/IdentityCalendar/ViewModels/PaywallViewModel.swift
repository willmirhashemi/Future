import Foundation
import SwiftUI
import StoreKit

/// Manages paywall view state and purchase flow
@MainActor
final class PaywallViewModel: ObservableObject {
    // MARK: - Published State

    @Published var selectedProduct: SubscriptionProduct = .yearlyPro
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var isRestoring = false
    @Published var errorMessage: String?
    @Published var purchaseSuccessful = false

    // MARK: - Dependencies

    private let subscriptionService: SubscriptionService

    // MARK: - Computed Properties

    var monthlyProduct: Product? {
        subscriptionService.monthlyProduct
    }

    var yearlyProduct: Product? {
        subscriptionService.yearlyProduct
    }

    var hasProducts: Bool {
        !subscriptionService.products.isEmpty
    }

    var isPremium: Bool {
        subscriptionService.isPremium
    }

    var selectedStoreProduct: Product? {
        subscriptionService.product(for: selectedProduct)
    }

    // Features for display
    let features: [PaywallFeature] = [
        PaywallFeature(
            icon: "arrow.triangle.2.circlepath",
            title: "Adaptive weekly planning",
            description: "Your calendar adjusts based on how your week went"
        ),
        PaywallFeature(
            icon: "infinity",
            title: "Unlimited identity paths",
            description: "Work on multiple goals simultaneously"
        ),
        PaywallFeature(
            icon: "calendar.badge.clock",
            title: "Smart rescheduling",
            description: "Move blocks and we'll rebalance your week"
        ),
        PaywallFeature(
            icon: "chart.line.uptrend.xyaxis",
            title: "Progress insights",
            description: "See your momentum over time"
        )
    ]

    // MARK: - Initialization

    init(subscriptionService: SubscriptionService = .shared) {
        self.subscriptionService = subscriptionService

        Task {
            await loadProducts()
        }
    }

    // MARK: - Product Loading

    func loadProducts() async {
        isLoading = true
        await subscriptionService.loadProducts()
        isLoading = false
    }

    // MARK: - Selection

    func selectProduct(_ product: SubscriptionProduct) {
        Haptics.select()
        selectedProduct = product
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product = selectedStoreProduct else {
            errorMessage = "Product not available"
            return
        }

        isPurchasing = true
        errorMessage = nil

        do {
            let success = try await subscriptionService.purchase(product)
            if success {
                purchaseSuccessful = true
                Haptics.success()
            }
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }

        isPurchasing = false
    }

    func restore() async {
        isRestoring = true
        errorMessage = nil

        do {
            try await subscriptionService.restorePurchases()
            if subscriptionService.isPremium {
                purchaseSuccessful = true
                Haptics.success()
            } else {
                errorMessage = "No previous purchases found"
            }
        } catch {
            errorMessage = error.localizedDescription
            Haptics.error()
        }

        isRestoring = false
    }

    // MARK: - Helpers

    func dismissError() {
        errorMessage = nil
    }
}

// MARK: - Paywall Feature

struct PaywallFeature: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

// MARK: - Price Helpers

extension PaywallViewModel {
    var monthlyPriceString: String {
        monthlyProduct?.displayPrice ?? SubscriptionProduct.monthlyPro.price
    }

    var yearlyPriceString: String {
        yearlyProduct?.displayPrice ?? SubscriptionProduct.yearlyPro.price
    }

    var yearlyMonthlyPriceString: String {
        if let yearly = yearlyProduct {
            let monthlyPrice = yearly.price / 12
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = yearly.priceFormatStyle.locale
            return formatter.string(from: monthlyPrice as NSNumber) ?? SubscriptionProduct.yearlyPro.pricePerMonth
        }
        return SubscriptionProduct.yearlyPro.pricePerMonth
    }

    var savingsPercentage: String {
        guard let monthly = monthlyProduct,
              let yearly = yearlyProduct else {
            return SubscriptionProduct.yearlyPro.savings ?? ""
        }

        let yearlyMonthly = yearly.price / 12
        let savings = (1 - (yearlyMonthly / monthly.price)) * 100
        return "Save \(Int(savings))%"
    }
}
