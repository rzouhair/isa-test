//
//  AppDelegate.swift
//  paperscan
//
//  Created by user on 15/2/2025.
//

import RevenueCat
import Foundation
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        configurePurchases()
        return true
    }
    
    private func configurePurchases() {
        Purchases.logLevel = .debug
        Purchases.configure(
            with: Configuration.Builder(withAPIKey: Constants.revenueCat)
                .build()
        )
    }
}

