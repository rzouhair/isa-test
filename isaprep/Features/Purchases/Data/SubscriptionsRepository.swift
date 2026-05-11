//
//  File.swift
//  
//
//  Created by user on 07/09/2023.
//

import Foundation
import RevenueCat

/// Purchases feature has its own data layer so it can be extracted to a separate package in the future and re-used in all apps.
/// Change the "pro" string on line 33 to the entitlement you set in RevenueCat
/// Change the "default" string on line 61 to the offering ID you set in RevenueCat
///
///
public class SubscriptionsRepository {

    static let shared = SubscriptionsRepository()

    var customerInfo: CustomerInfo?
    var isProUser: Bool {
        customerInfo?.entitlements.active[Subscription.pro.name] != nil
    }

    /// Convenience: the active pro entitlement, if any. Use for expiry dates /
    /// renewal info in UI.
    var activeProEntitlement: EntitlementInfo? {
        customerInfo?.entitlements.active[Subscription.pro.name]
    }

    var customerId: String {
        Purchases.shared.appUserID
    }

    enum Subscription {
        case pro

        /// Must match the entitlement identifier configured in RevenueCat.
        var name: String {
            switch self {
            case .pro: return Constants.revenueCatProEntitlement
            }
        }
    }

    private init() {}

    public func loadProData() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            customerInfo = nil
            DIContainer.shared.crashReportingService.captureError(
                error,
                context: ["action": "revenuecat_load_customer_info"]
            )
            return
        }
    }

    public func restorePurchase() async -> Result<Bool, Error> {
        do {
            customerInfo = try await Purchases.shared.restorePurchases()
            return .success(isProUser)
        } catch {
            return .failure(error)
        }
    }

    public func loadOffering() async -> Offering? {
        await withCheckedContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                if let error {
                    DIContainer.shared.crashReportingService.captureError(
                        error,
                        context: ["action": "revenuecat_load_offerings"]
                    )
                }
                continuation.resume(returning: offerings?.all.values.first)
            }
        }
    }

    public func getCurrentOffering() async -> Offering? {
        await withCheckedContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                if let error {
                    DIContainer.shared.crashReportingService.captureError(
                        error,
                        context: ["action": "revenuecat_get_current_offering"]
                    )
                }
                continuation.resume(returning: offerings?.current)
            }
        }
    }

    public func isUserEligibleForIntroductoryOffer(_ product: StoreProduct) async -> Bool {
        let status = await Purchases.shared.checkTrialOrIntroDiscountEligibility(product: product)
        return status == .eligible
    }

    public func purchase(package: Package) async -> Result<Bool, Error> {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            customerInfo = result.customerInfo
            return .success(!result.userCancelled)
        } catch {
            return .failure(error)
        }
    }
}
