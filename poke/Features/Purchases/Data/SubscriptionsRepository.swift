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
        customerInfo?.entitlements.active.contains(where: {$0.key.lowercased() == Subscription.pro.name}) ?? false
    }

    var customerId: String {
        Purchases.shared.appUserID
    }

    enum Subscription {
        case pro

        var name: String {
            switch self {
            case .pro: return "pro"
            }
        }
    }

    private init() {
      print(customerInfo)
    }

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
                guard let currentOffering = offerings?.all.values.first else {
                    continuation.resume(returning: nil)
                    print(offerings?.all)
                    return
                }

                continuation.resume(returning: currentOffering)
            }
        }
    }

    public func getCurrentOffering() async -> Offering? {
        await withCheckedContinuation { continuation in
            Purchases.shared.getOfferings { offerings, error in
                guard let currentOffering = offerings?.current else {
                    continuation.resume(returning: nil)
                    return
                }
                continuation.resume(returning: currentOffering)
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
