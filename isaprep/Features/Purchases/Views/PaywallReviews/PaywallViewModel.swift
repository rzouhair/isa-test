//
//  File.swift
//  
//
//  Created by user on 07/09/2023.
//

import Foundation
import SwiftUI
import RevenueCat

public class PaywallViewModel: ObservableObject {

    @Published var packages: [Package] = []
    @Published var mainPackage: Package?
    @Published var selectedPackage: Package?
    @Published var isLoading = false
    @Published var isUserEligibleForIntroOffer = false
    @Published var purchaseCompleted = false

    let subscriptionRepository: SubscriptionsRepository = SubscriptionsRepository.shared
    private let analytics = DIContainer.shared.analyticsService
    private let crashReporting = DIContainer.shared.crashReportingService

    public init() {
        Task {
            await onAppear()
        }
    }

    var mainPackageString: String {
        guard let mainPackage else { return "" }
        return mainPackage.priceString
    }

    var mainPackageWeeklyPriceString: String {
        guard let mainPackage else { return "" }
        return mainPackage.weeklyPriceString
    }

    func onAppear() async {
        await MainActor.run { isLoading = true }
        await loadPackages()
        await getUserIntroOfferEligibility()
        await MainActor.run { isLoading = false }
    }

    func loadPackages() async {
        let offering = await subscriptionRepository.loadOffering()
        await MainActor.run {
            self.packages = offering?.availablePackages ?? []
            self.mainPackage = offering?.annual
            selectedPackage = mainPackage
        }
    }

    func getUserIntroOfferEligibility() async {
        guard let product = mainPackage?.storeProduct else { return }
        let isEligible = await subscriptionRepository.isUserEligibleForIntroductoryOffer(product)
        await MainActor.run(body: {
            isUserEligibleForIntroOffer = isEligible
        })
    }

    func restorePurchase() async {
        await MainActor.run(body: { isLoading = true })
        let result = await subscriptionRepository.restorePurchase()
        await MainActor.run(body: {
            isLoading = false
            switch result {
            case .success(let restored):
                if restored {
                    analytics.capture(.purchaseRestored)
                }
            case .failure(let error):
                analytics.capture(.purchaseFailed, properties: ["action": "restore", "error": error.localizedDescription])
                crashReporting.captureError(error, context: ["action": "restore_purchase"])
            }
        })
    }

    func purchase(_ package: Package?) async {
        guard let package else { return }
        analytics.capture(.purchaseStarted, properties: ["package": package.identifier])
        await MainActor.run(body: { isLoading = true })
        let result = await subscriptionRepository.purchase(package: package)
        await MainActor.run(body: {
            switch result {
            case .success(let success):
                if success {
                    analytics.capture(.purchaseCompleted, properties: ["package": package.identifier])
                    UIApplication.showAlert(title: "🎉 Congratulations!", message: "Your Pro subscription was successfully activated and all Pro features were unlocked!") {
                         UIApplication.topViewController()?.dismiss(animated: true)
                    }
                }
            case .failure(let error):
                analytics.capture(.purchaseFailed, properties: ["package": package.identifier, "error": error.localizedDescription])
                crashReporting.captureError(error, context: ["action": "purchase", "package": package.identifier])
                UIApplication.showAlert(title: "Something went wrong", message: "An unknown error occured while trying to purchase the subscription. Please try again later or contact support at \(Constants.supportEmail)")
            }
        })
        await MainActor.run(body: { isLoading = false })
    }

    func showPrivacyPolicy() {
        guard let url = URL(string: Constants.privacyPolicyUrl) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }

    }

    func showEula() {
        guard let url = URL(string: Constants.appleEulaUrl) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}
