import Foundation
import Observation

@Observable final class AppState {
    #if DEBUG
    private static let debugForceProKey = "debug.forceProUser"
    /// Stored override that bypasses the real subscription check.
    /// Backed by UserDefaults so the toggle survives relaunches.
    /// Reads through @Observable, so flipping it triggers SwiftUI refresh.
    var debugForceProOverride: Bool = UserDefaults.standard.bool(forKey: AppState.debugForceProKey) {
        didSet {
            UserDefaults.standard.set(debugForceProOverride, forKey: Self.debugForceProKey)
        }
    }
    #endif

    /// Pro status. In DEBUG, honors `debugForceProOverride` so you can unlock
    /// Pro-gated content without running through a real purchase flow.
    var isProUser: Bool {
        #if DEBUG
        if debugForceProOverride { return true }
        #endif
        return SubscriptionService.shared.isProUser
    }

    // 0 = Home, 1 = Progress, 2 = Settings (Settings opens as sheet, tabs are 0/1)
    var selectedTab: Int = 0
    var wasPaywallShown: Bool = false
    var isPaywallShown: Bool = false

    /// Triggered after Pro activation to show the post-activation notification
    /// permission sheet. RootView observes this and presents the prompt once.
    var isPostActivationNotificationSheetShown: Bool = false

    private static let notificationPromptShownKey = "notifications.postActivationPromptShown"

    var shouldShowPaywall: Bool {
        guard !isProUser else { return false }
        guard !wasPaywallShown else { return false }
        guard !isPaywallShown else { return false }
        return true
    }

    func showPaywall() {
        isPaywallShown = true
        wasPaywallShown = true
    }

    /// Trigger the post-activation notification sheet once per device.
    /// No-op if user has already been asked or already declined.
    func triggerPostActivationNotificationPromptIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.notificationPromptShownKey) else { return }
        guard isProUser else { return }
        defaults.set(true, forKey: Self.notificationPromptShownKey)
        isPostActivationNotificationSheetShown = true
    }

    func dismissPostActivationNotificationSheet() {
        isPostActivationNotificationSheetShown = false
    }

    #if DEBUG
    func toggleDebugPro() {
        debugForceProOverride.toggle()
    }
    #endif
}
