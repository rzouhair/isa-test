import Foundation
import Observation

@Observable final class AppState {
    /// Pro status. In DEBUG, honors a `debug.forceProUser` UserDefaults
    /// override so you can unlock endorsement content without running
    /// through a real purchase flow.
    var isProUser: Bool {
        #if DEBUG
        if UserDefaults.standard.bool(forKey: "debug.forceProUser") { return true }
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
    /// Flip the local debug pro-user override. UI should call this then
    /// trigger a refresh (e.g., by toggling state) since `isProUser` is a
    /// computed property.
    func toggleDebugPro() {
        let key = "debug.forceProUser"
        let new = !UserDefaults.standard.bool(forKey: key)
        UserDefaults.standard.set(new, forKey: key)
    }
    #endif
}
