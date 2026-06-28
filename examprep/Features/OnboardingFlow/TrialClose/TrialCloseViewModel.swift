//
//  TrialCloseViewModel.swift
//  isaprep
//

import Foundation
import Observation
import RevenueCat
import UserNotifications
import UIKit

@MainActor
@Observable
final class TrialCloseViewModel {
    var step: Int = 0
    var legalText: String = ""
    var trialDaysText: String = ""
    var isLoading: Bool = false
    var onRestoreSuccess: (() -> Void)?

    private let subscriptionRepository = SubscriptionsRepository.shared
    private var trialDaysCount: Int = 3

    init() {
        Task {
            await loadTrialInfo()
        }
    }

    func loadTrialInfo() async {
        await MainActor.run { isLoading = true }

        guard let offering = await subscriptionRepository.loadOffering() else {
            await MainActor.run {
                isLoading = false
            }
            return
        }

        // Find the weekly package (has trial)
        let weeklyPackage = offering.availablePackages.first { package in
            package.storeProduct.subscriptionPeriod?.unit == .week
                && package.storeProduct.subscriptionPeriod?.value == 1
        }

        await MainActor.run {
            if let package = weeklyPackage {
                let priceString = package.localizedPriceString
                let periodUnit = package.storeProduct.subscriptionPeriod?.unit.string ?? "week"

                // Build trial duration text from intro offer
                if let intro = package.storeProduct.introductoryDiscount,
                   intro.price == 0 {
                    let trialPeriod = intro.subscriptionPeriod
                    let days = trialDays(from: trialPeriod)
                    trialDaysCount = days
                    trialDaysText = "\(days)"
                    legalText = "\(days)-day free trial, then \(priceString)/\(periodUnit)"
                } else {
                    trialDaysCount = 3
                    trialDaysText = "3"
                    legalText = "\(trialDaysText)-day free trial, then \(priceString)/\(periodUnit)"
                }
            }
            isLoading = false
        }
    }

    // MARK: - Trial Reminder Notification

    /// Request notification permission. Call right after trial close, before showing paywall.
    static func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    // Legacy identifiers from the Kash codebase. Keep in the removal list so
    // installs upgraded from early builds clear their orphan notifications.
    private static let trialReminderIdentifiers = [
        "isaprep_trial_reminder", "isaprep_trial_confirmation",
        "kash_trial_reminder", "kash_trial_confirmation"
    ]

    static func clearTrialNotifications() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: trialReminderIdentifiers)
        center.removeDeliveredNotifications(withIdentifiers: trialReminderIdentifiers)
    }

    /// Schedules a reminder 1 day before trial/intro expiration.
    /// Call after a successful purchase or restore with the resulting CustomerInfo.
    static func scheduleTrialReminderIfNeeded(customerInfo: CustomerInfo) {
        #if DEBUG
        print("[TrialReminder] called — entitlements: \(customerInfo.entitlements.active.keys.joined(separator: ", "))")
        #endif

        guard let entitlement = customerInfo.entitlements.active[Constants.revenueCatProEntitlement] else {
            #if DEBUG
            print("[TrialReminder] EXIT: no '\(Constants.revenueCatProEntitlement)' entitlement")
            #endif
            return
        }

        #if DEBUG
        print("[TrialReminder] periodType=\(entitlement.periodType) expiration=\(String(describing: entitlement.expirationDate))")
        #endif

        guard entitlement.periodType == .trial || entitlement.periodType == .intro else {
            #if DEBUG
            print("[TrialReminder] EXIT: periodType is not trial/intro, clearing pending notifications")
            #endif
            clearTrialNotifications()
            return
        }

        guard let expirationDate = entitlement.expirationDate else {
            #if DEBUG
            print("[TrialReminder] EXIT: no expiration date")
            #endif
            return
        }

        // Production: 1 day before expiration
        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: expirationDate) ?? expirationDate
        let interval = reminderDate.timeIntervalSinceNow

        #if DEBUG
        print("[TrialReminder] interval=\(interval)s")
        #endif

        guard interval > 0 else {
            #if DEBUG
            print("[TrialReminder] EXIT: less than 1 day remaining")
            #endif
            return
        }

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: trialReminderIdentifiers)

        // 1. Confirmation notification — 30s after purchase
        let confirmContent = UNMutableNotificationContent()
        confirmContent.title = "Notifications are set up!"
        confirmContent.body = "We'll remind you one day before your free trial ends — no surprises."
        confirmContent.sound = .default

        let confirmTrigger = UNTimeIntervalNotificationTrigger(timeInterval: 30, repeats: false)
        let confirmRequest = UNNotificationRequest(
            identifier: "isaprep_trial_confirmation",
            content: confirmContent,
            trigger: confirmTrigger
        )

        center.add(confirmRequest)

        // 2. Actual reminder — 1 day before trial ends
        let reminderContent = UNMutableNotificationContent()
        reminderContent.title = "Your free trial ends tomorrow"
        reminderContent.body = "Your \(Constants.appName) free trial expires soon. Open the app to keep your access or cancel — no charge if you do."
        reminderContent.sound = .default

        let reminderTrigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let reminderRequest = UNNotificationRequest(
            identifier: "isaprep_trial_reminder",
            content: reminderContent,
            trigger: reminderTrigger
        )

        center.add(reminderRequest)
    }

    func restorePurchases() async {
        await MainActor.run { isLoading = true }
        await Self.requestNotificationPermission()
        let result = await subscriptionRepository.restorePurchase()
        await MainActor.run {
            switch result {
            case .success(let restored):
                if restored {
                    if let customerInfo = self.subscriptionRepository.customerInfo {
                        Self.scheduleTrialReminderIfNeeded(customerInfo: customerInfo)
                    }
                    UIApplication.showAlert(title: "Purchase restored", message: "Your purchase was successfully restored. All of the Pro features were unlocked!") {
                        self.onRestoreSuccess?()
                    }
                } else {
                    UIApplication.showAlert(title: "Purchase not found", message: "Your purchase was not restored because it was not found. If you think this is a mistake, please reach out at \(Constants.supportEmail)")
                }
            case .failure(_):
                UIApplication.showAlert(title: "Purchase restoration failed", message: "An unknown error occured while restoring your purchase. Please try again later or contact support at \(Constants.supportEmail)")
            }
            isLoading = false
        }
    }

    private func trialDays(from period: SubscriptionPeriod) -> Int {
        switch period.unit {
        case .day: return period.value
        case .week: return period.value * 7
        case .month: return period.value * 30
        case .year: return period.value * 365
        }
    }
}
