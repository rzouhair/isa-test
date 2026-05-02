//
//  AppDelegate.swift
//  examprep
//
//  Created by user on 15/2/2025.
//

import Foundation
import SwiftUI
import UserNotifications

// RevenueCat is configured in AppMain.init so that the @main struct owns the
// SDK lifecycle and StoreKit 2 is selected before any `Purchases.shared`
// access. Do not re-configure here.
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        DIContainer.shared.crashReportingService.initialize()
        DIContainer.shared.analyticsService.initialize()
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Show notifications even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

