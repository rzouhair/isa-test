import RevenueCat
import Foundation
import MessageUI
import SwiftUI

@Observable
class SettingsViewModel {

    var isLoadingRestoration = false
    var isShowingMailComposer = false
    var isShowingManageSubscriptionsSheet = false
    var isShowingCustomerCenter = false
    #if DEBUG
    var sentryTestResult: String?
    #endif

    enum Event {
        case logout
        case deleteAccount
    }

    let onEvent: (Event) -> Void

    init(onEvent: @escaping (Event) -> Void) {
        self.onEvent = onEvent
    }

    func handleItemTap(_ item: SettingsItem) {
        switch item {
        case .manageSubscriptions:
            isShowingCustomerCenter = true
        case .restorePurchase:
            restorePurchase()
        case .reportBug:
            if MFMailComposeViewController.canSendMail() {
                isShowingMailComposer = true
            } else {
                UIApplication.showAlert(title: "Email Not Available", message: "Your device is not configured to send emails. Please report bugs to us at \(Constants.supportEmail)")
            }
        case .messageUs:
            messageUs()
        case .writeReview:
            guard !Constants.appStoreId.isEmpty,
                  let url = URL(string: "https://apps.apple.com/app/\(Constants.appStoreId)?action=write-review") else { return }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
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
        case .toggleDebugPro:
            let key = "debug.forceProUser"
            let now = !UserDefaults.standard.bool(forKey: key)
            UserDefaults.standard.set(now, forKey: key)
            sentryTestResult = "Debug Pro: \(now ? "ON" : "OFF"). Restart app (or close settings) to refresh UI."
        #endif
        case .signOut:
            onEvent(.logout)
        case .deleteAccount:
            onEvent(.deleteAccount)
        case .examDate, .bookmarks, .cheatSheets, .handbook, .aiTutor:
            break   // Handled via NavigationLink (see SettingsView.row(for:))
        }
    }

    func restorePurchase() {
        Task {
            await MainActor.run { isLoadingRestoration = true }
            let result = await SubscriptionService.shared.restorePurchase()
            await MainActor.run {
                isLoadingRestoration = false
                switch result {
                case .success(let restored):
                    if restored {
                        UIApplication.showAlert(title: "Purchase restored", message: "Your purchase was successfully restored. All Pro features were unlocked!")
                    } else {
                        UIApplication.showAlert(title: "Purchase not found", message: "Your purchase was not restored because it was not found. If you think this is a mistake, please reach out at \(Constants.supportEmail)")
                    }
                case .failure:
                    UIApplication.showAlert(title: "Purchase restoration failed", message: "An unknown error occurred while restoring your purchase. Please try again later or contact support at \(Constants.supportEmail)")
                }
            }
        }
    }

    private func openURL(_ string: String) {
        guard !string.isEmpty, let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }

    func messageUs() {
        if MFMailComposeViewController.canSendMail() {
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

    enum SettingsSection: String, CaseIterable, Identifiable {
        case study
        case membership
        case help
        case legal
        #if DEBUG
        case debug
        #endif

        var id: String { rawValue }

        var name: String {
            switch self {
            case .study: return "Study"
            case .membership: return "Membership"
            case .help: return "Help"
            case .legal: return "Legal"
            #if DEBUG
            case .debug: return "Debug"
            #endif
            }
        }

        var items: [SettingsItem] {
            switch self {
            case .study:
                // .cheatSheets hidden until content is seeded.
                var items: [SettingsItem] = [.examDate, .bookmarks, .handbook]
                if Constants.aiTutorEnabled { items.append(.aiTutor) }
                return items
            case .membership: return [.manageSubscriptions, .restorePurchase]
            case .help: return [.reportBug, .messageUs, .writeReview]
            case .legal:
                var legal: [SettingsItem] = []
                if !Constants.privacyPolicyUrl.isEmpty { legal.append(.privacyPolicy) }
                if !Constants.termsOfUseUrl.isEmpty { legal.append(.termsOfUse) }
                return legal
            #if DEBUG
            case .debug: return [.toggleDebugPro, .sendSentryTestEvent]
            #endif
            }
        }
    }

    enum SettingsItem: String, CaseIterable, Identifiable {
        case manageSubscriptions
        case restorePurchase
        case examDate
        case bookmarks
        case cheatSheets
        case handbook
        case aiTutor
        case reportBug
        case messageUs
        case writeReview
        case privacyPolicy
        case termsOfUse
        #if DEBUG
        case sendSentryTestEvent
        case toggleDebugPro
        #endif
        case signOut
        case deleteAccount

        var id: String { rawValue }

        var name: String {
            switch self {
            case .manageSubscriptions: return "Manage Subscriptions"
            case .restorePurchase: return "Restore Purchase"
            case .examDate: return "Exam Date & Reminders"
            case .bookmarks: return "Bookmarks"
            case .cheatSheets: return "Cheat Sheets"
            case .handbook: return "Handbook"
            case .aiTutor: return "AI Tutor"
            case .reportBug: return "Report a Bug"
            case .messageUs: return "Send Us a Message"
            case .writeReview: return "Write a Review"
            case .privacyPolicy: return "Privacy Policy"
            case .termsOfUse: return "Terms of Use"
            #if DEBUG
            case .sendSentryTestEvent: return "Send Sentry Test Event"
            case .toggleDebugPro: return "Toggle Debug Pro Unlock"
            #endif
            case .deleteAccount: return "Delete account"
            case .signOut: return "Sign Out"
            }
        }

        var icon: String {
            switch self {
            case .manageSubscriptions: return "person.circle"
            case .restorePurchase: return "dollarsign.arrow.circlepath"
            case .examDate: return "calendar"
            case .bookmarks: return "bookmark"
            case .cheatSheets: return "book.pages"
            case .handbook: return "book"
            case .aiTutor: return "sparkles"
            case .reportBug: return "ladybug"
            case .messageUs: return "envelope"
            case .writeReview: return "star"
            case .privacyPolicy: return "hand.raised"
            case .termsOfUse: return "doc.text"
            #if DEBUG
            case .sendSentryTestEvent: return "ant.fill"
            case .toggleDebugPro: return "lock.open.fill"
            #endif
            case .deleteAccount: return "trash"
            case .signOut: return "door.left.hand.open"
            }
        }

        var route: Router.Route? {
            switch self {
            case .examDate: return .examDatePicker
            case .bookmarks: return .bookmarks
            case .cheatSheets: return .cheatSheetList
            case .handbook: return .handbook
            case .aiTutor: return .aiTutor(questionId: nil)
            default: return nil
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
