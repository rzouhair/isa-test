//
//  SubscriptionService.swift
//  examprep
//
//  Created by user on 06/03/2024.
//

import Foundation
import RevenueCat
import RevenueCatUI
import SwiftUI

class SubscriptionService {

    static let shared = SubscriptionService()

    let subscriptionRrepository = SubscriptionsRepository.shared

    var isProUser: Bool {
        /// Uncomment the code below to test your Pro features or make a test transaction
        ///
        /// 
        // #if DEBUG
        // return true
        // #else
        subscriptionRrepository.isProUser
        // #endif
    }

    var paywallView: some View {
        /// Uncomment `PaywallView()` line for Remote Paywall fetched from RevenueCat
        ///
        ///
//        PaywallView()
        SailPaywallView(
            viewModel: PaywallViewModel()
        )
    }

    public func loadProStatus() async {
        await SubscriptionsRepository.shared.loadProData()
    }

    public func restorePurchase() async -> Result<Bool, Error> {
        await subscriptionRrepository.restorePurchase()
    }

    public func isFreeTrialAvailable() async -> Bool {
        guard let product = await subscriptionRrepository.getCurrentOffering()?.annual?.storeProduct else { return false }
        return await subscriptionRrepository.isUserEligibleForIntroductoryOffer(product)
    }

    public var customerId: String {
        subscriptionRrepository.customerId
    }
}
