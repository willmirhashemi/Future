import Foundation
import StoreKit

/// Handles in-app purchases and subscription management
@MainActor
final class SubscriptionService: ObservableObject {
    static let shared = SubscriptionService()

    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false
    @Published private(set) var subscription: Subscription = .free

    private var transactionListener: Task<Void, Error>?

    private init() {
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updateSubscriptionStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let productIDs = SubscriptionProduct.allCases.map { $0.rawValue }
            products = try await Product.products(for: Set(productIDs))
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
            products = []
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await updateSubscriptionStatus()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        try await AppStore.sync()
        await updateSubscriptionStatus()
    }

    // MARK: - Subscription Status

    func updateSubscriptionStatus() async {
        var activePurchases: Set<String> = []

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else {
                continue
            }

            if transaction.revocationDate == nil {
                activePurchases.insert(transaction.productID)
            }
        }

        purchasedProductIDs = activePurchases

        // Determine subscription tier
        let isPro = activePurchases.contains { id in
            SubscriptionProduct.allCases.map { $0.rawValue }.contains(id)
        }

        if isPro {
            // Find expiration date
            var expirationDate: Date?
            for await result in Transaction.currentEntitlements {
                if case .verified(let transaction) = result {
                    if let expDate = transaction.expirationDate, expDate > Date() {
                        expirationDate = expDate
                        break
                    }
                }
            }

            subscription = Subscription(
                tier: .pro,
                status: .active,
                expiresAt: expirationDate,
                startedAt: Date()
            )
        } else {
            subscription = .free
        }
    }

    // MARK: - Helpers

    var isPremium: Bool {
        subscription.isPremium
    }

    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.monthlyPro.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.yearlyPro.rawValue }
    }

    func product(for subscriptionProduct: SubscriptionProduct) -> Product? {
        products.first { $0.id == subscriptionProduct.rawValue }
    }

    // MARK: - Private

    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await self.updateSubscriptionStatus()
                    await transaction.finish()
                } catch {
                    print("Transaction verification failed: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

// MARK: - Errors

enum SubscriptionError: Error, LocalizedError {
    case verificationFailed
    case purchaseFailed
    case noProductsAvailable

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            return "Failed to verify purchase"
        case .purchaseFailed:
            return "Purchase could not be completed"
        case .noProductsAvailable:
            return "Products are not available"
        }
    }
}

// MARK: - Mock for Previews

#if DEBUG
extension SubscriptionService {
    static var preview: SubscriptionService {
        let service = SubscriptionService.shared
        return service
    }

    func setMockPremium(_ isPremium: Bool) {
        if isPremium {
            subscription = Subscription(
                tier: .pro,
                status: .active,
                expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60),
                startedAt: Date()
            )
        } else {
            subscription = .free
        }
    }
}
#endif
