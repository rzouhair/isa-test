//
//  SettingsViewModel.swift
//  paperscan
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
          Task {
            isShowingManageSubscriptionsSheet = true
            if #available(iOS 15.0, *) {
                do {
                    try await Purchases.shared.showManageSubscriptions()
                } catch {
                    // fallback
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        await UIApplication.shared.open(url)
                    }
                }
            } else {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    await UIApplication.shared.open(url)
                }
            }
          }
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
        case .importExport, .priceCheckInterval:
            break // Handled via NavigationLink in SettingsView
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

    enum SettingsSection: String, CaseIterable, Identifiable {
        case personal
        case membership
        case notifications
        case data
        case help

        var id: String { rawValue }

        var name: String {
            switch self {
            case .personal: return "Personal settings"
            case .membership: return "Membership"
            case .notifications: return "Notifications"
            case .data: return "Data"
            case .help: return "Help"
            }
        }

        var items: [SettingsItem] {
            switch self {
            case .personal: return [.manageSubscriptions]
            case .membership: return [.restorePurchase]
            case .notifications: return [.priceCheckInterval]
            case .data: return [.importExport]
            case .help: return [.reportBug, .messageUs, .writeReview]
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
            case .priceCheckInterval: return "Price Check Reminder"
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
            case .priceCheckInterval: return "bell.badge"
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
