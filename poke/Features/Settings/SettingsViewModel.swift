//
//  SettingsViewModel.swift
//  poke
//
//  Created by user on 24/03/2024.
//

import RevenueCat
import Foundation
import MessageUI
import SwiftUI

@Observable
class SettingsViewModel {
    
    var isLoadingRestoration = false
    var isShowingMailComposer = false
    var isShowingAboutAuthorView = false
    var isShowingManageSubscriptionsSheet = false
    var isShowingCustomerCenter = false
    #if DEBUG
    var sentryTestResult: String?
    #endif
    
    enum Event {
        case logout
        case deleteAccount
    }
    
    let onEvent: (Event) -> ()
    
    init(onEvent: @escaping (Event) -> Void) {
        self.onEvent = onEvent
    }
    
    func handleItemTap(_ item: SettingsItem) {
        switch item {
        case .manageSubscriptions:
            // Surfaces the RevenueCat Customer Center, which handles:
            // cancellation, restore, refund requests, plan swap, and support
            // flows — all backed by the active RevenueCat offering.
            isShowingCustomerCenter = true
        case .restorePurchase: restorePurchase()
        case .aboutAuthor:
            isShowingAboutAuthorView = true
        case .reportBug:
            if MFMailComposeViewController.canSendMail() {
                let mailComposer = MFMailComposeViewController()
                mailComposer.setToRecipients([Constants.supportEmail])
                mailComposer.setSubject("\(Constants.appName) Bug Report")
                mailComposer.setMessageBody("Hello \(Constants.appName) Team,\n\nI'd like to report a bug:\n\n", isHTML: false)
                isShowingMailComposer = true
            } else {
                UIApplication.showAlert(title: "Email Not Available", message: "Your device is not configured to send emails. Please report bugs to us at \(Constants.supportEmail)")
            }
        case .messageUs:
            messageUs()
        case .writeReview:
            // Use the app ID from Constants to redirect the user to the app's AppStore page
            guard let url = URL(string: "https://apps.apple.com/app/\(Constants.appStoreId)?action=write-review") else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        case .importExport, .priceCheckInterval, .priceCheckRemindersEnabled, .priceCheckReminderTime:
            break // Handled inline in SettingsView
        case .privacyPolicy:
            openURL(Constants.privacyPolicyUrl)
        case .termsOfUse:
            openURL(Constants.termsOfUseUrl)
        #if DEBUG
        case .sendSentryTestEvent:
            if let sentry = DIContainer.shared.crashReportingService as? SentryCrashReportingService {
                let marker = sentry.sendDebugTestEvent()
                sentryTestResult = "Sent. Look for marker: \(marker)"
            } else {
                sentryTestResult = "Crash reporting service is not SentryCrashReportingService."
            }
        #endif
        case .signOut:
            onEvent(.logout)
        case .deleteAccount:
            onEvent(.deleteAccount)
        }
    }
    
    func restorePurchase() {
        Task {
            await MainActor.run { isLoadingRestoration = true }
            let result = await SubscriptionService.shared.restorePurchase()
            await MainActor.run(body: {
                isLoadingRestoration = false
                switch result {
                case .success(let restored):
                    if restored {
                        UIApplication.showAlert(title: "Purchase restored", message: "Your purchase was successfully restored. All of the Pro feature were unlocked!")
                    } else {
                        UIApplication.showAlert(title: "Purchase not found", message: "Your purchase was not restored because it was not found. If you think this is a mistake, please reach out at \(Constants.supportEmail)")
                    }
                case .failure(_):
                    UIApplication.showAlert(title: "Purchase restoration failed", message: "An unknown error occurred while restoring your purchase. Please try again later or contact support at \(Constants.supportEmail)")
                }
            })
        }
    }
    
