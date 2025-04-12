// PurchaseModel SwiftUI
// Created by Adam Lyttle on 7/18/2024

// Make cool stuff and share your build with me:

//  --> x.com/adamlyttleapps
//  --> github.com/adamlyttleapps

import Foundation
import StoreKit
import RevenueCat

@Observable
class PaywallYearlyViewModel {
    
    var packages: [Package] = []
    var mainPackage: Package?
    var selectedPackage: Package?
    var isUserEligibleForIntroOffer: Bool = false
    
    var productIds: [String]
    var productDetails: [PurchaseProductDetails] = []

    var isSubscribed: Bool = false
    var isPurchasing: Bool = false
    var isFetchingProducts: Bool = false
    
    var isLoading: Bool = false
    
    let subscriptionRepository: SubscriptionsRepository = SubscriptionsRepository.shared

    init() {

        //initialise your productids and product details
        self.productIds = ["demo_y", "demo_w"]
        self.productDetails = [
            PurchaseProductDetails(price: "$25.99", productId: "demo_y", duration: "year", durationPlanName: "Yearly Plan", hasTrial: false),
            PurchaseProductDetails(price: "$4.99", productId: "demo_w", duration: "week", durationPlanName: "3-Day Trial", hasTrial: true)
        ]

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
    
    func purchaseSubscription(productId: String) {
        #if DEBUG
            isSubscribed = true
        #else
            //trigger purchase process
        #endif
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
    
    func restorePurchases() async {
        //trigger restore purchases
        await MainActor.run(body: { isLoading = true })
        let result = await subscriptionRepository.restorePurchase()
        await MainActor.run(body: {
            switch result {
            case .success(let restored):
                if restored {
                    UIApplication.showAlert(title: "Purchase restored", message: "Your purchase was successfully restored. All of the Pro feature were unlocked!")
                } else {
                    UIApplication.showAlert(title: "Purchase not found", message: "Your purchase was not restored because it was not found. If you think this is a mistake, please reach out at \(Constants.supportEmail)")
                }
            case .failure(_):
                print("Purchase restoration failed")
                UIApplication.showAlert(title: "Purchase restoration failed", message: "An unknown error occured while restoring your purchase. Please try again later or contact support at \(Constants.supportEmail)")
            }
        })
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

@Observable
class PurchaseProductDetails: Identifiable {
    let id: UUID
    
    var price: String
    var productId: String
    var duration: String
    var durationPlanName: String
    var hasTrial: Bool
    
    init(price: String = "", productId: String = "", duration: String = "", durationPlanName: String = "", hasTrial: Bool = false) {
        self.id = UUID()
        self.price = price
        self.productId = productId
        self.duration = duration
        self.durationPlanName = durationPlanName
        self.hasTrial = hasTrial
    }
    
}
