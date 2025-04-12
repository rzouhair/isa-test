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

    public init() {}

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
                    // UIApplication.showAlert(title: "Purchase restored", message: "Your purchase was successfully restored. All of the Pro feature were unlocked!")
                } else {
                    // UIApplication.showAlert(title: "Purchase not found", message: "Your purchase was not restored because it was not found. If you think this is a mistake, please reach out at \(Constants.supportEmail)")
                }
            case .failure(_):
                print("Purchase restoration failed")
                // UIApplication.showAlert(title: "Purchase restoration failed", message: "An unknown error occured while restoring your purchase. Please try again later or contact support at \(Constants.supportEmail)")
            }
        })
    }

    func purchase(_ package: Package?) async {
        guard let package else { return }
        await MainActor.run(body: { isLoading = true })
        let result = await subscriptionRepository.purchase(package: package)
        await MainActor.run(body: {
            switch result {
            case .success(let success):
                if success {
                    UIApplication.showAlert(title: "🎉 Congratulations!", message: "Your Pro subscription was successfully activated and all Pro features were unlocked!") {
                         UIApplication.topViewController()?.dismiss(animated: true)
                    }
                }
            case .failure(_):
                UIApplication.showAlert(title: "Something went wrong", message: "An unknown error occured while trying to purchase the subscription. Please try again later or contact support at \(Constants.supportEmail)")
                print("Something went wrong")
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