    private func openURL(_ string: String) {
        guard !string.isEmpty, let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    func messageUs() {
        if MFMailComposeViewController.canSendMail() {
            let mailComposer = MFMailComposeViewController()
            mailComposer.setToRecipients([Constants.supportEmail])
            mailComposer.setSubject("\(Constants.appName) Support Request")
            mailComposer.setMessageBody("Hello \(Constants.appName) Team,\n\n", isHTML: false)
            isShowingMailComposer = true
        } else {
            UIApplication.showAlert(title: "Email Not Available", message: "Your device is not configured to send emails. Please contact us at \(Constants.supportEmail)")
        }
    }
    
    var versionString: String {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let buildNumber = Bundle.main.infoDictionary?[kCFBundleVersionKey as String] as? String
        return "Version \(appVersion ?? "") (\(buildNumber ?? ""))"
    }
    
    var selectedRefreshInterval: Int {
        let stored = UserDefaults.standard.double(forKey: WatchlistPriceService.intervalKey)
        return stored > 0 ? Int(stored / 3600) : 12
    }

    func setRefreshInterval(_ hours: Int) {
        WatchlistPriceService.setRefreshInterval(hours: hours)
    }

    var remindersEnabled: Bool {
        get { WatchlistPriceService.remindersEnabled }
        set { Task { @MainActor in
            let applied = await WatchlistPriceService.setRemindersEnabled(newValue)
            if !applied && newValue {
                reminderPermissionDenied = true
            }
        } }
    }

    /// Set when user tries to enable reminders but OS-level permission was denied.
    var reminderPermissionDenied: Bool = false

    var reminderTime: Date {
        get { WatchlistPriceService.reminderDate }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            WatchlistPriceService.setReminderTime(
                hour: comps.hour ?? WatchlistPriceService.defaultReminderHour,
                minute: comps.minute ?? WatchlistPriceService.defaultReminderMinute
            )
        }
    }

    enum SettingsSection: String, CaseIterable, Identifiable {
        case personal
        case membership
        case notifications
        case data
        case help
        case legal
        #if DEBUG
        case debug
        #endif

        var id: String { rawValue }

        var name: String {
            switch self {
            case .personal: return "Personal settings"
            case .membership: return "Membership"
            case .notifications: return "Notifications"
            case .data: return "Data"
            case .help: return "Help"
            case .legal: return "Legal"
            #if DEBUG
            case .debug: return "Debug"
            #endif
            }
        }

        var items: [SettingsItem] {
            switch self {
            case .personal: return [.manageSubscriptions]
            case .membership: return [.restorePurchase]
            case .notifications: return [.priceCheckRemindersEnabled, .priceCheckReminderTime, .priceCheckInterval]
            case .data: return [.importExport]
            case .help: return [.reportBug, .messageUs, .writeReview]
            case .legal:
                var legal: [SettingsItem] = []
                if !Constants.privacyPolicyUrl.isEmpty { legal.append(.privacyPolicy) }
                if !Constants.termsOfUseUrl.isEmpty { legal.append(.termsOfUse) }
                return legal
            #if DEBUG
            case .debug: return [.sendSentryTestEvent]
            #endif
            }
        }
    }
    
    enum SettingsItem: String, CaseIterable, Identifiable {
        case manageSubscriptions
        case restorePurchase
        case aboutAuthor
        case reportBug
        case messageUs
        case writeReview
        case importExport
        case priceCheckInterval
        case priceCheckRemindersEnabled
        case priceCheckReminderTime
        case privacyPolicy
        case termsOfUse
        #if DEBUG
        case sendSentryTestEvent
        #endif
        case signOut
        case deleteAccount

        var id: String { rawValue }

        var name: String {
            switch self {
            case .manageSubscriptions: return "Manage Subscriptions"
            case .restorePurchase: return "Restore Purchase"
            case .aboutAuthor: return "About Author"
            case .reportBug: return "Report a Bug"
            case .messageUs: return "Send Us a Message"
            case .writeReview: return "Write a Review"
            case .importExport: return "Import & Export"
            case .priceCheckInterval: return "Refresh Interval"
            case .priceCheckRemindersEnabled: return "Daily Reminder"
            case .priceCheckReminderTime: return "Reminder Time"
            case .privacyPolicy: return "Privacy Policy"
            case .termsOfUse: return "Terms of Use"
            #if DEBUG
            case .sendSentryTestEvent: return "Send Sentry Test Event"
            #endif
            case .deleteAccount: return "Delete account"
            case .signOut: return "Sign Out"
            }
        }

        var icon: String {
            switch self {
            case .manageSubscriptions: return "person.circle"
            case .restorePurchase: return "dollarsign.arrow.circlepath"
            case .aboutAuthor: return "person"
            case .reportBug: return "ladybug"
            case .messageUs: return "envelope"
            case .writeReview: return "star"
            case .importExport: return "arrow.up.arrow.down"
            case .priceCheckInterval: return "arrow.clockwise"
            case .priceCheckRemindersEnabled: return "bell.badge"
            case .priceCheckReminderTime: return "clock"
            case .privacyPolicy: return "hand.raised"
            case .termsOfUse: return "doc.text"
            #if DEBUG
            case .sendSentryTestEvent: return "ant.fill"
            #endif
            case .deleteAccount: return "trash"
            case .signOut: return "door.left.hand.open"
            }
        }
        
        var isDestructive: Bool {
            switch self {
            case .signOut: return true
            default: return false
            }
        }
    }
    
}
